import type { FieldDefinition } from '../types'

export interface RawField {
  definition: FieldDefinition
  rawValue: string  // exatamente como estava no arquivo
}

/**
 * Extrai o valor bruto de um campo usando suas posições 1-based.
 * Esta é a única função no sistema que faz a conversão 1-based → 0-based.
 */
export function extractRawValue(line: string, start: number, end: number): string {
  // start e end chegam como 1-based (conforme FEBRABAN)
  // String.substring usa 0-based, exclusivo no end
  return line.substring(start - 1, end)
}

/**
 * Extrai todos os campos de uma linha conforme suas field_definitions.
 * Retorna o valor bruto de cada campo preservando espaços e zeros.
 */
export function extractFields(line: string, fields: FieldDefinition[]): RawField[] {
  return fields.map((def) => ({
    definition: def,
    rawValue: extractRawValue(line, def.startPosition, def.endPosition),
  }))
}
