# Pesquisa de satisfação · 5ª edição

Desenho aprovado em 18/10/2026. Texto das perguntas: o enviado pela organização, sem
mudar conteúdo (só a numeração, que veio quebrada, e "opinião" no título do último bloco).

## Objetivo

Ouvir quem esteve na 5ª edição e entregar à organização (as duas contas do admin, drihollandh@gmail.com e
vitoriamdfl@gmail.com) um resumo que se lê em um minuto, mais as respostas abertas e a planilha.

Sucesso: a participante responde pelo celular em ~3 minutos; o admin mostra o resumo e cada
resposta sem ninguém precisar abrir o Supabase; ninguém de fora consegue ler as respostas.

## Decisões tomadas

- **Cartão + página própria.** Depois do cartão da pré-venda, na página inicial, um cartão
  "Pesquisa de satisfação · 5ª edição" com botão para `pesquisa.html`. A página inicial não
  ganha 13 perguntas no meio da vitrine, e o link curto vai no grupo de WhatsApp.
- **Nome opcional.** A pesquisa é anônima por padrão; no fim, "Seu nome (opcional)".
- **Admin com resumo, respostas e planilha**, numa aba "Pesquisa" ao lado de "Cadastros".

## As perguntas: uma definição só

`assets/pesquisa.js` define o questionário como dado (`BW_PESQUISA`): blocos, perguntas,
tipo, opções (código + texto), obrigatória, "Outro" com campo "Qual?". A página do formulário,
o resumo do admin e a planilha leem a mesma definição. Duas cópias da lista de opções são
exatamente como o formulário e o resumo passam a discordar.

| # | Bloco | Código | Tipo | Obrigatória |
|---|---|---|---|---|
| 1 | Sobre sua experiência | `nota_geral` | escala 0–10 | não |
| 2 | | `gostou` | várias (+ Outro) | **sim** |
| 3 | | `organizacao` | uma | não |
| 4 | | `ambiente_conexao` | uma | não |
| 5 | Sobre o impacto | `momento` | texto | não |
| 6 | | `inspiracao` | texto | não |
| 7 | | `fez_conexao` | uma | não |
| 8 | Sobre as próximas edições | `melhorar` | texto | não |
| 9 | | `assuntos` | várias (+ Outro) | **sim** |
| 10 | | `participaria` | uma | não |
| 11 | | `recomendaria` | escala 0–10 | **sim** |
| 12 | Sua opinião importa | `descreveria` | texto | não |
| 13 | | `valor` | uma | não |
| — | | `nome` | texto curto | não |

## Banco: `bw_pesquisa`

Uma linha por resposta, colunas tipadas (não jsonb): o banco recusa nota fora de 0–10, opção
que não existe e texto gigante, mesmo que alguém poste direto na API com a chave pública.

- `id uuid` (padrão `gen_random_uuid()`), `criado_em timestamptz` (padrão `now()`),
  `edicao smallint` (padrão 5): a mesma tabela serve para a pesquisa da 6ª.
- Escalas `smallint` com `check` 0–10; `recomendaria` é `not null`.
- Escolha única: `text` com `check (... in (...))` dos códigos.
- Várias escolhas: `text[]` com `check (cardinality(x) >= 1 and x <@ array[...])`.
- Textos: `check (char_length(x) <= 1500)`; "Outro" e nome até 200 e 80.
- Acesso:
  - `anon` e `authenticated` **inserem** (grant só nas colunas de resposta: `id` e
    `criado_em` não são do cliente). Política de insert sem condição: quem valida são os
    `check`.
  - **Ninguém de fora lê.** `select` e `delete` só para `bw_is_admin()` (as duas contas do
    admin). Sem `update`: resposta não se edita.
  - O formulário insere sem pedir a linha de volta (o `anon` não tem `select`).

## Página `pesquisa.html`

- Mesma identidade do cadastro: cabeçalho com a marca e "Ver a vitrine", introdução com o
  texto da organização, os quatro blocos com o título de seção (`.sub`).
- Escala 0–10: 11 botões em grade de 6 colunas (duas linhas), cada um com pelo menos 44 px.
- Escolhas: os chips que o cadastro já usa. "Outro" marcado abre "Qual?".
- Erro em português, listando o que falta e rolando até a primeira pergunta pendente.
- Campo invisível contra robôs, como no cadastro.
- Depois de enviar: a mensagem de encerramento da organização, botão da pré-venda com
  `utm_content=pesquisa` e "Ver a vitrine". O aparelho guarda que já respondeu; ao voltar,
  vê "Você já respondeu neste aparelho" com "Responder de novo" (celular compartilhado existe,
  e a pesquisa é anônima: bloquear não protege nada).
- Modo exemplo (sem Supabase): não grava, só mostra o fluxo.
- Prévia do link no WhatsApp: título "Pesquisa de satisfação · 5ª edição Business Wave",
  imagem `assets/compartilhar.jpg`.

## Página inicial

Seção `#pesquisa` logo depois de `#prevenda`: eyebrow "Pesquisa de satisfação · 5ª edição",
título "Como foi a 5ª edição para você?", "São 3 minutinhos. Sua resposta ajuda a construir a
6ª." e botão "Responder a pesquisa". Sem item no menu (já tem três).

## Admin: aba "Pesquisa"

- Alternância "Cadastros | Pesquisa" no topo do painel. Cadastros continua como está.
- **Resumo:** total de respostas; média da experiência geral (0–10); recomendação: média e
  NPS (9–10 promotoras, 7–8 neutras, 0–6 detratoras; NPS = % promotoras − % detratoras), com
  a frase explicando o número; para cada pergunta de escolha, barras com contagem e % de quem
  respondeu (na ordem das opções, não por tamanho: "Excelente → Precisa melhorar" é uma escala).
  O texto dos "Outro" aparece embaixo das barras.
- **Respostas abertas por pergunta** (momento, inspiração, melhorar, descreveria): mais nova
  primeiro, com o nome ou "Anônima" e a data.
- **Todas as respostas:** uma por linha, fechada (`<details>`), com tudo o que a pessoa
  respondeu e "Apagar" com confirmação em dois toques (para teste e spam).
- **Planilha (CSV):** uma linha por resposta, os textos das opções (não os códigos), várias
  escolhas juntas por " | ", mesmo formato do CSV de cadastros (BOM, `;`).
- Carrega ao abrir a aba e tem "Atualizar".

## Testes

- Banco: transação desfeita com `raise` no fim conferindo insert válido do `anon`, recusa de
  nota 11, de opção inexistente, de `gostou` vazio, `select` negado ao `anon` e permitido ao
  admin.
- Telas: Playwright no modo exemplo — validação das obrigatórias, "Outro", envio, aviso de "já
  respondeu", cartão na página inicial, resumo e CSV do admin com respostas de exemplo, sem
  rolagem lateral em 360 px.

## Fora do escopo

Pesquisa da 6ª edição (a tabela já aceita, a página não), envio automático por WhatsApp,
gráficos por período, edição das perguntas pelo admin.
