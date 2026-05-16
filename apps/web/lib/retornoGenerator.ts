/**
 * Gera arquivo de retorno Itaú CNAB 400 a partir de dados de remessa + edições do usuário.
 * Referência: Manual Itaú CNAB 400 Cobrança – Janeiro/2017.
 */

export interface BoletoEdit {
  ocorrencia: string       // 2 dígitos, ex: '06'
  dtOcorrencia: string     // DDMMAA, ex: '160525'
  vlPrincipalCents: number // valor pago em centavos, ex: 123456 = R$ 1.234,56
  dtCredito: string        // DDMMAA
}

export interface DetalheInput {
  rawLine: string
  edit: BoletoEdit
}

// ---------- helpers de posicionamento ----------

/** Extrai substring com posições 1-based. */
function ex(line: string, start: number, end: number): string {
  return line.substring(start - 1, end)
}

/** Formata valor ALPHA: trunca ou completa com espaços à direita. */
function a(val: string, len: number): string {
  return val.substring(0, len).padEnd(len, ' ')
}

/** Formata valor NUM/MONETARY: remove não-dígitos, completa com zeros à esquerda. */
function n(val: string | number, len: number): string {
  const digits = String(val).replace(/\D/g, '')
  return digits.padStart(len, '0').slice(-len)
}

/** Substitui o trecho [start, end] (1-based) da linha pelo valor já formatado. */
function set(line: string, start: number, end: number, val: string): string {
  const len = end - start + 1
  if (val.length !== len) {
    // garante comprimento correto (trunca ou completa)
    val = val.length > len ? val.substring(0, len) : val.padEnd(len, ' ')
  }
  return line.substring(0, start - 1) + val + line.substring(end)
}

function todayDDMMYY(): string {
  const d = new Date()
  return (
    String(d.getDate()).padStart(2, '0') +
    String(d.getMonth() + 1).padStart(2, '0') +
    String(d.getFullYear()).slice(-2)
  )
}

// ---------- builders ----------

function buildHeader(remHdr: string): string {
  let l = ' '.repeat(400)
  l = set(l, 1,   1,   a('0', 1))
  l = set(l, 2,   2,   n('2', 1))
  l = set(l, 3,   9,   a('RETORNO', 7))
  l = set(l, 10,  11,  ex(remHdr, 10, 11))          // COD_SERVICO
  l = set(l, 12,  26,  a('COBRANCA', 15))
  l = set(l, 27,  30,  ex(remHdr, 27, 30))           // AGENCIA
  l = set(l, 31,  32,  n('0', 2))
  l = set(l, 33,  37,  ex(remHdr, 33, 37))           // CONTA
  l = set(l, 38,  38,  ex(remHdr, 38, 38))           // DAC
  l = set(l, 39,  46,  a('', 8))
  l = set(l, 47,  76,  a(ex(remHdr, 47, 76), 30))   // NOME_EMPRESA
  l = set(l, 77,  79,  n('341', 3))
  l = set(l, 80,  94,  a('BANCO ITAU SA', 15))
  l = set(l, 95,  100, a(todayDDMMYY(), 6))           // DT_GERACAO
  l = set(l, 101, 105, n('0', 5))                    // DENSIDADE
  l = set(l, 106, 108, a('', 3))
  l = set(l, 109, 113, n(ex(remHdr, 395, 400), 5))  // NRO_SEQ_ARQ
  l = set(l, 114, 119, a(todayDDMMYY(), 6))           // DT_CREDITO
  // BRANCOS_2 (120-394) já é espaço
  l = set(l, 395, 400, n('1', 6))
  return l
}

