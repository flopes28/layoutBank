-- ============================================================
-- LayoutBank — Migration 009: Corrige posições do header Bradesco
--
-- BRANCOS_1 no header remessa/retorno deve ir de 101 a 108 (8 chars),
-- não até 107 como estava.
-- Com isso UNID_DENSIDADE desloca para 109-110 (2 chars).
-- ============================================================

DO $$
DECLARE
  v_bank_id    UUID;
  v_rem_id     UUID;
  v_ret_id     UUID;
  v_rt_hdr_rem UUID;
  v_rt_hdr_ret UUID;

BEGIN

SELECT id INTO v_bank_id FROM banks WHERE code = '237';

SELECT id INTO v_rem_id FROM cnab_layouts
WHERE bank_id = v_bank_id AND format = 'CNAB400_REMESSA';

SELECT id INTO v_ret_id FROM cnab_layouts
WHERE bank_id = v_bank_id AND format = 'CNAB400_RETORNO';

SELECT id INTO v_rt_hdr_rem FROM record_types
WHERE layout_id = v_rem_id AND code = 'HEADER';

SELECT id INTO v_rt_hdr_ret FROM record_types
WHERE layout_id = v_ret_id AND code = 'HEADER';

-- ============================================================
-- HEADER REMESSA
-- ============================================================

-- BRANCOS_1: 101-107 (7) → 101-108 (8)
UPDATE field_definitions
SET end_position = 108, length = 8
WHERE record_type_id = v_rt_hdr_rem AND name = 'BRANCOS_1';

-- UNID_DENSIDADE: 108-110 (3) → 109-110 (2)
UPDATE field_definitions
SET start_position = 109, length = 2
WHERE record_type_id = v_rt_hdr_rem AND name = 'UNID_DENSIDADE';

-- HEADER RETORNO — DENSIDADE já estava em 101-108 (8 chars) na migration 006.
-- BRANCOS_1 do retorno começa em 109-379, não precisa de ajuste.

END $$;
