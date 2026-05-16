export function validateMonetary(rawValue: string, fieldLabel: string): string[] {
  const errors: string[] = []

  if (!/^\d+$/.test(rawValue)) {
    errors.push(
      `${fieldLabel}: campo monetário deve conter apenas dígitos (encontrado: "${rawValue.trim()}")`
    )
  }

  return errors
}