function buildTransacao(remDet: string, edit: BoletoEdit, seq: number): string {
  let l = ' '.repeat(400)
  l = set(l, 1,   1,   a('1', 1))
  l = set(l, 2,   3,   n(ex(remDet, 2, 3), 2))       // COD_INSCRICAO
  l = set(l, 4,   17,  n(ex(remDet, 4, 17), 14))     // NUM_INSCRICAO
  l = set(l, 18,  21,  n(ex(remDet, 18, 21), 4))     // AGENCIA
  l = set(l, 22,  23,  n('0', 2))
  l = set(l, 24,  28,  n(ex(remDet, 24, 28), 5))     // CONTA
  l = set(l, 29,  29,  n(ex(remDet, 29, 29), 1))     // DAC
  l = set(l, 30,  37,  a('', 8))
  l = set(l, 38,  62,  a(ex(remDet, 38, 62), 25))    // USO_EMPRESA
  l = set(l, 63,  70,  n(ex(remDet, 63, 70), 8))     // NOSSO_NUMERO
  l = set(l, 71,  82,  a('', 12))
  l = set(l, 83,  85,  n(ex(remDet, 84, 86), 3))     // CARTEIRA (NRO_CARTEIRA remessa)
  l = set(l, 86,  93,  n(ex(remDet, 63, 70), 8))     // NOSSO_NUMERO_2
  l = set(l, 94,  94,  n('0', 1))
  l = set(l, 95,  107, a('', 13))
  l = set(l, 108, 108, a(ex(remDet, 108, 108), 1))   // CARTEIRA_COD
  l = set(l, 109, 110, n(edit.ocorrencia, 2))         // COD_OCORRENCIA ← editável
  l = set(l, 111, 116, a(edit.dtOcorrencia, 6))       // DT_OCORRENCIA  ← editável
  l = set(l, 117, 126, a(ex(remDet, 111, 120), 10))  // NRO_DOCUMENTO
  l = set(l, 127, 134, n(ex(remDet, 63, 70), 8))     // NOSSO_NUMERO_CONF
  l = set(l, 135, 146, a('', 12))
  l = set(l, 147, 152, a(ex(remDet, 121, 126), 6))   // VENCIMENTO
  l = set(l, 153, 165, n(ex(remDet, 127, 139), 13))  // VL_BOLETO
  l = set(l, 166, 168, n('341', 3))
  l = set(l, 169, 172, n(ex(remDet, 143, 146), 4))   // AG_COBRADORA (4 de 5)
  l = set(l, 173, 173, n('0', 1))
  l = set(l, 174, 175, a(ex(remDet, 148, 149), 2))   // ESPECIE
  l = set(l, 176, 188, n('0', 13))                   // TARIFA
  l = set(l, 189, 214, a('', 26))
  l = set(l, 215, 227, n(ex(remDet, 193, 205), 13))  // VL_IOF
  l = set(l, 228, 240, n(ex(remDet, 206, 218), 13))  // VL_ABATIMENTO
  l = set(l, 241, 253, n(ex(remDet, 180, 192), 13))  // VL_DESCONTO
  l = set(l, 254, 266, n(edit.vlPrincipalCents, 13)) // VL_PRINCIPAL ← editável
  l = set(l, 267, 279, n('0', 13))                   // VL_JUROS_MORA
  l = set(l, 280, 292, n('0', 13))                   // OUTROS_CREDITO
  l = set(l, 293, 293, a('', 1))
  l = set(l, 294, 295, a('', 2))
  l = set(l, 296, 301, a(edit.dtCredito, 6))         // DT_CREDITO ← editável
  l = set(l, 302, 305, n('0', 4))
  l = set(l, 306, 311, a('', 6))
  l = set(l, 312, 324, n('0', 13))
  l = set(l, 325, 354, a(ex(remDet, 235, 264), 30))  // NOME_PAGADOR
  l = set(l, 355, 375, a('', 21))
  l = set(l, 376, 385, a('', 10))                    // ERROS
  l = set(l, 386, 392, a('', 7))
  l = set(l, 393, 394, a('', 2))
  l = set(l, 395, 400, n(seq, 6))
  return l
}

function buildTrailer(qtd: number, totalCents: number, seq: number): string {
  let l = ' '.repeat(400)
  l = set(l, 1,   1,   a('9', 1))
  l = set(l, 2,   2,   n('2', 1))
  l = set(l, 3,   4,   n('01', 2))
  l = set(l, 5,   7,   n('341', 3))
  l = set(l, 8,   17,  a('', 10))
  l = set(l, 18,  25,  n(qtd, 8))
  l = set(l, 26,  39,  n(totalCents, 14))
  l = set(l, 40,  47,  a('', 8))
  l = set(l, 48,  57,  a('', 10))
  l = set(l, 58,  65,  n('0', 8))
  l = set(l, 66,  79,  n('0', 14))
  l = set(l, 80,  87,  a('', 8))
  l = set(l, 88,  177, a('', 90))
  l = set(l, 178, 185, n('0', 8))
  l = set(l, 186, 199, n('0', 14))
  l = set(l, 200, 207, a('', 8))
  l = set(l, 208, 212, n('0', 5))
  l = set(l, 213, 220, n(qtd, 8))
  l = set(l, 221, 234, n(totalCents, 14))
  l = set(l, 235, 394, a('', 160))
  l = set(l, 395, 400, n(seq, 6))
  return l
}

// ---------- função principal ----------

export function generateRetornoFile(
  remessaHeaderRaw: string,
  detalhes: DetalheInput[],
): Buffer {
  const linhas: string[] = []

  linhas.push(buildHeader(remessaHeaderRaw))

  let seq = 2
  let totalCents = 0

  for (const { rawLine, edit } of detalhes) {
    linhas.push(buildTransacao(rawLine, edit, seq++))
    totalCents += edit.vlPrincipalCents
  }

  linhas.push(buildTrailer(detalhes.length, totalCents, seq))

  return Buffer.from(linhas.join('\r\n') + '\r\n', 'latin1')
}

/** Converte string de valor (ex: "1.234,56" ou "1234.56") para centavos inteiros. */
export function parseCurrency(val: string): number {
  // Suporta formato BR (1.234,56) e EN (1234.56)
  const cleaned = val.replace(/\./g, '').replace(',', '.')
  return Math.round(parseFloat(cleaned || '0') * 100)
}

/** Converte date input HTML (YYYY-MM-DD) para DDMMAA. */
export function toDateDDMMYY(iso: string): string {
  if (!iso || iso.length < 10) return '000000'
  const [y, m, d] = iso.split('-')
  return `${d}${m}${String(y).slice(-2)}`
}

/** Converte DDMMAA do CNAB para exibição (DD/MM/AAAA). */
export function formatCnabDate(ddmmyy: string): string {
  if (!ddmmyy || ddmmyy === '000000') return '—'
  const d = ddmmyy.substring(0, 2)
  const m = ddmmyy.substring(2, 4)
  const y = ddmmyy.substring(4, 6)
  const century = parseInt(y) > 50 ? '19' : '20'
  return `${d}/${m}/${century}${y}`
}

/** Converte valor monetário CNAB (13 dígitos, centavos) para exibição. */
export function formatCnabMoney(raw: string): string {
  const cents = parseInt(raw.replace(/\D/g, '') || '0', 10)
  return (cents / 100).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}
