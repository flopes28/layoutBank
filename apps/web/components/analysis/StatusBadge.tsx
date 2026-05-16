import { cn } from '@/lib/cn'
import type { RecordStatus } from '@layoutbank/shared-types'

interface Props {
  status: RecordStatus | 'UNKNOWN'
  size?: 'sm' | 'md'
}

const config = {
  OK:      { label: 'OK',          classes: 'bg-green-100 text-green-700 ring-green-200'  },
  WARNING: { label: 'Aviso',       classes: 'bg-yellow-100 text-yellow-700 ring-yellow-200' },
  ERROR:   { label: 'Erro',        classes: 'bg-red-100 text-red-700 ring-red-200'         },
  UNKNOWN: { label: 'Desconhecido',classes: 'bg-gray-100 text-gray-600 ring-gray-200'      },
}

export function StatusBadge({ status, size = 'md' }: Props) {
  const { label, classes } = config[status] ?? config.UNKNOWN

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full font-medium ring-1 ring-inset',
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-xs',
        classes
      )}
    >
      {label}
    </span>
  )
}
