import { eq } from 'drizzle-orm'
import { db } from '../client'
import { banks } from '../schema'
import type { Bank } from '../schema'

export async function findAllBanks(): Promise<Bank[]> {
  return db.select().from(banks).where(eq(banks.isActive, true)).orderBy(banks.name)
}

export async function findBankByCode(code: string): Promise<Bank | undefined> {
  const [bank] = await db.select().from(banks).where(eq(banks.code, code)).limit(1)
  return bank
}

export async function findBankById(id: string): Promise<Bank | undefined> {
  const [bank] = await db.select().from(banks).where(eq(banks.id, id)).limit(1)
  return bank
}
