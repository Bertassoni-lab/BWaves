# Pesquisa de satisfação · 5ª edição — plano de construção

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** formulário de satisfação da 5ª edição em `pesquisa.html`, chamado por um cartão na página inicial, gravando em `bw_pesquisa`, com resumo, respostas e planilha numa aba "Pesquisa" do admin.

**Architecture:** o questionário é dado (`assets/pesquisa.js`, `window.BW_PESQUISA`) com as funções puras de validação, resumo, NPS e CSV; o formulário e o admin só desenham a partir dele. O banco valida cada coluna com `check` e só deixa o admin ler.

**Tech Stack:** HTML/CSS/JS puro (sem build), supabase-js 2.117.3 UMD local, Postgres/Supabase (RLS), Playwright para telas.

**Spec:** `docs/superpowers/specs/2026-10-18-pesquisa-satisfacao-design.md`

## Global Constraints

- Português do Brasil em tudo; comentários de código sem acento (padrão do repositório).
- Banco: só `public.bw_*`; **mudança no banco e publicação só com OK explícito do Thiago**. A ferramenta do Supabase trava em `DROP`/destrutivos: nada de `drop` na migração.
- Sem segredos no repositório; só a chave publicável que já está em `assets/config.js`.
- Ao mudar CSS/JS, trocar o `?v=` nas páginas que carregam o arquivo (`style.css`, `bw.js`, `pesquisa.js`).
- Toque mínimo de 44 px; sem rolagem lateral em 360 px.
- Testes fora do repositório: `SCRATCH=/tmp/claude-0/-home-user/6703c483-9372-577e-99ee-d931adcf5a4d/scratchpad`; Playwright com `PWPATH=$(npm root -g)/playwright`, Chromium em `/opt/pw-browsers/chromium-1194/chrome-linux/chrome`, rotas do disco e modo exemplo por `$SCRATCH/galeria/rota.mjs` (`rotas(ctx)`, `SITE`).
- Textos das perguntas, opções, introdução e encerramento: **exatamente** os da Task 1 (vieram da organização).

## Review Focus

1. Resposta com HTML ou `<script>` no texto ou no nome → o admin mostra como texto (tudo passa por `BW.esc`). Teste na Task 4.
2. "Outro" marcado sem escrever "Qual?" é aceito; texto escrito em "Qual?" e depois "Outro" desmarcado **não** é enviado. Teste nas Tasks 1 e 3.
3. Falha ao gravar (sem internet, banco recusou) → mensagem em português, botão volta a "Enviar respostas" e nada do que foi preenchido some. Teste na Task 3.
4. Admin com zero respostas, ou com perguntas opcionais vazias → "Nenhuma resposta ainda", médias com `null` em vez de `NaN`, e o `n` de cada média conta só quem respondeu aquela pergunta. Teste nas Tasks 1 e 4.
5. Texto com `;`, aspas e quebra de linha → CSV continua com uma linha por resposta e as colunas no lugar. Teste na Task 1.

---

### Task 1: O questionário como dado (`assets/pesquisa.js`)

**Files:**
- Create: `assets/pesquisa.js`
- Test: `$SCRATCH/pesquisa/teste-logica.mjs` (carrega o arquivo num `vm` com `window = {}`)

**Interfaces:**
- Produces `window.BW_PESQUISA` com:
  - `edicao: 5`
  - `intro: { titulo, texto, tempo }`, `encerramento: string[]`
  - `blocos: [{ titulo, perguntas: string[] }]` (códigos na ordem)
  - `perguntas: { [codigo]: { n?: number, texto, tipo: 'escala'|'uma'|'varias'|'texto'|'curto', opcoes?: [codigo, texto][], obrigatoria?: true, outro?: true, max: number } }`
  - `faltando(r: object): string[]` — códigos obrigatórios sem resposta, na ordem do formulário
  - `rotulo(codigo: string, valor: any): string` — texto da opção; lista vira `"A | B"`; `null`/vazio vira `""`
  - `nps(valores: number[]): { n, promotoras, neutras, detratoras, nps: number|null }` (arredondado)
  - `resumo(respostas: object[]): { total, geral: { media: number|null, n }, recomendacao: { media: number|null, n, nps, promotoras, neutras, detratoras }, escolhas: { [codigo]: { n, opcoes: [{ codigo, texto, qtd, pct }], outros: string[] } } }` — `pct` sobre `n` de quem respondeu aquela pergunta, inteiro arredondado; `outros` são os `<codigo>_outro` não vazios
  - `csv(respostas: object[]): string` — BOM, separador `;`, cabeçalho `Data;Nome;<texto curto de cada pergunta na ordem>`, aspas duplicadas, uma linha por resposta (quebras de linha dentro das aspas)
