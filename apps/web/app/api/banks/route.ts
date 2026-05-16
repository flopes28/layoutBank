import { NextResponse } from 'next/server'
import { findAllBanks } from '@layoutbank/database'

export async function GET() {
  try {
    const banks = await findAllBanks()
    return NextResponse.json(banks)
  } catch (err) {
    console.error('[/api/banks] Erro:', err)
    return NextResponse.json({ error: 'INTERNAL_ERROR', message: 'Erro ao buscar bancos' }, { status: 500 })
  }
}
