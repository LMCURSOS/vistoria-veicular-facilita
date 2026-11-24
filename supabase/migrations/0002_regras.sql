-- Facilita · Ficha de entrega de veículos
-- 0002 · Regras: quem pode o quê, auditoria e travas da ficha (19/11/2026)

-- Quem está usando ---------------------------------------------------------

create or replace function eh_equipe() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from equipe where id = auth.uid() and ativo);
$$;

create or replace function eh_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from equipe where id = auth.uid() and ativo and papel = 'admin');
$$;

-- atualizado_em -------------------------------------------------------------

create or replace function tg_atualizado_em() returns trigger
language plpgsql as $$
begin
  new.atualizado_em := now();
  return new;
end $$;

create trigger veiculos_atualizado before update on veiculos for each row execute function tg_atualizado_em();
create trigger condutores_atualizado before update on condutores for each row execute function tg_atualizado_em();

-- Equipe: convite por e-mail ---------------------------------------------
-- O admin convida pelo painel do Supabase (Authentication > Users > Invite user).
-- Quem é convidado entra na equipe como 'equipe'; o nome pode ser ajustado depois.

create or replace function tg_novo_usuario() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into equipe (id, nome, email, papel)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'nome', ''), split_part(new.email, '@', 1)),
    new.email,
    case when (select count(*) from equipe) = 0 then 'admin'::papel_equipe else 'equipe'::papel_equipe end  -- a primeira pessoa vira admin
  )
  on conflict (id) do nothing;
  return new;
end $$;

create trigger auth_novo_usuario after insert on auth.users
  for each row execute function tg_novo_usuario();

-- Só o admin muda papel, ativo e e-mail; ninguém tira o último admin ativo.
create or replace function tg_equipe_regras() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not eh_admin() then
    if new.papel <> old.papel or new.ativo <> old.ativo or new.email <> old.email or new.id <> auth.uid() then
      raise exception 'Só o admin muda papel, situação ou e-mail da equipe.';
    end if;
  end if;
  if (old.papel = 'admin' and old.ativo) and not (new.papel = 'admin' and new.ativo)
     and (select count(*) from equipe where papel = 'admin' and ativo and id <> old.id) = 0 then
    raise exception 'A equipe precisa de pelo menos um admin ativo.';
  end if;
  return new;
end $$;

create trigger equipe_regras before update on equipe for each row execute function tg_equipe_regras();

-- Frota e condutores --------------------------------------------------------

create or replace function tg_veiculo_normaliza() returns trigger
language plpgsql as $$
begin
  new.placa := upper(regexp_replace(new.placa, '[^A-Za-z0-9-]', '', 'g'));
  if tg_op = 'INSERT' then new.criado_por := coalesce(auth.uid(), new.criado_por); end if;
  return new;
end $$;
create trigger veiculos_normaliza before insert or update on veiculos for each row execute function tg_veiculo_normaliza();

create or replace function tg_condutor_normaliza() returns trigger
language plpgsql as $$
begin
  new.cnh := regexp_replace(new.cnh, '\D', '', 'g');
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then new.criado_por := coalesce(auth.uid(), new.criado_por); end if;
  return new;
end $$;
create trigger condutores_normaliza before insert or update on condutores for each row execute function tg_condutor_normaliza();

-- Ficha: nascimento ---------------------------------------------------------

create or replace function tg_ficha_insere() returns trigger
language plpgsql security definer set search_path = public as $$
declare v veiculos;
begin
  select * into v from veiculos where id = new.veiculo_id;
  if v.id is null or not v.ativo then
    raise exception 'Veículo inexistente ou desativado.';
  end if;
  if v.foto_traseira is null or v.foto_lateral_direita is null or v.foto_frente is null or v.foto_lateral_esquerda is null then
    raise exception 'O veículo precisa das 4 fotos antes de entrar numa ficha (D67).';
  end if;
  new.status := 'rascunho';
  new.criado_por := coalesce(auth.uid(), new.criado_por);
  new.modelo_da_epoca := v.modelo;
  new.placa_da_epoca := v.placa;
  -- nada de entrega/devolução registrado por fora do fluxo
  new.entrega_por := null; new.entrega_em := null; new.rubrica_entrega_em := null;
  new.devolucao_por := null; new.devolucao_em := null; new.rubrica_devolucao_em := null;
  return new;
