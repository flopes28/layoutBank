'use client'

import { useState, useCallback } from 'react'
import type { ParseResult, ApiError } from '@layoutbank/shared-types'
import { DropZone }      from '@/components/upload/DropZone'
import { FileInfo }      from '@/components/upload/FileInfo'
import { FileSummary }   from '@/components/analysis/FileSummary'
import { ErrorSummary }  from '@/components/analysis/ErrorSummary'
import { RecordTable }   from '@/components/analysis/RecordTable'

type AppState =
  | { status: 'idle' }
  | { status: 'uploading'; fileName: string; fileSize: number }
  | { status: 'error'; message: string }
  | { status: 'analyzed'; result: ParseResult }

export default function AnalisarPage() {
  const [state, setState] = useState<AppState>({ status: 'idle' })

  const handleFile = useCallback(async (file: File) => {
    setState({ status: 'uploading', fileName: file.name, fileSize: file.size })

    try {
      const formData = new FormData()
      formData.append('file', file)

      const response = await fetch('/api/parse', {
        method: 'POST',
        body:   formData,
      })

      if (!response.ok) {
        const err: ApiError = await response.json()
        setState({ status: 'error', message: err.message })
        return
      }

      const result: ParseResult = await response.json()
      setState({ status: 'analyzed', result })
    } catch (err) {
      setState({
        status:  'error',
        message: err instanceof Error ? err.message : 'Erro inesperado ao processar o arquivo.',
      })
    }
  }, [])

  const reset = () => setState({ status: 'idle' })

  return (
    <div className="space-y-6">

      {(state.status === 'idle' || state.status === 'error') && (
        <div className="mx-auto max-w-2xl">
          <h2 className="mb-4 text-xl font-semibold text-gray-800">
            Analisar Arquivo de Remessa
          </h2>
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

      {state.status === 'analyzed' && (
        <div className="space-y-5">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold text-gray-800">Resultado da Análise</h2>
            <button
              onClick={reset}
              className="rounded-lg border bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 transition-colors"
            >
              Novo Upload
            </button>
          </div>

          <FileSummary
            fileInfo={state.result.fileInfo}
            summary={state.result.summary}
            layoutName={state.result.layoutName}
            bankName={state.result.bankName}
          />
          <ErrorSummary crossRecordErrors={state.result.crossRecordErrors} />
          <RecordTable records={state.result.records} />
        </div>
      )}
    </div>
  )
}
