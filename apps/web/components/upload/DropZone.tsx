'use client'

import { useRef, useState, useCallback } from 'react'
import { cn } from '@/lib/cn'

interface Props {
  onFile: (file: File) => void
  disabled?: boolean
}

const ACCEPTED = '.txt,.rem,.ret,.cnab'
const MAX_MB   = parseInt(process.env.NEXT_PUBLIC_MAX_FILE_SIZE_MB ?? '10')

export function DropZone({ onFile, disabled }: Props) {
  const inputRef  = useRef<HTMLInputElement>(null)
  const [isDragging, setIsDragging] = useState(false)
  const [sizeError, setSizeError]   = useState<string | null>(null)

  const handleFile = useCallback((file: File) => {
    setSizeError(null)
    if (file.size > MAX_MB * 1024 * 1024) {
      setSizeError(`Arquivo excede o limite de ${MAX_MB} MB.`)
      return
    }
    onFile(file)
  }, [onFile])

  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    if (!disabled) setIsDragging(true)
  }
  const onDragLeave = () => setIsDragging(false)
  const onDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    if (disabled) return
    const file = e.dataTransfer.files[0]
    if (file) handleFile(file)
  }
  const onInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) handleFile(file)
    e.target.value = ''
  }

  return (
    <div className="space-y-2">
      <div
        onDragOver={onDragOver}
        onDragLeave={onDragLeave}
        onDrop={onDrop}
        onClick={() => !disabled && inputRef.current?.click()}
        className={cn(
          'relative flex flex-col items-center justify-center rounded-xl border-2 border-dashed px-8 py-16 text-center transition-all',
          disabled
            ? 'cursor-not-allowed border-gray-200 bg-gray-50 opacity-60'
            : isDragging
            ? 'cursor-copy border-blue-400 bg-blue-50'
            : 'cursor-pointer border-gray-300 bg-white hover:border-blue-400 hover:bg-blue-50'
        )}
      >
        <div className="mb-4 text-5xl">{isDragging ? '📂' : '📁'}</div>
        <p className="text-base font-semibold text-gray-700">
          {isDragging ? 'Solte o arquivo aqui' : 'Arraste um arquivo CNAB'}
        </p>
        <p className="mt-1 text-sm text-gray-500">
          ou <span className="text-blue-600 underline underline-offset-2">clique para selecionar</span>
        </p>
        <p className="mt-3 text-xs text-gray-400">
          Formatos aceitos: .txt, .rem, .ret, .cnab &nbsp;·&nbsp; Máx. {MAX_MB} MB
        </p>
      </div>

      {sizeError && (
        <p className="text-sm text-red-600">{sizeError}</p>
      )}

      <input
        ref={inputRef}
        type="file"
        accept={ACCEPTED}
        onChange={onInputChange}
        className="sr-only"
        disabled={disabled}
      />
    </div>
  )
}
