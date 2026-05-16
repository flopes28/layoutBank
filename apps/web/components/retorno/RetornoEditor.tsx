'use client'

import { useState, useCallback } from 'react'
import { formatCnabDate, formatCnabMoney, toDateDDMMYY, parseCurrency } from '@/lib/retornoGenerator'

export interface BoletoRow {
  lineNumber: number
  nossoNumero: string   // raw 8 chars
  sacado: string        // NOME_SACADO raw
  vencimento: string    // DDMMAA raw
  vlBoleto: string      // monetary raw (13 chars)
  rawLine: string       // linha original completa
  // editáveis
  ocorrencia: string
  dtOcorrencia: string  // YYYY-MM-DD (input date)
  vlPrincipal: string   // ex: "1234.56"
  dtCredito: string     // YYYY-MM-DD (input date)
}

const OCORRENCIAS = [
  { code: '02', label: '02 – Entrada Confirmada' },
  { code: '03', label: '03 – Entrada Rejeitada' },
  { code: '06', label: '06 – Liquidação Normal' },
  { code: '07', label: '07 – Liquidação Parcial (B2B)' },
  { code: '08', label: '08 – Liquidação em Cartório' },
  { code: '09', label: '09 – Baixa Simples' },
  { code: '10', label: '10 – Baixa por Devolução' },
  { code: '11', label: '11 – Títulos em Cartório' },
  { code: '12', label: '12 – Abatimento Concedido' },
  { code: '13', label: '13 – Abatimento Cancelado' },
  { code: '14', label: '14 – Vencimento Alterado' },
  { code: '15', label: '15 – Liquidação em Cartório após Baixa' },
  { code: '16', label: '16 – Alteração de Dados' },
  { code: '17', label: '17 – Liquidação após Baixa / Título não Registrado' },
  { code: '18', label: '18 – Acerto de Depositária' },
  { code: '19', label: '19 – Confirmação de Instrução de Protesto' },
  { code: '20', label: '20 – Confirmação de Sustação de Protesto' },
  { code: '21', label: '21 – Acerto do Controle do Participante' },
  { code: '22', label: '22 – Título com Pagamento Cancelado' },
  { code: '23', label: '23 – Entrada do Título em Cartório' },
  { code: '24', label: '24 – Entrada Rejeitada por CEP Irregular' },
  { code: '25', label: '25 – Confirmação de Alteração de Outros Dados' },
  { code: '26', label: '26 – Débito de Tarifas/Custas' },
  { code: '27', label: '27 – Baixa Rejeitada' },
  { code: '28', label: '28 – Débito de Tarifas/Custas (mensagem)' },
  { code: '29', label: '29 – Ocorrência do Pagador' },
  { code: '30', label: '30 – Alteração de Outros Dados Rejeitada' },
  { code: '32', label: '32 – Instrução Rejeitada' },
  { code: '33', label: '33 – Confirmação de Pedido de Alteração de Outros Dados' },
  { code: '34', label: '34 – Retirada de Cartório e Manutenção em Carteira' },
  { code: '35', label: '35 – Desagendamento do Débito Automático' },
  { code: '36', label: '36 – Acerto de Dados de Rateio de Crédito' },
  { code: '37', label: '37 – Confirmação de Instrução de Negativação' },
  { code: '38', label: '38 – Confirmação de Instrução de Não Negativar' },
  { code: '39', label: '39 – Negativação Efetuada' },
  { code: '40', label: '40 – Complemento de Registro' },
  { code: '43', label: '43 – Requisição de Negativação' },
  { code: '44', label: '44 – Entrada em Negativação' },
  { code: '45', label: '45 – Saída de Negativação' },
]

interface Props {
  rows: BoletoRow[]
  onChange: (rows: BoletoRow[]) => void
}

