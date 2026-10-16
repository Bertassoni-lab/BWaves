-- Voucher Maresias Tour (16/10/2026): passeio de lancha compartilhada para as 20 primeiras
-- participantes da lista do evento que resgatarem no painel.
--
-- Os codigos sao cupons de uso unico criados no sistema de passeios da Maresias Tour
-- (R$ 200 de desconto, valor minimo R$ 300, so no passeio "As 3 Ilhas da Costa Sul",
-- valido ate 16/02/2027). O valor minimo e' a regra do acompanhante pagante: sozinha a
-- reserva da R$ 200 e nao passa; com qualquer acompanhante pagante passa.
--
-- A vitrine guarda os codigos e entrega um por participante. Nenhum dado dela vai para a
-- Maresias Tour: e' ela quem leva o codigo ao agendar.

-- Lista de inscritas do evento: e' ela que diz quem tem direito. So' o admin le.
create table if not exists public.bw_lista_evento (
  id bigint generated always as identity primary key,
  nome text not null,
  whatsapp text,
  email text,
  created_at timestamptz not null default now()
);
alter table public.bw_lista_evento enable row level security;
revoke all on public.bw_lista_evento from anon;
create policy "admin cuida da lista" on public.bw_lista_evento
  for all to authenticated using (public.bw_is_admin()) with check (public.bw_is_admin());

-- Os codigos. perfil_id vazio = livre. Unico: uma participante, um codigo.
create table if not exists public.bw_vouchers (
  codigo text primary key,
  perfil_id uuid unique references public.bw_perfis(id) on delete set null,
  resgatado_em timestamptz
);
alter table public.bw_vouchers enable row level security;
revoke all on public.bw_vouchers from anon;
create policy "admin ve os vouchers" on public.bw_vouchers
  for select to authenticated using (public.bw_is_admin());

-- Telefone comparavel: so digitos e sem o 55 do pais (a lista e o cadastro escrevem diferente).
create or replace function public.bw_fone(p text) returns text
language sql immutable set search_path = public as $$
  select case when length(d) >= 12 and left(d, 2) = '55' then substr(d, 3) else d end
  from (select regexp_replace(coalesce(p, ''), '\D', '', 'g') as d) x;
$$;

-- Situacao do voucher da participante, pelo link pessoal; com p_resgatar, resgata.
-- situacao: resgatado | disponivel | esgotado | fora_da_lista
create or replace function public.bw_voucher(p_token uuid, p_resgatar boolean default false)
returns table (situacao text, codigo text, resgatado_em timestamptz, restantes int)
language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare
  v_perfil public.bw_perfis;
  v_cod text;
  v_em timestamptz;
begin
  select * into v_perfil from public.bw_perfis p where p.token_edicao = p_token;
  if v_perfil.id is null then raise exception 'link inválido'; end if;
  -- trava o perfil: dois toques ao mesmo tempo nao pegam dois codigos
  if p_resgatar then perform 1 from public.bw_perfis p where p.id = v_perfil.id for update; end if;

  select v.codigo, v.resgatado_em into v_cod, v_em from public.bw_vouchers v where v.perfil_id = v_perfil.id;
  if v_cod is not null then
    return query select 'resgatado'::text, v_cod, v_em, (select count(*)::int from public.bw_vouchers v where v.perfil_id is null);
    return;
  end if;

  if not exists (
    select 1 from public.bw_lista_evento l
    where (public.bw_fone(l.whatsapp) <> '' and public.bw_fone(l.whatsapp) = public.bw_fone(v_perfil.whatsapp))
       or (coalesce(l.email, '') <> '' and lower(trim(l.email)) = lower(trim(v_perfil.email)))
  ) then
    return query select 'fora_da_lista'::text, null::text, null::timestamptz, null::int;
    return;
  end if;

  if not p_resgatar then
    return query select
      case when exists (select 1 from public.bw_vouchers v where v.perfil_id is null) then 'disponivel' else 'esgotado' end,
      null::text, null::timestamptz, (select count(*)::int from public.bw_vouchers v where v.perfil_id is null);
    return;
  end if;

  -- o proximo codigo livre, sem disputar com outro resgate acontecendo ao mesmo tempo
  update public.bw_vouchers v set perfil_id = v_perfil.id, resgatado_em = now()
   where v.codigo = (select l.codigo from public.bw_vouchers l where l.perfil_id is null
                     order by l.codigo limit 1 for update skip locked)
  returning v.codigo, v.resgatado_em into v_cod, v_em;

  if v_cod is null then
    return query select 'esgotado'::text, null::text, null::timestamptz, 0;
    return;
  end if;
  return query select 'resgatado'::text, v_cod, v_em, (select count(*)::int from public.bw_vouchers v where v.perfil_id is null);
end;
$$;
revoke all on function public.bw_voucher(uuid, boolean) from public;
grant execute on function public.bw_voucher(uuid, boolean) to anon, authenticated;
