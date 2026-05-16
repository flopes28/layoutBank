import type { FieldDataType } from '../../types'

export function validateRequired(
  rawValue: string,
  fieldLabel: string,
  dataType: FieldDataType
): string[] {
  const errors: string[] = []

  const isBlank =
    dataType === 'NUM' || dataType === 'MONETARY'
      ? /^0+$/.test(rawValue) || rawValue.trim() === ''
      : rawValue.trim() === ''

  if (isBlank) {
    errors.push(`${fieldLabel}: campo obrigatório não pode estar em branco ou zerado`)
  }

  return errors
}