end $$;
create trigger fichas_insere before insert on fichas for each row execute function tg_ficha_insere();

-- Ficha: mudanças e passagem de etapa --------------------------------------
-- rascunho → em_uso (rubrica da entrega) → finalizada (rubrica da devolução). Não volta.

create or replace function tg_ficha_atualiza() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  faltam_pontos int; faltam_comp int; bloqueio int; c condutores;
begin
  -- correção do admin (função corrigir_ficha) passa direto
  if current_setting('ficha.correcao', true) = 'on' then
    new.atualizado_em := now();
    return new;
  end if;

  if old.status = 'finalizada' then
    raise exception 'Ficha finalizada não muda. Correções só pelo admin, com motivo.';
  end if;
  if (old.status = 'em_uso' and new.status = 'rascunho') or (old.status = 'rascunho' and new.status = 'finalizada') then
    raise exception 'A ficha não pula nem volta etapa.';
  end if;

  -- campos que nunca mudam por aqui
  new.id := old.id; new.criado_por := old.criado_por; new.criado_em := old.criado_em;
  new.modelo_da_epoca := old.modelo_da_epoca; new.placa_da_epoca := old.placa_da_epoca;

  if old.status = 'em_uso' then
    -- a entrega já foi assinada: fica como estava (o PDF da entrega pode ser gravado uma vez)
    new.veiculo_id := old.veiculo_id; new.condutor_id := old.condutor_id;
    new.condutor_nome := old.condutor_nome; new.condutor_cnh := old.condutor_cnh;
    new.condutor_validade_cnh := old.condutor_validade_cnh; new.condutor_email := old.condutor_email;
    new.saida_em := old.saida_em; new.km_inicial := old.km_inicial; new.combustivel_saida := old.combustivel_saida;
    new.entrega_por := old.entrega_por; new.entrega_em := old.entrega_em;
    new.rubrica_entrega := old.rubrica_entrega; new.rubrica_entrega_em := old.rubrica_entrega_em;
    new.pdf_entrega := coalesce(old.pdf_entrega, new.pdf_entrega);
  else
    new.entrega_por := null; new.entrega_em := null; new.rubrica_entrega_em := null;
    if new.veiculo_id <> old.veiculo_id then
      perform 1 from veiculos where id = new.veiculo_id and ativo;
      if not found then raise exception 'Veículo inexistente ou desativado.'; end if;
      select modelo, placa into new.modelo_da_epoca, new.placa_da_epoca from veiculos where id = new.veiculo_id;
    end if;
  end if;

  -- passagem: entrega assinada
  if old.status = 'rascunho' and new.status = 'em_uso' then
    if new.condutor_id is null or new.saida_em is null or new.km_inicial is null
       or new.combustivel_saida is null or new.rubrica_entrega is null then
      raise exception 'Para concluir a entrega faltam condutor, saída, KM inicial, combustível ou rubrica.';
    end if;
    select 28 - count(*) into faltam_pontos from ficha_pontos where ficha_id = new.id and momento = 'entrega';
    select 16 - count(*) into faltam_comp from ficha_componentes where ficha_id = new.id and momento = 'entrega';
    if faltam_pontos > 0 or faltam_comp > 0 then
      raise exception 'Complete os itens pendentes: faltam % pontos e % componentes (D23).', faltam_pontos, faltam_comp;
    end if;
    select (select count(*) from ficha_pontos where ficha_id = new.id and momento = 'entrega' and situacao = 'avaria_nao_pode_usar')
         + (select count(*) from ficha_componentes where ficha_id = new.id and momento = 'entrega' and situacao = 'avaria_nao_pode_usar')
      into bloqueio;
    if bloqueio > 0 then
      raise exception 'Veículo não pode ser entregue: há avaria que não permite o uso (D38).';
    end if;
    select * into c from condutores where id = new.condutor_id;
    new.condutor_nome := c.nome; new.condutor_cnh := c.cnh;
    new.condutor_validade_cnh := c.validade_cnh; new.condutor_email := c.email;
    new.entrega_por := coalesce(auth.uid(), new.entrega_por);
    new.entrega_em := now();
    new.rubrica_entrega_em := now();
  end if;

  -- passagem: devolução assinada
  if old.status = 'em_uso' and new.status = 'finalizada' then
    if new.chegada_em is null or new.km_final is null or new.combustivel_chegada is null
       or new.houve_avaria_nova is null or new.rubrica_devolucao is null then
      raise exception 'Para concluir a devolução faltam chegada, KM final, combustível, a resposta sobre avaria nova ou a rubrica.';
    end if;
    new.devolucao_por := coalesce(auth.uid(), new.devolucao_por);
    new.devolucao_em := now();
    new.rubrica_devolucao_em := now();
  elsif new.status <> 'finalizada' then
    -- antes da devolução assinada, ninguém grava esses campos à mão
    new.devolucao_por := null; new.devolucao_em := null; new.rubrica_devolucao_em := null;
  end if;

  new.atualizado_em := now();
  return new;
