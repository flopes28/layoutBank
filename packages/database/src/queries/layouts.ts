import { and, eq, inArray } from 'drizzle-orm'
import { db } from '../client'
import { banks, cnabLayouts, recordTypes, fieldDefinitions } from '../schema'
import type { CnabLayout, RecordType, FieldDef } from '../schema'

export interface LayoutWithRelations extends CnabLayout {
  bank: { code: string; name: string; shortName: string }
  recordTypes: Array<RecordType & { fieldDefinitions: FieldDef[] }>
}

export async function findAllLayouts(filters?: {
  bankCode?: string
  format?: string
  active?: boolean
}): Promise<Array<CnabLayout & { bank: { code: string; name: string } }>> {
  const conditions = [eq(cnabLayouts.isActive, filters?.active ?? true)]

  const rows = await db
    .select({
      layout: cnabLayouts,
      bank: { code: banks.code, name: banks.name, shortName: banks.shortName },
    })
    .from(cnabLayouts)
    .innerJoin(banks, eq(cnabLayouts.bankId, banks.id))
    .where(
      and(
        eq(cnabLayouts.isActive, filters?.active ?? true),
        filters?.bankCode ? eq(banks.code, filters.bankCode) : undefined,
        filters?.format ? eq(cnabLayouts.format, filters.format) : undefined
      )
    )
    .orderBy(banks.name, cnabLayouts.format)

  return rows.map((r) => ({ ...r.layout, bank: r.bank }))
}

export async function findLayoutById(id: string): Promise<LayoutWithRelations | null> {
  const [layout] = await db
    .select({
      layout: cnabLayouts,
      bank: { code: banks.code, name: banks.name, shortName: banks.shortName },
    })
    .from(cnabLayouts)
    .innerJoin(banks, eq(cnabLayouts.bankId, banks.id))
    .where(eq(cnabLayouts.id, id))
    .limit(1)

  if (!layout) return null

  const rTypes = await db
    .select()
    .from(recordTypes)
    .where(eq(recordTypes.layoutId, id))
    .orderBy(recordTypes.sortOrder)

  const rTypeIds = rTypes.map((rt) => rt.id)
  const fields =
    rTypeIds.length > 0
      ? await db
          .select()
          .from(fieldDefinitions)
          .where(
            rTypeIds.length === 1
              ? eq(fieldDefinitions.recordTypeId, rTypeIds[0])
              : inArray(fieldDefinitions.recordTypeId, rTypeIds)
          )
          .orderBy(fieldDefinitions.recordTypeId, fieldDefinitions.sortOrder)
      : []

  const fieldsByType = fields.reduce<Record<string, FieldDef[]>>((acc, f) => {
    ;(acc[f.recordTypeId] ??= []).push(f)
    return acc
  }, {})

  return {
    ...layout.layout,
    bank: layout.bank,
    recordTypes: rTypes.map((rt) => ({
      ...rt,
      fieldDefinitions: fieldsByType[rt.id] ?? [],
    })),
  }
}

export async function findLayoutByBankAndFormat(
  bankCode: string,
  lineLength: number
): Promise<LayoutWithRelations | null> {
  const format = lineLength === 240 ? 'CNAB240' : 'CNAB400'

  const [row] = await db
    .select({ layout: cnabLayouts, bank: { code: banks.code, name: banks.name, shortName: banks.shortName } })
    .from(cnabLayouts)
    .innerJoin(banks, eq(cnabLayouts.bankId, banks.id))
    .where(
      and(
        eq(banks.code, bankCode),
        eq(cnabLayouts.format, format),
        eq(cnabLayouts.isActive, true)
      )
    )
    .orderBy(cnabLayouts.version)
    .limit(1)

  if (!row) return null
  return findLayoutById(row.layout.id)
}

/**
 * Localiza um layout ativo pelo código do banco e pelo nome exato do formato.
 *
 * Diferente de findLayoutByBankAndFormat (que infere o formato pelo comprimento
 * da linha), esta função aceita o nome de formato explicitamente, incluindo os
 * formatos distintos CNAB400_REMESSA e CNAB400_RETORNO.
 *
 * @param bankCode  Código COMPE do banco (ex.: '341')
 * @param formatName Nome exato do formato (ex.: 'CNAB400_REMESSA', 'CNAB400_RETORNO', 'CNAB240')
 */
export async function findLayoutByBankAndFormatName(
  bankCode: string,
  formatName: string
): Promise<LayoutWithRelations | null> {
  const [row] = await db
    .select({ layout: cnabLayouts, bank: { code: banks.code, name: banks.name, shortName: banks.shortName } })
    .from(cnabLayouts)
    .innerJoin(banks, eq(cnabLayouts.bankId, banks.id))
    .where(
      and(
        eq(banks.code, bankCode),
        eq(cnabLayouts.format, formatName),
        eq(cnabLayouts.isActive, true)
      )
    )
    .orderBy(cnabLayouts.version)
    .limit(1)

  if (!row) return null
  return findLayoutById(row.layout.id)
}
