-- Migrações aplicadas no Supabase (projeto okgo-homologacao, ref qmjdvnvbodplrwrdxdre), em ordem.
-- 1) bw_vitrine_inicial  -> ver docs/schema-inicial.sql (tabelas, regras de acesso, bucket de logos)
-- 2) bw_revoke_anon_is_admin
revoke execute on function public.bw_is_admin() from anon;

-- 3) bw_painel_participante_link (15/10/2026): link pessoal de edição da participante
alter table public.bw_perfis add column if not exists token_edicao uuid not null default gen_random_uuid();
create unique index if not exists bw_perfis_token_idx on public.bw_perfis (token_edicao);

create or replace function public.bw_meu_perfil(p_token uuid)
returns table (id uuid, status text, tipo text, nome_negocio text, responsavel text, segmento text, cidade text,
  descricao text, instagram text, whatsapp text, site text, logo_url text, oferta_bw text, ofereco text, preciso text, email text)
language sql stable security definer set search_path = public as $$
  select p.id, p.status, p.tipo, p.nome_negocio, p.responsavel, p.segmento, p.cidade, p.descricao, p.instagram,
         p.whatsapp, p.site, p.logo_url, p.oferta_bw, p.ofereco, p.preciso, p.email
  from public.bw_perfis p where p.token_edicao = p_token;
$$;

create or replace function public.bw_atualizar_meu_perfil(p_token uuid, p_dados jsonb)
returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  update public.bw_perfis p set
    nome_negocio = coalesce(nullif(trim(p_dados->>'nome_negocio'), ''), p.nome_negocio),
    responsavel  = coalesce(nullif(trim(p_dados->>'responsavel'), ''), p.responsavel),
    segmento     = coalesce(nullif(trim(p_dados->>'segmento'), ''), p.segmento),
    email        = coalesce(nullif(trim(p_dados->>'email'), ''), p.email),
    tipo         = case when p_dados->>'tipo' in ('participante','patrocinadora','parceira') then p_dados->>'tipo' else p.tipo end,
    cidade    = case when p_dados ? 'cidade'    then nullif(trim(p_dados->>'cidade'), '')    else p.cidade end,
    descricao = case when p_dados ? 'descricao' then nullif(trim(p_dados->>'descricao'), '') else p.descricao end,
    instagram = case when p_dados ? 'instagram' then nullif(trim(p_dados->>'instagram'), '') else p.instagram end,
    whatsapp  = case when p_dados ? 'whatsapp'  then nullif(trim(p_dados->>'whatsapp'), '')  else p.whatsapp end,
    site      = case when p_dados ? 'site'      then nullif(trim(p_dados->>'site'), '')      else p.site end,
    logo_url  = case when p_dados ? 'logo_url'  then nullif(trim(p_dados->>'logo_url'), '')  else p.logo_url end,
    oferta_bw = case when p_dados ? 'oferta_bw' then nullif(trim(p_dados->>'oferta_bw'), '') else p.oferta_bw end,
    ofereco   = case when p_dados ? 'ofereco'   then nullif(trim(p_dados->>'ofereco'), '')   else p.ofereco end,
    preciso   = case when p_dados ? 'preciso'   then nullif(trim(p_dados->>'preciso'), '')   else p.preciso end
  where p.token_edicao = p_token
  returning p.id into v_id;
  if v_id is null then raise exception 'link inválido'; end if;
  return v_id;
end;
$$;

revoke all on function public.bw_meu_perfil(uuid) from public;
revoke all on function public.bw_atualizar_meu_perfil(uuid, jsonb) from public;
grant execute on function public.bw_meu_perfil(uuid) to anon, authenticated;
grant execute on function public.bw_atualizar_meu_perfil(uuid, jsonb) to anon, authenticated;

-- 16/10/2026 · Link da oferta (migração bw_oferta_link)
-- "Quero essa oferta" leva para a página da oferta quando há link; sem link, abre o WhatsApp.
-- A função antiga foi RENOMEADA, não apagada: a ferramenta do Supabase trava em DROP
-- (pede uma confirmação que não chega). bw_meu_perfil_v1 não tem execute para ninguém
-- e pode ser apagada pelo SQL Editor: drop function public.bw_meu_perfil_v1(uuid);
alter table public.bw_perfis add column if not exists oferta_link text;
alter table public.bw_perfis add constraint bw_perfis_oferta_link_url
  check (oferta_link is null or (oferta_link ~* '^https?://[^[:space:]]+$' and length(oferta_link) <= 300));
