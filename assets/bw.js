// Núcleo compartilhado: cliente Supabase, modo exemplo e utilitários.
(function () {
  const C = window.BW_CONFIG;
  const DEMO = !C.SUPABASE_URL || !C.SUPABASE_ANON_KEY;
  const sb = DEMO ? null : window.supabase.createClient(C.SUPABASE_URL, C.SUPABASE_ANON_KEY);

  const PUBLIC_COLS = "id,created_at,tipo,nome_negocio,responsavel,segmento,cidade,descricao,instagram,whatsapp,site,logo_url,oferta_bw,ofereco,preciso,destaque";

  const SEGMENTOS = ["Beleza e estética","Moda","Alimentação e gastronomia","Saúde e bem-estar","Turismo e hospedagem","Imóveis","Educação e mentoria","Marketing e comunicação","Serviços","Decoração e eventos","Fotografia","Artesanato","Negócios locais","Outro"];

  // Dados de exemplo: aparecem só no modo exemplo (sem banco configurado).
  const EXEMPLO = [
    {id:"e1",tipo:"patrocinadora",nome_negocio:"Marca Patrocinadora (exemplo)",responsavel:"Responsável",segmento:"Decoração e eventos",cidade:"Maresias",descricao:"Exemplo de patrocinadora com destaque na vitrine. Aqui entra o que a marca faz e o benefício que oferece às participantes.",instagram:"exemplo",whatsapp:"",site:"",logo_url:"",oferta_bw:"10% para participantes do Business Wave",ofereco:"",preciso:"",destaque:true},
    {id:"e2",tipo:"participante",nome_negocio:"Ateliê Maré (exemplo)",responsavel:"Ana",segmento:"Moda",cidade:"Boiçucanga",descricao:"Moda praia autoral feita no Litoral Norte, com peças sob medida.",instagram:"exemplo",whatsapp:"5512900000000",site:"",logo_url:"",oferta_bw:"Frete grátis na costa sul",ofereco:"Peças para editoriais e eventos",preciso:"Fotógrafa para catálogo",destaque:false},
    {id:"e3",tipo:"participante",nome_negocio:"Studio Sal (exemplo)",responsavel:"Bia",segmento:"Beleza e estética",cidade:"Maresias",descricao:"Design de sobrancelhas, cílios e maquiagem para noivas e eventos.",instagram:"exemplo",whatsapp:"5512900000000",site:"",logo_url:"",oferta_bw:"",ofereco:"Maquiagem para eventos",preciso:"Parcerias com pousadas",destaque:false},
    {id:"e4",tipo:"participante",nome_negocio:"Cozinha da Costa (exemplo)",responsavel:"Carla",segmento:"Alimentação e gastronomia",cidade:"Juquehy",descricao:"Buffet e coffee break para eventos corporativos e celebrações.",instagram:"exemplo",whatsapp:"5512900000000",site:"",logo_url:"",oferta_bw:"Degustação grátis para participantes",ofereco:"Coffee break para eventos",preciso:"Indicações de empresas",destaque:false},
    {id:"e5",tipo:"parceira",nome_negocio:"Parceira Local (exemplo)",responsavel:"Responsável",segmento:"Turismo e hospedagem",cidade:"São Sebastião",descricao:"Exemplo de parceira do evento.",instagram:"exemplo",whatsapp:"",site:"",logo_url:"",oferta_bw:"",ofereco:"",preciso:"",destaque:false}
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

  window.BW = { C, DEMO, sb, SEGMENTOS, listarVitrine, esc, iniciais, soDigitos, ig, logoHTML, waLink, safeUrl, semAcento, reduzirFoto };

  if (DEMO) document.addEventListener("DOMContentLoaded", () => {
    const b = document.createElement("div"); b.className = "demo";
    b.textContent = "Prévia da Vitrine BW: os perfis são exemplos e os cadastros feitos aqui não são gravados.";
    document.body.prepend(b);
  });
})();
