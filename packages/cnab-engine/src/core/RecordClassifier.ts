import type { RecordTypeDefinition } from '../types'
import { extractRawValue } from './FieldExtractor'

/**
 * Identifica o tipo de registro de uma linha baseado nos identificadores
 * definidos no layout (posição + valor esperado).
 *
 * Suporta identificador primário e secundário (ex: CNAB 240 Segmento J).
 */
export function classifyRecord(
  line: string,
  recordTypes: RecordTypeDefinition[]
): RecordTypeDefinition | null {
  for (const rt of recordTypes) {
    const primary = extractRawValue(line, rt.identifier.start, rt.identifier.end)
    if (primary !== rt.identifier.value) continue

    if (rt.secondaryIdentifier) {
      const secondary = extractRawValue(
        line,
        rt.secondaryIdentifier.start,
        rt.secondaryIdentifier.end
      )
      if (secondary !== rt.secondaryIdentifier.value) continue
    }

    return rt
  }

  return null
}
