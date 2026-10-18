# Vitrine BW · Business Wave

Vitrine online das participantes do Business Wave (evento de mulheres empreendedoras do Litoral Norte de SP, fundado por Vitória Lemes). Projeto da OkGo. Responsável técnico: Thiago.

Objetivo: vitrine dos negócios das mulheres do BW com **oferta exclusiva BW**, cadastro rápido pelo celular (antes ou durante o evento) e contato direto com cada negócio pelo WhatsApp, no evento e depois dele. Afiliadas/Kiwify, pontos e ranking foram **retirados** do escopo.

5ª edição: 16/10/2026, 18h, Beach Hotel Maresias (Centro de Convenções), São Sebastião/SP.

## Regras de trabalho
- Escrever tudo em português do Brasil (código pode ter nomes em português, como já está).
- **Confirmar com o Thiago antes de modificar qualquer coisa** no banco (estrutura, regras de acesso, dados) e antes de publicar.
- A aprovação de cadastros é decisão do Thiago: cadastro entra como `pendente` e só aparece depois que a organização aprova. Não mudar para publicação automática sem pedir.

## Stack
- Site estático (HTML/CSS/JS puro, sem build). `assets/supabase.js` é o supabase-js 2.117.3 UMD, servido localmente.
- Banco: Supabase, projeto **okgo-homologacao** (ref `qmjdvnvbodplrwrdxdre`). Esse projeto também abriga o sistema da OkGo (schemas `nucleo`, `mkt`); a vitrine usa só tabelas `public.bw_*`. Não tocar em nada fora de `bw_*`.
- Chave pública (publishable) em `assets/config.js`. Não há segredos no repositório.
- Hospedagem: Hostinger, subdomínio **bw.okgo.dev.br** (pasta `public_html/bw` de okgo.dev.br, usuário `u618448665`).

## Páginas
- `index.html` vitrine pública: filtros (todos, com oferta, participantes, patrocinadoras e parceiras), busca, segmento, perfil em modal (`#perfil-<id>`, sem o "Procuro"), seção "O Business Wave" com fotos do evento (`assets/fotos/`, mosaico em `.galeria`). As fotos ficam depois da vitrine: quem abre o site quer achar um negócio primeiro. Essa seção vai virar a galeria das mídias do evento.
  - **A seção Conexões saiu (17/10/2026).** Ela mostrava o "Procuro" de cada participante com um botão "Posso ajudar" no WhatsApp: o caminho contrário da vitrine, em que quem pode ajudar acha quem precisa. Só funciona com pedido concreto ("fotógrafa para catálogo"), e das 28 na vitrine, 19 preencheram e **todas** escreveram algo genérico ("Clientes", "Parcerias", "Todos"; duas copiaram o exemplo da pergunta). A seção virou uma lista de "Procura: clientes", com um botão igual ao WhatsApp do perfil. O "Procuro" continua no cadastro, no painel, no admin e no CSV, para a organização usar; a pergunta do cadastro agora pede algo concreto. A coluna `preciso` ainda tem leitura pública no banco (grant por coluna), embora a vitrine não a busque mais. Voltar com a seção pede pedidos concretos, não só o código de volta.
  - O topo (`.hero`) termina na foto do brinde (`bw-brinde.jpg`) atravessando a tela, com a borda de cima em onda e um fio dourado em cima dela,: é o nome do evento virando imagem. Ela abre a página, colada no menu, no celular e no computador: a onda leva ao título, sem corte seco. A logo grande saiu do topo (fica só no menu) para o texto ter espaço. O título é **proporcional à largura onde mora** (tela no celular, coluna no computador): fica sempre em três linhas cheias, "As mulheres do BW / e seus negócios, / num só lugar.", igual em qualquer aparelho. O fator `.137` sai da linha mais longa medida na Cormorant; trocar o texto do título pede medir de novo. A máscara (`.onda img`) e o fio (`.onda-fio`) usam **a mesma curva no mesmo viewBox esticado**; mudar uma sem a outra descola o fio da borda.
  - Link de perfil que ainda não foi aprovado (o cadastro entrega o link na hora) abre um **aviso de "em análise"**, e não a vitrine muda. Se a tela ficar aberta, o perfil abre sozinho quando for aprovado.
  - A vitrine **se atualiza sozinha** a cada minuto e ao voltar para a aba, sem atropelar um perfil aberto: no evento as aprovações saem a toda hora e ninguém recarrega a página.
  - **"Quero essa oferta"** leva para o **link da oferta** (`oferta_link`) quando a participante informa um: loja, agenda, página de vendas (a da OkGo vai para o Site Vendedor). Sem link, abre o WhatsApp dela com a oferta escrita na mensagem. O link é opcional no cadastro, no painel e no admin, e fica dentro da caixa da oferta porque só vale junto com ela.
  - A busca compara **sem acento** (`BW.semAcento`): no celular quase ninguém digita acento.
  - A prévia dos links no WhatsApp usa `assets/compartilhar.jpg` (1200×630, foto do brinde com a logo). O WhatsApp guarda a prévia por link; link já compartilhado pode demorar a mostrar a nova.
  - **Pré-venda da 6ª edição (2027)**: a 5ª edição passou (16/10/2026), e a chamada da casa agora é a próxima. Por isso a seção `#prevenda` fica **logo depois do topo, antes da vitrine**, num cartão com a foto de grupo da 5ª edição (`bw-5a-edicao.jpg`, legenda "5ª edição · 16/10/2026"): a foto da que passou vende a próxima. Atalho no menu e no rodapé, levando para `businesswave.com.br/pre-venda-business-wave-2027/` em nova aba. Os links levam `utm_source=vitrine-bw` e `utm_content` (`secao` ou `rodape`), para a organização saber quantas vendas vieram da vitrine. A seção não cita preço, data nem lote: a página da pré-venda é a fonte, e um número escrito aqui ficaria velho sem ninguém ver.
    - No computador o cartão vira duas colunas só a partir de 1100 px, com a foto mais larga que o texto: abaixo disso a coluna ficaria estreita e a foto de grupo seria cortada nas pontas, deixando participantes de fora.
    - O selo do topo diz "rumo à 6ª edição" e o do cadastro, "Business Wave · Vitrine". O `qr.html` continua dizendo "5ª edição" porque é a tela do LED daquele evento.
  - **Pesquisa de satisfação** (`#pesquisa`): cartão logo depois da pré-venda, discreto (borda neutra, não dourada: a chamada da casa continua sendo a pré-venda), com o botão "Responder a pesquisa" para `pesquisa.html`. Sem item no menu.
  - A galeria (`.galeria`) é em colunas, com cada foto no formato dela, sem corte: foto nova é só mais um `<figure>` com `width`/`height` certos, e a `.destaque` atravessa as colunas.
