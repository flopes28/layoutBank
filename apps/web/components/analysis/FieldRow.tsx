import { cn } from '@/lib/cn'
import { formatParsedValue } from '@/lib/formatters'
import type { ParsedField } from '@layoutbank/shared-types'

interface Props {
  field: ParsedField
}

export function FieldRow({ field }: Props) {
  const hasErrors   = field.validation.errors.length > 0
  const hasWarnings = field.validation.warnings.length > 0
  const isInvalid   = hasErrors
  const isWarning   = !hasErrors && hasWarnings

  return (
    <div
      className={cn(
        'grid grid-cols-[auto_6rem_1fr_1fr_auto] items-start gap-2 rounded px-3 py-2 text-xs',
        isInvalid ? 'field-invalid' : isWarning ? 'field-warning' : 'hover:bg-gray-50'
      )}
    >
      {/* Status icon */}
      <span className="mt-0.5 w-4 text-center">
        {isInvalid  ? '✗' : isWarning ? '⚠' : '✓'}
      </span>

      {/* Position */}
      <span className="font-mono text-gray-500 shrink-0">
        {field.startPosition}–{field.endPosition}
      </span>

      {/* Field name + label */}
      <div className="min-w-0">
        <p className="font-semibold text-gray-900 truncate">{field.label}</p>
        <p className="text-gray-400 truncate">{field.name}</p>
      </div>

      {/* Raw value */}
      <div className="min-w-0">
        <p className="font-mono text-gray-700 truncate">
          &ldquo;{field.rawValue}&rdquo;
        </p>
        {field.parsedValue !== null && field.parsedValue !== field.rawValue.trim() && (
          <p className="text-gray-400 truncate">
            → {formatParsedValue(field.parsedValue, field.dataType)}
          </p>
        )}
      </div>

      {/* Type tag */}
      <span className="shrink-0 rounded bg-gray-100 px-1.5 py-0.5 font-mono text-gray-500">
        {field.dataType}
      </span>

      {/* Validation messages */}
      {(hasErrors || hasWarnings) && (
        <div className="col-span-5 ml-6 space-y-0.5">
          {field.validation.errors.map((e, i) => (
            <p key={i} className="text-red-600">{e}</p>
          ))}
          {field.validation.warnings.map((w, i) => (
            <p key={i} className="text-yellow-600">{w}</p>
          ))}
        </div>
      )}
    </div>
  )
}
