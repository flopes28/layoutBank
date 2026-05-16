import type { FileSummary as FileSummaryType, FileInfo } from '@layoutbank/shared-types'
import { formatFileSize } from '@/lib/formatters'

interface Props {
  fileInfo: FileInfo
  summary: FileSummaryType
  layoutName: string
  bankName: string
}

export function FileSummary({ fileInfo, summary, layoutName, bankName }: Props) {
  return (
    <div className="space-y-4">
      {/* Info do arquivo */}
      <div className="rounded-lg border bg-white px-5 py-4">
        <div className="flex flex-wrap items-center gap-x-8 gap-y-2 text-sm">
          <div>
            <span className="text-gray-500">Arquivo:</span>{' '}
            <span className="font-medium text-gray-900">{fileInfo.name}</span>
          </div>
          <div>
            <span className="text-gray-500">Tamanho:</span>{' '}
            <span className="font-medium">{formatFileSize(fileInfo.sizeBytes)}</span>
          </div>
          <div>
            <span className="text-gray-500">Encoding:</span>{' '}
            <span className="font-medium">{fileInfo.encoding}</span>
          </div>
          <div>
            <span className="text-gray-500">Banco:</span>{' '}
            <span className="font-medium">{bankName}</span>
          </div>
          <div>
            <span className="text-gray-500">Layout:</span>{' '}
            <span className="font-medium">{layoutName}</span>
          </div>
        </div>
      </div>

      {/* Cards de totais */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-7">
        <Card label="Total de Linhas"  value={summary.totalLines}   color="blue"   />
        <Card label="Headers"          value={summary.headerCount}  color="gray"   />
        <Card label="Detalhes"         value={summary.detailCount}  color="gray"   />
        <Card label="Trailers"         value={summary.trailerCount} color="gray"   />
        <Card label="Desconhecidos"    value={summary.unknownCount} color={summary.unknownCount > 0 ? 'red' : 'gray'} />
        <Card label="Com Erro"         value={summary.errorCount}   color={summary.errorCount > 0 ? 'red' : 'green'} />
        <Card label="Com Aviso"        value={summary.warningCount} color={summary.warningCount > 0 ? 'yellow' : 'green'} />
      </div>

      {/* Alerta de erros estruturais */}
      {summary.hasStructuralErrors && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          <strong>Erros estruturais detectados.</strong> Algumas linhas têm tamanho incorreto e não puderam ser processadas.
        </div>
      )}
    </div>
  )
}

type Color = 'blue' | 'green' | 'red' | 'yellow' | 'gray'

const colorMap: Record<Color, { bg: string; text: string; value: string }> = {
  blue:   { bg: 'bg-blue-50',   text: 'text-blue-600',   value: 'text-blue-900'   },
  green:  { bg: 'bg-green-50',  text: 'text-green-600',  value: 'text-green-900'  },
  red:    { bg: 'bg-red-50',    text: 'text-red-600',    value: 'text-red-900'    },
  yellow: { bg: 'bg-yellow-50', text: 'text-yellow-600', value: 'text-yellow-900' },
  gray:   { bg: 'bg-gray-50',   text: 'text-gray-500',   value: 'text-gray-900'   },
}

function Card({ label, value, color }: { label: string; value: number; color: Color }) {
  const c = colorMap[color]
  return (
    <div className={`rounded-lg border ${c.bg} px-4 py-3`}>
      <p className={`text-xs font-medium ${c.text} truncate`}>{label}</p>
      <p className={`mt-1 text-2xl font-bold ${c.value}`}>{value.toLocaleString('pt-BR')}</p>
    </div>
  )
}