- `cadastro.html` cadastro da participante (obrigatórios: nome, negócio, WhatsApp, segmento, e-mail e consentimento LGPD). Gera o `id` e o `token_edicao` no cliente e, no fim, mostra o link do painel pessoal (primeiro, com "Mandar para o meu WhatsApp", "Copiar" e "Abrir meu painel") e o link do perfil para compartilhar.
- `pesquisa.html` **pesquisa de satisfação da 5ª edição**: as 13 perguntas da organização, desenhadas a partir de `assets/pesquisa.js` (`BW_PESQUISA`), que é **a definição única** do questionário — textos, opções com os códigos que o banco aceita, obrigatórias, e as contas do resumo, do NPS e da planilha. Formulário, admin e planilha leem dali; duas cópias da lista de opções é como o formulário e o resumo passam a discordar.
  - Anônima com **nome opcional** no fim. Obrigatórias: o que mais gostou, assuntos e a recomendação de 0 a 10.
  - Escala 0–10 em grade de 6 colunas: 11 botões numa linha só ficariam pequenos demais no celular. Todo alvo de toque tem 44 px.
  - "Outro" abre "Qual?"; se for desmarcado, o texto não é enviado. Opcional em branco não vai na linha.
  - Falha ao gravar mantém tudo na tela e diz para tocar de novo. O aparelho que já respondeu vê "você já respondeu" com "Responder de novo": a pesquisa é anônima, bloquear não protegeria nada e celular compartilhado existe.
  - O encerramento leva à pré-venda com `utm_content=pesquisa`.
- `admin.html` painel da organização (login Supabase Auth + tabela `bw_admins`). Alterna entre **Cadastros** e **Pesquisa**. Na Pesquisa: números em quadros (respostas, experiência geral, recomendação com NPS e a frase que explica o número), uma barra por opção na **ordem das opções, não por tamanho** (são escalas: "Excelente → Precisa melhorar"), respostas abertas por pergunta, todas as respostas uma a uma com "Apagar" em dois toques, e a planilha. Médias e percentuais contam **só quem respondeu aquela pergunta**: opcional em branco não puxa a média para baixo nem vira NaN. Em Cadastros: aprovar, aprovar todos, ocultar, destacar, **editar** (todos os campos e foto), WhatsApp, **enviar link do painel** (WhatsApp para a participante), baixar CSV, atualização a cada 30 s. O CSV não leva o token, de propósito.
- `painel.html` **painel da participante** por link pessoal `painel.html#<token_edicao>`: status, link do perfil para compartilhar, edição dos próprios dados e da foto (via RPC). O painel vem primeiro na tela de sucesso porque ele já contém o link do perfil: quem guarda só ele não perde nada.
- `qr.html` tela para o painel de LED e mesas, com QR de cadastro e da vitrine (`assets/qr-*.svg`, apontando para bw.okgo.dev.br).

## Banco (ver `docs/`)
- `bw_perfis`: perfis. `status` in (`pendente`,`aprovado`,`recusado` = oculto), `destaque`, `email` (privado), `token_edicao` (privado), `oferta_link` (público, opcional).
  - `oferta_link` só aceita `http(s)://` sem espaço, até 300 caracteres (restrição `bw_perfis_oferta_link_url`). As telas completam o `https://` e conferem antes com `BW.linkOferta`, e a RPC do painel completa também: quem digita "minhaloja.com" não pode receber um "não salvou" sem motivo.
  - anon: insere só com `status='pendente'`, `destaque=false`, `consentimento=true`; lê só aprovados e só as colunas públicas (grant por coluna; `email` e `token_edicao` não são legíveis).
  - admin (`bw_is_admin()` = usuário em `bw_admins`): lê, edita e apaga tudo.
