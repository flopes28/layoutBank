import { NextRequest, NextResponse } from 'next/server'
import { CnabEngine } from '@layoutbank/cnab-engine'
import { DatabaseLayoutProvider } from '@/lib/DatabaseLayoutProvider'
import type { ApiError } from '@layoutbank/shared-types'

const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE_MB ?? '10') * 1024 * 1024

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData()
    const file = formData.get('file') as File | null
    const layoutId = formData.get('layoutId') as string | undefined

    if (!file) {
      return NextResponse.json<ApiError>(
        { error: 'MISSING_FILE', message: 'Nenhum arquivo enviado' },
        { status: 400 }
      )
    }

    if (file.size > MAX_FILE_SIZE) {
      return NextResponse.json<ApiError>(
        { error: 'FILE_TOO_LARGE', message: `Arquivo excede o limite de ${process.env.MAX_FILE_SIZE_MB ?? 10} MB` },
        { status: 413 }
      )
    }

    const buffer = Buffer.from(await file.arrayBuffer())

    const provider = new DatabaseLayoutProvider()
    const engine   = new CnabEngine(provider)

    const result = await engine.parse(buffer, { layoutId })

    // Injeta o nome do arquivo no resultado (engine não tem acesso ao nome)
    result.fileInfo.name = file.name

    return NextResponse.json(result)
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno ao processar arquivo'

    if (message.includes('Nenhum layout identificado')) {
      return NextResponse.json<ApiError>(
        { error: 'LAYOUT_NOT_FOUND', message },
        { status: 422 }
      )
    }

    if (message.includes('vazio')) {
      return NextResponse.json<ApiError>(
        { error: 'INVALID_FILE', message },
        { status: 400 }
      )
    }

    console.error('[/api/parse] Erro:', err)
    return NextResponse.json<ApiError>(
      { error: 'INTERNAL_ERROR', message },
      { status: 500 }
    )
  }
}
