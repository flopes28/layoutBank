// Tipos internos do cnab-engine.
// O engine é agnóstico ao banco de dados — recebe LayoutDefinition
// de qualquer fonte via LayoutProvider.

export type CnabFormat = 'CNAB240' | 'CNAB400' | 'CNAB400_REMESSA' | 'CNAB400_RETORNO' | 'CNAB240_COBRANCA_REM' | 'CNAB240_COBRANCA_RET'
export type RecordCategory = 'HEADER' | 'DETAIL' | 'TRAILER'
export type FieldDataType = 'ALPHA' | 'NUM' | 'DATE' | 'MONETARY' | 'ALPHANUM' | 'CONSTANT'

export interface ValidationRuleConfig {
  minValue?: number
  maxValue?: number
  allowedPattern?: string
  customMessage?: string
  mustMatchField?: string
  crossRecord?: string
}

export interface FieldDefinition {
  id: string
  name: string
  label: string
  description?: string | null
  startPosition: number   // 1-based, conforme FEBRABAN
  endPosition: number     // 1-based
  length: number
  dataType: FieldDataType
  formatMask?: string | null
  decimalPlaces: number
  isRequired: boolean
  isFiller: boolean
  allowedValues?: string[] | null
  validationRules?: ValidationRuleConfig | null
}

export interface RecordIdentifier {
  start: number   // 1-based
  end: number     // 1-based
  value: string
}

export interface RecordTypeDefinition {
  id: string
  code: string
  label: string
  category: RecordCategory
  identifier: RecordIdentifier
  secondaryIdentifier?: RecordIdentifier
  fields: FieldDefinition[]
}

export interface LayoutDefinition {
  id: string
  bankCode: string
  bankName: string
  format: CnabFormat
  version: string
  name: string
  lineLength: 240 | 400
  encoding: BufferEncoding
  recordTypes: RecordTypeDefinition[]
}

// Interface que o engine usa para obter layouts.
// Implementada fora do engine (ex: DatabaseLayoutProvider em apps/web)
export interface LayoutProvider {
  identify(firstLine: string, secondLine?: string): Promise<LayoutDefinition | null>
  getById(layoutId: string): Promise<LayoutDefinition | null>
}

export interface ParseOptions {
  layoutId?: string
  encoding?: BufferEncoding
}
