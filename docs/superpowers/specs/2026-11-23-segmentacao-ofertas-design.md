# Segmentação em linhas e ofertas guiadas (ata de 26/10/2026)

Aprovado com o Thiago em 23/11/2026. Partes 1 e 2 da primeira leva da ata; as partes 3 (Supabase
próprio do BW, na conta da Vitória) e 4 (login com Google) dependem de a Vitória criar a conta.
Combinado da reunião: **prints para o Renan validar antes de publicar** os ajustes visuais.

## Dados em 23/11/2026

32 negócios aprovados (meta: 100). 10 segmentos, os maiores genéricos: Serviços (6), Outro (4).
22 ofertas, 9 delas só um número ("10%", "5%"); uma é um nome ("Leticia").

## 1. Segmentação

- A vitrine vira **uma linha por segmento**, ordenadas pelo número de negócios. Cada linha rola
  para o lado (no celular aparece a pontinha do próximo cartão; no computador, setas).
- Segmento com **um negócio só** e o "Outro" vão para a linha **"Mais negócios"**, no fim.
- Atalhos (chips) no topo com cada segmento levam até a linha. O seletor de segmento sai:
  os chips fazem o papel dele.
- As abas que existem (todos, com oferta, participantes, patrocinadoras e parceiras) filtram
  dentro das linhas; linha vazia some.
- **Buscando**, as linhas dão lugar a uma lista única com os resultados.
- Lógica pura: `BW.agruparPorSegmento(lista)` em `assets/bw.js`.

## 2. Ofertas guiadas

- Tipos: `desconto_pct` (selo "10% OFF"), `desconto_valor` ("R$ 10 OFF"), `gratis` ("GRÁTIS"),
  `brinde` ("BRINDE"), `especial` ("ESPECIAL"). Definição única em `assets/oferta.js`
  (`BW_OFERTA`): tipos, rótulos dos campos, `selo()`, `frase()`, `normalizarCaixa()` e o
  componente dos campos com prévia, usado no cadastro, no painel e no admin.
- Campos: tipo; valor (só para desconto); "em quê" / "o que é grátis" / "qual brinde" /
  "qual a condição" (obrigatório quando há tipo, até 120 caracteres).
- `oferta_bw` continua sendo o texto da oferta, agora **montado** dos campos (busca, admin,
  planilha e mensagem de WhatsApp seguem iguais). Oferta antiga sem tipo continua aparecendo,
  com selo "OFERTA BW" e caixa alta ajustada.
- Cartão: selo + o "em quê". Perfil: selo + frase inteira.
- Banco (`bw_perfis`): `oferta_tipo`, `oferta_valor`, `oferta_detalhe` (leitura pública) e
  `oferta_revisar` (só admin). `bw_meu_perfil` passa a devolver os campos (a versão anterior
  é renomeada, padrão do projeto: a ferramenta trava em `DROP`); `bw_atualizar_meu_perfil`
  passa a gravá-los.
- As 22 ofertas atuais: tabela de conversão mostrada ao Thiago antes de aplicar; as que não
  dá para adivinhar ficam com `oferta_revisar` e aparecem marcadas no admin.

## Plano

1. Lógica pura (`agruparPorSegmento`, `BW_OFERTA`) com teste em node.
2. Vitrine em linhas + exibição da oferta nova (index.html, CSS), teste Playwright no modo exemplo
   (exemplos com segmentos suficientes para formar linhas).
3. Campos guiados no cadastro, painel e admin (componente único) + marca "revisar" no admin.
4. Migração do banco testada em transação desfeita; aplicada **só com OK**, junto da conversão.
5. Prints para o Renan; publicar **só depois** da validação.
