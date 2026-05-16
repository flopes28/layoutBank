const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
const DATE_FMT = new Intl.DateTimeFormat('pt-BR')

export function formatCurrency(value: number): string {
  return BRL.format(value)
}

export function formatDate(date: Date): string {
  return DATE_FMT.format(date)
}

export function formatFileSize(bytes: number): string {
  if (bytes < 1024)       return `${bytes} B`
  if (bytes < 1024 ** 2)  return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1024 ** 2).toFixed(2)} MB`
}

export function formatParsedValue(value: string | number | Date | null, dataType: string): string {
  if (value === null || value === undefined) return '—'
  if (value instanceof Date) return formatDate(value)
  if (dataType === 'MONETARY' && typeof value === 'number') return formatCurrency(value)
  return String(value)
}
