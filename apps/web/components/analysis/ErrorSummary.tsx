import type { CrossRecordError } from '@layoutbank/shared-types'

interface Props {
  crossRecordErrors: CrossRecordError[]
}

export function ErrorSummary({ crossRecordErrors }: Props) {
  if (crossRecordErrors.length === 0) return null

  return (
    <div className="rounded-lg border border-red-200 bg-red-50 p-4">
      <h3 className="mb-3 font-semibold text-red-800">
        Erros de Consistência ({crossRecordErrors.length})
      </h3>
      <ul className="space-y-1.5">
        {crossRecordErrors.map((err, i) => (
          <li key={i} className="flex items-start gap-2 text-sm text-red-700">
            <span className="mt-0.5 shrink-0 text-red-400">▶</span>
            <span>
              {err.message}
              {err.lines.length > 0 && (
                <span className="ml-1 text-red-400">
                  (linha{err.lines.length > 1 ? 's' : ''}: {err.lines.join(', ')})
                </span>
              )}
            </span>
          </li>
        ))}
      </ul>
    </div>
  )
}
