export function validateNumeric(rawValue: string, fieldLabel: string): string[] {
  const errors: string[] = []
  const trimmed = rawValue.trim()

  if (!/^\d*$/.test(rawValue)) {
    errors.push(`${fieldLabel}: campo numérico contém caracteres não-numéricos ("${rawValue.trim()}")`)
  } else if (trimmed === '' && rawValue.length > 0) {
    // Campo todo em branco onde se esperava numérico — pode ser inválido (verificado por RequiredRule)
  }

  return errors
}
