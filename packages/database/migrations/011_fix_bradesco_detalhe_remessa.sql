-- ============================================================
-- LayoutBank — Migration 011: Corrige DETALHE REMESSA Bradesco
--
-- Três blocos incorretos identificados via PDF oficial Ago/2022:
--
-- BLOCO A (002-037): O DB tinha CPF/CNPJ do cedente em 2-17, mas
--   o PDF define Agência/Conta de Débito do Pagador (déb. automático)
--   e a Identificação da Empresa Beneficiária no Banco (021-037).
--
-- BLOCO B (094-108): O DB tinha CARTEIRA (94-96) + USO_BANCO_3 + ACEITE,
--   mas o PDF define Ident. Débito Automático + Ident. Operação Banco
--   + Indicador Rateio + Endereço Aviso + Qtd. Pagamentos.
--
-- BLOCO C (335-394): O DB fragmentava em CIDADE/UF/BENEF_FINAL/PRAZO,
--   mas o PDF define um campo único de 60 chars:
--   "Beneficiário Final ou 2ª Mensagem".
--
-- Também: renomeia ACEITE_2 (150) para IDENT_ACEITE conforme PDF.
-- ============================================================

DO $$
DECLARE
  v_bank_id    UUID;
  v_rem_id     UUID;
  v_rt_det_rem UUID;

BEGIN

SELECT id INTO v_bank_id    FROM banks         WHERE code = '237';
SELECT id INTO v_rem_id     FROM cnab_layouts   WHERE bank_id = v_bank_id AND format = 'CNAB400_REMESSA';
SELECT id INTO v_rt_det_rem FROM record_types   WHERE layout_id = v_rem_id AND code = 'DETALHE_BOLETO';

-- ============================================================
-- BLOCO A: posições 002-037 — reestrutura identificação pagador
-- ============================================================
-- PDF:
--  002-006 (5) Agência de Débito do Pagador (opcional, débito automático)
--  007     (1) Dígito da Agência de Débito (opcional)
--  008-012 (5) Razão da Conta-Corrente (opcional)
--  013-019 (7) Conta-Corrente do Pagador (opcional)
--  020     (1) Dígito da Conta-Corrente (opcional)
--  021-037 (17) Identificação da Empresa Beneficiária no Banco
--             = Zero + Carteira + Agência + Conta-Corrente do cedente

DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_rem
  AND name IN ('COD_INSCRICAO', 'NUM_INSCRICAO', 'AGENCIA',
               'COMPLEMENTO_AGENCIA', 'CONTA', 'DAC',
               'DIGITO_AGENCIA', 'NRO_CONTROLE');

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_rem, 'AGENCIA_DEBITO',
   'Agência de Débito',
   'Código da agência do pagador para débito em conta-corrente (opcional)',
   2, 6, 5, 'ALPHA', 0, false, false, 2),

  (v_rt_det_rem, 'DIGITO_AGENCIA_DEB',
   'Dígito da Agência de Débito',
   'Dígito verificador da agência de débito do pagador (opcional)',
   7, 7, 1, 'ALPHA', 0, false, false, 7),

  (v_rt_det_rem, 'RAZAO_CC',
   'Razão da Conta-Corrente',
   'Razão da conta-corrente do pagador (opcional)',
   8, 12, 5, 'ALPHA', 0, false, false, 8),

  (v_rt_det_rem, 'CONTA_CORRENTE_DEB',
   'Conta-Corrente de Débito',
   'Número da conta-corrente do pagador para débito automático (opcional)',
   13, 19, 7, 'ALPHA', 0, false, false, 13),

  (v_rt_det_rem, 'DIGITO_CC',
   'Dígito da Conta-Corrente',
   'Dígito verificador da conta-corrente do pagador (opcional)',
   20, 20, 1, 'ALPHA', 0, false, false, 20),

  (v_rt_det_rem, 'IDENT_EMPRESA_BANCO',
   'Identificação da Empresa no Banco',
   'Zero + Carteira + Agência + Conta-Corrente do cedente — vide PDF pág. 16',
   21, 37, 17, 'ALPHA', 0, true, false, 21);

-- ============================================================
-- BLOCO B: posições 094-108 — reestrutura campos déb. automático
-- ============================================================
-- PDF:
--  094     (1) Ident. se emite Boleto para Débito Automático
--  095-104 (10) Identificação da Operação do Banco (brancos)
--  105     (1) Indicador Rateio Crédito ("R")
--  106     (1) Endereçamento p/ Aviso de Débito Automático
--  107-108 (2) Quantidade de Pagamentos

DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_rem
  AND name IN ('CARTEIRA', 'USO_BANCO_3', 'ACEITE');

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_rem, 'IDENT_DEBITO_AUTO',
   'Ident. Emissão Boleto / Débito Auto.',
   'N = não registra na cobrança; outro = registra e emite boleto',
   94, 94, 1, 'ALPHA', 0, false, false, 94),

  (v_rt_det_rem, 'IDENT_OP_BANCO',
   'Identificação da Operação do Banco',
   'Brancos',
   95, 104, 10, 'ALPHA', 0, false, true, 95),

  (v_rt_det_rem, 'INDIC_RATEIO',
   'Indicador de Rateio de Crédito',
   '"R" indica rateio de crédito (opcional)',
   105, 105, 1, 'ALPHA', 0, false, false, 105),

  (v_rt_det_rem, 'ENDERECO_AVISO_DEBITO',
   'Endereçamento p/ Aviso Débito Auto.',
   'Endereçamento para aviso de débito automático em conta-corrente',
   106, 106, 1, 'ALPHA', 0, false, false, 106),

  (v_rt_det_rem, 'QTD_PAGAMENTOS',
   'Quantidade de Pagamentos',
   'Quantidade de pagamentos para débito automático (opcional)',
   107, 108, 2, 'NUM', 0, false, false, 107);

-- ============================================================
-- BLOCO C: posições 335-394 — campo único de 60 chars conforme PDF
-- ============================================================

DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_rem
  AND name IN ('CIDADE', 'UF', 'BENEF_FINAL', 'BRANCOS_5', 'PRAZO', 'BRANCOS_6');

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_rem, 'BENEF_FINAL_MENSAGEM_2',
   'Beneficiário Final ou 2ª Mensagem',
   'Nome do beneficiário final do título ou 2ª mensagem ao pagador — vide PDF pág. 20',
   335, 394, 60, 'ALPHA', 0, false, false, 335);

-- ============================================================
-- Renomeia ACEITE_2 (150) para IDENT_ACEITE conforme PDF
-- PDF: "Identificação = Sempre N"
-- ============================================================

UPDATE field_definitions
SET name        = 'IDENT_ACEITE',
    label       = 'Identificação',
    description = 'Sempre "N" conforme PDF Bradesco'
WHERE record_type_id = v_rt_det_rem AND name = 'ACEITE_2';

END $$;
