'use client'

import { useEffect, useState, useMemo } from 'react'

// ---------- tipos ----------

interface LayoutSummary {
  id: string
  name: string
  format: string
  version: string
  lineLength: number
  bankCode: string
  bankName: string
}

interface FieldRow {
  seq: number
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
}

interface RecordType {
  id: string
  code: string
  description: string
  category: string
  sortOrder: number
  identifier: { start: number; end: number; value: string }
  fields: FieldRow[]
}

interface LayoutDetail {
  id: string
  name: string
  format: string
  version: string
  lineLength: number
  encoding: string
  bank: { code: string; name: string; shortName: string }
  recordTypes: RecordType[]
}

// ---------- helpers ----------

const DATA_TYPE_LABEL: Record<string, string> = {
  ALPHA:    'Alfa',
  NUM:      'Numérico',
  DATE:     'Data',
  MONETARY: 'Monetário',
  ALPHANUM: 'Alfanumérico',
  CONSTANT: 'Constante',
}

const CATEGORY_LABEL: Record<string, string> = {
  HEADER:  'Header',
  DETAIL:  'Detalhe',
  TRAILER: 'Trailer',
}

const CATEGORY_COLOR: Record<string, string> = {
  HEADER:  'bg-blue-50 text-blue-700 border-blue-200',
  DETAIL:  'bg-gray-50 text-gray-700 border-gray-200',
  TRAILER: 'bg-amber-50 text-amber-700 border-amber-200',
}

function fieldContent(field: FieldRow): string {
  if (field.allowedValues && field.allowedValues.length > 0) {
    return field.allowedValues.join(' | ')
  }
  if (field.isFiller) {
    return field.dataType === 'NUM' ? 'Zeros' : 'Brancos'
  }
  if (field.formatMask) return field.formatMask
  if (field.description) return field.description
  return '—'
}

function highlight(text: string, query: string): React.ReactNode {
  if (!query) return text
  const idx = text.toLowerCase().indexOf(query.toLowerCase())
  if (idx === -1) return text
  return (
    <>
      {text.slice(0, idx)}
      <mark className="bg-yellow-200 text-yellow-900 rounded-sm px-0.5">{text.slice(idx, idx + query.length)}</mark>
      {text.slice(idx + query.length)}
    </>
  )
}

// ---------- componentes ----------

function FieldTable({ fields, filter }: { fields: FieldRow[]; filter: string }) {
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full border-collapse text-sm">
        <thead>
          <tr className="bg-gray-700 text-white text-xs">
            <th className="border border-gray-600 px-3 py-2 text-center font-semibold w-10">Nº</th>
            <th className="border border-gray-600 px-3 py-2 text-left font-semibold">Campo</th>
            <th className="border border-gray-600 px-3 py-2 text-left font-semibold">Descrição / Significado</th>
            <th className="border border-gray-600 px-3 py-2 text-center font-semibold w-20">Pos. Ini.</th>
            <th className="border border-gray-600 px-3 py-2 text-center font-semibold w-20">Pos. Fin.</th>
            <th className="border border-gray-600 px-3 py-2 text-center font-semibold w-16">Tam.</th>
            <th className="border border-gray-600 px-3 py-2 text-center font-semibold w-24">Tipo</th>
            <th className="border border-gray-600 px-3 py-2 text-left font-semibold">Conteúdo / Observação</th>
          </tr>
        </thead>
        <tbody>
          {fields.length === 0 ? (
            <tr>
              <td colSpan={8} className="border border-gray-200 px-4 py-8 text-center text-sm text-gray-400">
                Nenhum campo encontrado para &ldquo;{filter}&rdquo;
              </td>
            </tr>
          ) : (
            fields.map((field, i) => (
              <tr
                key={field.name + field.startPosition}
                className={[
                  'transition-colors',
                  field.isFiller
                    ? 'bg-gray-50 text-gray-400'
                    : i % 2 === 0 ? 'bg-white' : 'bg-gray-50/60',
                  'hover:bg-blue-50/40',
                ].join(' ')}
              >
                <td className="border border-gray-200 px-3 py-2 text-center text-gray-400 tabular-nums">
                  {field.seq}
                </td>
                <td className="border border-gray-200 px-3 py-2 font-mono text-xs font-medium text-gray-700">
                  {highlight(field.name, filter)}
                </td>
                <td className="border border-gray-200 px-3 py-2 text-gray-800">
                  {highlight(field.label, filter)}
                </td>
                <td className="border border-gray-200 px-3 py-2 text-center tabular-nums text-gray-600">
                  {field.startPosition}
                </td>
                <td className="border border-gray-200 px-3 py-2 text-center tabular-nums text-gray-600">
                  {field.endPosition}
                </td>
                <td className="border border-gray-200 px-3 py-2 text-center tabular-nums font-medium text-gray-700">
                  {field.length}
                </td>
                <td className="border border-gray-200 px-3 py-2 text-center">
                  <span className={[
                    'inline-block rounded px-1.5 py-0.5 text-xs font-medium',
                    field.dataType === 'MONETARY' ? 'bg-green-50 text-green-700' :
                    field.dataType === 'DATE'     ? 'bg-purple-50 text-purple-700' :
                    field.dataType === 'NUM'      ? 'bg-orange-50 text-orange-700' :
                    field.dataType === 'ALPHA'    ? 'bg-blue-50 text-blue-700' :
                    'bg-gray-100 text-gray-600',
                  ].join(' ')}>
                    {DATA_TYPE_LABEL[field.dataType] ?? field.dataType}
                  </span>
                </td>
                <td className="border border-gray-200 px-3 py-2 text-xs text-gray-500">
                  {highlight(fieldContent(field), filter)}
                </td>
              </tr>
            ))
          )}
        </tbody>
        <tfoot>
          <tr className="bg-gray-100">
            <td colSpan={5} className="border border-gray-200 px-3 py-2 text-right text-xs font-medium text-gray-500">
              Total de posições
            </td>
            <td className="border border-gray-200 px-3 py-2 text-center text-xs font-bold text-gray-700">
              {fields.reduce((s, f) => s + f.length, 0)}
            </td>
            <td colSpan={2} className="border border-gray-200 px-3 py-2 text-xs text-gray-400">
              {fields.length} campo{fields.length !== 1 ? 's' : ''}
            </td>
          </tr>
        </tfoot>
      </table>
    </div>
  )
}