grant select (oferta_link) on public.bw_perfis to anon;

alter function public.bw_meu_perfil(uuid) rename to bw_meu_perfil_v1;
revoke all on function public.bw_meu_perfil_v1(uuid) from public, anon, authenticated;

create function public.bw_meu_perfil(p_token uuid)
returns table (id uuid, status text, tipo text, nome_negocio text, responsavel text, segmento text, cidade text,
  descricao text, instagram text, whatsapp text, site text, logo_url text, oferta_bw text, oferta_link text, ofereco text, preciso text, email text)
language sql stable security definer set search_path = public as $$
  select p.id, p.status, p.tipo, p.nome_negocio, p.responsavel, p.segmento, p.cidade, p.descricao, p.instagram,
         p.whatsapp, p.site, p.logo_url, p.oferta_bw, p.oferta_link, p.ofereco, p.preciso, p.email
  from public.bw_perfis p where p.token_edicao = p_token;
$$;
revoke all on function public.bw_meu_perfil(uuid) from public;
grant execute on function public.bw_meu_perfil(uuid) to anon, authenticated;

create or replace function public.bw_atualizar_meu_perfil(p_token uuid, p_dados jsonb)
returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_link text := nullif(trim(p_dados->>'oferta_link'), '');
begin
  if v_link is not null and v_link !~* '^https?://' then v_link := 'https://' || v_link; end if;
  update public.bw_perfis p set
    nome_negocio = coalesce(nullif(trim(p_dados->>'nome_negocio'), ''), p.nome_negocio),
    responsavel  = coalesce(nullif(trim(p_dados->>'responsavel'), ''), p.responsavel),
    segmento     = coalesce(nullif(trim(p_dados->>'segmento'), ''), p.segmento),
    email        = coalesce(nullif(trim(p_dados->>'email'), ''), p.email),
    tipo         = case when p_dados->>'tipo' in ('participante','patrocinadora','parceira') then p_dados->>'tipo' else p.tipo end,
    cidade    = case when p_dados ? 'cidade'    then nullif(trim(p_dados->>'cidade'), '')    else p.cidade end,
    descricao = case when p_dados ? 'descricao' then nullif(trim(p_dados->>'descricao'), '') else p.descricao end,
    instagram = case when p_dados ? 'instagram' then nullif(trim(p_dados->>'instagram'), '') else p.instagram end,
    whatsapp  = case when p_dados ? 'whatsapp'  then nullif(trim(p_dados->>'whatsapp'), '')  else p.whatsapp end,
    site      = case when p_dados ? 'site'      then nullif(trim(p_dados->>'site'), '')      else p.site end,
    logo_url  = case when p_dados ? 'logo_url'  then nullif(trim(p_dados->>'logo_url'), '')  else p.logo_url end,
    oferta_bw = case when p_dados ? 'oferta_bw' then nullif(trim(p_dados->>'oferta_bw'), '') else p.oferta_bw end,
    oferta_link = case when p_dados ? 'oferta_link' then v_link else p.oferta_link end,
    ofereco   = case when p_dados ? 'ofereco'   then nullif(trim(p_dados->>'ofereco'), '')   else p.ofereco end,
    preciso   = case when p_dados ? 'preciso'   then nullif(trim(p_dados->>'preciso'), '')   else p.preciso end
  where p.token_edicao = p_token
  returning p.id into v_id;
  if v_id is null then raise exception 'link inválido'; end if;
  return v_id;
end;
$$;

-- dado: a oferta da OkGo ("Site Vendedor") leva para a página dela
update public.bw_perfis set oferta_link = 'https://okgo.dev.br/site-vendedor/'
where id = 'bb8eb686-92eb-495d-b670-c5db128df60e';

-- 18/10/2026 · Pesquisa de satisfacao da 5a edicao (migracao bw_pesquisa), aplicada antes de publicar pesquisa.html
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

-- 24/11/2026 · Ofertas guiadas (migracao bw_ofertas_guiadas), aplicada antes de publicar a vitrine em linhas.
alter table public.bw_perfis
  add column oferta_tipo text check (oferta_tipo in ('desconto_pct', 'desconto_valor', 'gratis', 'brinde', 'especial')),
  add column oferta_valor numeric(10,2) check (oferta_valor > 0 and oferta_valor <= 100000),
  add column oferta_detalhe text check (char_length(oferta_detalhe) <= 120),
  add column oferta_revisar boolean not null default false;