- A resposta (`r`) usa os nomes das colunas do banco: `nota_geral, gostou, gostou_outro, organizacao, ambiente_conexao, momento, inspiracao, fez_conexao, melhorar, assuntos, assuntos_outro, participaria, recomendaria, descreveria, valor, nome, criado_em`.

Texto exato (blocos → perguntas → opções `codigo: texto`):

- Intro: título "Que alegria ter você conosco na 5ª edição do Business Wave!"; texto "Queremos ouvir você! Sua percepção é muito importante para continuarmos construindo experiências que promovam conexões e novas oportunidades para mulheres."; tempo "São apenas 3 minutinhos. 💗"
- **Sobre sua experiência**
  1. `nota_geral` escala — "De 0 a 10, como você avalia sua experiência geral no Business Wave?"
  2. `gostou` várias, obrigatória, outro — "O que você mais gostou nessa edição?" — `palestras`: Palestras; `networking`: Networking e conexões; `ambiente`: Ambiente e organização; `gastronomia`: Experiência gastronômica; `dinamicas`: Dinâmicas e interações; `energia`: Energia e acolhimento; `outro`: Outro
  3. `organizacao` uma — "Como você avalia a organização do evento?" — `excelente`: Excelente; `muito_boa`: Muito boa; `boa`: Boa; `regular`: Regular; `precisa_melhorar`: Precisa melhorar
  4. `ambiente_conexao` uma — "Você sentiu que o Business Wave proporcionou um ambiente favorável para conhecer e se conectar com outras mulheres?" — `sim_muito`: Sim, muito!; `sim_parcialmente`: Sim, parcialmente.; `nao_tanto`: Não tanto quanto esperava.
- **Sobre o impacto**
  5. `momento` texto — "Qual foi o momento mais marcante da noite para você?"
  6. `inspiracao` texto — "Você saiu do Business Wave com alguma nova percepção, inspiração ou vontade de colocar algo em prática? Qual?"
  7. `fez_conexao` uma — "Você fez alguma conexão que acredita que poderá gerar oportunidades pessoais ou profissionais?" — `sim_varias`: Sim, várias!; `sim_uma`: Sim, pelo menos uma.; `ainda_nao`: Ainda não, mas conheci pessoas interessantes.; `nao`: Não.
- **Sobre as próximas edições**
  8. `melhorar` texto — "O que você acredita que poderíamos melhorar para a próxima edição?"
  9. `assuntos` várias, obrigatória, outro — "Quais assuntos você gostaria de encontrar nas próximas edições?" — `empreendedorismo`: Empreendedorismo e negócios; `posicionamento`: Posicionamento e marca pessoal; `inteligencia_emocional`: Inteligência emocional; `lideranca`: Liderança feminina; `comunicacao`: Comunicação e oratória; `desenvolvimento_pessoal`: Desenvolvimento pessoal; `financas`: Finanças e investimentos; `outro`: Outro
  10. `participaria` uma — "Você participaria novamente do Business Wave?" — `com_certeza`: Com certeza!; `provavelmente`: Provavelmente sim.; `talvez`: Talvez.; `nao`: Não.
  11. `recomendaria` escala, obrigatória — "De 0 a 10, o quanto você recomendaria o Business Wave para uma amiga ou outra empreendedora?"
- **Sua opinião importa 💗**
  12. `descreveria` texto — "Se você pudesse descrever o Business Wave para uma mulher que nunca participou, o que diria?"
  13. `valor` uma — "Considerando o investimento realizado, como você avalia o valor da experiência proporcionada pelo Business Wave?" — `superou`: Superou minhas expectativas.; `correspondeu_total`: Correspondeu totalmente às minhas expectativas.; `correspondeu_parcial`: Correspondeu parcialmente às minhas expectativas.; `abaixo`: Ficou abaixo das minhas expectativas.; `convidada`: Participei como convidada.
  - `nome` curto (sem número) — "Seu nome (opcional)"
