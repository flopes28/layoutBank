-- ============================================================
-- LayoutBank — Migration 008: Corrige campos Bradesco CNAB 400
--
-- Problemas identificados ao validar arquivo real de remessa:
-- 1. DENSIDADE no Header: definido como NUM mas contém ALPHA ("MX...")
--    → Quebrar em UNID_DENSIDADE (ALPHA, 108-110) + NRO_SEQ_REMESSA move para 111-117
-- 2. Campos intermediários do detalhe definidos como BRANCOS (filler)
--    mas têm conteúdo numérico real no Bradesco
-- 3. CARTEIRA e ACEITE marcados como required mas ficam em branco
-- 4. PRAZO definido como NUM mas banco deixa com espaços
-- ============================================================

DO $$
DECLARE
  v_bank_id       UUID;
  v_rem_id        UUID;
  v_ret_id        UUID;
  v_rt_hdr_rem    UUID;
  v_rt_hdr_ret    UUID;
  v_rt_det_rem    UUID;
  v_rt_det_ret    UUID;

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

SELECT id INTO v_rt_det_rem FROM record_types
WHERE layout_id = v_rem_id AND code = 'DETALHE_BOLETO';

SELECT id INTO v_rt_det_ret FROM record_types
WHERE layout_id = v_ret_id AND code = 'TRANSACAO';

-- ============================================================
-- 1. HEADER REMESSA — corrige DENSIDADE e NRO_SEQ_REMESSA
-- ============================================================

-- Remove campo DENSIDADE (era NUM, conteúdo real é alfanumérico)
DELETE FROM field_definitions
WHERE record_type_id = v_rt_hdr_rem AND name = 'DENSIDADE';

-- Insere UNID_DENSIDADE como ALPHA (pos 108-110, ex: " MX", "BPI")
INSERT INTO field_definitions
  (record_type_id, name, label, description, start_position, end_position, length,
   data_type, decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_hdr_rem, 'UNID_DENSIDADE', 'Unidade de Densidade', 'Unidade de densidade da mídia (ex: BPI, MX)',
   108, 110, 3, 'ALPHA', 0, false, false, 12);

-- Move NRO_SEQ_REMESSA de 118-124 para 111-117
UPDATE field_definitions
SET start_position = 111, end_position = 117, length = 7
WHERE record_type_id = v_rt_hdr_rem AND name = 'NRO_SEQ_REMESSA';

-- Expande BRANCOS_2 para cobrir 118-394 (era 125-394)
UPDATE field_definitions
SET start_position = 118, end_position = 394, length = 277
WHERE record_type_id = v_rt_hdr_rem AND name = 'BRANCOS_2';

-- ============================================================
-- 2. HEADER RETORNO — corrige DENSIDADE
-- ============================================================

-- DENSIDADE no retorno header (101-108, NUM) → ALPHA, not required
UPDATE field_definitions
SET data_type = 'ALPHA', is_required = false
WHERE record_type_id = v_rt_hdr_ret AND name = 'DENSIDADE';

-- ============================================================
-- 3. DETALHE_BOLETO REMESSA — corrige campos intermediários
-- ============================================================

-- ZEROS (22-23): no Bradesco é COMPLEMENTO DA AGÊNCIA, não zeros filler
UPDATE field_definitions
SET name        = 'COMPLEMENTO_AGENCIA',
    label       = 'Complemento da Agência',
    description = 'Complemento da agência no Bradesco (varia por contrato)',
    data_type   = 'ALPHANUM',
    is_filler   = false
WHERE record_type_id = v_rt_det_rem AND name = 'ZEROS';

-- BRANCOS_1 (30): no Bradesco contém dígito ou código, não branco
UPDATE field_definitions
SET name        = 'DIGITO_AGENCIA',
    label       = 'Dígito da Agência',
    description = 'Dígito verificador da agência Bradesco',
    data_type   = 'NUM',
    is_filler   = false,
    is_required = false