- `bw_admins`: hoje 2 admins, drihollandh@gmail.com e vitoriamdfl@gmail.com (Vitória Lemes, criada em 15/10/2026 com senha temporária).
  - Conta de admin nova: criar o usuário em `auth.users` + `auth.identities` (e-mail já confirmado, senha com `extensions.crypt(..., gen_salt('bf'))`, colunas de token como `''`, nunca nulas) e depois inserir em `bw_admins`. O SMTP padrão não manda convite para fora da equipe do Supabase.
  - Todo usuário novo do projeto ganha uma linha em `nucleo.usuarios` pelo gatilho `nucleo_criar_usuario` (sistema da OkGo). É só id e nome, sem papel nem permissão; o nome vem de `raw_user_meta_data->>'nome'`.
- `bw_pesquisa`: uma linha por resposta da pesquisa de satisfação, com `edicao` (a mesma tabela serve para a da 6ª). Colunas tipadas com `check`: nota fora de 0–10, opção que não existe e texto gigante são recusados pelo banco, mesmo para quem posta direto na API com a chave pública. Os `check` usam **exatamente os códigos de `assets/pesquisa.js`** (a migração foi gerada a partir dele): mudar uma opção lá pede uma migração que mude o `check` no banco **antes** de publicar a página, senão o banco recusa a resposta nova.
  - Qualquer pessoa insere (grant só nas colunas de resposta: `id` e `criado_em` não são do cliente). **Ninguém de fora lê**: `select` e `delete` só para `bw_is_admin()`. Sem `update`. O Supabase dá `ALL` em tabela nova para `anon`/`authenticated`; a migração tira e devolve só o necessário.
  - O formulário insere sem pedir a linha de volta, porque o `anon` não tem `select`.
- `bw_embaixadoras`: sobra do escopo antigo (ranking). Não usada pelo site.
- Funções da participante: `bw_meu_perfil(p_token)` e `bw_atualizar_meu_perfil(p_token, p_dados jsonb)` (security definer, só campos permitidos; não mexem em status/destaque).
  - `bw_meu_perfil_v1` é a versão antiga, **renomeada e sem permissão para ninguém**. A ferramenta do Supabase usada pelo Claude trava em `DROP` (pede uma confirmação que não chega), então mudar o retorno de uma função é renomear a antiga e criar a nova. Pode ser apagada pelo SQL Editor.
- Storage: bucket público `bw-logos` (jpeg/png/webp, 3 MB). Fotos são reduzidas para 600 px no navegador antes do upload, por **uma função só** (`BW.reduzirFoto`, usada no cadastro, no painel e no admin), que pinta **fundo branco** antes de virar JPG: no JPG o transparente vira preto, e logo com letra escura sumia (foi o que aconteceu com a da OkGo). Foto enviada antes de 16/10 com esse defeito precisa ser enviada de novo.
- Migrações aplicadas: `docs/schema-inicial.sql` + `docs/migracoes-aplicadas.sql`.

## Testar
- Modo exemplo: com `SUPABASE_URL` vazio em `assets/config.js` o site roda com perfis de exemplo e não grava nada. Útil para testar layout (`python3 -m http.server`).
- Com o config real, testar o fluxo completo: cadastro → aparece em "Esperando aprovação" no admin → aprovar → aparece na vitrine → editar → painel da participante.

## Deploy
- Auto-deploy da Hostinger ligado ao GitHub (repo `Bertassoni-lab/BWaves`, branch `main`, raiz do site bw.okgo.dev.br).
- **O webhook falhou algumas vezes.** Depois de cada push, conferir se os arquivos no servidor mudaram (hPanel ou API da Hostinger). Se não mudaram, salvar de novo as configurações de auto-deploy (isso dispara o deploy na hora).
- Ao mudar CSS/JS, trocar o `?v=` nos links das páginas para furar o cache dos navegadores.
- O `.htaccess` manda `Cache-Control: no-cache` nas páginas `.html`: o navegador confere se há versão nova antes de usar a guardada. Antes disso, aparelhos ficaram presos em versões velhas, e a Hostinger também guarda cache (limpar pela API depois de publicar).

## Próximos passos
1. Segunda etapa: login de participante com **e-mail e senha** (Supabase Auth). Exige desligar "Confirm email" no Supabase; "esqueci a senha" depende de configurar SMTP próprio (o SMTP padrão do Supabase só envia para a equipe do projeto).
2. Ideias para o evento e depois: modo telão (perfis e ofertas passando no LED, com QR), botão "Salvar contato" (vCard), "Minhas conexões" (favoritos no celular), contador ao vivo, faixa das patrocinadoras, relatório de cliques por patrocinadora.
3. Pendências com a organização: pasta oficial da marca (fontes e cores), domínio definitivo (vitrine.businesswave.com.br), confirmar horário de encerramento (22h ou 22h30).
