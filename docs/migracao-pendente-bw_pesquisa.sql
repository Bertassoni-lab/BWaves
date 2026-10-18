-- PENDENTE: aplicar no banco ANTES de publicar pesquisa.html (senao toda resposta falha).
-- Depois de aplicada, este bloco vai para docs/migracoes-aplicadas.sql e este arquivo sai.
-- 18/10/2026 · Pesquisa de satisfacao da 5a edicao (migracao bw_pesquisa)
-- Gerada a partir de assets/pesquisa.js: os codigos dos "check" sao os das opcoes do formulario.
-- Qualquer pessoa envia; so as contas de bw_admins leem e apagam. Sem update: resposta nao se edita.
create table public.bw_pesquisa (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  edicao smallint not null default 5 check (edicao between 1 and 99),
  nota_geral smallint check (nota_geral between 0 and 10),
  gostou text[] not null check (cardinality(gostou) >= 1 and gostou <@ array['palestras', 'networking', 'ambiente', 'gastronomia', 'dinamicas', 'energia', 'outro']::text[]),
  gostou_outro text check (char_length(gostou_outro) <= 200),
  organizacao text check (organizacao in ('excelente', 'muito_boa', 'boa', 'regular', 'precisa_melhorar')),
  ambiente_conexao text check (ambiente_conexao in ('sim_muito', 'sim_parcialmente', 'nao_tanto')),
  momento text check (char_length(momento) <= 1500),
  inspiracao text check (char_length(inspiracao) <= 1500),
  fez_conexao text check (fez_conexao in ('sim_varias', 'sim_uma', 'ainda_nao', 'nao')),
  melhorar text check (char_length(melhorar) <= 1500),
  assuntos text[] not null check (cardinality(assuntos) >= 1 and assuntos <@ array['empreendedorismo', 'posicionamento', 'inteligencia_emocional', 'lideranca', 'comunicacao', 'desenvolvimento_pessoal', 'financas', 'outro']::text[]),
  assuntos_outro text check (char_length(assuntos_outro) <= 200),
  participaria text check (participaria in ('com_certeza', 'provavelmente', 'talvez', 'nao')),
  recomendaria smallint not null check (recomendaria between 0 and 10),
  descreveria text check (char_length(descreveria) <= 1500),
  valor text check (valor in ('superou', 'correspondeu_total', 'correspondeu_parcial', 'abaixo', 'convidada')),
  nome text check (char_length(nome) <= 80)
);
-- o Supabase da ALL em tabela nova para anon/authenticated: tira e devolve so o necessario
revoke all on public.bw_pesquisa from anon, authenticated;
grant insert (edicao, nota_geral, gostou, gostou_outro, organizacao, ambiente_conexao, momento, inspiracao, fez_conexao, melhorar, assuntos, assuntos_outro, participaria, recomendaria, descreveria, valor, nome) on public.bw_pesquisa to anon, authenticated;
grant select, delete on public.bw_pesquisa to authenticated;
alter table public.bw_pesquisa enable row level security;
create policy bw_pesquisa_enviar on public.bw_pesquisa for insert to anon, authenticated with check (true);
create policy bw_pesquisa_admin_ler on public.bw_pesquisa for select to authenticated using (public.bw_is_admin());
create policy bw_pesquisa_admin_apagar on public.bw_pesquisa for delete to authenticated using (public.bw_is_admin());
