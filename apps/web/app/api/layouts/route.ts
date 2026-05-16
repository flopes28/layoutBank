import { NextRequest, NextResponse } from 'next/server'
import { findAllLayouts } from '@layoutbank/database'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl
    const bankCode = searchParams.get('bankCode') ?? undefined
    const format   = searchParams.get('format') ?? undefined

    const layouts = await findAllLayouts({ bankCode, format })

    const dto = layouts.map((l) => ({
      id:         l.id,
      bankId:     l.bankId,
      bankCode:   (l as any).bank.code,
      bankName:   (l as any).bank.name,
      format:     l.format,
      version:    l.version,
      name:       l.name,
      lineLength: l.lineLength,
      encoding:   l.encoding,
      isActive:   l.isActive,
    }))

    return NextResponse.json(dto)
  } catch (err) {
    console.error('[/api/layouts] Erro:', err)
    return NextResponse.json({ error: 'INTERNAL_ERROR', message: 'Erro ao buscar layouts' }, { status: 500 })
  }
}
