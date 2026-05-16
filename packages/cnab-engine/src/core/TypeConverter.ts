import type { FieldDataType } from '../types'

export type ConvertedValue = string | number | Date | null

/**
 * Converte o valor bruto (string) para o tipo nativo correspondente.
 * Em caso de erro de conversão, retorna null — a validação reportará o problema.
 */
export function convertValue(
  rawValue: string,
  dataType: FieldDataType,
  formatMask?: string | null,
  decimalPlaces: number = 0
): ConvertedValue {
  switch (dataType) {
    case 'NUM':
      return convertNum(rawValue)
    case 'MONETARY':
      return convertMonetary(rawValue, decimalPlaces)
    case 'DATE':
      return convertDate(rawValue, formatMask ?? 'DDMMAAAA')
    case 'ALPHA':
    case 'ALPHANUM':
      return rawValue.trimEnd()
    case 'CONSTANT':
      return rawValue
    default:
      return rawValue.trimEnd()
  }
}

// ---- Conversores internos ----

function convertNum(raw: string): number | null {
  const trimmed = raw.trim()
  if (trimmed === '' || /^\s*$/.test(raw)) return null
  // Remove zeros à esquerda para converter, mas mantém "0" válido
  const value = parseInt(raw.trim(), 10)
  return isNaN(value) ? null : value
}

function convertMonetary(raw: string, decimalPlaces: number): number | null {
  const trimmed = raw.trim()
  if (trimmed === '' || trimmed === '0'.repeat(raw.length)) return 0
  const intValue = parseInt(raw, 10)
  if (isNaN(intValue)) return null
  return decimalPlaces > 0
    ? intValue / Math.pow(10, decimalPlaces)
    : intValue
}

/**
 * Converte string de data baseada no format_mask.
 * Suporta: DDMMAAAA, DDMMAA, MMAAAA, AAAAMMDD
 */
function convertDate(raw: string, mask: string): Date | null {
  const trimmed = raw.trim()
  // Datas vazias ou zero são representadas como null
  if (!trimmed || /^0+$/.test(trimmed) || trimmed === '00000000' || trimmed === '000000') {
    return null
  }

  let day = 1, month = 0, year = 1900

  const upperMask = mask.toUpperCase()

  if (upperMask === 'DDMMAAAA') {
    day   = parseInt(raw.substring(0, 2), 10)
    month = parseInt(raw.substring(2, 4), 10) - 1
    year  = parseInt(raw.substring(4, 8), 10)
  } else if (upperMask === 'DDMMAA') {
    day   = parseInt(raw.substring(0, 2), 10)
    month = parseInt(raw.substring(2, 4), 10) - 1
    year  = 2000 + parseInt(raw.substring(4, 6), 10)
  } else if (upperMask === 'MMAAAA') {
    month = parseInt(raw.substring(0, 2), 10) - 1
    year  = parseInt(raw.substring(2, 6), 10)
    day   = 1
  } else if (upperMask === 'AAAAMMDD') {
    year  = parseInt(raw.substring(0, 4), 10)
    month = parseInt(raw.substring(4, 6), 10) - 1
    day   = parseInt(raw.substring(6, 8), 10)
  } else {
    return null
  }

  if (isNaN(day) || isNaN(month) || isNaN(year)) return null

  const date = new Date(year, month, day)

  // Valida que a data construída é igual à esperada (ex: 32/01 viraria 01/02)
  if (
    date.getFullYear() !== year ||
    date.getMonth()    !== month ||
    date.getDate()     !== day
  ) {
    return null
  }

  return date
}
