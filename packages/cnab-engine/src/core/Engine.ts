import type { LayoutProvider, ParseOptions } from '../types'
import type { ParseResult, ParsedRecord, FileSummary, RecordStatus, FieldError } from '@layoutbank/shared-types'
import { readLines, detectLineLength, extractBankCode } from './LineReader'
import { classifyRecord } from './RecordClassifier'
import { extractFields } from './FieldExtractor'
import { validateFields } from '../validation/ValidationPipeline'
import { validateStructure } from '../validation/rules/StructuralRule'
import { validateCrossRecord } from '../validation/CrossRecordValidator'

export class CnabEngine {
  constructor(private readonly provider: LayoutProvider) {}

  async parse(buffer: Buffer, options: ParseOptions = {}): Promise<ParseResult> {
    const startedAt = new Date().toISOString()

    // ---- 1. Identificar e carregar o layout ----
    const lines = readLines(buffer, options.encoding ?? 'latin1')

    if (lines.length === 0) {
      throw new Error('Arquivo vazio ou inválido')
    }

    const lineLength = detectLineLength(lines)
    const bankCode   = extractBankCode(lines[0].content)

    const layout = options.layoutId
      ? await this.provider.getById(options.layoutId)
      : await this.provider.identify(lines[0].content, lines[1]?.content)

    if (!layout) {
      throw new Error(
        `Nenhum layout identificado para banco "${bankCode}" com linhas de ${lineLength} caracteres`
      )
    }

    // ---- 2. Processar cada linha ----
    const records: ParsedRecord[] = []

    for (const line of lines) {
      // Camada 1: validação estrutural
      const structural = validateStructure(line.content, layout.lineLength)

      if (!structural.isValid) {
        records.push({
          lineNumber:      line.lineNumber,
          rawContent:      line.content,
          recordTypeCode:  'UNKNOWN',
          recordTypeLabel: 'Registro Desconhecido',
          category:        'DETAIL',
          status:          'ERROR',
          fields:          [],
          errors:          [{ field: '_structural', message: structural.error!, severity: 'ERROR' }],
        })
        continue
      }

      // Identificar tipo de registro
      const recordType = classifyRecord(line.content, layout.recordTypes)

      if (!recordType) {
        records.push({
          lineNumber:      line.lineNumber,
          rawContent:      line.content,
          recordTypeCode:  'UNKNOWN',
          recordTypeLabel: 'Tipo de Registro Não Identificado',
          category:        'DETAIL',
          status:          'ERROR',
          fields:          [],
          errors:          [{
            field:    '_classifier',
            message:  `Tipo de registro não identificado para esta linha`,
            severity: 'ERROR',
          }],
        })
        continue
      }

      // Camadas 2: extrair campos e validar
      const rawFields    = extractFields(line.content, recordType.fields)
      const parsedFields = validateFields(rawFields)

      // Agregar erros e warnings dos campos
      const fieldErrors: FieldError[] = []
      for (const field of parsedFields) {
        for (const err of field.validation.errors) {
          fieldErrors.push({ field: field.name, message: err, severity: 'ERROR' })
        }
        for (const warn of field.validation.warnings) {
          fieldErrors.push({ field: field.name, message: warn, severity: 'WARNING' })
        }
      }

      const status: RecordStatus =
        fieldErrors.some((e) => e.severity === 'ERROR')
          ? 'ERROR'
          : fieldErrors.some((e) => e.severity === 'WARNING')
          ? 'WARNING'
          : 'OK'

      records.push({
        lineNumber:      line.lineNumber,
        rawContent:      line.content,
        recordTypeCode:  recordType.code,
        recordTypeLabel: recordType.label,
        category:        recordType.category,
        status,
        fields:          parsedFields,
        errors:          fieldErrors,
      })
    }

    // ---- 3. Cross-record validation ----
    const crossRecordErrors = validateCrossRecord(records)

    // ---- 4. Montar summary ----
    const summary = buildSummary(records)

    return {
      fileInfo: {
        name:       '',  // preenchido pela API route com o nome real do arquivo
        sizeBytes:  buffer.length,
        totalLines: lines.length,
        encoding:   layout.encoding,
      },
      layoutId:          layout.id,
      layoutName:        layout.name,
      bankCode:          layout.bankCode,
      bankName:          layout.bankName,
      format:            layout.format,
      summary,
      records,
      crossRecordErrors,
      parsedAt:          startedAt,
    }
  }
}

function buildSummary(records: ParsedRecord[]): FileSummary {
  let headerCount = 0, detailCount = 0, trailerCount = 0
  let errorCount = 0, warningCount = 0
  let hasStructuralErrors = false
  let unknownCount = 0

  for (const r of records) {
    if (r.recordTypeCode === 'UNKNOWN') {
      unknownCount++
      hasStructuralErrors = true
    } else if (r.category === 'HEADER')  headerCount++
    else if (r.category === 'DETAIL')    detailCount++
    else if (r.category === 'TRAILER')   trailerCount++

    if (r.status === 'ERROR')   errorCount++
    if (r.status === 'WARNING') warningCount++

    if (r.errors.some((e) => e.field === '_structural')) {
      hasStructuralErrors = true
    }
  }

  return {
    totalLines: records.length,
    headerCount,
    detailCount,
    trailerCount,
    errorCount,
    warningCount,
    hasStructuralErrors,
    unknownCount,
  }
}
