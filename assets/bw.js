// Núcleo compartilhado: cliente Supabase, modo exemplo e utilitários.
(function () {
  const C = window.BW_CONFIG;
  const DEMO = !C.SUPABASE_URL || !C.SUPABASE_ANON_KEY;
  const sb = DEMO ? null : window.supabase.createClient(C.SUPABASE_URL, C.SUPABASE_ANON_KEY);

  const PUBLIC_COLS = "id,created_at,tipo,nome_negocio,responsavel,segmento,cidade,descricao,instagram,whatsapp,site,logo_url,oferta_bw,oferta_link,ofereco,destaque";

  const SEGMENTOS = ["Beleza e estética","Moda","Alimentação e gastronomia","Saúde e bem-estar","Turismo e hospedagem","Imóveis","Educação e mentoria","Marketing e comunicação","Serviços","Decoração e eventos","Fotografia","Artesanato","Negócios locais","Outro"];

  // Dados de exemplo: aparecem só no modo exemplo (sem banco configurado).
  const EXEMPLO = [
    {"instagram":"exemplo","whatsapp":"","site":"","logo_url":"","oferta_bw":"10% de desconto para participantes do Business Wave","oferta_link":"","oferta_tipo":"desconto_pct","oferta_valor":10,"oferta_detalhe":"para participantes do Business Wave","ofereco":"","destaque":true,"id":"e1","tipo":"patrocinadora","nome_negocio":"Marca Patrocinadora (exemplo)","responsavel":"Responsável","segmento":"Decoração e eventos","cidade":"Maresias","descricao":"Exemplo de patrocinadora com destaque na vitrine. Aqui entra o que a marca faz e o benefício que oferece às participantes."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"Grátis: frete na costa sul","oferta_link":"","oferta_tipo":"gratis","oferta_valor":null,"oferta_detalhe":"frete na costa sul","ofereco":"Peças para editoriais e eventos","destaque":false,"id":"e2","tipo":"participante","nome_negocio":"Ateliê Maré (exemplo)","responsavel":"Ana","segmento":"Moda","cidade":"Boiçucanga","descricao":"Moda praia autoral feita no Litoral Norte, com peças sob medida."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"","oferta_link":"","oferta_tipo":null,"oferta_valor":null,"oferta_detalhe":null,"ofereco":"Maquiagem para eventos","destaque":false,"id":"e3","tipo":"participante","nome_negocio":"Studio Sal (exemplo)","responsavel":"Bia","segmento":"Beleza e estética","cidade":"Maresias","descricao":"Design de sobrancelhas, cílios e maquiagem para noivas e eventos."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"Grátis: degustação para participantes","oferta_link":"https://example.com/degustacao","oferta_tipo":"gratis","oferta_valor":null,"oferta_detalhe":"degustação para participantes","ofereco":"Coffee break para eventos","destaque":false,"id":"e4","tipo":"participante","nome_negocio":"Cozinha da Costa (exemplo)","responsavel":"Carla","segmento":"Alimentação e gastronomia","cidade":"Juquehy","descricao":"Buffet e coffee break para eventos corporativos e celebrações."},
    {"instagram":"exemplo","whatsapp":"","site":"","logo_url":"","oferta_bw":"","oferta_link":"","oferta_tipo":null,"oferta_valor":null,"oferta_detalhe":null,"ofereco":"","destaque":false,"id":"e5","tipo":"parceira","nome_negocio":"Parceira Local (exemplo)","responsavel":"Responsável","segmento":"Turismo e hospedagem","cidade":"São Sebastião","descricao":"Exemplo de parceira do evento."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"R$ 30 de desconto na primeira sessão","oferta_link":"","oferta_tipo":"desconto_valor","oferta_valor":30,"oferta_detalhe":"na primeira sessão","ofereco":"","destaque":false,"id":"e6","tipo":"participante","nome_negocio":"Espaço Lume (exemplo)","responsavel":"Duda","segmento":"Beleza e estética","cidade":"Camburi","descricao":"Limpeza de pele, massagem e estética facial."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"10% NA PRIMEIRA VISITA","oferta_link":"","oferta_tipo":null,"oferta_valor":null,"oferta_detalhe":null,"ofereco":"","destaque":false,"id":"e7","tipo":"participante","nome_negocio":"Unhas da Praia (exemplo)","responsavel":"Eva","segmento":"Beleza e estética","cidade":"Maresias","descricao":"Manicure e nail design com atendimento em casa."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"Brinde: caixa de brigadeiros em pedidos acima de R$ 150","oferta_link":"","oferta_tipo":"brinde","oferta_valor":null,"oferta_detalhe":"caixa de brigadeiros em pedidos acima de R$ 150","ofereco":"","destaque":false,"id":"e8","tipo":"participante","nome_negocio":"Doce Maré (exemplo)","responsavel":"Fê","segmento":"Alimentação e gastronomia","cidade":"Boiçucanga","descricao":"Bolos e doces para festas e eventos."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"Compre 2 peças e leve uma bolsa de praia","oferta_link":"","oferta_tipo":"especial","oferta_valor":null,"oferta_detalhe":"compre 2 peças e leve uma bolsa de praia","ofereco":"","destaque":false,"id":"e9","tipo":"participante","nome_negocio":"Linha & Areia (exemplo)","responsavel":"Gabi","segmento":"Moda","cidade":"Juquehy","descricao":"Crochê autoral e acessórios de praia."},
    {"instagram":"exemplo","whatsapp":"5512900000000","site":"","logo_url":"","oferta_bw":"","oferta_link":"","oferta_tipo":null,"oferta_valor":null,"oferta_detalhe":null,"ofereco":"","destaque":false,"id":"e10","tipo":"participante","nome_negocio":"Cuidar Mentoria (exemplo)","responsavel":"Helô","segmento":"Educação e mentoria","cidade":"São Sebastião","descricao":"Mentoria para mulheres que querem organizar o próprio negócio."}
  ];

  async function listarVitrine() {
    if (DEMO) return EXEMPLO;
    const { data, error } = await sb.from("bw_perfis").select(PUBLIC_COLS)
      .eq("status", "aprovado").order("destaque", { ascending: false }).order("created_at", { ascending: true });
    if (error) throw error;
    return data;
  }

  const esc = s => String(s ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
  const iniciais = n => String(n || "?").trim().split(/\s+/).slice(0, 2).map(p => p[0]).join("").toUpperCase();
  const soDigitos = s => String(s || "").replace(/\D/g, "");
  const ig = s => String(s || "").trim().replace(/^@/, "").replace(/^https?:\/\/(www\.)?instagram\.com\//, "").replace(/\/.*$/, "");
  function logoHTML(p) {
    if (p.logo_url && /^https:\/\//.test(p.logo_url)) return `<img class="logo" src="${esc(p.logo_url)}" alt="" loading="lazy">`;
    return `<span class="logo" aria-hidden="true">${esc(iniciais(p.nome_negocio))}</span>`;
  }
  function waLink(num, texto) {
    const d = soDigitos(num); if (!d) return "";
    const n = d.length <= 11 ? "55" + d : d;
    return `https://wa.me/${n}?text=${encodeURIComponent(texto || "")}`;
  }
  const safeUrl = u => /^https?:\/\//i.test(String(u || "")) ? u : (u ? "https://" + u : "");
  // Link da oferta: "" se vazio, null se nao for link (tem espaco), senao o link com https://.
  // O banco tem a mesma regra (bw_perfis_oferta_link_url); conferir aqui evita o "nao salvou" sem motivo.
  const linkOferta = u => {
    const s = String(u || "").trim(); if (!s) return "";
    const l = safeUrl(s); return /^https?:\/\/\S+$/i.test(l) && l.length <= 300 ? l : null;
  };
  // Vitrine em linhas por segmento: segmento com 2 ou mais negocios ganha linha propria, na
  // ordem de quem tem mais; sozinhos, "Outro" e sem segmento vao para "Mais negocios", no fim.
  // Linha de um negocio so' nao e' linha, e' um cartao perdido.
  function agruparPorSegmento(lista) {
    const grupos = new Map();
    lista.forEach(p => { const k = p.segmento || ""; if (!grupos.has(k)) grupos.set(k, []); grupos.get(k).push(p); });
    const linhas = [...grupos].filter(([k, ps]) => k && k !== "Outro" && ps.length >= 2)
      .sort((a, b) => b[1].length - a[1].length || a[0].localeCompare(b[0], "pt-BR"))
      .map(([segmento, perfis]) => ({ segmento, perfis }));
    const proprias = new Set(linhas.map(l => l.segmento));
    const resto = lista.filter(p => !proprias.has(p.segmento || ""));
    if (resto.length) linhas.push({ segmento: "Mais negócios", perfis: resto });
    return linhas;
  }
  // Para buscar: no celular quase ninguem digita acento ("estetica" tem de achar "Estetica" com acento).
  const semAcento = s => String(s ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

  // Reduz a foto para 600 px e converte para JPG. O fundo e' pintado de branco antes:
  // no JPG o transparente vira preto, e logo com letra escura sumia (preto no preto).
  async function reduzirFoto(file) {
    const img = await createImageBitmap(file);
    const k = Math.min(1, 600 / Math.max(img.width, img.height));
    const c = document.createElement("canvas"); c.width = Math.round(img.width * k); c.height = Math.round(img.height * k);
    const g = c.getContext("2d"); g.fillStyle = "#fff"; g.fillRect(0, 0, c.width, c.height);
    g.drawImage(img, 0, 0, c.width, c.height);
    return await new Promise(r => c.toBlob(r, "image/jpeg", 0.86));
  }

  window.BW = { C, DEMO, sb, SEGMENTOS, listarVitrine, esc, iniciais, soDigitos, ig, logoHTML, waLink, safeUrl, linkOferta, semAcento, reduzirFoto, agruparPorSegmento };

  if (DEMO) document.addEventListener("DOMContentLoaded", () => {
    const b = document.createElement("div"); b.className = "demo";
    b.textContent = "Prévia da Vitrine BW: os perfis são exemplos e os cadastros feitos aqui não são gravados.";
    document.body.prepend(b);
  });
})();
