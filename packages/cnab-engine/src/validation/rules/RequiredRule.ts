import type { FieldDataType } from '../../types'

export function validateRequired(
  rawValue: string,
  fieldLabel: string,
  dataType: FieldDataType
): string[] {
  const errors: string[] = []

  // Para MONETARY, zero-preenchido = não informado (ex: VL_BOLETO zerado é inválido).
  // Para NUM, zero é um valor legítimo (ex: TIPO_REGISTRO='0', DAC='0').
  // Para todos os tipos, campo todo-espaço = não preenchido.
  const isBlank =
    dataType === 'MONETARY'
      ? /^0+$/.test(rawValue) || rawValue.trim() === ''
      : rawValue.trim() === ''

  if (isBlank) {
    errors.push(`${fieldLabel}: campo obrigatório não pode estar em branco`)
  }

  return errors
}
