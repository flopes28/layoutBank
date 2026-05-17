'use client'

import { useState, useCallback } from 'react'
import type { ParseResult, ApiError } from '@layoutbank/shared-types'
import { DropZone }       from '@/components/upload/DropZone'
import { FileInfo }       from '@/components/upload/FileInfo'
import { RetornoEditor }  from '@/components/retorno/RetornoEditor'
import type { BoletoRow } from '@/components/retorno/RetornoEditor'
import { buildBoletoRowBradesco, toDateDDMMYY, parseCurrency } from '@/lib/retornoGeneratorBradesco'

type PageState =
  | { status: 'idle' }
  | { status: 'uploading'; fileName: string; fileSize: number }
  | { status: 'error'; message: string }
  | { status: 'editing' | 'generating'; result: ParseResult; rows: BoletoRow[]; headerRaw: string }

export default function SimularRetornoBradescoPage() {
  const [state, setState] = useState<PageState>({ status: 'idle' })

  const handleFile = useCallback(async (file: File) => {
    setState({ status: 'uploading', fileName: file.name, fileSize: file.size })

    try {
      const formData = new FormData()
      formData.append('file', file)

      const response = await fetch('/api/parse', { method: 'POST', body: formData })

      if (!response.ok) {
        const err: ApiError = await response.json()
        setState({ status: 'error', message: err.message })
        return
      }

      const result: ParseResult = await response.json()

      const headerRecord = result.records.find(r => r.recordTypeCode === 'HEADER')
      const detalhes = result.records.filter(r => r.recordTypeCode === 'DETALHE_BOLETO')

      if (!headerRecord) {
        setState({ status: 'error', message: 'Header não encontrado no arquivo.' })
        return
      }

      if (detalhes.length === 0) {
        setState({ status: 'error', message: 'Nenhum registro de detalhe (boleto) encontrado.' })
        return
      }

      const rows = detalhes.map(buildBoletoRowBradesco)

      setState({ status: 'editing', result, rows, headerRaw: headerRecord.rawContent })
    } catch (err) {
      setState({
        status:  'error',
        message: err instanceof Error ? err.message : 'Erro inesperado.',
      })
    }
  }, [])

  const handleGerarRetorno = useCallback(async () => {
    if (state.status !== 'editing') return
    setState(prev => ({ ...prev, status: 'generating' } as PageState))

    try {
      const body = {
        headerRaw: state.headerRaw,
        detalhes:  state.rows.map(row => ({
          rawLine: row.rawLine,
          edit: {
            ocorrencia:       row.ocorrencia.padStart(2, '0'),
            dtOcorrencia:     toDateDDMMYY(row.dtOcorrencia),
            vlPrincipalCents: parseCurrency(row.vlPrincipal),
            dtCredito:        toDateDDMMYY(row.dtCredito),
          },
        })),
      }

      const response = await fetch('/api/gerar-retorno-bradesco', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(body),
      })

      if (!response.ok) {
        const err = await response.json()
        setState(prev => ({ ...(prev as any), status: 'editing' }))
        alert(`Erro ao gerar retorno: ${err.message}`)
        return
      }

      const blob = await response.blob()
      const cd = response.headers.get('Content-Disposition') ?? ''
      const match = cd.match(/filename="([^"]+)"/)
      const fileName = match?.[1] ?? 'retorno_bradesco.ret'

      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = fileName
      a.click()
      URL.revokeObjectURL(url)

      setState(prev => ({ ...prev, status: 'editing' } as PageState))
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Erro ao gerar retorno.')
      setState(prev => ({ ...prev, status: 'editing' } as PageState))
    }
  }, [state])

  const reset = () => setState({ status: 'idle' })

  return (
    <div className="space-y-6">

      <div>
        <h2 className="text-xl font-semibold text-gray-800">Simular Retorno Bradesco CNAB 400</h2>
        <p className="mt-1 text-sm text-gray-500">
          Suba um arquivo de remessa Bradesco, edite os campos do retorno e baixe o arquivo <code>.ret</code> simulado.
        </p>
      </div>

      {(state.status === 'idle' || state.status === 'error') && (
        <div className="mx-auto max-w-2xl">
          <DropZone onFile={handleFile} disabled={false} />
          {state.status === 'error' && (
            <div className="mt-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
              <strong>Erro:</strong> {state.message}
            </div>
          )}
        </div>
      )}

      {state.status === 'uploading' && (
        <div className="mx-auto max-w-2xl">
          <FileInfo name={state.fileName} sizeBytes={state.fileSize} totalLines={0} />
          <div className="mt-4 flex items-center gap-3 text-sm text-gray-500">
            <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-blue-600 border-t-transparent" />
            Processando arquivo...
          </div>
        </div>
      )}

      {(state.status === 'editing' || state.status === 'generating') && (
        <div className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-gray-700">
                {state.result.fileInfo.name} — {state.rows.length} boleto{state.rows.length !== 1 ? 's' : ''}
              </p>
              <p className="text-xs text-gray-400">{state.result.layoutName}</p>
            </div>
            <div className="flex gap-2">
              <button
                onClick={reset}
                className="rounded-lg border bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 transition-colors"
              >
                Novo arquivo
              </button>
              <button
                onClick={handleGerarRetorno}
                disabled={state.status === 'generating'}
                className="flex items-center gap-2 rounded-lg bg-red-600 px-5 py-2 text-sm font-medium text-white shadow-sm hover:bg-red-700 disabled:opacity-60 transition-colors"
              >
                {state.status === 'generating' ? (
                  <>
                    <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    Gerando...
                  </>
                ) : (
                  'Gerar e Baixar Retorno'
                )}
              </button>
            </div>
          </div>

          <RetornoEditor
            rows={state.rows}
            onChange={rows => setState(prev => ({ ...prev, rows } as any))}
          />
        </div>
      )}

    </div>
  )
}
