# LayoutBank — Documentação do Banco de Dados

> **SGBD:** PostgreSQL  
> **ORM:** Drizzle ORM  
> **Migrations:** `packages/database/src/migrate.ts` (runner próprio, tabela `_migrations`)  
> **Schema Drizzle:** `packages/database/src/schema/index.ts`  
> **Diagrama ER:** [`DER.svg`](../DER.svg) (abrir no browser ou VS Code)

---

## Visão Geral

O banco segue uma hierarquia de quatro níveis:

```
banks
  └── cnab_layouts          (1 banco → N layouts)
        └── record_types    (1 layout → N tipos de registro)
              └── field_definitions  (1 tipo → N campos)
```

Cada nível herda o contexto do anterior: um campo só faz sentido dentro de um tipo de registro, que só faz sentido dentro de um layout, que pertence a um banco específico.

---

## Tabelas

### `banks`

Cadastro dos bancos suportados pela plataforma. É a raiz de toda a hierarquia — nenhum layout existe sem um banco.

```sql
CREATE TABLE banks (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(10)  UNIQUE NOT NULL,   -- código COMPE (ex: '341')
  name        VARCHAR(100) NOT NULL,
  short_name  VARCHAR(20)  NOT NULL,
  is_active   BOOLEAN      DEFAULT true NOT NULL,
  created_at  TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ  DEFAULT NOW() NOT NULL
);
```

| Campo | Descrição |
|---|---|
| `id` | Identificador interno UUID gerado automaticamente |
| `code` | Código COMPE do banco — único na tabela (ex: `341` = Itaú, `237` = Bradesco) |
| `name` | Razão social completa (ex: `Itaú Unibanco S.A.`) |
| `short_name` | Apelido para uso interno (ex: `itau`) |
| `is_active` | Permite desativar um banco sem apagar seus dados |

**Bancos cadastrados:**

| code | name | short_name |
|---|---|---|
| `341` | Itaú Unibanco S.A. | itau |
| `237` | Banco Bradesco S.A. | bradesco |

---

### `cnab_layouts`

Define **o que é um layout CNAB**: para qual banco, qual padrão (240 ou 400 posições), qual variante de operação (Cobrança, Pagamentos, Remessa, Retorno) e qual versão do manual bancário. Um banco pode ter múltiplos layouts.

```sql
CREATE TABLE cnab_layouts (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id      UUID         NOT NULL REFERENCES banks(id) ON DELETE RESTRICT,
  format       VARCHAR(30)  NOT NULL,
  version      VARCHAR(20)  NOT NULL,
  name         VARCHAR(150) NOT NULL,
  line_length  SMALLINT     NOT NULL,   -- 240 ou 400
  encoding     VARCHAR(20)  DEFAULT 'latin1' NOT NULL,
  is_active    BOOLEAN      DEFAULT true NOT NULL,
  notes        TEXT,
  created_at   TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  updated_at   TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  CONSTRAINT uq_layout UNIQUE (bank_id, format, version),
  CONSTRAINT chk_format CHECK (format IN (...)),
  CONSTRAINT chk_line_length CHECK (line_length IN (240, 400))
);
```

| Campo | Descrição |
|---|---|
| `bank_id` | FK para `banks.id` — `ON DELETE RESTRICT` (não apaga banco com layouts) |
| `format` | Nome do formato — ver valores aceitos abaixo |
| `version` | Versão do manual (ex: `10.4`, `2017.01`) |
| `line_length` | Comprimento fixo de cada linha: `240` ou `400` caracteres |
| `encoding` | Codificação do arquivo (`latin1` na maioria dos bancos brasileiros) |
| `is_active` | Permite versionar layouts sem apagar os antigos |
| `notes` | Observações livres sobre a especificação |

**Valores aceitos para `format`:**

