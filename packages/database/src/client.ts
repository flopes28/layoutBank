import { drizzle } from 'drizzle-orm/node-postgres'
import { Pool } from 'pg'
import * as schema from './schema'

// Singleton do pool de conexões para evitar múltiplas conexões em hot-reload do Next.js
const globalForDb = global as unknown as { pool: Pool | undefined }

function createPool(): Pool {
  const connectionString = process.env.DATABASE_URL
  if (!connectionString) {
    throw new Error('DATABASE_URL não está definida. Verifique o arquivo .env')
  }
  return new Pool({
    connectionString,
    max: 10,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
  })
}

const pool = globalForDb.pool ?? createPool()

if (process.env.NODE_ENV !== 'production') {
  globalForDb.pool = pool
}

export const db = drizzle(pool, { schema })
export { pool }
export type Db = typeof db
