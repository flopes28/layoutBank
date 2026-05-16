import { NextRequest, NextResponse } from 'next/server'
import { findLayoutById } from '@layoutbank/database'

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params
    const layout = await findLayoutById(id)

    if (!layout) {
      return NextResponse.json({ error: 'NOT_FOUND', message: 'Layout não encontrado' }, { status: 404 })
    }

    return NextResponse.json({
      id:          layout.id,
      name:        layout.name,
      format:      layout.format,
      version:     layout.version,
      lineLength:  layout.lineLength,
      encoding:    layout.encoding,
      bank: {
        code:      layout.bank.code,
        name:      layout.bank.name,
        shortName: layout.bank.shortName,
      },
      recordTypes: layout.recordTypes.map(rt => ({
        id:          rt.id,
        code:        rt.code,
        description: rt.description,
        category:    rt.category,
        sortOrder:   rt.sortOrder,
        identifier: {
          start: rt.identifierStart,
          end:   rt.identifierEnd,
          value: rt.identifierValue,
        },
        fields: rt.fieldDefinitions.map((fd, idx) => ({
          seq:           idx + 1,
          name:          fd.name,
          label:         fd.label,
          description:   fd.description,
          startPosition: fd.startPosition,
          endPosition:   fd.endPosition,
          length:        fd.length,
          dataType:      fd.dataType,
          formatMask:    fd.formatMask,
          decimalPlaces: fd.decimalPlaces,
          isRequired:    fd.isRequired,
          isFiller:      fd.isFiller,
          allowedValues: fd.allowedValues,
        })),
      })),
    })
  } catch (err) {
    console.error('[/api/layouts/[id]]', err)
    return NextResponse.json({ error: 'INTERNAL_ERROR', message: 'Erro ao buscar layout' }, { status: 500 })
  }
}
