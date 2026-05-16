import { formatFileSize } from '@/lib/formatters'

interface Props {
  name: string
  sizeBytes: number
  totalLines: number
}

export function FileInfo({ name, sizeBytes, totalLines }: Props) {
  return (
    <div className="flex items-center gap-4 rounded-lg border bg-gray-50 px-4 py-3 text-sm">
      <span className="text-2xl">📄</span>
      <div className="min-w-0">
        <p className="truncate font-medium text-gray-900">{name}</p>
        <p className="text-gray-500">
          {formatFileSize(sizeBytes)} · {totalLines.toLocaleString('pt-BR')} linhas
        </p>
      </div>
    </div>
  )
}
