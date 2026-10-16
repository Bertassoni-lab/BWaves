// Configuração da Vitrine BW.
window.BW_CONFIG = {
  SUPABASE_URL: "https://qmjdvnvbodplrwrdxdre.supabase.co",       // vazio = modo exemplo
  SUPABASE_ANON_KEY: "sb_publishable_7pEjMVYGoQxHHZK_G5alHA_0sMMYb7Y",
  SITE_URL: "https://bw.okgo.dev.br",
  LINK_INGRESSO: "https://businesswave.com.br",
  INSTAGRAM: "businesswavelitoral",
  EVENTO: { edicao: "5ª edição", data: "16.10.2026", hora: "18h às 22h", local: "Beach Hotel Maresias", cidade: "Maresias · São Sebastião/SP" },
  // Presente da Maresias Tour no painel da participante. Quem tem direito e o codigo vem do
  // banco (bw_voucher); sem a funcao no banco, o cartao simplesmente nao aparece.
  VOUCHER: {
    de: "Maresias Tour",
    passeio: "Passeio de lancha compartilhada",
    roteiro: "As 3 Ilhas da Costa Sul",
    detalhe: "Roteiro As 3 Ilhas da Costa Sul: cerca de 3 horas, saindo da Praia de Boiçucanga. Saídas às 9h, 12h e 15h.",
    validade: "16/02/2027",
    total: 20,
    whatsapp: "5512996509051"   // WhatsApp da Maresias Tour para agendar
  }
};
