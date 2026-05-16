import { cn } from '@/lib/cn'
import { StatusBadge } from './StatusBadge'
import type { ParsedRecord } from '@layoutbank/shared-types'

interface Props {
  record: ParsedRecord
  isSelected: boolean
  onClick: () => void
  style?: React.CSSProperties
}

const categoryLabel: Record<string, string> = {
  HEADER:  'Header',
  DETAIL:  'Detalhe',
  TRAILER: 'Trailer',
}

const rowClass: Record<string, string> = {
  OK:      'record-row-ok      hover:bg-blue-50',
  WARNING: 'record-row-warning hover:bg-yellow-100',
  ERROR:   'record-row-error   hover:bg-red-100',
  UNKNOWN: 'record-row-unknown hover:bg-red-200',
}

export function RecordRow({ record, isSelected, onClick, style }: Props) {
  const status = record.recordTypeCode === 'UNKNOWN' ? 'UNKNOWN' : record.status
  const errorCount   = record.errors.filter((e) => e.severity === 'ERROR').length
  const warningCount = record.errors.filter((e) => e.severity === 'WARNING').length

  return (
    <div
      style={style}
      onClick={onClick}
      className={cn(
        'grid cursor-pointer items-center gap-2 border-b px-4 py-2 text-sm transition-colors',
        'grid-cols-[4rem_6rem_1fr_5rem_7rem]',
        rowClass[status] ?? rowClass.OK,
        isSelected && 'ring-2 ring-inset ring-blue-400'
      )}
    >
      {/* Nº linha */}
      <span className="font-mono text-xs text-gray-400">{record.lineNumber}</span>

      {/* Categoria */}
      <span className="text-xs text-gray-500">{categoryLabel[record.category] ?? record.category}</span>

      {/* Tipo / Descrição */}
      <span className="truncate font-medium text-gray-900">{record.recordTypeLabel}</span>

      {/* Status badge */}
      <StatusBadge status={status as any} size="sm" />

      {/* Erros / Avisos */}
      <div className="flex items-center gap-1.5 justify-end">
        {errorCount > 0 && (
          <span className="text-xs font-medium text-red-600">
            {errorCount} erro{errorCount > 1 ? 's' : ''}
          </span>
        )}
        {warningCount > 0 && (
          <span className="text-xs font-medium text-yellow-600">
            {warningCount} aviso{warningCount > 1 ? 's' : ''}
          </span>
        )}
        {errorCount === 0 && warningCount === 0 && (
          <span className="text-xs text-gray-300">—</span>
        )}
      </div>
    </div>
  )
}