- Encerramento: "Obrigada por compartilhar sua experiência conosco!" / "Cada resposta nos ajuda a aprimorar o Business Wave e construir encontros cada vez mais significativos." / "Foi um prazer ter você conosco na 5ª edição." / "Nos vemos na 6ª! 💗"
- `max`: texto 1500, outro 200, nome 80.

- [ ] **Step 1: Write the failing test** `$SCRATCH/pesquisa/teste-logica.mjs` com `node:assert`:
  - `faltando({})` → `['gostou','assuntos','recomendaria']`; `faltando({gostou:['outro'], assuntos:['lideranca'], recomendaria:0})` → `[]` (Outro sem texto é aceito; 0 é resposta).
  - `nps([10,9,8,7,6,0])` → `{ n:6, promotoras:2, neutras:2, detratoras:2, nps:0 }`; `nps([])` → `nps: null`.
  - `resumo([])` → `total 0`, `geral.media null`, `recomendacao.media null`.
  - `resumo` de 3 respostas onde só 2 têm `nota_geral` (8 e 10) → `geral: { media: 9, n: 2 }`; `escolhas.gostou.opcoes` na ordem da definição; `pct` de `palestras` marcado por 1 de 2 que responderam → 50; `outros` traz o texto de `gostou_outro`.
  - `rotulo('gostou', ['palestras','energia'])` → `'Palestras | Energia e acolhimento'`; `rotulo('organizacao', null)` → `''`.
  - `csv([{ criado_em:'2026-10-18T12:00:00Z', nome:'Ana; "A"', melhorar:'linha 1\nlinha 2', gostou:['palestras'], assuntos:['lideranca'], recomendaria:9 }])`: começa com `﻿`, tem exatamente 1 linha de dados fora das aspas, contém `"Ana; ""A"""`.
- [ ] **Step 2: Run** `node $SCRATCH/pesquisa/teste-logica.mjs` — Expected: falha (arquivo não existe).
- [ ] **Step 3: Implement `assets/pesquisa.js`** com o texto exato acima. Média com uma casa decimal (`Math.round(x*10)/10`).
- [ ] **Step 4: Run** de novo — Expected: `ok` sem erro.
- [ ] **Step 5: Commit** `git add assets/pesquisa.js && git commit` ("Questionário da pesquisa como dado").

### Task 2: Banco `bw_pesquisa`

**Files:**
- Modify: `docs/migracoes-aplicadas.sql` (acrescentar a migração `bw_pesquisa`)
- Modify: `CLAUDE.md` (seção Banco: a tabela e quem lê)

**Interfaces:**
- Consumes: códigos de opção da Task 1 (os `check` usam os mesmos).
- Produces: tabela `public.bw_pesquisa` com as colunas da Task 1 + `id uuid default gen_random_uuid() primary key`, `criado_em timestamptz not null default now()`, `edicao smallint not null default 5 check (edicao between 1 and 99)`; `recomendaria not null`; `gostou`/`assuntos` `text[] not null` com `cardinality >= 1` e `<@ array[...]`; escolhas únicas com `in (...)`; escalas `between 0 and 10`; textos `char_length <= 1500`, `*_outro <= 200`, `nome <= 80`.
- Acesso: RLS ligado; `grant insert (colunas de resposta, edicao) to anon, authenticated`; política `insert` para `anon, authenticated` `with check (true)`; `grant select, delete to authenticated`; políticas `select` e `delete` `using (public.bw_is_admin())`. Sem `update`.

- [ ] **Step 1: Teste em transação desfeita** (execute_sql, `begin; set local lock_timeout='5s';` + migração + bloco `do` que junta resultados e termina com `raise exception 'RESULTADO: %'`): como `set local role anon`, insert válido passa; `recomendaria = 11` recusa (`check_violation`); `gostou = '{xyz}'` recusa; `gostou = '{}'` recusa; `select count(*)` como `anon` dá `insufficient_privilege` ou 0 linhas; `reset role` e o dono lê. Expected: `RESULTADO` com os seis itens certos e nada persistido (conferir que a tabela não existe depois).
- [ ] **Step 2: Pedir OK do Thiago** para aplicar no banco. Sem OK, parar aqui.
- [ ] **Step 3: Aplicar** com `apply_migration` (nome `bw_pesquisa`) e conferir: tabela existe, `anon` não tem `select`, as duas contas de `bw_admins` continuam lá.
- [ ] **Step 4: Commit** docs (`docs/migracoes-aplicadas.sql`, `CLAUDE.md`).