// ---------- página ----------

export default function LayoutsPage() {
  const [layouts, setLayouts]       = useState<LayoutSummary[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [detail, setDetail]         = useState<LayoutDetail | null>(null)
  const [activeRt, setActiveRt]     = useState<string | null>(null)
  const [loading, setLoading]       = useState(false)
  const [error, setError]           = useState<string | null>(null)
  const [fieldFilter, setFieldFilter] = useState('')

  // Limpa filtro ao trocar de layout ou tipo de registro
  useEffect(() => { setFieldFilter('') }, [selectedId, activeRt])

  // Carrega lista de layouts
  useEffect(() => {
    fetch('/api/layouts')
      .then(r => r.json())
      .then((data: LayoutSummary[]) => {
        setLayouts(data)
        if (data.length > 0) setSelectedId(data[0].id)
      })
      .catch(() => setError('Erro ao carregar layouts.'))
  }, [])

  // Carrega detalhe quando seleciona um layout
  useEffect(() => {
    if (!selectedId) return
    setLoading(true)
    setDetail(null)
    setActiveRt(null)
    fetch(`/api/layouts/${selectedId}`)
      .then(r => r.json())
      .then((data: LayoutDetail) => {
        setDetail(data)
        if (data.recordTypes.length > 0) setActiveRt(data.recordTypes[0].id)
      })
      .catch(() => setError('Erro ao carregar detalhes do layout.'))
      .finally(() => setLoading(false))
  }, [selectedId])

  const currentRt = detail?.recordTypes.find(rt => rt.id === activeRt) ?? null

  const filteredFields = useMemo(() => {
    if (!currentRt) return []
    const q = fieldFilter.trim().toLowerCase()
    if (!q) return currentRt.fields
    return currentRt.fields.filter(f =>
      f.name.toLowerCase().includes(q) ||
      f.label.toLowerCase().includes(q) ||
      (f.description ?? '').toLowerCase().includes(q) ||
      String(f.startPosition).includes(q) ||
      String(f.endPosition).includes(q)
    )
  }, [currentRt, fieldFilter])

  // Agrupa layouts por banco
  const byBank = layouts.reduce<Record<string, { bankName: string; layouts: LayoutSummary[] }>>(
    (acc, l) => {
      if (!acc[l.bankCode]) acc[l.bankCode] = { bankName: l.bankName, layouts: [] }
      acc[l.bankCode].layouts.push(l)
      return acc
    },
    {},
  )

  return (
    <div className="space-y-6">
      {/* Título */}
      <div>
        <h2 className="text-xl font-semibold text-gray-800">Layouts CNAB</h2>
        <p className="mt-1 text-sm text-gray-500">
          Consulte a estrutura de campos de cada layout conforme o manual bancário.
        </p>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="flex gap-6 items-start">

        {/* Sidebar de seleção */}
        <aside className="w-64 shrink-0 rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden">
          <div className="bg-gray-50 border-b border-gray-200 px-4 py-3">
            <p className="text-xs font-semibold uppercase tracking-widest text-gray-400">Layouts</p>
          </div>
          <nav className="divide-y divide-gray-100">
            {Object.entries(byBank).map(([code, { bankName, layouts: bLayouts }]) => (
              <div key={code}>
                <div className="px-4 py-2 bg-gray-50/60">
                  <p className="text-xs font-semibold text-gray-500">{bankName}</p>
                </div>
                {bLayouts.map(l => (
                  <button
                    key={l.id}
                    onClick={() => setSelectedId(l.id)}
                    className={[
                      'w-full text-left px-4 py-3 text-sm transition-colors',
                      selectedId === l.id
                        ? 'bg-blue-600 text-white'
                        : 'text-gray-700 hover:bg-gray-50',
                    ].join(' ')}
                  >
                    <p className="font-medium leading-tight">{l.name}</p>
                    <p className={[
                      'text-xs mt-0.5',
                      selectedId === l.id ? 'text-blue-200' : 'text-gray-400',
                    ].join(' ')}>
                      {l.format} · {l.lineLength} pos. · v{l.version}
                    </p>
                  </button>
                ))}
              </div>
            ))}
          </nav>
        </aside>

        {/* Conteúdo principal */}
        <div className="flex-1 min-w-0 space-y-4">

          {loading && (
            <div className="flex items-center gap-3 py-16 justify-center text-sm text-gray-400">
              <span className="h-4 w-4 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
              Carregando layout...
            </div>
          )}

          {detail && (
            <>
              {/* Cabeçalho do layout */}
              <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">{detail.name}</h3>
                    <p className="text-sm text-gray-500 mt-0.5">
                      Banco {detail.bank.code} — {detail.bank.name}
                    </p>
                  </div>
                  <div className="flex flex-wrap gap-2 text-xs">
                    <span className="rounded-full border bg-gray-50 px-2.5 py-1 text-gray-600">
                      Versão {detail.version}
                    </span>
                    <span className="rounded-full border bg-gray-50 px-2.5 py-1 text-gray-600">
                      {detail.lineLength} posições por linha
                    </span>
                    <span className="rounded-full border bg-gray-50 px-2.5 py-1 text-gray-600">
                      Encoding: {detail.encoding}
                    </span>
                  </div>
                </div>
              </div>

              {/* Abas de tipos de registro */}
              <div className="flex flex-wrap gap-2">
                {detail.recordTypes.map(rt => (
                  <button
                    key={rt.id}
                    onClick={() => setActiveRt(rt.id)}
                    className={[
                      'rounded-lg border px-4 py-2 text-sm font-medium transition-colors',
                      activeRt === rt.id
                        ? 'bg-gray-800 text-white border-gray-800'
                        : 'bg-white text-gray-600 border-gray-200 hover:border-gray-400 hover:text-gray-800',
                    ].join(' ')}
                  >
                    <span className={[
                      'mr-2 inline-block rounded px-1.5 py-0.5 text-xs',
                      CATEGORY_COLOR[rt.category] ?? 'bg-gray-100 text-gray-600',
                    ].join(' ')}>
                      {CATEGORY_LABEL[rt.category] ?? rt.category}
                    </span>
                    {rt.description}
                  </button>
                ))}
              </div>

              {/* Tabela de campos */}
              {currentRt && (
                <div className="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden">
                  {/* Cabeçalho do tipo de registro */}
                  <div className="border-b border-gray-200 bg-gray-50 px-5 py-3 space-y-2">
                    <div className="flex items-center justify-between">
                      <div>
                        <span className={[
                          'rounded border px-2 py-0.5 text-xs font-medium mr-2',
                          CATEGORY_COLOR[currentRt.category] ?? 'bg-gray-100 text-gray-600 border-gray-200',
                        ].join(' ')}>
                          {CATEGORY_LABEL[currentRt.category] ?? currentRt.category}
                        </span>
                        <span className="text-sm font-semibold text-gray-800">{currentRt.description}</span>
                        <span className="ml-2 text-xs text-gray-400">
                          — identificado pela posição {currentRt.identifier.start} = &ldquo;{currentRt.identifier.value}&rdquo;
                        </span>
                      </div>
                      <span className="text-xs text-gray-400">
                        {fieldFilter
                          ? `${filteredFields.length} de ${currentRt.fields.length} campos`
                          : `${currentRt.fields.length} campos`}
                      </span>
                    </div>

                    {/* Barra de busca */}
                    <div className="relative">
                      <svg
                        className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400"
                        fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}
                      >
                        <path strokeLinecap="round" strokeLinejoin="round"
                          d="M21 21l-4.35-4.35M17 11A6 6 0 1 1 5 11a6 6 0 0 1 12 0z" />
                      </svg>
                      <input
                        type="text"
                        value={fieldFilter}
                        onChange={e => setFieldFilter(e.target.value)}
                        placeholder="Buscar campo por nome, descrição ou posição..."
                        className="w-full rounded-lg border border-gray-200 bg-white py-2 pl-9 pr-9 text-sm text-gray-800 placeholder-gray-400 focus:border-blue-400 focus:outline-none focus:ring-1 focus:ring-blue-300"
                      />
                      {fieldFilter && (
                        <button
                          onClick={() => setFieldFilter('')}
                          className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                          aria-label="Limpar filtro"
                        >
                          ×
                        </button>
                      )}
                    </div>
                  </div>

                  <FieldTable fields={filteredFields} filter={fieldFilter.trim()} />
                </div>
              )}
            </>
          )}

          {!loading && !detail && !error && (
            <div className="py-16 text-center text-sm text-gray-400">
              Selecione um layout na barra lateral para visualizar.
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