| Valor | Descrição |
|---|---|
| `CNAB240` | CNAB 240 — Pagamento de Títulos (Segmento J) |
| `CNAB400` | CNAB 400 genérico (legado) |
| `CNAB400_REMESSA` | CNAB 400 — Cobrança Remessa |
| `CNAB400_RETORNO` | CNAB 400 — Cobrança Retorno |
| `CNAB240_COBRANCA_REM` | CNAB 240 — Cobrança Bancária Remessa (Seg. P/Q/R) |
| `CNAB240_COBRANCA_RET` | CNAB 240 — Cobrança Bancária Retorno (Seg. T/U) |

**Constraint:** `(bank_id, format, version)` é único — o mesmo layout não pode ser cadastrado duas vezes para o mesmo banco.

**Layouts cadastrados (Itaú 341):**

| format | version | name |
|---|---|---|
| `CNAB240` | `10.4` | Itaú CNAB 240 - Pagamento de Títulos |
| `CNAB400_REMESSA` | `2025.03` | Itaú CNAB 400 - Cobrança Remessa |
| `CNAB400_RETORNO` | `2025.03` | Itaú CNAB 400 - Cobrança Retorno |
| `CNAB240_COBRANCA_REM` | `2017.01` | Itaú CNAB 240 - Cobrança Bancária Remessa |
| `CNAB240_COBRANCA_RET` | `2017.01` | Itaú CNAB 240 - Cobrança Bancária Retorno |

**Layouts cadastrados (Bradesco 237):**

| format | version | name |
|---|---|---|
| `CNAB400_REMESSA` | `2022.08` | Bradesco CNAB 400 - Cobrança Remessa |
| `CNAB400_RETORNO` | `2022.08` | Bradesco CNAB 400 - Cobrança Retorno |

---

### `record_types`

Define os **tipos de linha** que existem dentro de um layout: Header de Arquivo, Header de Lote, Segmento P, Segmento Q, Trailer de Lote, etc. Cada tipo de registro sabe como se identificar dentro do arquivo pelo valor em uma posição específica.

```sql
CREATE TABLE record_types (
  id                          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  layout_id                   UUID         NOT NULL REFERENCES cnab_layouts(id) ON DELETE CASCADE,
  code                        VARCHAR(30)  NOT NULL,
  description                 VARCHAR(200) NOT NULL,
  category                    VARCHAR(10)  NOT NULL,   -- 'HEADER' | 'DETAIL' | 'TRAILER'
  identifier_start            SMALLINT     NOT NULL,   -- posição início (1-based)
  identifier_end              SMALLINT     NOT NULL,   -- posição fim (1-based)
  identifier_value            VARCHAR(20)  NOT NULL,   -- valor esperado
  secondary_identifier_start  SMALLINT,               -- nullable
  secondary_identifier_end    SMALLINT,               -- nullable
  secondary_identifier_value  VARCHAR(20),            -- nullable
  sort_order                  SMALLINT     NOT NULL,
  created_at                  TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  CONSTRAINT uq_record_type UNIQUE (layout_id, code),
  CONSTRAINT chk_category   CHECK (category IN ('HEADER', 'DETAIL', 'TRAILER'))
);
```

| Campo | Descrição |
|---|---|
| `layout_id` | FK para `cnab_layouts.id` — `ON DELETE CASCADE` |
| `code` | Código único dentro do layout (ex: `HEADER_ARQUIVO`, `DETALHE_P`, `TRAILER_LOTE`) |
| `category` | `HEADER`, `DETAIL` ou `TRAILER` — usado na contagem e validação cruzada |
| `identifier_start/end` | Posição (1-based) onde fica o campo identificador do tipo de registro |
| `identifier_value` | Valor esperado nessa posição (ex: `'0'` = Header Arquivo, `'3'` = Detalhe) |
| `secondary_identifier_*` | Identificador secundário — usado em CNAB 240 para distinguir segmentos (ex: posição 14 = `'P'`, `'Q'`, `'T'`) |
| `sort_order` | Ordem de exibição na interface |

**Como a identificação funciona:**