### Task 3: Página `pesquisa.html`

**Files:**
- Create: `pesquisa.html`
- Modify: `assets/style.css` (escala 0–10 em grade de 6 colunas, botões ≥ 44 px; resto reaproveita `.chips/.chip/.field/.sub/.offer`)
- Test: `$SCRATCH/pesquisa/teste-pagina.mjs`

**Interfaces:**
- Consumes: `BW_PESQUISA` (Task 1); `BW.sb`, `BW.DEMO`, `BW.C` de `assets/bw.js`; tabela da Task 2 (`sb.from('bw_pesquisa').insert(row)` sem `.select()`).
- Produces: `pesquisa.html` com `<form id="f">`, um elemento por pergunta com `id="q-<codigo>"`, `#err`, `#send`, `#done`, `#ja` (aviso de já respondeu) e honeypot `#empresa_site`; `localStorage['bw_pesquisa_5'] = '1'` após envio (leitura e escrita em `try/catch`).
- Cabeçalho igual ao do cadastro; `<title>` "Pesquisa de satisfação · Business Wave"; `og:title` "Pesquisa de satisfação · 5ª edição Business Wave"; `og:image` `assets/compartilhar.jpg`.
- Botão da pré-venda no fim: mesmo link da página inicial com `utm_content=pesquisa`.

- [ ] **Step 1: Write the failing test** (Playwright, modo exemplo, 390×844):
  - abrir `/pesquisa.html`; 4 títulos de bloco e 13 perguntas numeradas na ordem;
  - enviar vazio → `#err` visível listando "o que você mais gostou", "assuntos" e "recomendaria", foco/rolagem em `#q-gostou`;
  - marcar Outro em `gostou`, escrever "Qual?", desmarcar Outro → o campo some e a linha montada para envio não leva `gostou_outro` (expor a linha via `window.__ultimaResposta` só no modo exemplo);
  - preencher as três obrigatórias e enviar → `#done` com "Nos vemos na 6ª! 💗" e o link da pré-venda contendo `utm_content=pesquisa`;
  - recarregar → `#ja` visível; "Responder de novo" mostra o formulário;
  - forçar falha (rota para `*/rest/v1/bw_pesquisa` com 500, config real simulado) → mensagem de erro, `#send` habilitado com "Enviar respostas", campos ainda preenchidos;
  - `scrollWidth <= innerWidth` em 360 px.
- [ ] **Step 2: Run** `PWPATH=$(npm root -g)/playwright node $SCRATCH/pesquisa/teste-pagina.mjs` — Expected: falha (página não existe).
- [ ] **Step 3: Implement** `pesquisa.html` desenhando tudo a partir de `BW_PESQUISA` (escala = rádios com rótulo 0–10; várias = checkboxes; `maxlength` = `max`).
- [ ] **Step 4: Run** de novo — Expected: tudo certo, sem erro de console; capturas em 390 e 1280 px conferidas a olho.
- [ ] **Step 5: Commit** (`pesquisa.html`, `assets/style.css`).

### Task 4: Cartão na página inicial e aba "Pesquisa" no admin

**Files:**
- Modify: `index.html` (seção `#pesquisa` logo depois de `#prevenda`; `?v=` do CSS)
- Modify: `admin.html` (alternância Cadastros | Pesquisa; área da pesquisa; respostas de exemplo no modo exemplo; carrega `assets/pesquisa.js`)
- Modify: `assets/style.css` (barras do resumo; números grandes do resumo)
- Test: `$SCRATCH/pesquisa/teste-admin.mjs`

