export interface StructuralValidation {
  isValid: boolean
  error?: string
}

/**
 * Camada 1 de validação: verifica integridade estrutural da linha.
 * Se falhar, a linha não deve ser processada campo a campo.
 */
export function validateStructure(
  lineContent: string,
  expectedLength: number
): StructuralValidation {
  const actual = lineContent.length

  if (actual === 0) {
    return { isValid: false, error: 'Linha vazia' }
  }

  if (actual !== expectedLength) {
    return {
      isValid: false,
      error: `Tamanho incorreto: esperado ${expectedLength} caracteres, encontrado ${actual}`,
    }
  }

  return { isValid: true }
}