end $$;
create trigger fichas_atualiza before update on fichas for each row execute function tg_ficha_atualiza();

-- Itens da vistoria: só na etapa certa -------------------------------------
-- Pontos e componentes da entrega mudam só no rascunho; os da devolução, só com o carro em uso.

create or replace function tg_item_etapa() returns trigger
language plpgsql security definer set search_path = public as $$
declare st status_ficha; m momento_vistoria; fid uuid;
begin
  if current_setting('ficha.correcao', true) = 'on' then
    return coalesce(new, old);
  end if;
  fid := coalesce(new.ficha_id, old.ficha_id);
  m := coalesce(new.momento, old.momento);
  select status into st from fichas where id = fid;
  if (m = 'entrega' and st <> 'rascunho') or (m = 'devolucao' and st <> 'em_uso') then
    raise exception 'Este item não pode mais mudar nesta etapa da ficha.';
  end if;
  if tg_op <> 'DELETE' then
    new.marcado_por := coalesce(auth.uid(), new.marcado_por);
    new.marcado_em := now();
    return new;
  end if;
  return old;
end $$;
create trigger pontos_etapa before insert or update or delete on ficha_pontos for each row execute function tg_item_etapa();
create trigger componentes_etapa before insert or update or delete on ficha_componentes for each row execute function tg_item_etapa();

-- Envios: registra quem enviou ---------------------------------------------

create or replace function tg_envio() returns trigger
language plpgsql as $$
begin
  new.enviado_por := coalesce(auth.uid(), new.enviado_por);
  new.enviado_em := now();
  return new;
end $$;
create trigger envios_registra before insert on envios for each row execute function tg_envio();

-- Correção de ficha finalizada (só admin, com motivo e registro) -----------

create or replace function corrigir_ficha(p_ficha uuid, p_campo text, p_valor text, p_motivo text)
returns void language plpgsql security definer set search_path = public as $$
declare anterior text;
begin
  if not eh_admin() then
    raise exception 'Só o admin corrige ficha finalizada.';
  end if;
  if p_campo not in ('km_inicial', 'km_final', 'combustivel_saida', 'combustivel_chegada', 'trajeto',
                     'saida_em', 'chegada_em', 'condutor_nome', 'condutor_cnh', 'condutor_validade_cnh', 'condutor_email') then
    raise exception 'Campo % não pode ser corrigido.', p_campo;
  end if;
  if coalesce(length(trim(p_motivo)), 0) < 5 then
    raise exception 'Informe o motivo da correção.';
  end if;
  execute format('select %I::text from fichas where id = $1', p_campo) into anterior using p_ficha;
  perform set_config('ficha.correcao', 'on', true);
  execute format('update fichas set %I = $1::%s where id = $2', p_campo,
                 (select format_type(atttypid, atttypmod) from pg_attribute
                   where attrelid = 'fichas'::regclass and attname = p_campo))
    using p_valor, p_ficha;
  perform set_config('ficha.correcao', 'off', true);
  insert into correcoes (ficha_id, campo, valor_anterior, valor_novo, motivo, feito_por)
  values (p_ficha, p_campo, anterior, p_valor, p_motivo, auth.uid());