**Interfaces:**
- Consumes: `BW_PESQUISA.resumo/nps/rotulo/csv/perguntas/blocos` (Task 1); `BW.esc`; `sb.from('bw_pesquisa').select('*').order('criado_em', {ascending:false})` e `.delete().eq('id', id)`.
- Produces: no admin, `#areaCadastros` (o conteúdo atual de `#app`, sem mudança de comportamento) e `#areaPesquisa` com `#pResumo`, `#pAbertas`, `#pTodas`, `#pCsv`, `#pAtualizar`; alternância `.tab[data-area]`.
- Cartão: eyebrow "Pesquisa de satisfação · 5ª edição", h2 "Como foi a 5ª edição para você?", texto "São 3 minutinhos. Sua resposta ajuda a construir a 6ª.", botão "Responder a pesquisa" → `pesquisa.html`.
- Resumo: total; "Experiência geral" média/10 com n; "Recomendação" média/10, NPS e a frase "NPS = % de quem deu 9 ou 10 menos % de quem deu 0 a 6"; uma barra por opção na ordem da definição com `qtd` e `pct`; "Outro" em lista embaixo. Abertas: `momento`, `inspiracao`, `melhorar`, `descreveria`, mais nova primeiro, com nome ou "Anônima" e data `dd/mm hh:mm`. Todas: `<details>` por resposta, "Apagar" com confirmação em dois toques (mesmo padrão do "Aprovar todos").

- [ ] **Step 1: Write the failing test** (Playwright, modo exemplo):
  - página inicial: seções na ordem `hero > prevenda > pesquisa > vitrine > evento > band`; botão leva a `pesquisa.html`;
  - admin: clicar "Pesquisa" mostra `#areaPesquisa` e esconde `#areaCadastros`; com as respostas de exemplo (6, incluindo uma com `nome = '<img src=x onerror=alert(1)>'` e uma sem `nota_geral`), o total aparece, a média da experiência usa só quem respondeu, há uma barra por opção de `organizacao` na ordem Excelente → Precisa melhorar, nenhum `<img>` é criado a partir do nome e nenhum `NaN` aparece no texto;
  - "Baixar planilha" gera um arquivo com 7 linhas (cabeçalho + 6);
  - "Apagar" pede confirmação e, no segundo toque, a resposta some e o total cai para 5;
  - modo exemplo sem respostas → "Nenhuma resposta ainda.";
  - voltar para "Cadastros" mostra a lista como antes.
- [ ] **Step 2: Run** `PWPATH=$(npm root -g)/playwright node $SCRATCH/pesquisa/teste-admin.mjs` — Expected: falha.
- [ ] **Step 3: Implement** a seção na página inicial e a aba no admin.
- [ ] **Step 4: Run** de novo, e repetir os testes das Tasks 1 e 3 e o teste antigo do admin (`$SCRATCH/oferta/admin.mjs`) — Expected: tudo passa.
- [ ] **Step 5: Commit** (`index.html`, `admin.html`, `assets/style.css`).

### Task 5: Documentação, publicação e conferência

**Files:**
- Modify: `CLAUDE.md` (páginas: `pesquisa.html`, cartão `#pesquisa`, aba Pesquisa do admin; ordem das seções)
- Modify: `?v=` de `style.css` em `index.html`, `admin.html`, `pesquisa.html`; `pesquisa.js?v=20261018a` em `pesquisa.html` e `admin.html`

- [ ] **Step 1: Conferir os `?v=`**: `grep -n "style.css?v=\|pesquisa.js?v=\|bw.js?v=" *.html` — Expected: cada página que mudou com versão nova.
- [ ] **Step 2: Commit** dos docs e versões; `git push` do branch `pesquisa-satisfacao`.
- [ ] **Step 3: Pedir OK do Thiago para publicar.** Com OK: `git switch main && git merge --ff-only pesquisa-satisfacao && git push origin main`.
- [ ] **Step 4: Conferir o deploy** pela API da Hostinger (`hosting_files_website-content` de `pesquisa.html` e `assets/pesquisa.js` em `bw.okgo.dev.br`, usuário `u618448665`) e limpar o cache (`hosting_cache_clear-website`). Sem o conector, dizer isso e passar ao Thiago o que olhar no celular.
- [ ] **Step 5: Teste real**: uma resposta de teste em `pesquisa.html` no ar, conferir no banco que entrou, e apagá-la (com o OK de quem estiver acompanhando) para não sujar o resumo.