alter table public.bw_perfis add constraint bw_perfis_oferta_pct
  check (oferta_tipo is distinct from 'desconto_pct' or oferta_valor between 1 and 100);
-- leitura publica dos campos que a vitrine desenha; oferta_revisar e' so' do admin
grant select (oferta_tipo, oferta_valor, oferta_detalhe) on public.bw_perfis to anon;

-- bw_meu_perfil passa a devolver os campos. A versao anterior e' renomeada (a ferramenta do
-- Supabase usada pelo Claude trava em DROP) e fica sem permissao para ninguem.
alter function public.bw_meu_perfil(uuid) rename to bw_meu_perfil_v2;
revoke all on function public.bw_meu_perfil_v2(uuid) from public, anon, authenticated;
create function public.bw_meu_perfil(p_token uuid)
returns table (id uuid, status text, tipo text, nome_negocio text, responsavel text, segmento text, cidade text,
  descricao text, instagram text, whatsapp text, site text, logo_url text, oferta_bw text, oferta_link text,
  oferta_tipo text, oferta_valor numeric, oferta_detalhe text, ofereco text, preciso text, email text)
language sql stable security definer set search_path = public as $$
  select p.id, p.status, p.tipo, p.nome_negocio, p.responsavel, p.segmento, p.cidade, p.descricao, p.instagram,
         p.whatsapp, p.site, p.logo_url, p.oferta_bw, p.oferta_link, p.oferta_tipo, p.oferta_valor, p.oferta_detalhe,
         p.ofereco, p.preciso, p.email
  from public.bw_perfis p where p.token_edicao = p_token;
$$;
revoke all on function public.bw_meu_perfil(uuid) from public;
grant execute on function public.bw_meu_perfil(uuid) to anon, authenticated;

-- bw_atualizar_meu_perfil grava os campos; converter para o formato novo tira da revisao
create or replace function public.bw_atualizar_meu_perfil(p_token uuid, p_dados jsonb)
returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_link text := nullif(trim(p_dados->>'oferta_link'), '');
begin
  if v_link is not null and v_link !~* '^https?://' then v_link := 'https://' || v_link; end if;
  update public.bw_perfis p set
    nome_negocio = coalesce(nullif(trim(p_dados->>'nome_negocio'), ''), p.nome_negocio),
    responsavel  = coalesce(nullif(trim(p_dados->>'responsavel'), ''), p.responsavel),
    segmento     = coalesce(nullif(trim(p_dados->>'segmento'), ''), p.segmento),
    email        = coalesce(nullif(trim(p_dados->>'email'), ''), p.email),
    tipo         = case when p_dados->>'tipo' in ('participante','patrocinadora','parceira') then p_dados->>'tipo' else p.tipo end,
    cidade    = case when p_dados ? 'cidade'    then nullif(trim(p_dados->>'cidade'), '')    else p.cidade end,
    descricao = case when p_dados ? 'descricao' then nullif(trim(p_dados->>'descricao'), '') else p.descricao end,
    instagram = case when p_dados ? 'instagram' then nullif(trim(p_dados->>'instagram'), '') else p.instagram end,
    whatsapp  = case when p_dados ? 'whatsapp'  then nullif(trim(p_dados->>'whatsapp'), '')  else p.whatsapp end,
    site      = case when p_dados ? 'site'      then nullif(trim(p_dados->>'site'), '')      else p.site end,
    logo_url  = case when p_dados ? 'logo_url'  then nullif(trim(p_dados->>'logo_url'), '')  else p.logo_url end,
    oferta_bw = case when p_dados ? 'oferta_bw' then nullif(trim(p_dados->>'oferta_bw'), '') else p.oferta_bw end,
    oferta_link = case when p_dados ? 'oferta_link' then v_link else p.oferta_link end,
    oferta_tipo = case when p_dados ? 'oferta_tipo' then nullif(trim(p_dados->>'oferta_tipo'), '') else p.oferta_tipo end,
    oferta_valor = case when p_dados ? 'oferta_valor' then nullif(trim(p_dados->>'oferta_valor'), '')::numeric else p.oferta_valor end,
    oferta_detalhe = case when p_dados ? 'oferta_detalhe' then nullif(trim(p_dados->>'oferta_detalhe'), '') else p.oferta_detalhe end,
    oferta_revisar = case when nullif(trim(p_dados->>'oferta_tipo'), '') is not null then false else p.oferta_revisar end,
    ofereco   = case when p_dados ? 'ofereco'   then nullif(trim(p_dados->>'ofereco'), '')   else p.ofereco end,
    preciso   = case when p_dados ? 'preciso'   then nullif(trim(p_dados->>'preciso'), '')   else p.preciso end
  where p.token_edicao = p_token
  returning p.id into v_id;
  if v_id is null then raise exception 'link inválido'; end if;
  return v_id;
