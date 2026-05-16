export interface RawLine {
  lineNumber: number  // 1-based
  content: string     // conteúdo sem \r\n
}

/**
 * Converte um Buffer de arquivo CNAB em array de linhas brutas.
 * Trata \r\n (Windows) e \n (Unix). Ignora linhas completamente vazias
 * no final do arquivo (artifact comum de editores).
 */
export function readLines(buffer: Buffer, encoding: BufferEncoding = 'latin1'): RawLine[] {
  const text = buffer.toString(encoding)
  const rawLines = text.split('\n')
  const result: RawLine[] = []

  for (let i = 0; i < rawLines.length; i++) {
    const content = rawLines[i].replace(/\r$/, '') // remove \r de CRLF
    // Ignora linhas vazias apenas no final do arquivo
    if (content === '' && i === rawLines.length - 1) continue
    result.push({ lineNumber: i + 1, content })
  }

  return result
}

/**
 * Detecta o comprimento de linha predominante no arquivo.
 * Usa as primeiras 5 linhas não-vazias para ser robusto.
 */
export function detectLineLength(lines: RawLine[]): number {
  const sample = lines.slice(0, 5).filter((l) => l.content.length > 0)
  if (sample.length === 0) return 0

  // Assume o comprimento mais frequente nas primeiras linhas
  const counts: Record<number, number> = {}
  for (const line of sample) {
    counts[line.content.length] = (counts[line.content.length] ?? 0) + 1
  }
  return parseInt(
    Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0]
  )
}

/**
 * Extrai o código do banco da primeira linha.
 * CNAB 240: posições 1-3. CNAB 400: posições 77-79.
 */
export function extractBankCode(firstLine: string): string {
  if (firstLine.length === 400) return firstLine.substring(76, 79).trim()
  return firstLine.substring(0, 3).trim()
}