No CNAB 240, todos os registros de detalhe têm o valor `3` na posição 8 (identificador primário). Para diferenciar o Segmento P do Segmento Q, usa-se o identificador secundário na posição 14:

```
Posição 8 = '3' (DETALHE)  +  Posição 14 = 'P'  →  DETALHE_P
Posição 8 = '3' (DETALHE)  +  Posição 14 = 'Q'  →  DETALHE_Q
Posição 8 = '0' (HEADER)                         →  HEADER_ARQUIVO
```

**Tipos de registro por layout (Itaú CNAB 240 Cobrança Remessa):**

| code | category | Identificador | Descrição |
|---|---|---|---|
| `HEADER_ARQUIVO` | HEADER | pos 8 = `0` | Header de Arquivo |
| `HEADER_LOTE` | HEADER | pos 8 = `1` | Header de Lote |
| `DETALHE_P` | DETAIL | pos 8 = `3`, pos 14 = `P` | Dados do Título |
| `DETALHE_Q` | DETAIL | pos 8 = `3`, pos 14 = `Q` | Dados do Pagador |
| `DETALHE_R` | DETAIL | pos 8 = `3`, pos 14 = `R` | Descontos / Mora / Mensagens |
| `TRAILER_LOTE` | TRAILER | pos 8 = `5` | Trailer de Lote |
| `TRAILER_ARQUIVO` | TRAILER | pos 8 = `9` | Trailer de Arquivo |

---

### `field_definitions`

Define **cada campo individual** dentro de um tipo de registro — posição exata no arquivo, tamanho, tipo de dado e regras de validação. É a tabela mais granular e mais populosa do banco.

```sql
CREATE TABLE field_definitions (
  id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  record_type_id   UUID         NOT NULL REFERENCES record_types(id) ON DELETE CASCADE,
  name             VARCHAR(100) NOT NULL,
  label            VARCHAR(200) NOT NULL,
  description      TEXT,
  start_position   SMALLINT     NOT NULL,   -- 1-based, conforme FEBRABAN
  end_position     SMALLINT     NOT NULL,   -- 1-based
  length           SMALLINT     NOT NULL,
  data_type        VARCHAR(20)  NOT NULL,
  format_mask      VARCHAR(50),
  decimal_places   SMALLINT     DEFAULT 0 NOT NULL,
  is_required      BOOLEAN      DEFAULT true NOT NULL,
  is_filler        BOOLEAN      DEFAULT false NOT NULL,
  allowed_values   TEXT[],
  validation_rules JSONB,
  sort_order       SMALLINT     NOT NULL,
  created_at       TIMESTAMPTZ  DEFAULT NOW() NOT NULL
);
```

| Campo | Descrição |
|---|---|
| `record_type_id` | FK para `record_types.id` — `ON DELETE CASCADE` |
| `start_position` | Posição inicial do campo no arquivo (1-based, padrão FEBRABAN) |
| `end_position` | Posição final do campo |
| `length` | Tamanho em caracteres (`end_position - start_position + 1`) |
| `data_type` | Tipo do campo — ver valores abaixo |
| `format_mask` | Máscara de formatação (ex: `DDMMAAAA` para datas) |
| `decimal_places` | Casas decimais implícitas para campos `MONETARY` (ex: `2` = centavos) |
| `is_required` | Se `true`, campo em branco ou zerado gera erro de validação |
| `is_filler` | Campos de preenchimento fixo (brancos ou zeros) — ignorados na análise |
| `allowed_values` | Array de valores válidos (ex: `['1','2']` para CPF/CNPJ) |
| `validation_rules` | JSONB com regras avançadas (cross-record, regex, limites numéricos) |

**Valores aceitos para `data_type`:**

