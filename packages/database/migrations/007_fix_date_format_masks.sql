-- ============================================================
-- LayoutBank — Migration 007: Corrige format_mask de campos DATE
--
-- Nas migrations anteriores, o format_mask não foi preenchido
-- para campos do tipo DATE. O engine caía no padrão 'DDMMAAAA'
-- para todos, mas campos CNAB 400 têm datas de 6 chars (DDMMAA).
--
-- Regra:
--   length = 6  → DDMMAA    (CNAB 400 — Cobrança)
--   length = 8  → DDMMAAAA  (CNAB 240 — FEBRABAN)
-- ============================================================

UPDATE field_definitions
SET format_mask = CASE
  WHEN length = 6 THEN 'DDMMAA'
  WHEN length = 8 THEN 'DDMMAAAA'
  ELSE 'DDMMAAAA'
END
WHERE data_type = 'DATE'
  AND format_mask IS NULL;
