import type { ParsedRecord } from '@layoutbank/shared-types'
import type { CrossRecordError } from '@layoutbank/shared-types'

/**
 * Camada 3 de validação: verifica relacionamentos entre registros.
 * Executado após o processamento de todas as linhas.
 */
export function validateCrossRecord(records: ParsedRecord[]): CrossRecordError[] {
  const errors: CrossRecordError[] = []

  errors.push(...validateStructure(records))
  errors.push(...validateCounts(records))

  return errors
}

// ---- Validações estruturais ----

function validateStructure(records: ParsedRecord[]): CrossRecordError[] {
  const errors: CrossRecordError[] = []

  const headers  = records.filter((r) => r.recordTypeCode.startsWith('HEADER_ARQUIVO') || r.recordTypeCode === 'HEADER')
  const trailers = records.filter((r) => r.recordTypeCode.startsWith('TRAILER_ARQUIVO') || r.recordTypeCode === 'TRAILER')

  if (headers.length === 0) {
    errors.push({
      type: 'MISSING_HEADER',
      severity: 'ERROR',
      message: 'Header de arquivo não encontrado',
      lines: [],
    })
  } else if (headers.length > 1) {
    errors.push({
      type: 'STRUCTURAL',
      severity: 'ERROR',
      message: `Múltiplos headers de arquivo encontrados (${headers.length})`,
      lines: headers.map((h) => h.lineNumber),
    })
  }

  if (trailers.length === 0) {
    errors.push({
      type: 'MISSING_TRAILER',
      severity: 'ERROR',
      message: 'Trailer de arquivo não encontrado',
      lines: [],
    })
  } else if (trailers.length > 1) {
    errors.push({
      type: 'STRUCTURAL',
      severity: 'ERROR',
      message: `Múltiplos trailers de arquivo encontrados (${trailers.length})`,
      lines: trailers.map((t) => t.lineNumber),
    })
  }

  // Valida balanceamento de lotes no CNAB 240
  const headerLotes  = records.filter((r) => r.recordTypeCode === 'HEADER_LOTE')
  const trailerLotes = records.filter((r) => r.recordTypeCode === 'TRAILER_LOTE')

  if (headerLotes.length !== trailerLotes.length) {
    errors.push({
      type: 'UNBALANCED_BATCH',
      severity: 'ERROR',
      message: `Número de headers de lote (${headerLotes.length}) não corresponde ao de trailers de lote (${trailerLotes.length})`,
      lines: [...headerLotes, ...trailerLotes].map((r) => r.lineNumber),
    })
  }

  return errors
}

// ---- Validações de contagem e totais ----

function validateCounts(records: ParsedRecord[]): CrossRecordError[] {
  const errors: CrossRecordError[] = []

  const totalRecords = records.length

  // Verifica QTD_REGISTROS no trailer de arquivo
  const trailer = records.find(
    (r) => r.recordTypeCode === 'TRAILER_ARQUIVO' || r.recordTypeCode === 'TRAILER'
  )

  if (trailer) {
    const countField = trailer.fields.find((f) => f.name === 'QTD_REGISTROS')
    if (countField && typeof countField.parsedValue === 'number') {
      if (countField.parsedValue !== totalRecords) {
        errors.push({
          type: 'TOTAL_MISMATCH',
          severity: 'ERROR',
          message: `Quantidade de registros no trailer (${countField.parsedValue}) não corresponde ao total real (${totalRecords})`,
          lines: [trailer.lineNumber],
        })
      }
    }
  }

  return errors
}
