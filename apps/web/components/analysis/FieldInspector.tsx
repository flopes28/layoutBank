'use client'

import { useEffect, useRef } from 'react'
import type { ParsedRecord } from '@layoutbank/shared-types'
import { StatusBadge } from './StatusBadge'
import { FieldRow } from './FieldRow'

interface Props {
  record: ParsedRecord | null
  onClose: () => void
}

export function FieldInspector({ record, onClose }: Props) {
  const panelRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!record) return
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [record, onClose])

  if (!record) return null

  const errorCount   = record.errors.filter((e) => e.severity === 'ERROR').length
  const warningCount = record.errors.filter((e) => e.severity === 'WARNING').length

  return (
    <>
      {/* Overlay */}
      <div
        className="fixed inset-0 z-40 bg-black/20 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Painel lateral */}
      <div
        ref={panelRef}
        className="fixed right-0 top-0 z-50 flex h-full w-full max-w-2xl flex-col bg-white shadow-2xl"
      >
        {/* Header do painel */}
        <div className="flex items-start justify-between border-b bg-gray-50 px-5 py-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="text-sm font-mono text-gray-400">Linha {record.lineNumber}</span>
              <StatusBadge status={record.status} />
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
            </div>
            <h2 className="mt-1 font-semibold text-gray-900">{record.recordTypeLabel}</h2>
            <p className="text-xs text-gray-500 font-mono">{record.recordTypeCode}</p>
          </div>
          <button
            onClick={onClose}
            className="rounded-md p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
            aria-label="Fechar"
          >
            ✕
          </button>
        </div>

        {/* Linha bruta */}
        <div className="border-b bg-gray-900 px-5 py-3">
          <p className="text-xs text-gray-400 mb-1">Conteúdo bruto da linha:</p>
          <p className="font-mono text-xs text-green-400 break-all leading-relaxed">
            {record.rawContent}
          </p>
        </div>

        {/* Tabela de campos */}
        <div className="flex-1 overflow-y-auto">
          {/* Cabeçalho da tabela */}
          <div className="sticky top-0 grid grid-cols-[auto_6rem_1fr_1fr_auto] gap-2 border-b bg-gray-50 px-3 py-2 text-xs font-medium text-gray-500">
            <span className="w-4" />
            <span>Posição</span>
            <span>Campo</span>
            <span>Valor</span>
            <span>Tipo</span>
          </div>

          {/* Linhas de campos */}
          <div className="divide-y divide-gray-100 pb-4">
            {record.fields.length > 0 ? (
              record.fields.map((field, i) => (
                <FieldRow key={i} field={field} />
              ))
            ) : (
              <p className="px-5 py-8 text-center text-sm text-gray-400">
                Não foi possível extrair os campos deste registro.
              </p>
            )}
          </div>
        </div>
      </div>
    </>
  )
}
