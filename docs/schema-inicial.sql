-- Vitrine BW · Business Wave
-- Banco: Supabase (Postgres). Rodar uma vez no projeto escolhido.
-- Regras: o público vê só perfis aprovados e só as colunas públicas;
-- e-mail de contato fica privado; qualquer pessoa pode se cadastrar (entra como pendente);
-- só admins (tabela bw_admins) aprovam, editam e mexem no ranking.

create extension if not exists pgcrypto;

-- ADMINS ---------------------------------------------------------------
create table if not exists public.bw_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  created_at timestamptz not null default now()
);
alter table public.bw_admins enable row level security;

create or replace function public.bw_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.bw_admins where user_id = auth.uid());
$$;
revoke all on function public.bw_is_admin() from public;
grant execute on function public.bw_is_admin() to anon, authenticated;

create policy "admins se veem" on public.bw_admins
  for select to authenticated using (public.bw_is_admin());

-- PERFIS DA VITRINE ------------------------------------------------------
create table if not exists public.bw_perfis (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  tipo text not null default 'participante'
    check (tipo in ('participante','patrocinadora','parceira')),
  nome_negocio text not null check (char_length(nome_negocio) between 2 and 80),
  responsavel  text not null check (char_length(responsavel) between 2 and 80),
  segmento     text not null check (char_length(segmento) <= 40),
  cidade       text check (char_length(cidade) <= 60),
  descricao    text check (char_length(descricao) <= 400),
  instagram    text check (char_length(instagram) <= 60),
  whatsapp     text check (char_length(whatsapp) <= 20),
  site         text check (char_length(site) <= 200),
  logo_url     text check (char_length(logo_url) <= 400),
  oferta_bw    text check (char_length(oferta_bw) <= 160),
  ofereco      text check (char_length(ofereco) <= 200),
  preciso      text check (char_length(preciso) <= 200),
  email        text not null check (char_length(email) <= 120),   -- privado
  consentimento boolean not null check (consentimento = true),
  status  text not null default 'pendente' check (status in ('pendente','aprovado','recusado')),
  destaque boolean not null default false
);
create index if not exists bw_perfis_status_idx on public.bw_perfis (status, tipo);
alter table public.bw_perfis enable row level security;

-- público: só colunas públicas, só aprovados
revoke select on public.bw_perfis from anon;
grant select (id, created_at, tipo, nome_negocio, responsavel, segmento, cidade, descricao,
              instagram, whatsapp, site, logo_url, oferta_bw, ofereco, preciso, destaque, status)
  on public.bw_perfis to anon;
grant insert on public.bw_perfis to anon;

create policy "publico ve aprovados" on public.bw_perfis
  for select to anon using (status = 'aprovado');
create policy "cadastro entra pendente" on public.bw_perfis
  for insert to anon, authenticated
  with check (status = 'pendente' and destaque = false and consentimento = true);
create policy "admin le tudo" on public.bw_perfis
  for select to authenticated using (public.bw_is_admin() or status = 'aprovado');
create policy "admin edita" on public.bw_perfis
  for update to authenticated using (public.bw_is_admin()) with check (public.bw_is_admin());
create policy "admin apaga" on public.bw_perfis
  for delete to authenticated using (public.bw_is_admin());

-- RANKING DAS EMBAIXADORAS -------------------------------------------------
create table if not exists public.bw_embaixadoras (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (char_length(nome) <= 80),
  instagram text check (char_length(instagram) <= 60),
  vendas int not null default 0 check (vendas >= 0),
  atualizado_em timestamptz not null default now()
);
alter table public.bw_embaixadoras enable row level security;
create policy "ranking publico" on public.bw_embaixadoras
  for select to anon, authenticated using (true);
create policy "admin mexe no ranking" on public.bw_embaixadoras
  for all to authenticated using (public.bw_is_admin()) with check (public.bw_is_admin());

-- LOGOS (storage) --------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('bw-logos', 'bw-logos', true, 3145728, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "bw_logos_insert" on storage.objects
  for insert to anon, authenticated with check (bucket_id = 'bw-logos');
create policy "bw_logos_select" on storage.objects
  for select to anon, authenticated using (bucket_id = 'bw-logos');
create policy "bw_logos_delete" on storage.objects
  for delete to authenticated using (bucket_id = 'bw-logos' and public.bw_is_admin());

-- Depois de criar o usuário da Vitória em Authentication > Users:
-- insert into public.bw_admins (user_id, nome) values ('<uuid do usuário>', 'Vitória Lemes');
