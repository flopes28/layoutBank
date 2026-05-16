import Link from 'next/link'
import { BankCard } from '@/components/home/BankCard'
import type { BankEntry } from '@/components/home/BankCard'

// ---------- dados dos módulos ----------

const ANALISAR_CARD = {
  title:       'Analisar Arquivo CNAB',
  description: 'Faça upload de qualquer arquivo CNAB 240 ou CNAB 400. Valide campos, identifique erros e inspecione cada registro. Funciona com qualquer banco cadastrado na plataforma.',
  href:        '/analisar',
  icon:        '🔍',
  badge:       'Todos os bancos',
}

const LAYOUTS_CARD = {
  title:       'Consultar Layouts',
  description: 'Visualize a estrutura completa de campos de cada layout CNAB cadastrado: nome, descrição, posição, tamanho e tipo de cada campo, no formato do manual bancário.',
  href:        '/layouts',
  icon:        '📋',
  badge:       'Referência',
}

const RETORNO_BANKS: BankEntry[] = [
  {
    name:      'Itaú Unibanco',
    code:      '341',
    formats:   ['CNAB 400 – Cobrança'],
    href:      '/simular-retorno',
    available: true,
    color:     '#EC7000',
  },
  {
    name:      'Bradesco',
    code:      '237',
    formats:   ['CNAB 400 – Cobrança'],
    href:      null,
    available: false,
    color:     '#CC092F',
  },
  {
    name:      'Banco do Brasil',
    code:      '001',
    formats:   ['CNAB 400', 'CNAB 240'],
    href:      null,
    available: false,
    color:     '#003882',
  },
  {
    name:      'Santander',
    code:      '033',
    formats:   ['CNAB 400 – Cobrança'],
    href:      null,
    available: false,
    color:     '#EC0000',
  },
  {
    name:      'Caixa Econômica Federal',
    code:      '104',
    formats:   ['CNAB 240'],
    href:      null,
    available: false,
    color:     '#005CA9',
  },
  {
    name:      'Sicoob',
    code:      '756',
    formats:   ['CNAB 400'],
    href:      null,
    available: false,
    color:     '#007A3D',
  },
]

// ---------- componentes ----------

function ToolCard({ card }: { card: typeof ANALISAR_CARD }) {
  return (
    <Link
      href={card.href}
      className="group flex flex-col rounded-2xl border border-gray-200 bg-white p-6 shadow-sm hover:border-blue-300 hover:shadow-md transition-all"
    >
      <div className="flex items-start justify-between">
        <span className="text-3xl">{card.icon}</span>
        <span className="rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-medium text-blue-700">
          {card.badge}
        </span>
      </div>
      <h3 className="mt-4 text-lg font-semibold text-gray-900 group-hover:text-blue-700 transition-colors">
        {card.title}
      </h3>
      <p className="mt-2 flex-1 text-sm text-gray-500 leading-relaxed">
        {card.description}
      </p>
      <div className="mt-5 flex items-center gap-1.5 text-sm font-medium text-blue-600 group-hover:gap-2.5 transition-all">
        Acessar
        <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
        </svg>
      </div>
    </Link>
  )
}

function AnalyzeCard() { return <ToolCard card={ANALISAR_CARD} /> }
function LayoutsCard() { return <ToolCard card={LAYOUTS_CARD} /> }

// ---------- página ----------

export default function HomePage() {
  return (
    <div className="space-y-12">

      {/* Hero */}
      <div className="text-center pt-4">
        <h2 className="text-2xl font-bold text-gray-900">
          O que você deseja fazer?
        </h2>
        <p className="mt-2 text-sm text-gray-500">
          Escolha uma das ferramentas abaixo para começar
        </p>
      </div>

      {/* Seção: Ferramentas */}
      <section>
        <div className="mb-4 flex items-center gap-3">
          <div className="h-px flex-1 bg-gray-200" />
          <h3 className="text-xs font-semibold uppercase tracking-widest text-gray-400">
            Ferramentas
          </h3>
          <div className="h-px flex-1 bg-gray-200" />
        </div>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 max-w-3xl mx-auto">
          <AnalyzeCard />
          <LayoutsCard />
        </div>
      </section>

      {/* Seção: Simular Retorno */}
      <section id="retorno">
        <div className="mb-4 flex items-center gap-3">
          <div className="h-px flex-1 bg-gray-200" />
          <h3 className="text-xs font-semibold uppercase tracking-widest text-gray-400">
            Simulação de Retorno
          </h3>
          <div className="h-px flex-1 bg-gray-200" />
        </div>
        <p className="mb-5 text-center text-sm text-gray-500">
          Selecione o banco para gerar um arquivo de retorno simulado
        </p>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
          {RETORNO_BANKS.map(bank => (
            <BankCard key={bank.code} bank={bank} />
          ))}
        </div>
      </section>

    </div>
  )
}
