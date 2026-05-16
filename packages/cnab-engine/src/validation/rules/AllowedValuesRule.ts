export function validateAllowedValues(
  rawValue: string,
  fieldLabel: string,
  allowedValues: string[]
): string[] {
  const errors: string[] = []
  const trimmed = rawValue.trim()

  if (allowedValues.length > 0 && !allowedValues.includes(trimmed)) {
    errors.push(
      `${fieldLabel}: valor "${trimmed}" não permitido. Valores aceitos: ${allowedValues.join(', ')}`
    )
  }

  return errors
}
