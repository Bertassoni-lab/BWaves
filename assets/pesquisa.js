// Pesquisa de satisfacao: o questionario e' dado. O formulario (pesquisa.html), o resumo do
// admin e a planilha leem esta definicao; duas copias da lista de opcoes e' como o formulario
// e o resumo passam a discordar. Os codigos das opcoes sao os mesmos dos "check" do banco
// (bw_pesquisa): mudar um aqui pede mudar la.
(function () {
  const perguntas = {
    nota_geral: { n: 1, tipo: "escala", curto: "Experiência geral (0 a 10)",
      texto: "De 0 a 10, como você avalia sua experiência geral no Business Wave?" },
    gostou: { n: 2, tipo: "varias", obrigatoria: true, outro: true, curto: "O que mais gostou",
      texto: "O que você mais gostou nessa edição?",
      opcoes: [["palestras", "Palestras"], ["networking", "Networking e conexões"], ["ambiente", "Ambiente e organização"],
        ["gastronomia", "Experiência gastronômica"], ["dinamicas", "Dinâmicas e interações"], ["energia", "Energia e acolhimento"], ["outro", "Outro"]] },
    organizacao: { n: 3, tipo: "uma", curto: "Organização",
      texto: "Como você avalia a organização do evento?",
      opcoes: [["excelente", "Excelente"], ["muito_boa", "Muito boa"], ["boa", "Boa"], ["regular", "Regular"], ["precisa_melhorar", "Precisa melhorar"]] },
    ambiente_conexao: { n: 4, tipo: "uma", curto: "Ambiente para se conectar",
      texto: "Você sentiu que o Business Wave proporcionou um ambiente favorável para conhecer e se conectar com outras mulheres?",
      opcoes: [["sim_muito", "Sim, muito!"], ["sim_parcialmente", "Sim, parcialmente."], ["nao_tanto", "Não tanto quanto esperava."]] },
    momento: { n: 5, tipo: "texto", curto: "Momento mais marcante",
      texto: "Qual foi o momento mais marcante da noite para você?" },
    inspiracao: { n: 6, tipo: "texto", curto: "Percepção ou inspiração",
      texto: "Você saiu do Business Wave com alguma nova percepção, inspiração ou vontade de colocar algo em prática? Qual?" },
    fez_conexao: { n: 7, tipo: "uma", curto: "Fez conexão com oportunidade",
      texto: "Você fez alguma conexão que acredita que poderá gerar oportunidades pessoais ou profissionais?",
      opcoes: [["sim_varias", "Sim, várias!"], ["sim_uma", "Sim, pelo menos uma."], ["ainda_nao", "Ainda não, mas conheci pessoas interessantes."], ["nao", "Não."]] },
    melhorar: { n: 8, tipo: "texto", curto: "O que melhorar",
      texto: "O que você acredita que poderíamos melhorar para a próxima edição?" },
    assuntos: { n: 9, tipo: "varias", obrigatoria: true, outro: true, curto: "Assuntos desejados",
      texto: "Quais assuntos você gostaria de encontrar nas próximas edições?",
      opcoes: [["empreendedorismo", "Empreendedorismo e negócios"], ["posicionamento", "Posicionamento e marca pessoal"],
        ["inteligencia_emocional", "Inteligência emocional"], ["lideranca", "Liderança feminina"], ["comunicacao", "Comunicação e oratória"],
        ["desenvolvimento_pessoal", "Desenvolvimento pessoal"], ["financas", "Finanças e investimentos"], ["outro", "Outro"]] },
    participaria: { n: 10, tipo: "uma", curto: "Participaria de novo",
      texto: "Você participaria novamente do Business Wave?",
      opcoes: [["com_certeza", "Com certeza!"], ["provavelmente", "Provavelmente sim."], ["talvez", "Talvez."], ["nao", "Não."]] },
    recomendaria: { n: 11, tipo: "escala", obrigatoria: true, curto: "Recomendaria (0 a 10)",
      texto: "De 0 a 10, o quanto você recomendaria o Business Wave para uma amiga ou outra empreendedora?" },
    descreveria: { n: 12, tipo: "texto", curto: "Como descreveria o BW",
      texto: "Se você pudesse descrever o Business Wave para uma mulher que nunca participou, o que diria?" },
    valor: { n: 13, tipo: "uma", curto: "Valor pelo investimento",
      texto: "Considerando o investimento realizado, como você avalia o valor da experiência proporcionada pelo Business Wave?",
      opcoes: [["superou", "Superou minhas expectativas."], ["correspondeu_total", "Correspondeu totalmente às minhas expectativas."],
        ["correspondeu_parcial", "Correspondeu parcialmente às minhas expectativas."], ["abaixo", "Ficou abaixo das minhas expectativas."],
        ["convidada", "Participei como convidada."]] },
    nome: { tipo: "curto", curto: "Nome", texto: "Seu nome (opcional)" }
  };
  const MAX = { texto: 1500, curto: 80 }, MAX_OUTRO = 200;
  Object.values(perguntas).forEach(p => { p.max = MAX[p.tipo] || null; });

  const blocos = [
    { titulo: "Sobre sua experiência", perguntas: ["nota_geral", "gostou", "organizacao", "ambiente_conexao"] },
    { titulo: "Sobre o impacto", perguntas: ["momento", "inspiracao", "fez_conexao"] },
    { titulo: "Sobre as próximas edições", perguntas: ["melhorar", "assuntos", "participaria", "recomendaria"] },
    { titulo: "Sua opinião importa 💗", perguntas: ["descreveria", "valor", "nome"] }
  ];
  const ordem = blocos.flatMap(b => b.perguntas);

  const respondida = (p, v) => p.tipo === "varias" ? Array.isArray(v) && v.length > 0
    : p.tipo === "escala" ? typeof v === "number" && v >= 0 && v <= 10
    : typeof v === "string" && v.trim() !== "";

  // Codigos das obrigatorias sem resposta, na ordem do formulario. Zero e' resposta.
  const faltando = r => ordem.filter(c => perguntas[c].obrigatoria && !respondida(perguntas[c], r[c]));

  const media = vs => vs.length ? Math.round(vs.reduce((a, b) => a + b, 0) / vs.length * 10) / 10 : null;

  // NPS: 9-10 promotoras, 7-8 neutras, 0-6 detratoras; % promotoras - % detratoras.
  function nps(valores) {
    const n = valores.length, promotoras = valores.filter(v => v >= 9).length, detratoras = valores.filter(v => v <= 6).length;
    return { n, promotoras, neutras: n - promotoras - detratoras, detratoras,
      nps: n ? Math.round((promotoras - detratoras) / n * 100) : null };
  }

  function rotulo(codigo, valor) {
    if (valor === null || valor === undefined || valor === "") return "";
    const p = perguntas[codigo], texto = v => ((p && p.opcoes) ? (p.opcoes.find(o => o[0] === v) || [v, v])[1] : String(v));
    return Array.isArray(valor) ? valor.map(texto).join(" | ") : texto(valor);
  }

  // Medias e percentuais contam so quem respondeu aquela pergunta: pergunta opcional em branco
  // nao puxa a media para baixo nem vira NaN.
  function resumo(respostas) {
    const escalas = c => respostas.map(r => r[c]).filter(v => typeof v === "number");
    const geral = escalas("nota_geral"), rec = escalas("recomendaria");
    const escolhas = {};
    ordem.filter(c => perguntas[c].opcoes).forEach(c => {
      const p = perguntas[c], quem = respostas.filter(r => respondida(p, p.tipo === "varias" ? r[c] : (r[c] || "")));
      const marcou = (r, v) => p.tipo === "varias" ? r[c].includes(v) : r[c] === v;
      escolhas[c] = {
        n: quem.length,
        opcoes: p.opcoes.map(([v, t]) => {
          const qtd = quem.filter(r => marcou(r, v)).length;
          return { codigo: v, texto: t, qtd, pct: quem.length ? Math.round(qtd / quem.length * 100) : 0 };
        }),
        outros: p.outro ? respostas.map(r => (r[c + "_outro"] || "").trim()).filter(Boolean) : []
      };
    });
    return { total: respostas.length, geral: { media: media(geral), n: geral.length },
      recomendacao: { media: media(rec), ...nps(rec) }, escolhas };
  }

  const dataBR = d => d ? new Date(d).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" }) : "";

  // Planilha: uma linha por resposta, texto das opcoes (nao os codigos), mesmo formato do CSV
  // de cadastros (BOM para o Excel abrir acento, separador ";").
  function csv(respostas) {
    const cols = [["Data", r => dataBR(r.criado_em)], ["Nome", r => r.nome || ""]];
    ordem.filter(c => c !== "nome").forEach(c => {
      cols.push([perguntas[c].curto, r => rotulo(c, r[c])]);
      if (perguntas[c].outro) cols.push([perguntas[c].curto + " (outro)", r => r[c + "_outro"] || ""]);
    });
    // Resposta que comeca com = + - @ viraria formula no Excel ("- som baixo" aparece como #NOME?): vai como texto.
    const q = v => { const s = String(v ?? ""); return `"${(/^[=+\-@\t\r]/.test(s) ? "'" + s : s).replace(/"/g, '""')}"`; };
    return "﻿" + [cols.map(c => q(c[0])).join(";"), ...respostas.map(r => cols.map(c => q(c[1](r))).join(";"))].join("\n");
  }

  // Respostas de exemplo: so o modo exemplo do admin usa (sem Supabase), para ver o resumo.
  const exemplos = [
    { id: "x1", criado_em: "2026-10-17T23:40:00Z", nota_geral: 10, gostou: ["energia", "networking", "palestras"], organizacao: "excelente", ambiente_conexao: "sim_muito",
      momento: "A fala sobre recomeços.", fez_conexao: "sim_varias", assuntos: ["inteligencia_emocional", "desenvolvimento_pessoal"], participaria: "com_certeza",
      recomendaria: 10, descreveria: "Acolhimento e negócio na mesma noite.", valor: "convidada", nome: "Bia" },
    { id: "x2", criado_em: "2026-10-17T22:10:00Z", gostou: ["networking"], assuntos: ["financas"], recomendaria: 9 },
    { id: "x3", criado_em: "2026-10-17T21:30:00Z", nota_geral: 7, gostou: ["dinamicas"], organizacao: "regular", ambiente_conexao: "nao_tanto", fez_conexao: "nao",
      melhorar: "Começar no horário.", assuntos: ["empreendedorismo"], participaria: "talvez", recomendaria: 6, valor: "abaixo" },
    { id: "x4", criado_em: "2026-10-17T20:50:00Z", nota_geral: 8, gostou: ["gastronomia", "outro"], gostou_outro: "O brinde", organizacao: "boa", ambiente_conexao: "sim_parcialmente",
      melhorar: "O som estava baixo no fundo da sala.", fez_conexao: "ainda_nao", assuntos: ["comunicacao", "outro"], assuntos_outro: "Vendas pelo WhatsApp",
      participaria: "provavelmente", recomendaria: 8, valor: "correspondeu_parcial", nome: "Carla" },
    { id: "x5", criado_em: "2026-10-17T19:20:00Z", nota_geral: 9, gostou: ["palestras", "ambiente"], organizacao: "muito_boa", ambiente_conexao: "sim_muito", fez_conexao: "sim_uma",
      assuntos: ["lideranca"], participaria: "com_certeza", recomendaria: 9, valor: "correspondeu_total" },
    { id: "x6", criado_em: "2026-10-17T18:05:00Z", nota_geral: 10, gostou: ["networking", "energia"], organizacao: "excelente", ambiente_conexao: "sim_muito",
      momento: "A foto de todas juntas no final.", inspiracao: "Organizar melhor meu Instagram.", fez_conexao: "sim_varias",
      melhorar: "Mais tempo para conversar entre as palestras.", assuntos: ["posicionamento", "financas"], participaria: "com_certeza", recomendaria: 10,
      descreveria: "Uma noite de mulheres que se ajudam de verdade.", valor: "superou", nome: "Ana" }
  ];

  window.BW_PESQUISA = {
    edicao: 5,
    intro: {
      titulo: "Que alegria ter você conosco na 5ª edição do Business Wave!",
      texto: "Queremos ouvir você! Sua percepção é muito importante para continuarmos construindo experiências que promovam conexões e novas oportunidades para mulheres.",
      tempo: "São apenas 3 minutinhos. 💗"
    },
    encerramento: [
      "Obrigada por compartilhar sua experiência conosco!",
      "Cada resposta nos ajuda a aprimorar o Business Wave e construir encontros cada vez mais significativos.",
      "Foi um prazer ter você conosco na 5ª edição.",
      "Nos vemos na 6ª! 💗"
    ],
    MAX_OUTRO, blocos, perguntas, ordem, faltando, nps, rotulo, resumo, csv, dataBR, exemplos
  };
})();
