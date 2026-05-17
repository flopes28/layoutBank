import { NextRequest, NextResponse } from 'next/server'
import { generateRetornoFileBradesco } from '@/lib/retornoGeneratorBradesco'
import type { DetalheInput } from '@/lib/retornoGeneratorBradesco'

export interface GerarRetornoBradescoRequest {
  headerRaw: string
  detalhes: DetalheInput[]
}

export async function POST(request: NextRequest) {
  try {
    const body: GerarRetornoBradescoRequest = await request.json()

    if (!body.headerRaw || !Array.isArray(body.detalhes)) {
      return NextResponse.json({ error: 'INVALID_BODY', message: 'headerRaw e detalhes são obrigatórios' }, { status: 400 })
    }

    if (body.headerRaw.length !== 400) {
      return NextResponse.json({ error: 'INVALID_HEADER', message: 'Header deve ter 400 caracteres' }, { status: 400 })
    }

    const buffer = generateRetornoFileBradesco(body.headerRaw, body.detalhes)

    const today = new Date()
    const dd = String(today.getDate()).padStart(2, '0')
    const mm = String(today.getMonth() + 1).padStart(2, '0')
    const yyyy = today.getFullYear()
    const fileName = `retorno_bradesco_${dd}${mm}${yyyy}.ret`

    return new NextResponse(new Uint8Array(buffer), {
      status: 200,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': `attachment; filename="${fileName}"`,
        'Content-Length': String(buffer.length),
      },
    })
  } catch (err) {
    console.error('[/api/gerar-retorno-bradesco]', err)
    return NextResponse.json(
      { error: 'INTERNAL_ERROR', message: err instanceof Error ? err.message : 'Erro interno' },
      { status: 500 },
    )
  }
}
