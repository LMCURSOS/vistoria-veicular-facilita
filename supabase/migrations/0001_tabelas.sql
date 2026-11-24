-- Facilita · Ficha de entrega de veículos
-- 0001 · Tabelas (19/11/2026)
-- Rodar no editor SQL do Supabase, nesta ordem: 0001, 0002, 0003 e depois seed.sql.

-- gen_random_uuid() já vem no Postgres do Supabase.

-- Tipos -------------------------------------------------------------------

create type papel_equipe as enum ('admin', 'equipe');
create type status_ficha as enum ('rascunho', 'em_uso', 'finalizada');
create type momento_vistoria as enum ('entrega', 'devolucao');
create type situacao_item as enum ('conforme', 'avaria_pode_usar', 'avaria_nao_pode_usar');
create type vista_carro as enum ('traseira', 'lateral_direita', 'frente', 'lateral_esquerda');
create type grupo_componente as enum ('externos', 'internos', 'equipamentos');
create type tipo_pdf as enum ('entrega', 'final');
create type status_envio as enum ('enviado', 'falhou');

-- Equipe Facilita (D59) ---------------------------------------------------
-- Cada pessoa da equipe é um usuário do Supabase Auth, criado por convite do admin.

create table equipe (
  id          uuid primary key references auth.users (id) on delete restrict,
  nome        text not null check (length(trim(nome)) > 1),
  email       text not null unique,
  papel       papel_equipe not null default 'equipe',
  ativo       boolean not null default true,
  criado_em   timestamptz not null default now()
);
comment on table equipe is 'Pessoas da equipe Facilita que preenchem as fichas. Só o admin convida, desativa e troca papel.';

-- Tabelas de referência (fixas) -------------------------------------------

create table pontos_padrao (
  numero  smallint primary key check (numero between 1 and 28),
  vista   vista_carro not null,
  peca    text not null,
  x_pct   numeric(5,2) not null check (x_pct between 0 and 100),
  y_pct   numeric(5,2) not null check (y_pct between 0 and 100)
);
comment on table pontos_padrao is 'D66: os 28 pontos do mapa ficam sempre no mesmo lugar da moldura (posição em % da vista). 1 a 27 são do papel; 28 é o retrovisor direito (D29).';

create table componentes_padrao (
  id     smallint primary key check (id between 1 and 16),
  nome   text not null unique,
  grupo  grupo_componente not null,
  ordem  smallint not null
);
comment on table componentes_padrao is 'Os 16 componentes da ficha em papel, nos grupos da D30.';

-- Frota (D60, D64–D68) ----------------------------------------------------

create table veiculos (
  id                     uuid primary key default gen_random_uuid(),
  modelo                 text not null check (length(trim(modelo)) > 1),
  placa                  text not null unique check (placa ~ '^[A-Z0-9-]{7,8}$'),
  foto_traseira          text,
  foto_lateral_direita   text,
  foto_frente            text,
  foto_lateral_esquerda  text,
  ativo                  boolean not null default true,
  criado_por             uuid references equipe (id),
  criado_em              timestamptz not null default now(),
  atualizado_em          timestamptz not null default now()
);
comment on table veiculos is 'Veículos do sistema, não de quem cadastrou (D64). Nunca são apagados, só desativados (D68).';

-- D67: o carro só aparece na ficha de entrega com as 4 fotos.
create view veiculos_disponiveis with (security_invoker = true) as
  select * from veiculos
  where ativo
    and foto_traseira is not null and foto_lateral_direita is not null
    and foto_frente is not null and foto_lateral_esquerda is not null;

-- Condutores (D53, D61, D63) ----------------------------------------------

