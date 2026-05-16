import type { FieldDataType } from '../../types'

export function validateFiller(
  rawValue: string,
  fieldLabel: string,
  dataType: FieldDataType
): string[] {
  const warnings: string[] = []

  const expectedFiller =
    dataType === 'NUM' || dataType === 'MONETARY'
      ? /^0+$/.test(rawValue)
      : /^\s*$/.test(rawValue)

  if (!expectedFiller) {
    warnings.push(
      `${fieldLabel}: campo de uso exclusivo FEBRABAN deve ser ${
        dataType === 'NUM' || dataType === 'MONETARY' ? 'zeros' : 'brancos'
      } (encontrado: "${rawValue.trim()}")`
    )
  }

  return warnings
}
