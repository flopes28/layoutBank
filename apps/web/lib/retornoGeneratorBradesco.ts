/**
 * Gera arquivo de retorno Bradesco CNAB 400 a partir de dados de remessa + edições do usuário.
 * Referência: Manual de Procedimentos Operacionais - Cobrança Bradesco CNAB 400, Agosto/2022.
 */

export interface BoletoEdit {
  ocorrencia: string       // 2 dígitos, ex: '06'
  dtOcorrencia: string     // DDMMAA, ex: '160525'
  vlPrincipalCents: number // valor pago em centavos
  dtCredito: string        // DDMMAA
}

export interface DetalheInput {
  rawLine: string
  edit: BoletoEdit
}

// ---------- helpers ----------

function ex(line: string, start: number, end: number): string {
  return line.substring(start - 1, end)
}

function a(val: string, len: number): string {
  return val.substring(0, len).padEnd(len, ' ')
}

function n(val: string | number, len: number): string {
  const digits = String(val).replace(/\D/g, '')
  return digits.padStart(len, '0').slice(-len)
}

function set(line: string, start: number, end: number, val: string): string {
  const len = end - start + 1
  if (val.length !== len) {
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
  l = set(l, 1,   1,   '0')
  l = set(l, 2,   2,   '2')
  l = set(l, 3,   9,   a('RETORNO', 7))
  l = set(l, 10,  11,  ex(remHdr, 10, 11))          // COD_SERVICO
  l = set(l, 12,  26,  a('COBRANCA', 15))
  l = set(l, 27,  46,  a(ex(remHdr, 27, 46), 20))  // COD_EMPRESA Bradesco (20 chars)
  l = set(l, 47,  76,  a(ex(remHdr, 47, 76), 30))  // NOME_EMPRESA
  l = set(l, 77,  79,  n('237', 3))
  l = set(l, 80,  94,  a('BRADESCO', 15))
  l = set(l, 95,  100, a(todayDDMMYY(), 6))
  l = set(l, 101, 108, n('01600000', 8))             // densidade
  // 109-379 brancos
  l = set(l, 380, 385, a(todayDDMMYY(), 6))           // DT_CREDITO header
  // 386-394 brancos
  l = set(l, 395, 400, n('1', 6))
  return l
}

function buildTransacao(remDet: string, edit: BoletoEdit, seq: number): string {
  let l = ' '.repeat(400)
  l = set(l, 1,   1,   '1')
  l = set(l, 2,   3,   n(ex(remDet, 2, 3), 2))       // COD_INSCRICAO
  l = set(l, 4,   17,  n(ex(remDet, 4, 17), 14))     // NUM_INSCRICAO
  l = set(l, 18,  21,  n(ex(remDet, 18, 21), 4))     // AGENCIA
  l = set(l, 22,  23,  n('0', 2))
  l = set(l, 24,  28,  n(ex(remDet, 24, 28), 5))     // CONTA
  l = set(l, 29,  29,  n(ex(remDet, 29, 29), 1))     // DAC
  // 30 branco
  l = set(l, 31,  37,  n(ex(remDet, 31, 37), 7))     // NRO_CONTROLE
  l = set(l, 38,  62,  a(ex(remDet, 38, 62), 25))    // USO_EMPRESA
  // 63-70 brancos
  l = set(l, 71,  81,  n(ex(remDet, 71, 81), 11))    // NOSSO_NUMERO (11 dígitos)
  l = set(l, 82,  82,  n(ex(remDet, 82, 82), 1))     // DIGITO_NN
  // 83-93 brancos
  l = set(l, 94,  96,  n(ex(remDet, 94, 96), 3))     // CARTEIRA
  // 97-108 brancos
  l = set(l, 109, 110, n(edit.ocorrencia, 2))         // COD_OCORRENCIA ← editável
  l = set(l, 111, 116, a(edit.dtOcorrencia, 6))       // DT_OCORRENCIA  ← editável
  l = set(l, 117, 126, a(ex(remDet, 111, 120), 10))  // NRO_DOCUMENTO
  l = set(l, 127, 146, n('0', 20))                    // NOSSO_NUMERO_BANCO (banco gera)
  l = set(l, 147, 152, a(ex(remDet, 121, 126), 6))   // VENCIMENTO
  l = set(l, 153, 165, n(ex(remDet, 127, 139), 13))  // VL_BOLETO
  l = set(l, 166, 168, n('237', 3))
  l = set(l, 169, 173, n(ex(remDet, 143, 147), 5))   // AG_COBRADORA
  l = set(l, 174, 175, n(ex(remDet, 148, 149), 2))   // ESPECIE
  l = set(l, 176, 188, n('0', 13))                    // TARIFA
  // 189-214 brancos
  l = set(l, 215, 227, n(ex(remDet, 193, 205), 13))  // VL_IOF
  l = set(l, 228, 240, n(ex(remDet, 206, 218), 13))  // VL_ABATIMENTO
  l = set(l, 241, 253, n(ex(remDet, 180, 192), 13))  // VL_DESCONTO
  l = set(l, 254, 266, n(edit.vlPrincipalCents, 13)) // VL_PAGO ← editável
  l = set(l, 267, 279, n('0', 13))                    // VL_JUROS_MORA
  l = set(l, 280, 292, n('0', 13))                    // OUTROS_CREDITOS
  // 293-295 brancos
  l = set(l, 296, 301, a(edit.dtCredito, 6))          // DT_CREDITO ← editável
  // 302-328 brancos/uso banco
  l = set(l, 329, 358, a(ex(remDet, 235, 274), 30))  // NOME_PAGADOR (40→trunca a 30)
  // 359-392 brancos
  l = set(l, 393, 394, a('  ', 2))                    // COD_LIQUIDACAO
  l = set(l, 395, 400, n(seq, 6))
  return l
}

function buildTrailer(qtd: number, totalCents: number, seq: number): string {
  let l = ' '.repeat(400)
  l = set(l, 1,   1,   '9')
  l = set(l, 2,   2,   '2')
  l = set(l, 3,   4,   n('01', 2))
  l = set(l, 5,   7,   n('237', 3))
  // 8-17 brancos
  l = set(l, 18,  25,  n(qtd, 8))
  l = set(l, 26,  39,  n(totalCents, 14))
  // 40-394 brancos
  l = set(l, 395, 400, n(seq, 6))
  return l
}

// ---------- função principal ----------

export function generateRetornoFileBradesco(
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

// ---------- helpers de UI (usados no client) ----------

export { parseCurrency, toDateDDMMYY, formatCnabDate, formatCnabMoney } from '@/lib/retornoGenerator'

/** Converte ParsedRecord Bradesco DETALHE_BOLETO para BoletoRow. */
export function buildBoletoRowBradesco(record: { lineNumber: number; rawContent: string }) {
  const raw = record.rawContent
  const today = new Date().toISOString().substring(0, 10)

  const vlBoletoRaw = raw.substring(126, 139)  // pos 127-139
  const vlCents = parseInt(vlBoletoRaw.replace(/\D/g, '') || '0', 10)

  return {
    lineNumber:   record.lineNumber,
    nossoNumero:  raw.substring(70, 82),   // pos 71-82 (11 dígitos + check)
    sacado:       raw.substring(234, 274), // pos 235-274 (40 chars)
    vencimento:   raw.substring(120, 126), // pos 121-126
    vlBoleto:     vlBoletoRaw,
    rawLine:      raw,
    ocorrencia:   '06',
    dtOcorrencia: today,
    vlPrincipal:  (vlCents / 100).toFixed(2),
    dtCredito:    today,
  }
}
