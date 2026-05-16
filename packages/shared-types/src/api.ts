import type { ParseResult, CnabFormat } from './cnab'

// ---- Request / Response types para as API Routes ----

export interface ParseRequest {
  layoutId?: string  // se omitido, detecção automática
}

export type ParseResponse = ParseResult

export interface ApiError {
  error: string
  message: string
  details?: unknown
}

// ---- Tipos de retorno das APIs de layout/banco ----

export interface BankDto {
  id: string
  code: string
  name: string
  shortName: string
  isActive: boolean
}

export interface CnabLayoutDto {
  id: string
  bankId: string
  bankCode: string
  bankName: string
  format: CnabFormat
  version: string
  name: string
  lineLength: number
  encoding: string
  isActive: boolean
}

export interface RecordTypeDto {
  id: string
  layoutId: string
  code: string
  description: string
  category: 'HEADER' | 'DETAIL' | 'TRAILER'
  sortOrder: number
}

export interface FieldDefinitionDto {
  id: string
  recordTypeId: string
  name: string
  label: string
  description: string | null
  startPosition: number
  endPosition: number
  length: number
  dataType: string
  formatMask: string | null
  decimalPlaces: number
  isRequired: boolean
  isFiller: boolean
  allowedValues: string[] | null
  validationRules: Record<string, unknown> | null
  sortOrder: number
}

export interface CnabLayoutDetailDto extends CnabLayoutDto {
  recordTypes: Array<RecordTypeDto & { fieldDefinitions: FieldDefinitionDto[] }>
}
