import { readFileSync, readdirSync } from 'fs'
import { join } from 'path'
import { Pool } from 'pg'

async function main() {
  const connectionString = process.env.DATABASE_URL ?? 'postgresql://postgres:password@localhost:5432/layoutbank'
  const pool = new Pool({ connectionString })
  const client = await pool.connect()

  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS _migrations (
        name TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `)

    const { rows: applied } = await client.query<{ name: string }>('SELECT name FROM _migrations')
    const appliedSet = new Set(applied.map((r) => r.name))

    const migrationsDir = join(__dirname, '..', 'migrations')
    const files = readdirSync(migrationsDir)
      .filter((f) => f.endsWith('.sql'))
      .sort()

    console.log(`Encontradas ${files.length} migrations em ${migrationsDir}\n`)

    for (const file of files) {
      if (appliedSet.has(file)) {
        console.log(`⏭ Pulando (já aplicada): ${file}`)
        continue
      }
      console.log(`▶ Executando: ${file}`)
      const sql = readFileSync(join(migrationsDir, file), 'utf-8')
      await client.query(sql)
      await client.query('INSERT INTO _migrations (name) VALUES ($1)', [file])
      console.log(`✓ Concluída: ${file}\n`)
    }

    console.log('Todas as migrations executadas com sucesso.')
  } catch (err) {
    console.error('Erro ao executar migrations:', err)
    process.exit(1)
  } finally {
    client.release()
    await pool.end()
  }
}

main()
