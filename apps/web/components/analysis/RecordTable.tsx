'use client'

import { useRef, useState } from 'react'
import { useVirtualizer } from '@tanstack/react-virtual'
import type { ParsedRecord, RecordStatus } from '@layoutbank/shared-types'
import { RecordRow } from './RecordRow'
import { FieldInspector } from './FieldInspector'

interface Props {
  records: ParsedRecord[]
}

type FilterStatus = 'ALL' | RecordStatus | 'UNKNOWN'

const filterLabels: Record<FilterStatus, string> = {
  ALL:     'Todos',
  OK:      'OK',
  WARNING: 'Avisos',
  ERROR:   'Erros',
  UNKNOWN: 'Desconhecidos',
}

export function RecordTable({ records }: Props) {
  const [filter, setFilter]           = useState<FilterStatus>('ALL')
  const [selectedRecord, setSelected] = useState<ParsedRecord | null>(null)

  const filtered = records.filter((r) => {
    if (filter === 'ALL') return true
    if (filter === 'UNKNOWN') return r.recordTypeCode === 'UNKNOWN'
    return r.status === filter
  })

  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count:           filtered.length,
    getScrollElement: () => parentRef.current,
    estimateSize:    () => 45,
    overscan:        10,
  })

  const items = virtualizer.getVirtualItems()

  return (
    <div className="flex flex-col rounded-lg border bg-white shadow-sm">
      {/* Toolbar */}
      <div className="flex items-center gap-2 border-b px-4 py-3">
        <span className="text-sm font-medium text-gray-700 mr-2">Filtrar:</span>
        {(Object.keys(filterLabels) as FilterStatus[]).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`rounded-full px-3 py-1 text-xs font-medium transition-colors ${
              filter === f
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {filterLabels[f]}{' '}
            <span className="opacity-70">
              ({
                f === 'ALL'     ? records.length :
                f === 'UNKNOWN' ? records.filter((r) => r.recordTypeCode === 'UNKNOWN').length :
                records.filter((r) => r.status === f).length
              })
            </span>
          </button>
        ))}
        <span className="ml-auto text-xs text-gray-400">
          Clique em uma linha para inspecionar os campos
        </span>
      </div>

      {/* Cabeçalho da tabela */}
      <div className="grid grid-cols-[4rem_6rem_1fr_5rem_7rem] gap-2 border-b bg-gray-50 px-4 py-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
        <span>Linha</span>
        <span>Categoria</span>
        <span>Tipo / Descrição</span>
        <span>Status</span>
        <span className="text-right">Ocorrências</span>
      </div>

      {/* Tabela virtualizada */}
      <div
        ref={parentRef}
        className="overflow-auto"
        style={{ height: 'min(600px, calc(100vh - 420px))' }}
      >
        <div
          style={{
            height:   `${virtualizer.getTotalSize()}px`,
            position: 'relative',
          }}
        >
          {items.map((item) => {
            const record = filtered[item.index]
            return (
              <div
                key={item.key}
                style={{
                  position:  'absolute',
                  top:       0,
                  left:      0,
                  right:     0,
                  transform: `translateY(${item.start}px)`,
                }}
              >
                <RecordRow
                  record={record}
                  isSelected={selectedRecord?.lineNumber === record.lineNumber}
                  onClick={() => setSelected(record)}
                />
              </div>
            )
          })}
        </div>
      </div>

      {filtered.length === 0 && (
        <div className="px-4 py-12 text-center text-sm text-gray-400">
          Nenhum registro encontrado com o filtro selecionado.
        </div>
      )}

      {/* Painel de inspeção */}
      <FieldInspector record={selectedRecord} onClose={() => setSelected(null)} />
    </div>
  )
}
