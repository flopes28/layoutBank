// Tipos centrais do domínio CNAB compartilhados entre engine, database e web

export type CnabFormat = 'CNAB240' | 'CNAB400' | 'CNAB400_REMESSA' | 'CNAB400_RETORNO'
export type RecordCategory = 'HEADER' | 'DETAIL' | 'TRAILER'
export type RecordStatus = 'OK' | 'WARNING' | 'ERROR'
export type FieldDataType = 'ALPHA' | 'NUM' | 'DATE' | 'MONETARY' | 'ALPHANUM' | 'CONSTANT'

export interface FileInfo {
  name: string
  sizeBytes: number
  totalLines: number
  encoding: string
}

export interface FileSummary {
  totalLines: number
  headerCount: number
  detailCount: number
  trailerCount: number
  errorCount: number
  warningCount: number
  hasStructuralErrors: boolean
  unknownCount: number
}

export interface FieldValidation {
  isValid: boolean
  errors: string[]
  warnings: string[]
}

export interface ParsedField {
  name: string
  label: string
  description: string | null
  startPosition: number   // 1-based, conforme FEBRABAN
  endPosition: number     // 1-based
  rawValue: string        // exatamente o que estava no arquivo
  parsedValue: string | number | Date | null
  dataType: FieldDataType
  isRequired: boolean
  isFiller: boolean
  validation: FieldValidation
}

export interface FieldError {
  field: string
  message: string
  severity: 'ERROR' | 'WARNING'
}

export interface ParsedRecord {
  lineNumber: number          // 1-based
  rawContent: string          // linha original intacta
  recordTypeCode: string      // 'HEADER_ARQUIVO', 'DETALHE_J', etc.
  recordTypeLabel: string     // 'Header de Arquivo'
  category: RecordCategory
  status: RecordStatus
  fields: ParsedField[]
  errors: FieldError[]
}

export interface CrossRecordError {
  type: 'TOTAL_MISMATCH' | 'MISSING_HEADER' | 'MISSING_TRAILER' | 'SEQUENCE_ERROR' | 'UNBALANCED_BATCH' | 'STRUCTURAL'
  message: string
  severity: 'ERROR' | 'WARNING'
  lines: number[]
}

export interface ParseResult {
  fileInfo: FileInfo
  layoutId: string
  layoutName: string
  bankCode: string
  bankName: string
  format: CnabFormat
  summary: FileSummary
  records: ParsedRecord[]
  crossRecordErrors: CrossRecordError[]
  parsedAt: string  // ISO 8601
}
