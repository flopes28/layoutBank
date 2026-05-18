-- ============================================================
-- LayoutBank — Migration 012: Corrige TRANSACAO RETORNO Bradesco
--
-- Layout do Arquivo-Retorno — Registro de Transação — Tipo 1
-- Manual de Procedimentos Bradesco CNAB 400 Ago/2022
--
-- Problemas identificados:
--
-- BLOCO A (018-037): Retorno tem COD_INSCRICAO + NUM_INSCRICAO (2-17)
--   corretos, mas posições 18-37 deveriam ser Zeros(3) +
--   IDENT_EMPRESA_BANCO(17). O DB tinha AGENCIA/CONTA/DAC herdados
--   da migration 006 (estrutura de remessa, não de retorno).
--
-- BLOCO B (063-070): Migration 010 aplicou erroneamente campos do
--   remessa (COD_BANCO_DEB/CAMPO_MULTA/PERC_MULTA). No retorno
--   essas posições são Zeros (8 chars).
--
-- BLOCO C (082-108): Posição 82 é "Uso do Banco" (não DIGITO_NN).
--   Posições 83-94 são Zeros (12). Posições 95-108 têm estrutura
--   específica do retorno: USO_BANCO(10) + INDIC_RATEIO(1) +
--   PAGAMENTO_PARCIAL(2) + CARTEIRA(1).
--
-- BLOCO D (293-295): BRANCOS_6 (3 chars) deve ser Branco(1) +
--   MOTIVO_REJEICAO (2) = Motivos das rejeições para ocorrências 109-110.
-- ============================================================

DO $$
DECLARE
  v_bank_id    UUID;
  v_ret_id     UUID;
  v_rt_det_ret UUID;

BEGIN

SELECT id INTO v_bank_id    FROM banks       WHERE code = '237';
SELECT id INTO v_ret_id     FROM cnab_layouts WHERE bank_id = v_bank_id AND format = 'CNAB400_RETORNO';
SELECT id INTO v_rt_det_ret FROM record_types WHERE layout_id = v_ret_id AND code = 'TRANSACAO';

-- Normaliza sort_order → start_position em toda a tabela
UPDATE field_definitions
SET sort_order = start_position
WHERE record_type_id = v_rt_det_ret;

-- ============================================================
-- BLOCO A: posições 018-037 — reestrutura identificação
-- ============================================================
-- PDF: COD_INSCRICAO(2-3) + NUM_INSCRICAO(4-17) ficam inalterados.
-- Posições 18-20 = Zeros (3). Posições 21-37 = Ident. Empresa (17).

DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret
  AND name IN ('AGENCIA', 'ZEROS', 'CONTA', 'DAC', 'DIGITO_AGENCIA', 'NRO_CONTROLE');

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'ZEROS_18_20',
   'Zeros',
   'Preencher com zeros',
   18, 20, 3, 'NUM', 0, false, true, 18),

  (v_rt_det_ret, 'IDENT_EMPRESA_BANCO',
   'Identificação da Empresa no Banco',
   'Zero + Carteira + Agência + Conta-Corrente do cedente — vide PDF pág. 16',
   21, 37, 17, 'ALPHA', 0, true, false, 21);

-- ============================================================
-- BLOCO B: posições 063-070 — reverte erro da migration 010
-- ============================================================
-- No retorno, essas posições são Zeros (não campos de multa do remessa).

DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret
  AND name IN ('COD_BANCO_DEB', 'CAMPO_MULTA', 'PERC_MULTA');

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'ZEROS_63_70',
   'Zeros',
   'Preencher com zeros',
   63, 70, 8, 'NUM', 0, false, true, 63);

-- ============================================================
-- BLOCO C: posições 082-108 — reestrutura campos retorno
-- ============================================================

-- 082: Uso do Banco (não DIGITO_NN como herdado do remessa)
UPDATE field_definitions
SET name        = 'USO_BANCO_82',
    label       = 'Uso do Banco',
    description = 'Uso do banco — posição 82',
    data_type   = 'ALPHA',
    is_required = false
WHERE record_type_id = v_rt_det_ret AND name = 'DIGITO_NN';

-- Remove campos 83-108 incorretos (herdados do remessa via mig 010)
DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret
  AND name IN ('DESC_BONIFICACAO', 'COND_EMISSAO_BOLETO', 'CARTEIRA', 'USO_BANCO_3');

-- Insere estrutura correta do retorno para posições 83-108:
-- 083-094 (12): Zeros
-- 095-104 (10): Uso do Banco
-- 105     (1):  Indicador de Rateio Crédito
-- 106-107 (2):  Pagamento Parcial
-- 108     (1):  Carteira
INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'ZEROS_83_94',
   'Zeros',
   'Preencher com zeros',
   83, 94, 12, 'NUM', 0, false, true, 83),

  (v_rt_det_ret, 'USO_BANCO_95_104',
   'Uso do Banco',
   'Uso exclusivo do banco — brancos',
   95, 104, 10, 'ALPHA', 0, false, true, 95),

  (v_rt_det_ret, 'INDIC_RATEIO',
   'Indicador de Rateio de Crédito',
   '"R" = indica rateio de crédito (opcional)',
   105, 105, 1, 'ALPHA', 0, false, false, 105),

  (v_rt_det_ret, 'PAGAMENTO_PARCIAL',
   'Pagamento Parcial',
   'Indicador de pagamento parcial do título',
   106, 107, 2, 'ALPHA', 0, false, false, 106),

  (v_rt_det_ret, 'CARTEIRA',
   'Carteira',
   'Código da carteira de cobrança',
   108, 108, 1, 'ALPHA', 0, false, false, 108);

-- ============================================================
-- BLOCO D: posições 293-295 — Branco + Motivo de Rejeição
-- ============================================================
-- PDF: 293(1) = Branco, 294-295(2) = Motivos das rejeições
--   para as ocorrências das posições 109-110

DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret AND name = 'BRANCOS_6';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'BRANCO_293',
   'Branco',
   'Preencher com branco',
   293, 293, 1, 'ALPHA', 0, false, true, 293),

  (v_rt_det_ret, 'MOTIVO_REJEICAO',
   'Motivo de Rejeição',
   'Motivos das rejeições para as ocorrências das posições 109-110 — vide PDF pág. 40',
   294, 295, 2, 'ALPHA', 0, false, false, 294);

END $$;
