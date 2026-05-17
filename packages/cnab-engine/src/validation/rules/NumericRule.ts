export function validateNumeric(rawValue: string, fieldLabel: string): string[] {
  const errors: string[] = []
  const trimmed = rawValue.trim()

  // Campo todo em branco: banco deixou vazio (RequiredRule trata obrigatoriedade)
  if (trimmed === '') return errors

  if (!/^\d+$/.test(trimmed)) {
    errors.push(`${fieldLabel}: campo numérico contém caracteres não-numéricos ("${trimmed}")`)
  }

  return errors
}
