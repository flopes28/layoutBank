import { convertValue } from '../../core/TypeConverter'

export function validateDate(
  rawValue: string,
  fieldLabel: string,
  formatMask: string = 'DDMMAAAA',
  isRequired: boolean = true
): string[] {
  const errors: string[] = []
  const trimmed = rawValue.trim()

  if (!trimmed || /^0+$/.test(trimmed)) {
    if (isRequired) {
      errors.push(`${fieldLabel}: data obrigatória não informada`)
    }
    return errors
  }

  const expectedLength = formatMask.replace(/[^A-Z]/gi, '').length
  if (rawValue.length !== expectedLength) {
    errors.push(`${fieldLabel}: comprimento inválido para o formato ${formatMask}`)
    return errors
  }

  if (!/^\d+$/.test(trimmed)) {
    errors.push(`${fieldLabel}: data contém caracteres não-numéricos`)
    return errors
  }

  const converted = convertValue(rawValue, 'DATE', formatMask)
  if (converted === null) {
    errors.push(`${fieldLabel}: data inválida "${rawValue}" para o formato ${formatMask}`)
  }

  return errors
}
