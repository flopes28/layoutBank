-- ============================================================
-- LayoutBank — Migration 010: Corrige campos Bradesco v2
--
-- Correções baseadas no Manual CNAB 400 Bradesco Ago/2022:
-- 1. HEADER REMESSA: UNID_DENSIDADE → IDENT_SISTEMA
-- 2. HEADER RETORNO: adiciona NRO_AVISO_BANCARIO (109-113)
-- 3. DETALHE REMESSA: desmembra USO_BANCO_1 (63-70) → 3 campos
-- 4. DETALHE REMESSA: desmembra USO_BANCO_2 (83-93) → 2 campos
-- 5. DETALHE REMESSA: BAIRRO (315-326) → MENSAGEM_1
-- 6. DETALHE REMESSA: CEP (327-334, 8) → CEP (327-331, 5) + SUFIXO_CEP (332-334, 3)
-- 7. TRANSACAO RETORNO: mesmas correções dos itens 3 e 4
-- 8. TRAILER RETORNO: adiciona NRO_AVISO_BANCARIO (40-47)
--
-- Estratégia sort_order: normalizado para = start_position em todos
-- os record_types modificados, garantindo ordem correta de exibição.
-- ============================================================

DO $$
DECLARE
  v_bank_id    UUID;
  v_rem_id     UUID;
  v_ret_id     UUID;
  v_rt_hdr_rem UUID;
  v_rt_hdr_ret UUID;
  v_rt_det_rem UUID;
  v_rt_det_ret UUID;
  v_rt_trl_ret UUID;

BEGIN

SELECT id INTO v_bank_id FROM banks WHERE code = '237';
SELECT id INTO v_rem_id   FROM cnab_layouts WHERE bank_id = v_bank_id AND format = 'CNAB400_REMESSA';
SELECT id INTO v_ret_id   FROM cnab_layouts WHERE bank_id = v_bank_id AND format = 'CNAB400_RETORNO';

SELECT id INTO v_rt_hdr_rem FROM record_types WHERE layout_id = v_rem_id AND code = 'HEADER';
SELECT id INTO v_rt_hdr_ret FROM record_types WHERE layout_id = v_ret_id AND code = 'HEADER';
SELECT id INTO v_rt_det_rem FROM record_types WHERE layout_id = v_rem_id AND code = 'DETALHE_BOLETO';
SELECT id INTO v_rt_det_ret FROM record_types WHERE layout_id = v_ret_id AND code = 'TRANSACAO';
SELECT id INTO v_rt_trl_ret FROM record_types WHERE layout_id = v_ret_id AND code = 'TRAILER';

-- ============================================================
-- 1. HEADER REMESSA — UNID_DENSIDADE → IDENT_SISTEMA
-- ============================================================

UPDATE field_definitions
SET name        = 'IDENT_SISTEMA',
    label       = 'Identificação do Sistema',
    description = 'Identificação do sistema — valor fixo "MX"',
    data_type   = 'ALPHA'
WHERE record_type_id = v_rt_hdr_rem AND name = 'UNID_DENSIDADE';

-- ============================================================
-- 2. HEADER RETORNO — adiciona NRO_AVISO_BANCARIO (109-113)
-- ============================================================

-- Normaliza sort_order para = start_position no header retorno
UPDATE field_definitions
SET sort_order = start_position
WHERE record_type_id = v_rt_hdr_ret;

-- Recua BRANCOS_1: era (109-379, 271) → passa a (114-379, 266)
UPDATE field_definitions
SET start_position = 114, length = 266
WHERE record_type_id = v_rt_hdr_ret AND name = 'BRANCOS_1';

-- Insere campo com sort_order = start_position (109), fica entre DENSIDADE e BRANCOS_1
INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_hdr_ret, 'NRO_AVISO_BANCARIO', 'Nº do Aviso Bancário',
   'Número do aviso bancário emitido pelo Bradesco',
   109, 113, 5, 'ALPHA', 0, false, false, 109);

-- ============================================================
-- 3. DETALHE REMESSA — normaliza sort_order e desmembra campos
-- ============================================================

-- Normaliza sort_order → start_position para toda a tabela
UPDATE field_definitions
SET sort_order = start_position
WHERE record_type_id = v_rt_det_rem;