end;
$$;

-- 24/11/2026 · Conversao das 22 ofertas para o formato guiado (dados, junto da migracao acima).
-- Texto de antes, para o caso de precisar voltar alguma (id8 · oferta_bw):
--   00f77423 · Passeio de Lancha - Roteiro 3 Ilhas = Compre 2, pague 1.
--   10494d96 · 10%
--   1b831dbe · 1⁰ Diagnóstico Empresarial e Orientações Gratuito
--   2683a315 · Página web - 15%
--   2b987707 · 10% na primeira compra
--   2c105b81 · 10%
--   4369d58c · Leticia
--   49101cd2 · 5% de desconto
--   6bab488d · Diagnóstico Gratuito para empresas
--   78589de9 · 10%
--   84ade812 · 10,00 de desconto na próxima compra
--   9416af20 · 5%
--   9501a6b1 · 10% nos serviços de staff
--   afeadb66 · 20%
--   b857da92 · 10% off
--   bb8eb686 · Site Vendedor
--   c524967c · 5% off
--   cd3103da · Avaliação gratuita
--   de44ad83 · 30%
--   e0eca7a2 · 5%
--   e5d775d1 · Matrícula Grátis
--   eac4122a · 5%
update public.bw_perfis p set oferta_tipo = c.tipo, oferta_valor = c.valor, oferta_detalhe = c.detalhe,
  oferta_revisar = c.revisar,
  oferta_bw = case c.tipo
    when 'desconto_pct' then trim(trim(to_char(c.valor, 'FM999990')) || '% de desconto ' || coalesce(c.detalhe, ''))
    when 'desconto_valor' then trim('R$ ' || trim(to_char(c.valor, 'FM999990')) || ' de desconto ' || coalesce(c.detalhe, ''))
    when 'gratis' then 'Grátis: ' || c.detalhe
    when 'especial' then upper(left(c.detalhe, 1)) || substr(c.detalhe, 2)
    else p.oferta_bw end
from (values
  ('de44ad83', 'desconto_pct', 30::numeric, null::text, true),
  ('b857da92', 'desconto_pct', 10, null, true),
  ('78589de9', 'desconto_pct', 10, null, true),
  ('2b987707', 'desconto_pct', 10, 'na primeira compra', false),
  ('6bab488d', 'gratis', null, 'diagnóstico para empresas', false),
  ('cd3103da', 'gratis', null, 'avaliação', false),
  ('eac4122a', 'desconto_pct', 5, null, true),
  ('4369d58c', null, null, null, true),
  ('e5d775d1', 'gratis', null, 'matrícula', false),
  ('2c105b81', 'desconto_pct', 10, null, true),
  ('9501a6b1', 'desconto_pct', 10, 'nos serviços de staff', false),
  ('00f77423', 'especial', null, 'compre 2, pague 1 no passeio de lancha Roteiro 3 Ilhas', false),
  ('10494d96', 'desconto_pct', 10, null, true),
  ('bb8eb686', null, null, null, true),
  ('c524967c', 'desconto_pct', 5, null, true),
  ('1b831dbe', 'gratis', null, 'primeiro diagnóstico empresarial e orientações', false),
  ('afeadb66', 'desconto_pct', 20, null, true),
  ('2683a315', 'desconto_pct', 15, 'na criação de página web', false),
  ('84ade812', 'desconto_valor', 10, 'na próxima compra', false),
  ('e0eca7a2', 'desconto_pct', 5, null, true),
  ('9416af20', 'desconto_pct', 5, null, true),
  ('49101cd2', 'desconto_pct', 5, null, true)
) as c(id8, tipo, valor, detalhe, revisar)
where p.id::text like c.id8 || '%' and p.oferta_bw is not null;
