-- PENDENTE (dados): conversao das 22 ofertas de 23/11/2026 para o formato guiado. Aplicar junto da
-- migracao, com o OK do Thiago. Oferta so' com numero ("10%") vira desconto sem o "em que" e fica
-- marcada para revisar; o que nao e' oferta ("Leticia", "Site Vendedor") fica como esta, para revisar.
-- oferta_bw e' remontado com a mesma regra de assets/oferta.js (frase).
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
