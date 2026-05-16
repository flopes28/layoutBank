# LayoutBank — Documento de Arquitetura

> **Versão:** 1.0  
> **Data:** 2026-05-16  
> **Status:** Aprovada para implementação  
> **Escopo MVP:** Itaú CNAB 240 e CNAB 400

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Decisões Arquiteturais](#2-decisões-arquiteturais)
3. [Estrutura de Pastas](#3-estrutura-de-pastas)
4. [Schema do Banco de Dados](#4-schema-do-banco-de-dados)
5. [Motor de Parsing — cnab-engine](#5-motor-de-parsing--cnab-engine)
6. [Estratégia de Validação](#6-estratégia-de-validação)
7. [API Design](#7-api-design)
8. [Arquitetura Frontend](#8-arquitetura-frontend)
9. [Interpretação de Posições Fixas](#9-interpretação-de-posições-fixas)
10. [Suporte a Múltiplos Bancos](#10-suporte-a-múltiplos-bancos)
11. [Performance e Arquivos Grandes](#11-performance-e-arquivos-grandes)
12. [Stack Tecnológica](#12-stack-tecnológica)
13. [Roadmap do MVP](#13-roadmap-do-mvp)
14. [Glossário](#14-glossário)

---

## 1. Visão Geral

O **LayoutBank** é uma aplicação web profissional para análise, parsing e validação de arquivos de remessa bancária no formato CNAB (Centro Nacional de Automação Bancária).

### Objetivo

Permitir que usuários façam upload de arquivos TXT de remessa bancária e obtenham:

- Identificação e classificação de cada registro
- Extração de campos por posição fixa
- Validação de tipos, formatos e regras de negócio
- Visualização estruturada dos dados em tabela
- Inspeção detalhada de cada campo com destaque visual de erros

### Escopo MVP

- **Itaú CNAB 240** — Pagamento de boletos (Segmento J) e demais segmentos
- **Itaú CNAB 400** — Cobrança (Remessa Padrão)
- Layouts armazenados em banco de dados PostgreSQL
- Arquitetura extensível para novos bancos sem alteração de código

### Bancos previstos para fases futuras

| Código | Banco |
|--------|-------|
| 237 | Bradesco |
| 104 | Caixa Econômica Federal |
| 001 | Banco do Brasil |
| 033 | Santander |
| 041 | Banrisul |
| 748 | Sicredi |
| 077 | Inter |

---

## 2. Decisões Arquiteturais

### 2.1 Monorepo com Next.js (frontend + API no mesmo repositório)

**Decisão:** Usar Turborepo com Next.js App Router, onde as API Routes atuam como backend Node.js.

**Justificativa:**
- Elimina overhead de CORS, autenticação dupla e dois servidores em desenvolvimento
- O motor de parsing (`packages/cnab-engine`) é um pacote isolado sem dependência de framework, podendo ser extraído para um microserviço independente no futuro
- A fronteira entre frontend e backend é clara por convenção de pastas

**Consequência aceita:** Quando o sistema crescer (filas de processamento assíncrono, webhooks, múltiplos clientes), o `cnab-engine` já está pronto para virar um serviço independente sem reescrita.

---

### 2.2 Layouts bancários armazenados em PostgreSQL

**Decisão:** Cada campo de cada registro de cada layout bancário é uma linha na tabela `field_definitions`.

**Justificativa:**
- Layouts CNAB mudam — bancos atualizam suas especificações periodicamente
- Atualizar um layout não exige deploy da aplicação
- Múltiplas versões de um mesmo layout coexistem (Itaú v1, v2, v3)
- Uma interface administrativa pode criar layouts de novos bancos sem alterar código
- Auditoria completa de alterações nos layouts

**Alternativa rejeitada:** Layouts como arquivos JSON/TypeScript no código-fonte. Rejeitada porque exige deploy para qualquer atualização de layout e não permite versionamento independente.

---

### 2.3 Engine de parsing agnóstico ao banco

**Decisão:** O `cnab-engine` não contém lógica específica de nenhum banco. Toda regra de layout vem do banco de dados via `LayoutRegistry`.

**Justificativa:**
- Adicionar um novo banco = inserir registros no PostgreSQL, sem alterar código
- Testabilidade: o engine pode ser testado com layouts sintéticos
- Separação de responsabilidades: o engine sabe *como* parsear, o banco de dados sabe *o que* parsear

**Exceção permitida:** Bancos com regras de negócio impossíveis de expressar em JSONB genérico podem registrar um `BankSpecificValidator` opcional. Se não houver validator registrado, o engine usa apenas as regras do banco de dados.

---

### 2.4 Drizzle ORM (SQL-first)

**Decisão:** Usar Drizzle ORM em vez de Prisma ou query builder puro.

**Justificativa:**
- SQL-first: as queries são SQL legível, sem abstrações que escondem o que está sendo executado
- Type-safe: o schema TypeScript é a única fonte de verdade
- Migrations controladas: sem magia de "auto-migrate", cada migração é um arquivo SQL versionado
- Performance: sem overhead de ORM pesado para queries simples

---

## 3. Estrutura de Pastas

```
layoutbank/
│
├── apps/
│   └── web/                              # Aplicação Next.js (App Router)
│       ├── app/
│       │   ├── (dashboard)/
│       │   │   ├── page.tsx              # Tela principal: upload e análise
│       │   │   ├── history/
│       │   │   │   └── page.tsx          # Histórico de arquivos processados
│       │   │   └── admin/
│       │   │       └── layouts/
│       │   │           ├── page.tsx      # Listagem de layouts cadastrados
│       │   │           └── [id]/
│       │   │               └── page.tsx  # Visualização/edição de layout
│       │   ├── api/
│       │   │   ├── parse/
│       │   │   │   └── route.ts          # POST: recebe arquivo, retorna análise
│       │   │   ├── layouts/
│       │   │   │   ├── route.ts          # GET: lista layouts disponíveis
│       │   │   │   └── [id]/
│       │   │   │       └── route.ts      # GET/PUT/DELETE layout específico
│       │   │   ├── banks/
│       │   │   │   └── route.ts          # GET: lista bancos cadastrados
│       │   │   └── validate/
│       │   │       └── route.ts          # POST: valida sem persistir resultado
│       │   └── layout.tsx
│       │
│       ├── components/
│       │   ├── upload/
│       │   │   ├── DropZone.tsx          # Área drag-and-drop
│       │   │   └── FileInfo.tsx          # Nome, tamanho, qtd de linhas
│       │   ├── analysis/
│       │   │   ├── RecordTable.tsx       # Tabela principal (virtualizada)
│       │   │   ├── RecordRow.tsx         # Linha da tabela com destaque visual
│       │   │   ├── FieldInspector.tsx    # Painel lateral de inspeção
│       │   │   ├── FieldRow.tsx          # Linha do painel (campo + validação)
│       │   │   ├── StatusBadge.tsx       # Badge OK / WARNING / ERROR
│       │   │   ├── ErrorSummary.tsx      # Resumo de erros no topo
│       │   │   └── FileSummary.tsx       # Cards de totais (linhas, erros, etc.)
│       │   └── ui/                       # shadcn/ui re-exports e extensões locais
│       │
│       ├── hooks/
│       │   ├── useFileUpload.ts          # Estado e lógica do upload
│       │   ├── useParseResult.ts         # Gerencia resultado do parsing
│       │   └── useFieldInspection.ts     # Estado do painel de inspeção
│       │
│       └── lib/
│           ├── api-client.ts             # Funções tipadas para as API routes
│           └── formatters.ts             # Formatação de valores, datas, moeda
│
├── packages/
│   │
│   ├── cnab-engine/                      # Motor de parsing (zero dependência de framework)
│   │   ├── src/
│   │   │   ├── core/
│   │   │   │   ├── Engine.ts             # Orquestrador: coordena todos os subsistemas
│   │   │   │   ├── LineReader.ts         # Leitura linha a linha via stream
│   │   │   │   ├── RecordClassifier.ts   # Identifica tipo de registro por posição
│   │   │   │   ├── FieldExtractor.ts     # Extrai campos por start/end position
│   │   │   │   └── TypeConverter.ts      # Converte string bruta em tipo nativo
│   │   │   │
│   │   │   ├── validation/
│   │   │   │   ├── ValidationPipeline.ts # Orquestra cadeia de validações
│   │   │   │   ├── CrossRecordValidator.ts # Valida relações entre registros
│   │   │   │   └── rules/
│   │   │   │       ├── StructuralRule.ts   # Tamanho de linha, encoding
│   │   │   │       ├── NumericRule.ts      # Campo NUM contém só dígitos
│   │   │   │       ├── DateRule.ts         # Data é válida, formato correto
│   │   │   │       ├── MonetaryRule.ts     # Valor monetário com casas corretas
│   │   │   │       ├── RequiredRule.ts     # Campo obrigatório não está em branco
│   │   │   │       ├── AllowedValuesRule.ts # Campo enum tem valor permitido
│   │   │   │       └── FillerRule.ts       # Campo filler está em branco/zeros
│   │   │   │
│   │   │   ├── registry/
│   │   │   │   ├── LayoutRegistry.ts     # Carrega layouts do PostgreSQL
│   │   │   │   └── LayoutCache.ts        # Cache em memória com TTL
│   │   │   │
│   │   │   └── types/
│   │   │       ├── Layout.ts             # Tipos internos do engine
│   │   │       ├── ParseResult.ts        # Estrutura de saída do parsing
│   │   │       └── ValidationResult.ts   # Estrutura de resultado de validação
│   │   │
│   │   └── package.json
│   │
│   ├── database/                         # Schema, migrations, queries
│   │   ├── migrations/
│   │   │   ├── 001_create_banks.sql
│   │   │   ├── 002_create_layouts.sql
│   │   │   ├── 003_create_record_types.sql
│   │   │   ├── 004_create_field_definitions.sql
│   │   │   └── 005_seed_itau.sql         # Layout completo Itaú 240 e 400
│   │   ├── queries/
│   │   │   ├── layouts.ts                # Queries tipadas para layouts
│   │   │   └── banks.ts                  # Queries tipadas para bancos
│   │   └── schema/
│   │       └── index.ts                  # Drizzle schema (fonte de verdade dos tipos)
│   │
│   └── shared-types/                     # Contratos TypeScript compartilhados
│       └── src/
│           ├── cnab.ts                   # Tipos do domínio CNAB
│           ├── api.ts                    # Tipos de request/response das APIs
│           └── index.ts
│
├── docker-compose.yml                    # PostgreSQL local para desenvolvimento
├── .env.example                          # Variáveis de ambiente necessárias
├── turbo.json                            # Configuração do Turborepo
├── package.json                          # Root package.json (workspaces)
└── ARCHITECTURE.md                       # Este documento
```

---

## 4. Schema do Banco de Dados

### 4.1 Diagrama de Entidades

```
banks
  └── cnab_layouts (1 banco : N layouts)
        └── record_types (1 layout : N tipos de registro)
              └── field_definitions (1 tipo : N campos)
```

### 4.2 DDL Completo

```sql
-- ============================================================
-- Bancos cadastrados
-- ============================================================
CREATE TABLE banks (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(10)  UNIQUE NOT NULL,   -- '341' = Itaú, '237' = Bradesco
  name        VARCHAR(100) NOT NULL,          -- 'Itaú Unibanco S.A.'
  short_name  VARCHAR(20)  NOT NULL,          -- 'itau'
  is_active   BOOLEAN      DEFAULT true,
  created_at  TIMESTAMPTZ  DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
-- Layouts por banco e formato
-- ============================================================
CREATE TABLE cnab_layouts (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id      UUID        NOT NULL REFERENCES banks(id) ON DELETE RESTRICT,
  format       VARCHAR(10) NOT NULL,           -- 'CNAB240' | 'CNAB400'
  version      VARCHAR(20) NOT NULL,           -- '10.4', '2023.1'
  name         VARCHAR(150) NOT NULL,          -- 'Itaú CNAB 240 - Pagamentos'
  line_length  SMALLINT    NOT NULL,           -- 240 ou 400
  encoding     VARCHAR(20) DEFAULT 'latin1',   -- 'latin1' | 'utf-8'
  is_active    BOOLEAN     DEFAULT true,
  notes        TEXT,                           -- observações sobre o layout
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (bank_id, format, version)
);

-- ============================================================
-- Tipos de registro dentro de cada layout
-- ============================================================
CREATE TABLE record_types (
  id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  layout_id                   UUID        NOT NULL REFERENCES cnab_layouts(id) ON DELETE CASCADE,
  code                        VARCHAR(30) NOT NULL,  -- 'HEADER_ARQUIVO', 'DETALHE_J', 'TRAILER_LOTE'
  description                 VARCHAR(200) NOT NULL, -- 'Header de Arquivo'
  category                    VARCHAR(10) NOT NULL,  -- 'HEADER' | 'DETAIL' | 'TRAILER'
  -- Identificador primário: posição no registro que define o tipo
  identifier_start            SMALLINT    NOT NULL,  -- posição 1-based de início
  identifier_end              SMALLINT    NOT NULL,  -- posição 1-based de fim
  identifier_value            VARCHAR(20) NOT NULL,  -- '0', '1', '9', 'J', 'A'
  -- Identificador secundário: para segmentos com sub-identificador (ex: J-52)
  secondary_identifier_start  SMALLINT,
  secondary_identifier_end    SMALLINT,
  secondary_identifier_value  VARCHAR(20),
  sort_order                  SMALLINT    NOT NULL,  -- ordem esperada no arquivo
  created_at                  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (layout_id, code)
);

-- ============================================================
-- Definição de cada campo do registro
-- ============================================================
CREATE TABLE field_definitions (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  record_type_id   UUID        NOT NULL REFERENCES record_types(id) ON DELETE CASCADE,
  name             VARCHAR(100) NOT NULL,    -- nome técnico: 'COD_BANCO', 'NUM_INSCRICAO'
  label            VARCHAR(200) NOT NULL,    -- nome legível: 'Código do Banco'
  description      TEXT,                    -- descrição completa conforme FEBRABAN
  start_position   SMALLINT    NOT NULL,    -- 1-based, conforme especificação FEBRABAN
  end_position     SMALLINT    NOT NULL,    -- 1-based
  length           SMALLINT    NOT NULL,    -- end_position - start_position + 1
  data_type        VARCHAR(20) NOT NULL,    -- veja enum abaixo
  format_mask      VARCHAR(50),            -- 'DDMMAAAA', 'MMAAAA', '9(13)V99'
  decimal_places   SMALLINT    DEFAULT 0,  -- para tipo MONETARY
  is_required      BOOLEAN     DEFAULT true,
  is_filler        BOOLEAN     DEFAULT false, -- campo de uso futuro / brancos / zeros
  allowed_values   TEXT[],                 -- ['0','1','2'] para campos enum
  validation_rules JSONB,                  -- regras customizadas (veja seção 4.3)
  sort_order       SMALLINT    NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  -- Integridade: start <= end e length correto
  CONSTRAINT chk_positions CHECK (start_position <= end_position),
  CONSTRAINT chk_length     CHECK (length = end_position - start_position + 1),
  -- Enum de tipos de dados
  CONSTRAINT chk_data_type  CHECK (data_type IN (
    'ALPHA',     -- alfanumérico, justificado à esquerda, espaços à direita
    'NUM',       -- numérico, justificado à direita, zeros à esquerda
    'DATE',      -- data, formato em format_mask
    'MONETARY',  -- valor monetário com casas decimais implícitas
    'ALPHANUM',  -- alfanumérico sem justificação específica
    'CONSTANT'   -- valor fixo, sempre igual a identifier_value
  ))
);

-- Índices para performance
CREATE INDEX idx_field_definitions_record_type ON field_definitions(record_type_id);
CREATE INDEX idx_record_types_layout ON record_types(layout_id);
CREATE INDEX idx_cnab_layouts_bank ON cnab_layouts(bank_id);
CREATE INDEX idx_banks_code ON banks(code);
```

### 4.3 Estrutura do JSONB `validation_rules`

O campo `validation_rules` em `field_definitions` permite regras customizadas que não se encaixam em colunas fixas:

```json
{
  "minValue": 0,
  "maxValue": 999999999,
  "minLength": 1,
  "allowedPattern": "^[0-9]{11,14}$",
  "mustBeZeroWhenField": "COD_INSCRICAO",
  "mustBeZeroWhenValue": "0",
  "mustMatchField": "TOTAL_REGISTROS",
  "customMessage": "CPF deve ter 11 dígitos ou CNPJ 14 dígitos"
}
```

---

## 5. Motor de Parsing — cnab-engine

### 5.1 Fluxo de Processamento

```
Arquivo TXT (upload)
        │
        ▼
  LineReader
  ─────────────────────────────────────────────
  Lê o arquivo linha a linha via stream.
  Nunca carrega o arquivo inteiro na memória.
  Produz: { lineNumber, rawContent }
        │
        ▼
  RecordClassifier
  ─────────────────────────────────────────────
  Consulta o LayoutRegistry para obter os
  record_types do layout identificado.
  Extrai o identificador na posição definida.
  Produz: { lineNumber, rawContent, recordType }
        │
        ▼
  FieldExtractor
  ─────────────────────────────────────────────
  Para cada field_definition do record_type,
  executa substring(start-1, end).
  Produz: { ...anterior, rawFields[] }
        │
        ▼
  TypeConverter
  ─────────────────────────────────────────────
  Converte cada rawField para seu tipo nativo:
  DATE → Date | null
  MONETARY → number (com casas decimais)
  NUM → number
  ALPHA/ALPHANUM → string (trimmed)
  Produz: { ...anterior, parsedFields[] }
        │
        ▼
  ValidationPipeline
  ─────────────────────────────────────────────
  Aplica cada ValidationRule em sequência.
  Se STRUCTURAL falhar → para a cadeia para esta linha.
  Produz: { ...anterior, fieldValidations[] }
        │
        ▼
  CrossRecordValidator
  ─────────────────────────────────────────────
  Após processar TODOS os registros:
  Verifica totais do trailer x soma dos detalhes.
  Verifica sequência de lotes.
  Verifica estrutura header/trailer.
  Produz: crossRecordErrors[]
        │
        ▼
  ParseResult (estrutura tipada final)
```

### 5.2 Tipos de Dados do ParseResult

```typescript
// packages/shared-types/src/cnab.ts

interface ParseResult {
  fileInfo:           FileInfo
  layoutId:           string
  bankCode:           string
  format:             'CNAB240' | 'CNAB400'
  summary:            FileSummary
  records:            ParsedRecord[]
  crossRecordErrors:  CrossRecordError[]
}

interface FileInfo {
  name:       string
  sizeBytes:  number
  totalLines: number
  encoding:   string
  detectedAt: string  // ISO 8601
}

interface FileSummary {
  totalLines:           number
  headerCount:          number
  detailCount:          number
  trailerCount:         number
  errorCount:           number
  warningCount:         number
  hasStructuralErrors:  boolean
}

interface ParsedRecord {
  lineNumber:       number           // 1-based
  rawContent:       string           // linha original intacta (sem modificação)
  recordTypeCode:   string           // 'HEADER_ARQUIVO', 'DETALHE_J'
  recordTypeLabel:  string           // 'Header de Arquivo'
  category:         RecordCategory   // 'HEADER' | 'DETAIL' | 'TRAILER'
  status:           RecordStatus     // 'OK' | 'WARNING' | 'ERROR'
  fields:           ParsedField[]
  errors:           FieldError[]     // erros desta linha especificamente
}

interface ParsedField {
  name:         string
  label:        string
  description:  string | null
  startPosition: number             // 1-based
  endPosition:   number             // 1-based
  rawValue:      string             // exatamente o que estava no arquivo
  parsedValue:   string | number | Date | null
  dataType:      FieldDataType
  isRequired:    boolean
  isFiller:      boolean
  validation:    FieldValidation
}

interface FieldValidation {
  isValid:   boolean
  errors:    string[]
  warnings:  string[]
}

interface CrossRecordError {
  type:     string    // 'TOTAL_MISMATCH' | 'MISSING_TRAILER' | 'SEQUENCE_ERROR'
  message:  string
  lines:    number[]  // linhas envolvidas no erro
}

type RecordCategory = 'HEADER' | 'DETAIL' | 'TRAILER'
type RecordStatus   = 'OK' | 'WARNING' | 'ERROR'
type FieldDataType  = 'ALPHA' | 'NUM' | 'DATE' | 'MONETARY' | 'ALPHANUM' | 'CONSTANT'
```

### 5.3 LayoutRegistry e Cache

```
LayoutRegistry
├── Ao inicializar: carrega todos os layouts ativos do PostgreSQL
├── Método identify(line, lineLength): retorna o layout provável
│   └── Heurísticas:
│       1. lineLength → CNAB240 ou CNAB400
│       2. line[0..2] (posição 1-3) → código do banco
│       3. Retorna o layout ativo correspondente
├── Método getRecordType(layoutId, line): retorna o record_type da linha
│   └── Testa identifier_value na posição identifier_start..identifier_end
│       e opcionalmente secondary_identifier_value
└── Método getFieldDefinitions(recordTypeId): retorna todos os campos ordenados

LayoutCache
├── TTL padrão: 5 minutos
├── Invalida ao alterar layout via API
└── Evita consultas repetidas ao banco por arquivo
```

---

## 6. Estratégia de Validação

### 6.1 Três Camadas Independentes e Encadeadas

```
Camada 1 — ESTRUTURAL (antes de parsear)
├── Tamanho de cada linha (deve ser exatamente 240 ou 400 chars)
├── Encoding do arquivo (latin1 vs UTF-8)
├── Caracteres de controle inválidos
└── Arquivo vazio ou corrompido

Se falhar na Camada 1: reporta erro estrutural e NÃO processa a linha.
A linha receberá status ERROR com categoria STRUCTURAL.

Camada 2 — POR CAMPO (durante parsing, campo a campo)
├── NumericRule:       campo NUM contém apenas dígitos [0-9]?
├── DateRule:          data é uma data válida no formato do format_mask?
├── MonetaryRule:      valor tem exatamente o número de dígitos esperado?
├── RequiredRule:      campo obrigatório não está em branco (espaços/zeros)?
├── AllowedValuesRule: campo enum tem valor que está em allowed_values[]?
├── FillerRule:        campo is_filler está preenchido com brancos ou zeros?
└── PatternRule:       rawValue bate com allowedPattern do validation_rules?

Camada 3 — CROSS-RECORD (após processar todos os registros)
├── Contagem: total de registros no trailer == quantidade real de linhas?
├── Somatória: soma dos valores nos detalhes == total no trailer?
├── Estrutura: exatamente 1 header de arquivo e 1 trailer de arquivo?
├── Lotes: cada header de lote tem seu trailer correspondente?
└── Sequência: numeração dos lotes é sequencial e sem lacunas?
```

### 6.2 Por que separar em camadas?

Se uma linha tem tamanho errado (Camada 1), a extração de campos (Camada 2) seria completamente inválida. Não faz sentido reportar 30 erros de campo quando o problema real é a linha truncada.

A separação permite **parar cedo, reportar o erro correto** e não gerar ruído de falsos positivos.

### 6.3 ValidationPipeline — Chain of Responsibility

```
arquivo.txt
    │
    ├── linha 001 → [StructuralRule] → PASS → [Campo 1..N: Rules] → PASS → OK
    ├── linha 002 → [StructuralRule] → PASS → [Campo 1..N: Rules] → FAIL campo 5 → ERROR
    ├── linha 003 → [StructuralRule] → FAIL (260 chars em vez de 240) → ERROR (para aqui)
    └── linha 004 → [StructuralRule] → PASS → [Campo 1..N: Rules] → WARNING campo 2 → WARNING
```

---

## 7. API Design

### 7.1 Endpoints

#### `POST /api/parse`

Recebe o arquivo e retorna a análise completa.

```
Request:
  Content-Type: multipart/form-data
  Body:
    file: File            (obrigatório) arquivo TXT de remessa
    layoutId?: string     (opcional) UUID do layout; se omitido, detecção automática

Response 200:
  Content-Type: application/json
  Body: ParseResult

Response 400:
  { error: 'INVALID_FILE', message: 'Arquivo inválido ou corrompido' }

Response 422:
  { error: 'LAYOUT_NOT_FOUND', message: 'Nenhum layout identificado para este arquivo' }
```

#### `GET /api/layouts`

Lista layouts disponíveis.

```
Query params:
  bankCode?: string   ex: '341'
  format?: string     ex: 'CNAB240'
  active?: boolean    default: true

Response 200:
  CnabLayout[]
```

#### `GET /api/layouts/:id`

Retorna layout completo com record_types e field_definitions.

```
Response 200:
  CnabLayout & {
    recordTypes: (RecordType & { fieldDefinitions: FieldDefinition[] })[]
  }
```

#### `GET /api/banks`

Lista bancos cadastrados.

```
Response 200:
  Bank[]
```

### 7.2 Detecção Automática de Layout

Quando `layoutId` não é informado no `POST /api/parse`:

1. Mede o comprimento das primeiras 5 linhas → identifica 240 ou 400
2. Extrai posições 1-3 da primeira linha → código do banco
3. Busca no banco: `WHERE bank.code = :code AND layout.format = :format AND layout.is_active = true`
4. Se encontrar exatamente 1 resultado: usa este layout
5. Se encontrar múltiplos (várias versões): usa o de `version` mais recente
6. Se não encontrar: retorna erro 422

---

## 8. Arquitetura Frontend

### 8.1 Fluxo de Estado da Aplicação

```
[Idle]
  │ usuário arrasta arquivo ou clica em upload
  ▼
[Uploading] ── POST /api/parse ──▶ API
  │                                 │
  │ response (ParseResult)          │
  ◀────────────────────────────────┘
  ▼
[Analyzed]
  ├── FileSummary (cards de totais)
  ├── ErrorSummary (resumo de erros críticos)
  ├── RecordTable (tabela virtualizada)
  │     │ clique em linha
  │     ▼
  │   FieldInspector (painel lateral deslizante)
  └── (botões: exportar JSON, exportar CSV, novo upload)
```

### 8.2 Componentes Principais

#### `RecordTable` — tabela virtualizada

Usa `@tanstack/react-virtual` para renderizar apenas as linhas visíveis no viewport. Para arquivos com 10.000+ linhas, sem virtualização o browser congela.

Colunas:
| Nº Linha | Tipo de Registro | Descrição | Status | Erros |
|---|---|---|---|---|
| 1 | Header Arquivo | Cabeçalho do arquivo | ✓ OK | — |
| 4 | Detalhe Seg. J | Pagamento de boleto | ✗ ERRO | 2 erros |
| 5 | Detalhe Seg. J | Pagamento de boleto | ⚠ AVISO | 1 aviso |

#### `RecordRow` — linha com destaque visual

```
OK:       bg-white         border-l-4 border-transparent
WARNING:  bg-yellow-50     border-l-4 border-yellow-400
ERROR:    bg-red-50        border-l-4 border-red-500
CRITICAL: bg-red-100       border-l-4 border-red-700   ← erro estrutural (tamanho)
```

#### `FieldInspector` — painel lateral deslizante

Abre ao clicar em qualquer linha da RecordTable. Exibe:

```
┌─────────────────────────────────────────────────────────────────────┐
│ LINHA 15 — Detalhe Segmento J                ● 2 erros  ▲ 1 aviso │
├──────────────────┬───────────┬──────────────────────┬──────────────┤
│ Campo            │ Posição   │ Valor Bruto           │ Validação    │
├──────────────────┼───────────┼──────────────────────┼──────────────┤
│ Código do Banco  │  1 –  3   │ "341"                 │ ✓            │
│ Lote de Serviço  │  4 –  7   │ "0001"                │ ✓            │
│ Tipo de Registro │  8 –  8   │ "3"                   │ ✓            │
│ Código de Barras │ 14 – 57   │ "34191090020000..."   │ ✓            │
│ Nome do Cedente  │ 58 – 90   │ "EMPRESA XYZ LTDA  "  │ ✓            │
│ Data Vencimento  │ 91 – 98   │ "32012024"            │ ✗ Data inválida │
│ Código Moeda     │ 11 – 13   │ "   "                 │ ✗ Obrigatório   │
└──────────────────┴───────────┴──────────────────────┴──────────────┘
```

Campos inválidos ficam com fundo vermelho claro na linha inteira. O valor bruto é sempre exibido exatamente como está no arquivo.

#### `FileSummary` — cards de resumo

```
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  247 linhas │ │ 245 detalhes│ │  2 erros    │ │  1 aviso    │
│  arquivo    │ │  de detalhe │ │  críticos   │ │             │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

### 8.3 Filtros na Tabela

- Mostrar todos
- Mostrar apenas erros
- Mostrar apenas warnings
- Mostrar apenas Headers/Trailers
- Busca por conteúdo (rawContent contém texto)

---

## 9. Interpretação de Posições Fixas

### 9.1 Regra Fundamental

As especificações FEBRABAN usam posições **1-based**. O JavaScript usa índices **0-based**. A conversão é feita apenas em um lugar (`FieldExtractor.ts`) para evitar bugs.

```typescript
// FieldExtractor.ts
function extractField(
  line: string,
  startPosition: number,  // 1-based, conforme FEBRABAN
  endPosition: number     // 1-based, conforme FEBRABAN
): string {
  // Conversão: subtract 1 apenas no start (substring é exclusivo no end)
  return line.substring(startPosition - 1, endPosition)
}

// Exemplo: COD_BANCO, posição 1-3
// line.substring(0, 3) → "341"
//
// Exemplo: NOME_EMPRESA, posição 33-72
// line.substring(32, 72) → "EMPRESA XYZ LTDA                        "
```

### 9.2 Conversão de Tipos

```typescript
// TypeConverter.ts

// MONETARY: "0000000001500" com 2 casas decimais = 15.00
function convertMonetary(raw: string, decimalPlaces: number): number {
  const normalized = raw.replace(/\s/g, '').padStart(1, '0')
  const integer = parseInt(normalized, 10)
  if (isNaN(integer)) throw new TypeError(`Valor monetário inválido: "${raw}"`)
  return integer / Math.pow(10, decimalPlaces)
}

// DATE: "16052026" com mask "DDMMAAAA" → Date(2026, 4, 16)
function convertDate(raw: string, mask: string): Date | null {
  if (!raw || raw.trim() === '' || raw === '00000000') return null
  const mapping = parseMask(mask)  // { day: [0,2], month: [2,4], year: [4,8] }
  const day   = parseInt(raw.substring(mapping.day[0],   mapping.day[1]))
  const month = parseInt(raw.substring(mapping.month[0], mapping.month[1])) - 1
  const year  = parseInt(raw.substring(mapping.year[0],  mapping.year[1]))
  const date  = new Date(year, month, day)
  // Validar que a data construída é igual à esperada (evita 32/01 virar 01/02)
  if (date.getDate() !== day || date.getMonth() !== month) return null
  return date
}

// NUM: "00341" → 341
function convertNum(raw: string): number {
  const trimmed = raw.trimStart().replace(/^0+/, '') || '0'
  const value = parseInt(trimmed, 10)
  if (isNaN(value)) throw new TypeError(`Valor numérico inválido: "${raw}"`)
  return value
}

// ALPHA: "EMPRESA XYZ LTDA  " → "EMPRESA XYZ LTDA"
function convertAlpha(raw: string): string {
  return raw.trimEnd()
}
```

---

## 10. Suporte a Múltiplos Bancos

### 10.1 Estratégia

O banco de dados resolve 90% do problema. O engine é **completamente agnóstico** ao banco — não contém nenhuma referência a "Itaú", "Bradesco", etc.

O que muda de banco para banco fica exclusivamente no PostgreSQL (layouts, posições, regras). O engine lê o layout e processa sem saber qual banco é.

### 10.2 Adicionando um Novo Banco

Para adicionar o Bradesco CNAB 400:

1. Inserir registro em `banks` (code: '237', name: 'Bradesco', short_name: 'bradesco')
2. Inserir registro em `cnab_layouts` (bank_id, format: 'CNAB400', version: '1.0')
3. Inserir registros em `record_types` (header, detalhe, trailer)
4. Inserir registros em `field_definitions` (todos os campos de cada tipo)
5. **Zero alteração de código**

### 10.3 Regras de Negócio Específicas por Banco (exceção)

Alguns bancos têm validações impossíveis de expressar em JSONB genérico (ex: algoritmo de validação do nosso número, dígito verificador da agência). Para esses casos, existe um hook opcional:

```typescript
// packages/cnab-engine/src/registry/LayoutRegistry.ts

interface BankSpecificValidator {
  bankCode: string
  validate(record: ParsedRecord, context: ValidationContext): ValidationResult
}

// Registro do validator específico
registry.registerBankValidator('341', new ItauSpecificValidator())

// Se não houver validator registrado → engine usa apenas regras do banco de dados
// Este é o comportamento padrão e o caso mais comum
```

O `ItauSpecificValidator` implementa:
- Validação do nosso número (módulo 10)
- Validação do dígito verificador da agência
- Regras específicas de cada produto Itaú

---

## 11. Performance e Arquivos Grandes

### 11.1 Estratégia por Tamanho de Arquivo

| Tamanho | Estratégia | Tempo estimado |
|---------|-----------|----------------|
| < 1 MB | Parsing síncrono, resposta direta | < 1s |
| 1–10 MB | Streaming com progresso via Server-Sent Events | 2–15s |
| > 10 MB | Upload para storage, processamento assíncrono (fila) | > 30s |

Para o MVP, focar em < 10 MB. Arquivos maiores são raros para remessa bancária de boletos avulsos (uma remessa de 10k boletos em CNAB 240 tem ~2.4 MB).

### 11.2 Streaming no Servidor

```typescript
// LineReader.ts — nunca carrega o arquivo inteiro na memória

import { createInterface } from 'readline'
import { Readable } from 'stream'

async function* readLines(buffer: Buffer, encoding: BufferEncoding = 'latin1') {
  const stream = Readable.from(buffer.toString(encoding))
  const rl = createInterface({ input: stream, crlfDelay: Infinity })
  let lineNumber = 0
  for await (const line of rl) {
    lineNumber++
    yield { lineNumber, rawContent: line }
  }
}
```

### 11.3 Virtualização no Frontend

`@tanstack/react-virtual` renderiza apenas as linhas visíveis no viewport.

```
Arquivo com 10.000 linhas:
  Sem virtualização: 10.000 <tr> no DOM → browser congela
  Com virtualização: ~30 <tr> no DOM (apenas as visíveis) → 60fps
```

### 11.4 Filtragem Inteligente

O padrão de uso é: o analista quer ver **apenas os erros**. Disponibilizar filtro `status=ERROR` elimina a necessidade de scrollar 10.000 linhas OK.

---

## 12. Stack Tecnológica

| Camada | Tecnologia | Versão | Justificativa |
|--------|-----------|--------|---------------|
| Runtime | Node.js | 22 LTS | LTS estável, suporte nativo a streams |
| Framework | Next.js App Router | 15 | Server Components, API Routes, SSE nativo |
| Linguagem | TypeScript strict | 5.x | Financeiro exige tipos precisos, sem `any` |
| CSS | Tailwind CSS | 4 | Velocidade de desenvolvimento sem sacrificar qualidade |
| Componentes | shadcn/ui | latest | Acessível, customizável, não é uma biblioteca opaca |
| Virtualização | @tanstack/react-virtual | 3 | Performance com listas de 10k+ itens |
| ORM | Drizzle ORM | latest | SQL-first, type-safe, migrations explícitas |
| Banco de dados | PostgreSQL | 16 | JSONB para regras flexíveis + relacional para estrutura |
| Monorepo | Turborepo | latest | Build cache, workspace simples |
| Testes | Vitest | latest | Rápido, compatível com ESM, API similar ao Jest |
| Container | Docker + docker-compose | — | PostgreSQL local em desenvolvimento |

### 12.1 Variáveis de Ambiente

```env
# .env.example

# PostgreSQL
DATABASE_URL=postgresql://postgres:password@localhost:5432/layoutbank

# Next.js
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Parsing
MAX_FILE_SIZE_MB=10
LAYOUT_CACHE_TTL_SECONDS=300
```

---

## 13. Roadmap do MVP

### Fase 1 — Fundação (Semana 1–2)
- [ ] Setup do monorepo com Turborepo
- [ ] Configuração do Next.js 15 com TypeScript strict
- [ ] Docker Compose com PostgreSQL 16
- [ ] Schema do banco de dados e migrations (001–004)
- [ ] Seed completo: Itaú CNAB 240 — Segmento J (pagamento de boletos)
- [ ] Seed completo: Itaú CNAB 400 — Remessa de Cobrança
- [ ] Engine core: LineReader, RecordClassifier, FieldExtractor, TypeConverter
- [ ] Validações Camada 1 e 2 (estrutural + por campo)
- [ ] API `POST /api/parse` funcional com retorno `ParseResult`

### Fase 2 — Interface (Semana 3)
- [ ] DropZone com drag-and-drop
- [ ] FileSummary (cards de totais)
- [ ] RecordTable básica (sem virtualização no início)
- [ ] FieldInspector (painel lateral deslizante)
- [ ] Destaque visual: bordas coloridas por status
- [ ] StatusBadge e ErrorSummary

### Fase 3 — Completar Itaú (Semana 4)
- [ ] CrossRecordValidator (totais, sequências, estrutura de lotes)
- [ ] Seed: demais segmentos do Itaú CNAB 240 (A, B, O, N, W, Z)
- [ ] Detecção automática de layout (sem informar layoutId)
- [ ] Filtros na tabela (apenas erros, apenas warnings)
- [ ] Testes unitários no engine (Vitest) — cobertura dos conversores e validators

### Fase 4 — Qualidade e UX (Semana 5)
- [ ] Virtualização com @tanstack/react-virtual
- [ ] Export do resultado em JSON
- [ ] Export do resultado em CSV (apenas erros)
- [ ] Tratamento de encoding: detecção automática latin1 vs UTF-8
- [ ] Mensagens de erro amigáveis na interface
- [ ] Responsividade básica

### Fase 5 — Escalabilidade (Futuro)
- [ ] Interface admin: CRUD de layouts bancários
- [ ] Histórico de arquivos processados (com autenticação)
- [ ] Processamento assíncrono para arquivos > 10 MB
- [ ] Multi-tenant (por empresa/cliente)
- [ ] Adição dos demais bancos (Bradesco, BB, Caixa, Santander, Banrisul, Sicredi, Inter)
- [ ] API pública documentada (Swagger/OpenAPI)

---

## 14. Glossário

| Termo | Definição |
|-------|-----------|
| **CNAB** | Centro Nacional de Automação Bancária. Padrão de arquivos de troca bancária no Brasil. |
| **CNAB 240** | Layout com 240 caracteres por linha. Padrão mais moderno, suporta múltiplos lotes. |
| **CNAB 400** | Layout com 400 caracteres por linha. Padrão legado, ainda amplamente usado. |
| **Remessa** | Arquivo enviado pelo cedente (empresa) ao banco. Contém instruções de cobrança ou pagamento. |
| **Retorno** | Arquivo enviado pelo banco ao cedente. Contém confirmações e resultados. |
| **Header** | Registro de cabeçalho. Identifica o início do arquivo ou de um lote. |
| **Detalhe** | Registro de dados. Contém uma instrução de cobrança ou pagamento. |
| **Trailer** | Registro de rodapé. Contém totalizadores e encerra o arquivo ou lote. |
| **Segmento** | Subdivisão do detalhe no CNAB 240. Ex: Segmento J para boletos. |
| **Lote** | Agrupamento de registros relacionados no CNAB 240. |
| **Posição fixa** | Campos determinados pela posição dos caracteres na linha, não por separador. |
| **Filler** | Campo reservado para uso futuro. Deve conter brancos ou zeros. |
| **Cedente** | Empresa que emite os boletos ou realiza os pagamentos. |
| **FEBRABAN** | Federação Brasileira de Bancos. Define os padrões CNAB. |
| **Nosso Número** | Identificador único do boleto atribuído pelo banco. |

---

*Este documento deve ser atualizado a cada decisão arquitetural relevante tomada durante o desenvolvimento.*
