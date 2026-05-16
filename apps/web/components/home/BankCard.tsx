import Link from 'next/link'

export interface BankEntry {
  name:      string
  code:      string
  formats:   string[]
  href:      string | null
  available: boolean
  color:     string
}

export function BankCard({ bank }: { bank: BankEntry }) {
  const inner = (
    <div
      className={[
        'flex flex-col rounded-xl border p-4 transition-all h-full',
        bank.available
          ? 'border-gray-200 bg-white shadow-sm hover:border-blue-300 hover:shadow-md cursor-pointer group'
          : 'border-gray-100 bg-gray-50 opacity-60 cursor-not-allowed',
      ].join(' ')}
    >
      {/* Badge colorido + disponibilidade */}
      <div className="flex items-start justify-between gap-2">
        <div
          className="h-10 w-10 rounded-lg flex items-center justify-center text-white font-bold text-xs font-mono shrink-0"
          style={{ backgroundColor: bank.color }}
        >
          {bank.code}
        </div>
        {bank.available ? (
          <span className="rounded-full bg-green-50 px-2 py-0.5 text-xs font-medium text-green-700 whitespace-nowrap">
            Disponível
          </span>
        ) : (
          <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-400 whitespace-nowrap">
            Em breve
          </span>
        )}
      </div>

      {/* Nome */}
      <p className={[
        'mt-3 font-semibold text-sm leading-tight',
        bank.available
          ? 'text-gray-900 group-hover:text-blue-700 transition-colors'
          : 'text-gray-400',
      ].join(' ')}>
        {bank.name}
      </p>

      {/* Formatos */}
      <ul className="mt-1.5 flex-1 space-y-0.5">
        {bank.formats.map(f => (
          <li key={f} className="text-xs text-gray-400">{f}</li>
        ))}
      </ul>

      {/* CTA */}
      {bank.available && (
        <div className="mt-3 flex items-center gap-1 text-xs font-medium text-blue-600 group-hover:gap-2 transition-all">
          Simular retorno
          <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
          </svg>
        </div>
      )}
    </div>
  )

  if (!bank.available) return inner
  return <Link href={bank.href!} className="h-full block">{inner}</Link>
}
