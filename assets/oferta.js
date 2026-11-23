// Ofertas guiadas: o tipo, o valor e o "em que" viram sempre o mesmo formato na vitrine
// (selo curto + frase). Definicao unica, lida pela vitrine, pelo cadastro, pelo painel e pelo
// admin; os codigos dos tipos sao os mesmos do "check" do banco (bw_perfis.oferta_tipo).
(function () {
  const TIPOS = [
    { codigo: "desconto_pct", nome: "Desconto em %", valor: "pct", pergunta: "Em quê?", exemplo: "na primeira compra" },
    { codigo: "desconto_valor", nome: "Desconto em R$", valor: "reais", pergunta: "Em quê?", exemplo: "na próxima compra" },
    { codigo: "gratis", nome: "Algo grátis", valor: null, pergunta: "O que é grátis?", exemplo: "avaliação, diagnóstico, frete…" },
    { codigo: "brinde", nome: "Brinde", valor: null, pergunta: "Qual brinde?", exemplo: "kit de amostras na primeira visita" },
    { codigo: "especial", nome: "Condição especial", valor: null, pergunta: "Qual a condição?", exemplo: "compre 2, pague 1 no passeio 3 Ilhas" }
  ];
  const MAX_DETALHE = 120;
  const tipo = c => TIPOS.find(t => t.codigo === c);

  // Texto todo em caixa alta (com pelo menos 4 letras) vira frase normal; espacos sobrando saem.
  function normalizarCaixa(s) {
    const t = String(s ?? "").trim().replace(/\s+/g, " ");
    const letras = t.replace(/[^\p{L}]/gu, "");
    if (letras.length >= 4 && letras === letras.toLocaleUpperCase("pt-BR") && letras !== letras.toLocaleLowerCase("pt-BR")) {
      const m = t.toLocaleLowerCase("pt-BR"); return m.charAt(0).toLocaleUpperCase("pt-BR") + m.slice(1);
    }
    return t;
  }
  const limpar = s => normalizarCaixa(s).replace(/[.;]+$/, "");
  const maiuscula = s => s.charAt(0).toLocaleUpperCase("pt-BR") + s.slice(1);
  // "em que" depois de "de desconto" comeca minusculo, a nao ser que seja sigla ("BW na criacao...")
  const minuscula = s => /^\p{Lu}\p{Lu}/u.test(s) ? s : s.charAt(0).toLocaleLowerCase("pt-BR") + s.slice(1);
  const reais = v => Number(v).toLocaleString("pt-BR", { minimumFractionDigits: Number(v) % 1 ? 2 : 0, maximumFractionDigits: 2 });

  function selo(p) {
    switch (p.oferta_tipo) {
      case "desconto_pct": return `${Number(p.oferta_valor)}% OFF`;
      case "desconto_valor": return `R$ ${reais(p.oferta_valor)} OFF`;
      case "gratis": return "GRÁTIS";
      case "brinde": return "BRINDE";
      case "especial": return "ESPECIAL";
    }
    return p.oferta_bw ? "OFERTA BW" : "";
  }

  // A frase inteira: e' o que vai para oferta_bw (busca, admin, planilha, WhatsApp).
  function frase(t, valor, detalhe) {
    const d = limpar(detalhe);
    switch (t) {
      case "desconto_pct": return `${Number(valor)}% de desconto ${minuscula(d)}`.trim();
      case "desconto_valor": return `R$ ${reais(valor)} de desconto ${minuscula(d)}`.trim();
      case "gratis": return `Grátis: ${minuscula(d)}`;
      case "brinde": return `Brinde: ${minuscula(d)}`;
      case "especial": return maiuscula(d);
    }
    return "";
  }

  // O texto do cartao, embaixo do selo: o selo ja diz o quanto, aqui vai o em que.
  function resumo(p) {
    if (!p.oferta_tipo) return normalizarCaixa(p.oferta_bw);
    const d = limpar(p.oferta_detalhe);
    return p.oferta_tipo.startsWith("desconto") ? minuscula(d) : maiuscula(d);
  }

  function validar(o) {
    const t = tipo(o.oferta_tipo); if (!t) return "";
    const v = Number(o.oferta_valor), d = String(o.oferta_detalhe ?? "").trim();
    if (t.valor === "pct" && !(v >= 1 && v <= 100)) return "Confira o valor do desconto: de 1 a 100%.";
    if (t.valor === "reais" && !(v > 0 && v <= 100000)) return "Confira o valor do desconto em reais.";
    if (!d) return `Falta dizer na oferta: ${t.pergunta.toLocaleLowerCase("pt-BR")}`;
    if (d.length > MAX_DETALHE) return `A oferta pode ter até ${MAX_DETALHE} caracteres no "${t.pergunta}".`;
    return "";
  }

  const esc = x => String(x ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const numero = x => { const t = String(x ?? "").trim().replace(",", "."); return t === "" || isNaN(Number(t)) ? null : Number(t); };

  // Os campos guiados com a previa, iguais no cadastro, no painel e no admin. Oferta antiga
  // (texto livre, sem tipo) aparece como "Manter como esta": salvar o resto do perfil nao pode
  // apagar a oferta de quem ainda nao converteu.
  function campos(el, prefixo = "") {
    const id = n => prefixo + n;
    el.innerHTML = `
      <div class="field"><label for="${id("oferta_tipo")}">Tipo de oferta</label><select id="${id("oferta_tipo")}"></select></div>
      <div class="two oferta-linha">
        <div class="field oferta-valor"><label for="${id("oferta_valor")}"></label><input id="${id("oferta_valor")}" inputmode="decimal" maxlength="9" autocomplete="off"></div>
        <div class="field"><label for="${id("oferta_detalhe")}"></label><input id="${id("oferta_detalhe")}" maxlength="${MAX_DETALHE}" autocomplete="off"></div>
      </div>
      <div class="oferta-previa" aria-live="polite"><span class="h">Como vai aparecer na vitrine</span><div class="mini-offer"></div></div>`;
    const $ = n => el.querySelector("#" + id(n));
    const sel = $("oferta_tipo"), valor = $("oferta_valor"), det = $("oferta_detalhe");
    let antiga = "";

    function ler() {
      if (sel.value === "__manter") return { oferta_tipo: null, oferta_valor: null, oferta_detalhe: null, oferta_bw: antiga };
      const t = tipo(sel.value);
      if (!t) return { oferta_tipo: null, oferta_valor: null, oferta_detalhe: null, oferta_bw: null };
      const o = { oferta_tipo: t.codigo, oferta_valor: t.valor ? numero(valor.value) : null, oferta_detalhe: det.value.trim() || null };
      o.oferta_bw = frase(o.oferta_tipo, o.oferta_valor, o.oferta_detalhe || "");
      return o;
    }
    function atualizar() {
      const t = tipo(sel.value), o = ler();
      el.querySelector(".oferta-linha").hidden = !t;
      el.querySelector(".oferta-valor").hidden = !t || !t.valor;
      if (t) {
        el.querySelector(`label[for="${id("oferta_valor")}"]`).textContent = t.valor === "pct" ? "Desconto (%)" : "Desconto (R$)";
        el.querySelector(`label[for="${id("oferta_detalhe")}"]`).textContent = t.pergunta;
        det.placeholder = t.exemplo; valor.placeholder = t.valor === "pct" ? "10" : "20";
      }
      const mostrar = o.oferta_bw && !(t && t.valor && o.oferta_valor === null);
      el.querySelector(".oferta-previa").hidden = !mostrar;
      if (mostrar) el.querySelector(".oferta-previa .mini-offer").innerHTML = `<b class="selo">${esc(selo(o))}</b> ${esc(resumo(o))}`;
    }
    function preencher(p = {}) {
      antiga = !p.oferta_tipo && p.oferta_bw ? p.oferta_bw : "";
      const curto = antiga.length > 40 ? antiga.slice(0, 40) + "…" : antiga;
      sel.innerHTML = (antiga ? `<option value="__manter">Manter como está: “${esc(curto)}”</option>` : "")
        + `<option value="">Sem oferta por enquanto</option>` + TIPOS.map(t => `<option value="${t.codigo}">${esc(t.nome)}</option>`).join("");
      sel.value = p.oferta_tipo || (antiga ? "__manter" : "");
      valor.value = p.oferta_valor ?? ""; det.value = p.oferta_detalhe ?? "";
      atualizar();
    }
    const erro = () => sel.value === "__manter" || !sel.value ? "" : validar(ler());
    el.addEventListener("input", atualizar); el.addEventListener("change", atualizar);
    preencher();
    return { ler, erro, preencher };
  }

  window.BW_OFERTA = { TIPOS, MAX_DETALHE, tipo, normalizarCaixa, selo, frase, resumo, validar, campos };
})();
