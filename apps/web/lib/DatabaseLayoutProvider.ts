import type { LayoutProvider, LayoutDefinition, RecordTypeDefinition, FieldDefinition } from '@layoutbank/cnab-engine'
import { findLayoutById, findLayoutByBankAndFormatName } from '@layoutbank/database'
import type { LayoutWithRelations } from '@layoutbank/database'
import type { CnabFormat } from '@layoutbank/shared-types'

export class DatabaseLayoutProvider implements LayoutProvider {
  async identify(firstLine: string): Promise<LayoutDefinition | null> {
    const lineLength = firstLine.length
    if (lineLength !== 240 && lineLength !== 400) return null

    let bankCode: string
    let formatName: string

    if (lineLength === 240) {
      // CNAB 240: código do banco nas posições 1-3 (1-indexed)
      bankCode = firstLine.substring(0, 3).trim()
      formatName = 'CNAB240'
    } else {
      // CNAB 400: código do banco nas posições 77-79 (1-indexed)
      bankCode = firstLine.substring(76, 79).trim()
      // Posição 2 (índice 1) distingue remessa ('1') de retorno ('2')
      const tipoOp = firstLine.charAt(1)
      formatName = tipoOp === '2' ? 'CNAB400_RETORNO' : 'CNAB400_REMESSA'
    }

    const layout = await findLayoutByBankAndFormatName(bankCode, formatName)
    return layout ? mapToLayoutDefinition(layout) : null
  }

  async getById(layoutId: string): Promise<LayoutDefinition | null> {
    const layout = await findLayoutById(layoutId)
    if (!layout) return null
    return mapToLayoutDefinition(layout)
  }
}

function mapToLayoutDefinition(layout: LayoutWithRelations): LayoutDefinition {
  return {
    id:         layout.id,
    bankCode:   layout.bank.code,
    bankName:   layout.bank.name,
    format:     layout.format as CnabFormat,
    version:    layout.version,
    name:       layout.name,
    lineLength: layout.lineLength as 240 | 400,
    encoding:   (layout.encoding ?? 'latin1') as BufferEncoding,
    recordTypes: layout.recordTypes.map(mapToRecordType),
  }
}

function mapToRecordType(rt: LayoutWithRelations['recordTypes'][number]): RecordTypeDefinition {
  return {
    id:       rt.id,
    code:     rt.code,
    label:    rt.description,
    category: rt.category as 'HEADER' | 'DETAIL' | 'TRAILER',
    identifier: {
      start: rt.identifierStart,
      end:   rt.identifierEnd,
      value: rt.identifierValue,
    },
    secondaryIdentifier:
      rt.secondaryIdentifierStart && rt.secondaryIdentifierEnd && rt.secondaryIdentifierValue
        ? {
            start: rt.secondaryIdentifierStart,
            end:   rt.secondaryIdentifierEnd,
            value: rt.secondaryIdentifierValue,
          }
        : undefined,
    fields: rt.fieldDefinitions.map(mapToFieldDefinition),
  }
}

function mapToFieldDefinition(fd: LayoutWithRelations['recordTypes'][number]['fieldDefinitions'][number]): FieldDefinition {
  return {
    id:              fd.id,
    name:            fd.name,
    label:           fd.label,
    description:     fd.description,
    startPosition:   fd.startPosition,
    endPosition:     fd.endPosition,
    length:          fd.length,
    dataType:        fd.dataType as FieldDefinition['dataType'],
    formatMask:      fd.formatMask,
    decimalPlaces:   fd.decimalPlaces,
    isRequired:      fd.isRequired,
    isFiller:        fd.isFiller,
    allowedValues:   fd.allowedValues ?? null,
    validationRules: fd.validationRules as FieldDefinition['validationRules'] ?? null,
  }
}