WHERE record_type_id = v_rt_det_rem AND name = 'BRANCOS_1';

-- BRANCOS_2 (63-70): no Bradesco é numérico (uso banco), não branco
UPDATE field_definitions
SET name        = 'USO_BANCO_1',
    label       = 'Uso do Banco',
    description = 'Uso exclusivo Bradesco — campo numérico',
    data_type   = 'NUM',
    is_filler   = false,
    is_required = false
WHERE record_type_id = v_rt_det_rem AND name = 'BRANCOS_2';

-- BRANCOS_3 (83-93): no Bradesco tem conteúdo numérico (parte do nosso número banco)
UPDATE field_definitions
SET name        = 'USO_BANCO_2',
    label       = 'Uso do Banco',
    description = 'Uso exclusivo Bradesco — complemento nosso número',
    data_type   = 'ALPHA',
    is_filler   = false,
    is_required = false
WHERE record_type_id = v_rt_det_rem AND name = 'BRANCOS_3';

-- CARTEIRA (94-96): pode estar em branco no arquivo
UPDATE field_definitions
SET is_required = false,
    data_type   = 'ALPHA'
WHERE record_type_id = v_rt_det_rem AND name = 'CARTEIRA';

-- BRANCOS_4 (97-107): contém dados no Bradesco
UPDATE field_definitions
SET name        = 'USO_BANCO_3',
    label       = 'Uso do Banco',
    description = 'Uso exclusivo Bradesco',
    data_type   = 'ALPHA',
    is_filler   = false,
    is_required = false
WHERE record_type_id = v_rt_det_rem AND name = 'BRANCOS_4';

-- ACEITE (108): no Bradesco pode vir em branco
UPDATE field_definitions
SET is_required = false
WHERE record_type_id = v_rt_det_rem AND name = 'ACEITE';

-- ACEITE_2 (150): também pode vir em branco
UPDATE field_definitions
SET is_required = false
WHERE record_type_id = v_rt_det_rem AND name = 'ACEITE_2';

-- PRAZO (392-393): banco envia espaços em vez de zeros → ALPHA
UPDATE field_definitions
SET data_type = 'ALPHA'
WHERE record_type_id = v_rt_det_rem AND name = 'PRAZO';

-- ============================================================
-- 4. TRANSACAO RETORNO — corrige campos similares
-- ============================================================

-- BRANCOS_1 (30): pode ter conteúdo no retorno também
UPDATE field_definitions
SET name='DIGITO_AGENCIA', label='Dígito da Agência',
    data_type='NUM', is_filler=false, is_required=false
WHERE record_type_id = v_rt_det_ret AND name = 'BRANCOS_1';

-- BRANCOS_2 (63-70): numérico no retorno
UPDATE field_definitions
SET name='USO_BANCO_1', label='Uso do Banco',
    data_type='NUM', is_filler=false, is_required=false
WHERE record_type_id = v_rt_det_ret AND name = 'BRANCOS_2';

-- BRANCOS_3 (83-93): conteúdo no retorno
UPDATE field_definitions
SET name='USO_BANCO_2', label='Uso do Banco',
    data_type='ALPHA', is_filler=false, is_required=false
WHERE record_type_id = v_rt_det_ret AND name = 'BRANCOS_3';

-- CARTEIRA (94-96): pode estar em branco
UPDATE field_definitions
SET is_required=false, data_type='ALPHA'
WHERE record_type_id = v_rt_det_ret AND name = 'CARTEIRA';

-- BRANCOS_4 (97-108): conteúdo no retorno
UPDATE field_definitions
SET name='USO_BANCO_3', label='Uso do Banco',
    data_type='ALPHA', is_filler=false, is_required=false
WHERE record_type_id = v_rt_det_ret AND name = 'BRANCOS_4';

-- COD_LIQUIDACAO (393-394): pode vir em branco
UPDATE field_definitions
SET is_required=false
WHERE record_type_id = v_rt_det_ret AND name = 'COD_LIQUIDACAO';

END $$;
