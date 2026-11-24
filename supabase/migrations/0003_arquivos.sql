-- Facilita · Ficha de entrega de veículos
-- 0003 · Arquivos: fotos, rubricas e PDFs (19/11/2026)
-- Todos os espaços são privados: os arquivos abrem só por link temporário, para quem é da equipe.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('veiculos-fotos', 'veiculos-fotos', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),  -- 4 fotos por veículo (D65)
  ('avarias-fotos',  'avarias-fotos',  false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),  -- fotos de pontos e componentes (A04)
  ('rubricas',       'rubricas',       false, 1048576,  array['image/png']),                              -- rubrica do condutor (D49)
  ('pdfs',           'pdfs',           false, 20971520, array['application/pdf'])                         -- PDF da entrega e PDF final (D50)
on conflict (id) do nothing;

-- Organização das pastas:
--   veiculos-fotos/<veiculo_id>/<vista>.jpg
--   avarias-fotos/<ficha_id>/<entrega|devolucao>/<ponto-ou-componente>.jpg
--   rubricas/<ficha_id>/<entrega|devolucao>.png
--   pdfs/<ficha_id>/<entrega|final>.pdf

create policy arquivos_ve on storage.objects for select to authenticated
  using (bucket_id in ('veiculos-fotos', 'avarias-fotos', 'rubricas', 'pdfs') and public.eh_equipe());

create policy arquivos_envia on storage.objects for insert to authenticated
  with check (bucket_id in ('veiculos-fotos', 'avarias-fotos', 'rubricas', 'pdfs') and public.eh_equipe());

-- Fotos podem ser trocadas; rubricas e PDFs não (o que foi assinado fica como está).
create policy fotos_troca on storage.objects for update to authenticated
  using (bucket_id in ('veiculos-fotos', 'avarias-fotos') and public.eh_equipe())
  with check (bucket_id in ('veiculos-fotos', 'avarias-fotos') and public.eh_equipe());

create policy fotos_apaga on storage.objects for delete to authenticated
  using (bucket_id in ('veiculos-fotos', 'avarias-fotos') and public.eh_equipe());