create table condutores (
  id            uuid primary key default gen_random_uuid(),
  nome          text not null check (length(trim(nome)) > 1),
  cnh           text not null unique check (cnh ~ '^[0-9]{11}$'),
  validade_cnh  date not null,
  email         text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  telefone      text,
  criado_por    uuid references equipe (id),
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
comment on column condutores.validade_cnh is 'D63: CNH vencida só avisa, não trava a entrega.';

-- Fichas ------------------------------------------------------------------
-- Uma ficha só, do rascunho à devolução (D01, D37, D58).

create table fichas (
  id                      uuid primary key default gen_random_uuid(),
  status                  status_ficha not null default 'rascunho',
  veiculo_id              uuid not null references veiculos (id),
  condutor_id             uuid references condutores (id),

  -- retrato da época (D64): mudar o cadastro depois não muda fichas antigas
  modelo_da_epoca         text,
  placa_da_epoca          text,
  condutor_nome           text,
  condutor_cnh            text,
  condutor_validade_cnh   date,
  condutor_email          text,

  -- entrega (saída)
  saida_em                timestamptz,
  km_inicial              integer check (km_inicial >= 0),
  combustivel_saida       smallint check (combustivel_saida between 0 and 8),  -- 9 posições (D06): 0 vazio … 8 cheio
  entrega_por             uuid references equipe (id),
  entrega_em              timestamptz,
  rubrica_entrega         text,
  rubrica_entrega_em      timestamptz,
  pdf_entrega             text,

  -- devolução (chegada)
  chegada_em              timestamptz,
  km_final                integer,
  combustivel_chegada     smallint check (combustivel_chegada between 0 and 8),
  trajeto                 text,                                               -- A07: texto livre, preenchido na devolução (D43)
  houve_avaria_nova       boolean,                                            -- D62
  devolucao_por           uuid references equipe (id),
  devolucao_em            timestamptz,
  rubrica_devolucao       text,
  rubrica_devolucao_em    timestamptz,
  pdf_final               text,

  mes_referencia          date generated always as (date_trunc('month', saida_em at time zone 'America/Sao_Paulo')::date) stored,  -- A08: mês da saída
  apagar_em               date,                                               -- LGPD: prazo de guarda, a definir com o jurídico
  criado_por              uuid not null references equipe (id),
  criado_em               timestamptz not null default now(),
  atualizado_em           timestamptz not null default now(),

  constraint km_final_maior check (km_final is null or km_inicial is null or km_final >= km_inicial),
  constraint chegada_depois_da_saida check (chegada_em is null or saida_em is null or chegada_em >= saida_em)
);
create index fichas_status_idx on fichas (status);
create index fichas_mes_idx on fichas (mes_referencia desc);
create index fichas_veiculo_idx on fichas (veiculo_id);
create index fichas_condutor_idx on fichas (condutor_id);

-- Um carro não pode estar em duas entregas abertas ao mesmo tempo.
create unique index um_uso_por_veiculo on fichas (veiculo_id) where status = 'em_uso';

-- Vistoria: antes (entrega) e depois (devolução) -------------------------

create table ficha_pontos (
  ficha_id     uuid not null references fichas (id) on delete cascade,
  momento      momento_vistoria not null,
  ponto        smallint not null references pontos_padrao (numero),
  situacao     situacao_item not null,
  observacao   text,
  foto         text,                      -- A04: opcional, recomendada; vai no anexo do PDF
  marcado_por  uuid references equipe (id),
  marcado_em   timestamptz not null default now(),
  primary key (ficha_id, momento, ponto)
);

create table ficha_componentes (
  ficha_id     uuid not null references fichas (id) on delete cascade,
  momento      momento_vistoria not null,
  componente   smallint not null references componentes_padrao (id),
  situacao     situacao_item not null,
  observacao   text,
  foto         text,
  marcado_por  uuid references equipe (id),
  marcado_em   timestamptz not null default now(),
  primary key (ficha_id, momento, componente)
);

-- Envios do PDF (D52, D57) ------------------------------------------------

create table envios (
  id           uuid primary key default gen_random_uuid(),
  ficha_id     uuid not null references fichas (id) on delete cascade,
  pdf          tipo_pdf not null,
  para         text[] not null check (cardinality(para) between 1 and 5),
  status       status_envio not null,
  erro         text,
  enviado_por  uuid not null references equipe (id),
  enviado_em   timestamptz not null default now()
);
create index envios_ficha_idx on envios (ficha_id, enviado_em desc);

-- Correções feitas pelo admin em fichas finalizadas ----------------------

create table correcoes (
  id              uuid primary key default gen_random_uuid(),
  ficha_id        uuid not null references fichas (id) on delete cascade,
  campo           text not null,
  valor_anterior  text,
  valor_novo      text,
  motivo          text not null check (length(trim(motivo)) > 4),
  feito_por       uuid not null references equipe (id),
  feito_em        timestamptz not null default now()
);
comment on table correcoes is 'Ficha finalizada só muda pelo admin, com motivo; cada mudança fica registrada aqui.';
