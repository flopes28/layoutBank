-- ============================================================
-- LayoutBank — Migration 001: Schema inicial
-- ============================================================

-- Bancos cadastrados
CREATE TABLE IF NOT EXISTS banks (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(10)  UNIQUE NOT NULL,
  name        VARCHAR(100) NOT NULL,
  short_name  VARCHAR(20)  NOT NULL,
  is_active   BOOLEAN      DEFAULT true NOT NULL,
  created_at  TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ  DEFAULT NOW() NOT NULL
);

-- Layouts por banco e formato
CREATE TABLE IF NOT EXISTS cnab_layouts (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id      UUID         NOT NULL REFERENCES banks(id) ON DELETE RESTRICT,
  format       VARCHAR(10)  NOT NULL,
  version      VARCHAR(20)  NOT NULL,
  name         VARCHAR(150) NOT NULL,
  line_length  SMALLINT     NOT NULL,
  encoding     VARCHAR(20)  DEFAULT 'latin1' NOT NULL,
  is_active    BOOLEAN      DEFAULT true NOT NULL,
  notes        TEXT,
  created_at   TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  updated_at   TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  CONSTRAINT uq_layout UNIQUE (bank_id, format, version),
  CONSTRAINT chk_format      CHECK (format IN ('CNAB240', 'CNAB400')),
  CONSTRAINT chk_line_length CHECK (line_length IN (240, 400))
);

-- Tipos de registro dentro de cada layout
CREATE TABLE IF NOT EXISTS record_types (
  id                          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  layout_id                   UUID         NOT NULL REFERENCES cnab_layouts(id) ON DELETE CASCADE,
  code                        VARCHAR(30)  NOT NULL,
  description                 VARCHAR(200) NOT NULL,
  category                    VARCHAR(10)  NOT NULL,
  identifier_start            SMALLINT     NOT NULL,
  identifier_end              SMALLINT     NOT NULL,
  identifier_value            VARCHAR(20)  NOT NULL,
  secondary_identifier_start  SMALLINT,
  secondary_identifier_end    SMALLINT,
  secondary_identifier_value  VARCHAR(20),
  sort_order                  SMALLINT     NOT NULL,
  created_at                  TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  CONSTRAINT uq_record_type   UNIQUE (layout_id, code),
  CONSTRAINT chk_category     CHECK (category IN ('HEADER', 'DETAIL', 'TRAILER'))
);

-- Definição de cada campo
CREATE TABLE IF NOT EXISTS field_definitions (
  id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  record_type_id   UUID         NOT NULL REFERENCES record_types(id) ON DELETE CASCADE,
  name             VARCHAR(100) NOT NULL,
  label            VARCHAR(200) NOT NULL,
  description      TEXT,
  start_position   SMALLINT     NOT NULL,
  end_position     SMALLINT     NOT NULL,
  length           SMALLINT     NOT NULL,
  data_type        VARCHAR(20)  NOT NULL,
  format_mask      VARCHAR(50),
  decimal_places   SMALLINT     DEFAULT 0 NOT NULL,
  is_required      BOOLEAN      DEFAULT true NOT NULL,
  is_filler        BOOLEAN      DEFAULT false NOT NULL,
  allowed_values   TEXT[],
  validation_rules JSONB,
  sort_order       SMALLINT     NOT NULL,
  created_at       TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
  CONSTRAINT chk_positions  CHECK (start_position <= end_position),
  CONSTRAINT chk_length     CHECK (length = end_position - start_position + 1),
  CONSTRAINT chk_data_type  CHECK (data_type IN ('ALPHA','NUM','DATE','MONETARY','ALPHANUM','CONSTANT'))
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_field_def_record_type ON field_definitions(record_type_id);
CREATE INDEX IF NOT EXISTS idx_record_type_layout    ON record_types(layout_id);
CREATE INDEX IF NOT EXISTS idx_cnab_layout_bank      ON cnab_layouts(bank_id);
CREATE INDEX IF NOT EXISTS idx_bank_code             ON banks(code);
