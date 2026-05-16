import type { Metadata } from 'next'
import Link from 'next/link'
import './globals.css'

export const metadata: Metadata = {
  title: 'LayoutBank — Análise de Arquivos CNAB',
  description: 'Ferramenta profissional para parsing e validação de arquivos de remessa bancária CNAB 240 e CNAB 400',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body className="min-h-screen bg-gray-50 antialiased">
        <header className="border-b bg-white shadow-sm">
          <div className="mx-auto max-w-screen-2xl px-6 py-0 flex items-center justify-between">
            <div className="flex items-center gap-3 py-4">
              <div className="h-8 w-8 rounded-lg bg-blue-600 flex items-center justify-center">
                <span className="text-white font-bold text-sm">LB</span>
              </div>
              <div>
                <h1 className="text-lg font-semibold text-gray-900 leading-none">LayoutBank</h1>
                <p className="text-xs text-gray-500 leading-none mt-0.5">Análise de Arquivos CNAB</p>
              </div>
            </div>
            <nav className="flex items-center gap-1">
              <Link
                href="/analisar"
                className="px-4 py-5 text-sm font-medium text-gray-600 hover:text-blue-600 border-b-2 border-transparent hover:border-blue-600 transition-colors"
              >
                Analisar Arquivo
              </Link>
              <Link
                href="/#retorno"
                className="px-4 py-5 text-sm font-medium text-gray-600 hover:text-blue-600 border-b-2 border-transparent hover:border-blue-600 transition-colors"
              >
                Simular Retorno
              </Link>
              <Link
                href="/layouts"
                className="px-4 py-5 text-sm font-medium text-gray-600 hover:text-blue-600 border-b-2 border-transparent hover:border-blue-600 transition-colors"
              >
                Layouts
              </Link>
            </nav>
          </div>
        </header>
        <main className="mx-auto max-w-screen-2xl px-6 py-6">
          {children}
        </main>
      </body>
    </html>
  )
}
