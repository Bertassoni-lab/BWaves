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
