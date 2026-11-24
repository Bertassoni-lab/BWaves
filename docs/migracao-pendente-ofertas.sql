-- PENDENTE: aplicar no banco ANTES de publicar o branch ajustes-reuniao-2610 (o cadastro passa a
-- enviar oferta_tipo/oferta_valor/oferta_detalhe; sem as colunas, todo cadastro falha).
-- Depois de aplicada, este bloco vai para docs/migracoes-aplicadas.sql e este arquivo sai.
-- 23/11/2026 · Ofertas guiadas (ata da reuniao de 26/10/2026). Os codigos de oferta_tipo sao os de
-- assets/oferta.js (BW_OFERTA.TIPOS). oferta_bw continua sendo o texto da oferta, montado dos campos.
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