export function RetornoEditor({ rows, onChange }: Props) {
  const [globalOcorrencia, setGlobalOcorrencia] = useState('06')
  const [globalDtOcorrencia, setGlobalDtOcorrencia] = useState('')
  const [globalDtCredito, setGlobalDtCredito] = useState('')

  const update = useCallback((idx: number, field: keyof BoletoRow, value: string) => {
    const next = rows.map((r, i) => (i === idx ? { ...r, [field]: value } : r))
    onChange(next)
  }, [rows, onChange])

  const applyGlobal = () => {
    const next = rows.map(r => ({
      ...r,
      ocorrencia:    globalOcorrencia,
      dtOcorrencia:  globalDtOcorrencia || r.dtOcorrencia,
      vlPrincipal:   r.vlPrincipal || (parseInt(r.vlBoleto) / 100).toFixed(2),
      dtCredito:     globalDtCredito || r.dtCredito,
    }))
    onChange(next)
  }

  return (
    <div className="space-y-4">
      {/* Painel de aplicação global */}
      <div className="rounded-lg border border-blue-200 bg-blue-50 p-4">
        <p className="mb-3 text-sm font-medium text-blue-800">Aplicar a todos os registros</p>
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <label className="block text-xs text-blue-700 mb-1">Ocorrência</label>
            <select
              value={globalOcorrencia}
              onChange={e => setGlobalOcorrencia(e.target.value)}
              className="rounded border border-blue-300 bg-white px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            >
              {OCORRENCIAS.map(o => (
                <option key={o.code} value={o.code}>{o.label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs text-blue-700 mb-1">Data de Ocorrência</label>
            <input
              type="date"
              value={globalDtOcorrencia}
              onChange={e => setGlobalDtOcorrencia(e.target.value)}
              className="rounded border border-blue-300 px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            />
          </div>
          <div>
            <label className="block text-xs text-blue-700 mb-1">Data de Crédito</label>
            <input
              type="date"
              value={globalDtCredito}
              onChange={e => setGlobalDtCredito(e.target.value)}
              className="rounded border border-blue-300 px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            />
          </div>
          <button
            onClick={applyGlobal}
            className="rounded-lg bg-blue-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
          >
            Aplicar a todos
          </button>
        </div>
      </div>

      {/* Tabela */}
      <div className="overflow-x-auto rounded-lg border border-gray-200 shadow-sm">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-gray-500">
            <tr>
              <th className="px-3 py-3 text-left font-medium">Linha</th>
              <th className="px-3 py-3 text-left font-medium">Nosso Número</th>
              <th className="px-3 py-3 text-left font-medium">Sacado</th>
              <th className="px-3 py-3 text-right font-medium">Vencimento</th>
              <th className="px-3 py-3 text-right font-medium">Valor Boleto</th>
              <th className="px-3 py-3 text-left font-medium text-blue-700">Ocorrência</th>
              <th className="px-3 py-3 text-left font-medium text-blue-700">Data Ocorrência</th>
              <th className="px-3 py-3 text-right font-medium text-blue-700">Valor Pago (R$)</th>
              <th className="px-3 py-3 text-left font-medium text-blue-700">Data Crédito</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 bg-white">
            {rows.map((row, idx) => (
              <tr key={row.lineNumber} className="hover:bg-gray-50">
                <td className="px-3 py-2 text-gray-400">{row.lineNumber}</td>
                <td className="px-3 py-2 font-mono text-gray-800">{row.nossoNumero.trim()}</td>
                <td className="px-3 py-2 text-gray-700 max-w-[180px] truncate">{row.sacado.trim()}</td>
                <td className="px-3 py-2 text-right text-gray-700">{formatCnabDate(row.vencimento)}</td>
                <td className="px-3 py-2 text-right text-gray-700">{formatCnabMoney(row.vlBoleto)}</td>

                {/* Ocorrência */}
                <td className="px-3 py-2">
                  <select
                    value={row.ocorrencia}
                    onChange={e => update(idx, 'ocorrencia', e.target.value)}
                    className="w-full rounded border border-gray-300 px-1.5 py-1 text-xs focus:outline-none focus:ring-2 focus:ring-blue-400"
                  >
                    {OCORRENCIAS.map(o => (
                      <option key={o.code} value={o.code}>{o.label}</option>
                    ))}
                  </select>
                </td>

                {/* Data Ocorrência */}
                <td className="px-3 py-2">
                  <input
                    type="date"
                    value={row.dtOcorrencia}
                    onChange={e => update(idx, 'dtOcorrencia', e.target.value)}
                    className="w-full rounded border border-gray-300 px-1.5 py-1 text-xs focus:outline-none focus:ring-2 focus:ring-blue-400"
                  />
                </td>

                {/* Valor Pago */}
                <td className="px-3 py-2">
                  <input
                    type="text"
                    value={row.vlPrincipal}
                    onChange={e => update(idx, 'vlPrincipal', e.target.value)}
                    placeholder="0,00"
                    className="w-28 rounded border border-gray-300 px-1.5 py-1 text-right text-xs focus:outline-none focus:ring-2 focus:ring-blue-400"
                  />
                </td>

                {/* Data Crédito */}
                <td className="px-3 py-2">
                  <input
                    type="date"
                    value={row.dtCredito}
                    onChange={e => update(idx, 'dtCredito', e.target.value)}
                    className="w-full rounded border border-gray-300 px-1.5 py-1 text-xs focus:outline-none focus:ring-2 focus:ring-blue-400"
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p className="text-xs text-gray-400">
        {rows.length} registro{rows.length !== 1 ? 's' : ''} — campos em azul são editáveis
      </p>
    </div>
  )
}

/** Converte um ParsedRecord de DETALHE_BOLETO para BoletoRow. */
export function buildBoletoRow(record: { lineNumber: number; rawContent: string }): BoletoRow {
  const raw = record.rawContent

  const today = new Date()
  const todayISO = today.toISOString().substring(0, 10)

  // valor do boleto em centavos → string decimal para o input
  const vlBoletoRaw = raw.substring(126, 139)  // posições 127-139 (0-indexed)
  const vlCents = parseInt(vlBoletoRaw.replace(/\D/g, '') || '0', 10)
  const vlStr = (vlCents / 100).toFixed(2)

  return {
    lineNumber:   record.lineNumber,
    nossoNumero:  raw.substring(62, 70),   // pos 63-70
    sacado:       raw.substring(234, 264), // pos 235-264
    vencimento:   raw.substring(120, 126), // pos 121-126
    vlBoleto:     vlBoletoRaw,
    rawLine:      raw,
    ocorrencia:   '06',
    dtOcorrencia: todayISO,
    vlPrincipal:  vlStr,
    dtCredito:    todayISO,
  }
}

/** Converte BoletoRow para o formato aceito pela API. */
export function rowToDetalheInput(row: BoletoRow) {
  return {
    rawLine: row.rawLine,
    edit: {
      ocorrencia:       row.ocorrencia.padStart(2, '0'),
      dtOcorrencia:     toDateDDMMYY(row.dtOcorrencia),
      vlPrincipalCents: parseCurrency(row.vlPrincipal),
      dtCredito:        toDateDDMMYY(row.dtCredito),
    },
  }
}