| Valor | Descrição | Exemplo |
|---|---|---|
| `ALPHA` | Alfanumérico, alinhado à esquerda, completado com espaços | Nome, endereço |
| `NUM` | Numérico, alinhado à direita, completado com zeros | Código do banco, agência |
| `DATE` | Data no formato `DDMMAAAA` (8 chars) | Vencimento, emissão |
| `MONETARY` | Numérico com `decimal_places` casas decimais implícitas | Valor do título |
| `ALPHANUM` | Misto sem regra de alinhamento definida | Nosso número em alguns bancos |
| `CONSTANT` | Valor fixo imutável — sempre o mesmo | Código do banco na linha |

**Estrutura de `validation_rules` (JSONB):**

```json
{
  "crossRecord": "lote_count",   // validação entre registros (totalizador)
  "minValue": 0,
  "maxValue": 9999999,
  "allowedPattern": "^[0-9]+$",
  "customMessage": "Deve ser numérico"
}
```

---

### `_migrations` (tabela interna)

Tabela de controle do runner de migrations. Armazena o nome de cada arquivo `.sql` já aplicado para garantir idempotência.

```sql
CREATE TABLE _migrations (
  name        TEXT        PRIMARY KEY,
  applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Não tem relação com nenhuma outra tabela — é gerenciada exclusivamente pelo `packages/database/src/migrate.ts`.

---

## Relacionamentos e Integridade Referencial

```
banks (1) ──────────────────────── (N) cnab_layouts
                                         ON DELETE RESTRICT
                                         (não apaga banco com layouts)

cnab_layouts (1) ───────────────── (N) record_types
                                         ON DELETE CASCADE
                                         (apaga layout → apaga seus tipos de registro)

record_types (1) ───────────────── (N) field_definitions
                                         ON DELETE CASCADE
                                         (apaga tipo → apaga seus campos)
```

O `RESTRICT` em `banks` é intencional: impede que um banco seja removido enquanto houver layouts cadastrados, evitando perda acidental de dados de layout.

---

## Como o Engine usa esse schema

O `CnabEngine` (`packages/cnab-engine`) é **agnóstico ao banco de dados**. Ele recebe os layouts via interface `LayoutProvider`, implementada pelo `DatabaseLayoutProvider` (`apps/web/lib/DatabaseLayoutProvider.ts`).

**Fluxo de identificação de um arquivo:**

1. Engine lê as duas primeiras linhas do arquivo
2. Chama `provider.identify(firstLine, secondLine)`
3. `DatabaseLayoutProvider` inspeciona:
   - Comprimento da linha → `240` ou `400`
   - Para CNAB 240: posições 10-11 da segunda linha (serviço `01`=Cobrança, `20`=Pagamentos)
   - Para Cobrança 240: posição 143 da primeira linha (`1`=Remessa, `2`=Retorno)
   - Para CNAB 400: posição 2 da primeira linha (`1`=Remessa, `2`=Retorno)
4. Chama `findLayoutByBankAndFormatName(bankCode, formatName)` no banco
5. Retorna `LayoutDefinition` com todos os `record_types` e `field_definitions` carregados

---

## Migrations aplicadas

| Arquivo | Conteúdo |
|---|---|
| `001_schema.sql` | Criação das tabelas (`banks`, `cnab_layouts`, `record_types`, `field_definitions`) |
| `002_seed_itau.sql` | Itaú `CNAB240` (Pagamentos, Seg. J) + `CNAB400` base |
| `003_cnab400_remessa_retorno.sql` | Substitui `CNAB400` por `CNAB400_REMESSA` e `CNAB400_RETORNO` |
| `004_itau400_2017.sql` | Layout completo Itaú CNAB 400 baseado no manual mar/2025 |
| `005_itau_cnab240_cobranca.sql` | Layouts `CNAB240_COBRANCA_REM` e `CNAB240_COBRANCA_RET` (FEBRABAN Jan/2017) |
| `006_bradesco_cnab400.sql` | Banco Bradesco (237) + `CNAB400_REMESSA` e `CNAB400_RETORNO` (Manual Ago/2022) |

Para rodar migrations pendentes:

```bash
cd packages/database
DATABASE_URL="postgresql://usuario:senha@host:5432/layoutbank" npm run migrate
```