end $$;

-- LGPD: limpeza das fichas vencidas (o prazo será definido com o jurídico) --
-- Ainda não é agendada. As fotos, rubricas e PDFs são apagados pela função do servidor que chama esta.

create or replace function fichas_vencidas() returns setof fichas
language sql stable security definer set search_path = public as $$
  select * from fichas where apagar_em is not null and apagar_em < current_date;
$$;

-- Acesso por linha (RLS) ----------------------------------------------------

alter table equipe enable row level security;
alter table pontos_padrao enable row level security;
alter table componentes_padrao enable row level security;
alter table veiculos enable row level security;
alter table condutores enable row level security;
alter table fichas enable row level security;
alter table ficha_pontos enable row level security;
alter table ficha_componentes enable row level security;
alter table envios enable row level security;
alter table correcoes enable row level security;

create policy equipe_ve on equipe for select to authenticated using (eh_equipe());
create policy equipe_muda on equipe for update to authenticated using (eh_admin() or id = auth.uid()) with check (eh_admin() or id = auth.uid());

create policy pontos_ve on pontos_padrao for select to authenticated using (eh_equipe());
create policy componentes_ve on componentes_padrao for select to authenticated using (eh_equipe());

create policy veiculos_ve on veiculos for select to authenticated using (eh_equipe());
create policy veiculos_cria on veiculos for insert to authenticated with check (eh_equipe());
create policy veiculos_muda on veiculos for update to authenticated using (eh_equipe()) with check (eh_equipe());
-- sem política de delete: veículo não se apaga (D68)

create policy condutores_ve on condutores for select to authenticated using (eh_equipe());
create policy condutores_cria on condutores for insert to authenticated with check (eh_equipe());
create policy condutores_muda on condutores for update to authenticated using (eh_equipe()) with check (eh_equipe());

create policy fichas_ve on fichas for select to authenticated using (eh_equipe());
create policy fichas_cria on fichas for insert to authenticated with check (eh_equipe());
create policy fichas_muda on fichas for update to authenticated using (eh_equipe()) with check (eh_equipe());
create policy fichas_exclui_rascunho on fichas for delete to authenticated
  using (eh_equipe() and status = 'rascunho' and (criado_por = auth.uid() or eh_admin()));   -- D58

create policy pontos_ficha_ve on ficha_pontos for select to authenticated using (eh_equipe());
create policy pontos_ficha_cria on ficha_pontos for insert to authenticated with check (eh_equipe());
create policy pontos_ficha_muda on ficha_pontos for update to authenticated using (eh_equipe()) with check (eh_equipe());
create policy pontos_ficha_tira on ficha_pontos for delete to authenticated using (eh_equipe());

create policy comp_ficha_ve on ficha_componentes for select to authenticated using (eh_equipe());
create policy comp_ficha_cria on ficha_componentes for insert to authenticated with check (eh_equipe());
create policy comp_ficha_muda on ficha_componentes for update to authenticated using (eh_equipe()) with check (eh_equipe());
create policy comp_ficha_tira on ficha_componentes for delete to authenticated using (eh_equipe());

create policy envios_ve on envios for select to authenticated using (eh_equipe());
create policy envios_cria on envios for insert to authenticated with check (eh_equipe());

create policy correcoes_ve on correcoes for select to authenticated using (eh_equipe());
-- correções entram só pela função corrigir_ficha

-- Acesso pela API ---------------------------------------------------------
-- O projeto é criado sem acesso automático das tabelas novas à API.
-- Aqui fica explícito: só quem está logado (authenticated) chega às tabelas,
-- e mesmo assim as políticas acima decidem o que cada um vê.
-- Visitante sem login (anon) não chega a nada.
revoke all on all tables in schema public from anon, public;
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
revoke execute on function eh_equipe(), eh_admin(), corrigir_ficha(uuid, text, text, text) from public, anon;
grant execute on function eh_equipe(), eh_admin() to authenticated;
grant execute on function corrigir_ficha(uuid, text, text, text) to authenticated;
revoke execute on function fichas_vencidas() from public, anon, authenticated;