-- 3a. Desmembra USO_BANCO_1 (63-70, 8) → 3 campos do PDF
DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_rem AND name = 'USO_BANCO_1';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_rem, 'COD_BANCO_DEB',  'Código do Banco Debitado',
   'Código do banco debitado na câmara de compensação',
   63, 65, 3, 'NUM', 0, false, false, 63),
  (v_rt_det_rem, 'CAMPO_MULTA',    'Campo de Multa',
   '0 = sem multa, 2 = percentual de multa',
   66, 66, 1, 'ALPHA', 0, false, false, 66),
  (v_rt_det_rem, 'PERC_MULTA',     'Percentual de Multa',
   'Percentual de multa cobrado após vencimento (2 decimais implícitos)',
   67, 70, 4, 'NUM', 0, false, false, 67);

-- 3b. Desmembra USO_BANCO_2 (83-93, 11) → 2 campos do PDF
DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_rem AND name = 'USO_BANCO_2';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_rem, 'DESC_BONIFICACAO',    'Desconto Bonificação/Dia',
   'Valor de desconto por dia de antecipação de pagamento (2 decimais)',
   83, 92, 10, 'NUM', 0, false, false, 83),
  (v_rt_det_rem, 'COND_EMISSAO_BOLETO', 'Condição de Emissão do Boleto',
   '2 = emite empresa, 4 = emite banco, 9 = a cargo do banco',
   93, 93, 1, 'ALPHA', 0, false, false, 93);

-- 3c. BAIRRO (315-326) → MENSAGEM_1 conforme PDF
UPDATE field_definitions
SET name        = 'MENSAGEM_1',
    label       = '1ª Mensagem ao Pagador',
    description = 'Primeira linha de mensagem livre ao pagador no boleto'
WHERE record_type_id = v_rt_det_rem AND name = 'BAIRRO';

-- 3d. CEP (327-334, 8) → CEP (327-331, 5) + SUFIXO_CEP (332-334, 3)
UPDATE field_definitions
SET end_position = 331, length = 5
WHERE record_type_id = v_rt_det_rem AND name = 'CEP';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_rem, 'SUFIXO_CEP', 'Sufixo do CEP',
   'Complemento do CEP do pagador (3 dígitos)',
   332, 334, 3, 'NUM', 0, false, false, 332);

-- ============================================================
-- 4. TRANSACAO RETORNO — mesmas correções dos campos 63-93
-- ============================================================

-- Normaliza sort_order → start_position
UPDATE field_definitions
SET sort_order = start_position
WHERE record_type_id = v_rt_det_ret;

-- 4a. Desmembra USO_BANCO_1 (63-70, 8)
DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret AND name = 'USO_BANCO_1';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'COD_BANCO_DEB',  'Código do Banco Debitado',
   'Código do banco debitado na câmara de compensação',
   63, 65, 3, 'NUM', 0, false, false, 63),
  (v_rt_det_ret, 'CAMPO_MULTA',    'Campo de Multa',
   '0 = sem multa, 2 = percentual de multa',
   66, 66, 1, 'ALPHA', 0, false, false, 66),
  (v_rt_det_ret, 'PERC_MULTA',     'Percentual de Multa',
   'Percentual de multa cobrado após vencimento (2 decimais implícitos)',
   67, 70, 4, 'NUM', 0, false, false, 67);

-- 4b. Desmembra USO_BANCO_2 (83-93, 11)
DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret AND name = 'USO_BANCO_2';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'DESC_BONIFICACAO',    'Desconto Bonificação/Dia',
   'Valor de desconto por dia de antecipação (2 decimais)',
   83, 92, 10, 'NUM', 0, false, false, 83),
  (v_rt_det_ret, 'COND_EMISSAO_BOLETO', 'Condição de Emissão do Boleto',
   '2 = emite empresa, 4 = emite banco, 9 = a cargo do banco',
   93, 93, 1, 'ALPHA', 0, false, false, 93);

-- ============================================================
-- 5. TRAILER RETORNO — adiciona NRO_AVISO_BANCARIO (40-47)
-- ============================================================

-- Normaliza sort_order → start_position
UPDATE field_definitions
SET sort_order = start_position
WHERE record_type_id = v_rt_trl_ret;

-- BRANCOS_2 era (40-394, 355) → passa a (48-394, 347) para abrir espaço
UPDATE field_definitions
SET start_position = 48, end_position = 394, length = 347
WHERE record_type_id = v_rt_trl_ret AND name = 'BRANCOS_2';

-- Insere NRO_AVISO_BANCARIO em (40-47, 8)
INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_trl_ret, 'NRO_AVISO_BANCARIO', 'Nº do Aviso Bancário',
   'Número do aviso bancário do Bradesco (referência do lote de crédito)',
   40, 47, 8, 'ALPHA', 0, false, false, 40);

END $$;
