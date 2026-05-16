import { NextRequest, NextResponse } from 'next/server'
import { generateRetornoFile } from '@/lib/retornoGenerator'
import type { DetalheInput } from '@/lib/retornoGenerator'

export interface GerarRetornoRequest {
  headerRaw: string
  detalhes: DetalheInput[]
}

export async function POST(request: NextRequest) {
  try {
    const body: GerarRetornoRequest = await request.json()

    if (!body.headerRaw || !Array.isArray(body.detalhes)) {
      return NextResponse.json({ error: 'INVALID_BODY', message: 'headerRaw e detalhes são obrigatórios' }, { status: 400 })
    }

    if (body.headerRaw.length !== 400) {
      return NextResponse.json({ error: 'INVALID_HEADER', message: 'Header deve ter 400 caracteres' }, { status: 400 })
    }

    const buffer = generateRetornoFile(body.headerRaw, body.detalhes)

    const today = new Date()
    const dd = String(today.getDate()).padStart(2, '0')
    const mm = String(today.getMonth() + 1).padStart(2, '0')
    const yyyy = today.getFullYear()
    const fileName = `retorno_${dd}${mm}${yyyy}.ret`

    return new NextResponse(new Uint8Array(buffer), {
      status: 200,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': `attachment; filename="${fileName}"`,
        'Content-Length': String(buffer.length),
      },
    })
  } catch (err) {
    console.error('[/api/gerar-retorno]', err)
    return NextResponse.json(
      { error: 'INTERNAL_ERROR', message: err instanceof Error ? err.message : 'Erro interno' },
      { status: 500 },
    )
  }
}
