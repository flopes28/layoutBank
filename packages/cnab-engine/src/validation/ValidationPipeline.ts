import type { FieldDefinition } from '../types'
import type { RawField } from '../core/FieldExtractor'
import { convertValue } from '../core/TypeConverter'
import { validateNumeric } from './rules/NumericRule'
import { validateDate } from './rules/DateRule'
import { validateMonetary } from './rules/MonetaryRule'
import { validateRequired } from './rules/RequiredRule'
import { validateAllowedValues } from './rules/AllowedValuesRule'
import { validateFiller } from './rules/FillerRule'
import type { FieldValidation, ParsedField } from '@layoutbank/shared-types'

/**
 * Aplica todas as regras de validação em um campo extraído.
 * Retorna um ParsedField completo com rawValue, parsedValue e validação.
 *
 * Ordem de execução:
 * 1. Filler (aviso se preenchido incorretamente)
 * 2. Required (erro se vazio)
 * 3. Type-specific (NUM, DATE, MONETARY)
 * 4. AllowedValues (enum)
 */
export function validateField(rawField: RawField): ParsedField {
  const { definition: def, rawValue } = rawField
  const errors: string[] = []
  const warnings: string[] = []

  // 1. Filler — aviso, não bloqueia validações seguintes
  if (def.isFiller) {
    const fillerWarnings = validateFiller(rawValue, def.label, def.dataType)
    warnings.push(...fillerWarnings)
  } else {
    // 2. Required — só para campos não-filler
    if (def.isRequired) {
      const requiredErrors = validateRequired(rawValue, def.label, def.dataType)
      errors.push(...requiredErrors)
    }

    // 3. Type-specific
    if (def.dataType === 'NUM') {
      errors.push(...validateNumeric(rawValue, def.label))
    } else if (def.dataType === 'MONETARY') {
      errors.push(...validateMonetary(rawValue, def.label))
    } else if (def.dataType === 'DATE') {
      errors.push(...validateDate(rawValue, def.label, def.formatMask ?? 'DDMMAAAA', def.isRequired))
    }

    // 4. Allowed values
    if (def.allowedValues && def.allowedValues.length > 0) {
      errors.push(...validateAllowedValues(rawValue, def.label, def.allowedValues))
    }

    // 5. Pattern from validationRules
    if (def.validationRules?.allowedPattern) {
      const pattern = new RegExp(def.validationRules.allowedPattern)
      if (!pattern.test(rawValue.trim())) {
        const msg = def.validationRules.customMessage
          ?? `${def.label}: valor "${rawValue.trim()}" não corresponde ao padrão esperado`
        errors.push(msg)
      }
    }
  }

  const isValid = errors.length === 0
  const validation: FieldValidation = { isValid, errors, warnings }

  return {
    name:          def.name,
    label:         def.label,
    description:   def.description ?? null,
    startPosition: def.startPosition,
    endPosition:   def.endPosition,
    rawValue,
    parsedValue:   convertValue(rawValue, def.dataType, def.formatMask, def.decimalPlaces),
    dataType:      def.dataType as any,
    isRequired:    def.isRequired,
    isFiller:      def.isFiller,
    validation,
  }
}

/**
 * Processa todos os campos de um registro e retorna ParsedField[].
 */
export function validateFields(rawFields: RawField[]): ParsedField[] {
  return rawFields.map(validateField)
}
