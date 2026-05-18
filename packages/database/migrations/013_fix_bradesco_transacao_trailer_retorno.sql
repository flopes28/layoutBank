-- ============================================================
-- LayoutBank — Migration 013: Corrige TRANSACAO (302-383) e
--   expande TRAILER RETORNO Bradesco CNAB 400
--
-- TRANSACAO RETORNO — posições 302-383:
--   302-305 (4):  Brancos
--   306-315 (10): Motivos de Instruções Canceladas (5 x 2 chars)
--   316-318 (3):  Brancos (já correto)
--   319-328 (10): Motivos de Rejeição (já correto)
--   329-358 (30): Nome do Pagador (já correto)
--   359-368 (10): Brancos (já correto)
--   369-370 (2):  Nº do Cartório
--   371-380 (10): Nº do Protocolo
--   381-383 (3):  Brancos
--
-- TRAILER RETORNO — BRANCOS_2 (48-394, 347) detalhado em:
--   048-057 (10):  Brancos
--   13 x blocos de ocorrência (Qtd 6 + Valor 16 = 22 chars cada)
--     Ocorrências: 06, 02, 03, 09, 10, 13, 14, 15, 16, 17, 11, 12, 25
--     Cobrindo posições 058-343
--   344-362 (19): Brancos
--   363-374 (12): Qtd Total dos Rateios Efetuados
--   375-385 (11): Valor Total dos Rateios Efetuados
--   386-394 (9):  Brancos
-- ============================================================

DO $$
DECLARE
  v_bank_id    UUID;
  v_ret_id     UUID;
  v_rt_det_ret UUID;
  v_rt_trl_ret UUID;

BEGIN

SELECT id INTO v_bank_id    FROM banks       WHERE code = '237';
SELECT id INTO v_ret_id     FROM cnab_layouts WHERE bank_id = v_bank_id AND format = 'CNAB400_RETORNO';
SELECT id INTO v_rt_det_ret FROM record_types WHERE layout_id = v_ret_id AND code = 'TRANSACAO';
SELECT id INTO v_rt_trl_ret FROM record_types WHERE layout_id = v_ret_id AND code = 'TRAILER';

-- ============================================================
-- PARTE 1: TRANSACAO RETORNO — posições 302-383
-- ============================================================

-- 1a. Posições 302-315: substitui BRANCOS_7 + INSTR_CANCELADA
DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret
  AND name IN ('BRANCOS_7', 'INSTR_CANCELADA');

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'BRANCOS_302_305',
   'Brancos',
   'Preencher com brancos',
   302, 305, 4, 'ALPHA', 0, false, true, 302),

  (v_rt_det_ret, 'MOTIVOS_INSTRUCAO',
   'Motivos de Instruções Canceladas',
   'Códigos de ocorrência das instruções canceladas — 5 x 2 chars',
   306, 315, 10, 'ALPHA', 0, false, false, 306);

-- 1b. Renomeia BRANCOS_8 para BRANCOS_316_318 (316-318)
UPDATE field_definitions
SET name = 'BRANCOS_316_318'
WHERE record_type_id = v_rt_det_ret AND name = 'BRANCOS_8';

-- 1c. Posições 369-383: substitui SACADOR por Cartório + Protocolo
DELETE FROM field_definitions
WHERE record_type_id = v_rt_det_ret AND name = 'SACADOR';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES
  (v_rt_det_ret, 'NRO_CARTORIO',
   'Nº do Cartório',
   'Número do cartório onde o título foi protestado',
   369, 370, 2, 'ALPHA', 0, false, false, 369),

  (v_rt_det_ret, 'NRO_PROTOCOLO',
   'Nº do Protocolo',
   'Número do protocolo do cartório',
   371, 380, 10, 'ALPHA', 0, false, false, 371),

  (v_rt_det_ret, 'BRANCOS_381_383',
   'Brancos',
   'Preencher com brancos',
   381, 383, 3, 'ALPHA', 0, false, true, 381);

-- ============================================================
-- PARTE 2: TRAILER RETORNO — expande BRANCOS_2 (48-394, 347)
-- ============================================================
-- Estrutura: 10 brancos + 13 blocos × 22 chars + 19 brancos + 12+11+9

DELETE FROM field_definitions
WHERE record_type_id = v_rt_trl_ret AND name = 'BRANCOS_2';

INSERT INTO field_definitions
  (record_type_id, name, label, description,
   start_position, end_position, length, data_type,
   decimal_places, is_required, is_filler, sort_order)
VALUES

-- Brancos entre NRO_AVISO_BANCARIO (40-47) e contadores
(v_rt_trl_ret, 'BRANCOS_048_057', 'Brancos', 'Preencher com brancos',
 48, 57, 10, 'ALPHA', 0, false, true, 48),

-- Bloco 01 — Ocorrência 06: Liquidação Bancária (058-079)
(v_rt_trl_ret, 'QTD_OC_06', 'Qtd. Registros — Ocorrência 06 (Liquidação)',
 'Quantidade de títulos liquidados bancariamente',
 58, 63, 6, 'NUM', 0, false, false, 58),
(v_rt_trl_ret, 'VL_OC_06',  'Valor — Ocorrência 06 (Liquidação)',
 'Valor total dos títulos liquidados (2 decimais)',
 64, 79, 16, 'MONETARY', 2, false, false, 64),

-- Bloco 02 — Ocorrência 02: Entradas Confirmadas (080-101)
(v_rt_trl_ret, 'QTD_OC_02', 'Qtd. Registros — Ocorrência 02 (Entradas Confirmadas)',
 'Quantidade de entradas confirmadas pelo banco',
 80, 85, 6, 'NUM', 0, false, false, 80),
(v_rt_trl_ret, 'VL_OC_02',  'Valor — Ocorrência 02 (Entradas Confirmadas)',
 'Valor total das entradas confirmadas (2 decimais)',
 86, 101, 16, 'MONETARY', 2, false, false, 86),

-- Bloco 03 — Ocorrência 03: Entradas Rejeitadas (102-123)
(v_rt_trl_ret, 'QTD_OC_03', 'Qtd. Registros — Ocorrência 03 (Entradas Rejeitadas)',
 'Quantidade de entradas rejeitadas pelo banco',
 102, 107, 6, 'NUM', 0, false, false, 102),
(v_rt_trl_ret, 'VL_OC_03',  'Valor — Ocorrência 03 (Entradas Rejeitadas)',
 'Valor total das entradas rejeitadas (2 decimais)',
 108, 123, 16, 'MONETARY', 2, false, false, 108),

-- Bloco 04 — Ocorrência 09: Baixados (124-145)
(v_rt_trl_ret, 'QTD_OC_09', 'Qtd. Registros — Ocorrência 09 (Baixados)',
 'Quantidade de títulos baixados',
 124, 129, 6, 'NUM', 0, false, false, 124),
(v_rt_trl_ret, 'VL_OC_09',  'Valor — Ocorrência 09 (Baixados)',
 'Valor total dos títulos baixados (2 decimais)',
 130, 145, 16, 'MONETARY', 2, false, false, 130),

-- Bloco 05 — Ocorrência 10: Liquidados com Baixa (146-167)
(v_rt_trl_ret, 'QTD_OC_10', 'Qtd. Registros — Ocorrência 10 (Liquid. c/ Baixa)',
 'Quantidade de títulos liquidados com baixa',
 146, 151, 6, 'NUM', 0, false, false, 146),
(v_rt_trl_ret, 'VL_OC_10',  'Valor — Ocorrência 10 (Liquid. c/ Baixa)',
 'Valor total dos títulos liquidados com baixa (2 decimais)',
 152, 167, 16, 'MONETARY', 2, false, false, 152),

-- Bloco 06 — Ocorrência 13: Enviados ao Cartório (168-189)
(v_rt_trl_ret, 'QTD_OC_13', 'Qtd. Registros — Ocorrência 13 (Enviados Cartório)',
 'Quantidade de títulos enviados ao cartório',
 168, 173, 6, 'NUM', 0, false, false, 168),
(v_rt_trl_ret, 'VL_OC_13',  'Valor — Ocorrência 13 (Enviados Cartório)',
 'Valor total dos títulos enviados ao cartório (2 decimais)',
 174, 189, 16, 'MONETARY', 2, false, false, 174),

-- Bloco 07 — Ocorrência 14: Instrução de Protesto Confirmada (190-211)
(v_rt_trl_ret, 'QTD_OC_14', 'Qtd. Registros — Ocorrência 14 (Conf. Protesto)',
 'Quantidade de confirmações de instrução de protesto',
 190, 195, 6, 'NUM', 0, false, false, 190),
(v_rt_trl_ret, 'VL_OC_14',  'Valor — Ocorrência 14 (Conf. Protesto)',
 'Valor total das confirmações de protesto (2 decimais)',
 196, 211, 16, 'MONETARY', 2, false, false, 196),

-- Bloco 08 — Ocorrência 15: Sustação de Protesto (212-233)
(v_rt_trl_ret, 'QTD_OC_15', 'Qtd. Registros — Ocorrência 15 (Sustação Protesto)',
 'Quantidade de sustações de protesto',
 212, 217, 6, 'NUM', 0, false, false, 212),
(v_rt_trl_ret, 'VL_OC_15',  'Valor — Ocorrência 15 (Sustação Protesto)',
 'Valor total das sustações de protesto (2 decimais)',
 218, 233, 16, 'MONETARY', 2, false, false, 218),

-- Bloco 09 — Ocorrência 16: Instrução de Baixa do Protestado (234-255)
(v_rt_trl_ret, 'QTD_OC_16', 'Qtd. Registros — Ocorrência 16 (Baixa Protestado)',
 'Quantidade de baixas de títulos protestados',
 234, 239, 6, 'NUM', 0, false, false, 234),
(v_rt_trl_ret, 'VL_OC_16',  'Valor — Ocorrência 16 (Baixa Protestado)',
 'Valor total das baixas de protestados (2 decimais)',
 240, 255, 16, 'MONETARY', 2, false, false, 240),

-- Bloco 10 — Ocorrência 17: Débito de Custas/Tarifas (256-277)
(v_rt_trl_ret, 'QTD_OC_17', 'Qtd. Registros — Ocorrência 17 (Débito Custas)',
 'Quantidade de débitos de custas',
 256, 261, 6, 'NUM', 0, false, false, 256),
(v_rt_trl_ret, 'VL_OC_17',  'Valor — Ocorrência 17 (Débito Custas)',
 'Valor total dos débitos de custas (2 decimais)',
 262, 277, 16, 'MONETARY', 2, false, false, 262),

-- Bloco 11 — Ocorrência 11 (278-299)
(v_rt_trl_ret, 'QTD_OC_11', 'Qtd. Registros — Ocorrência 11',
 'Quantidade de registros — ocorrência 11',
 278, 283, 6, 'NUM', 0, false, false, 278),
(v_rt_trl_ret, 'VL_OC_11',  'Valor — Ocorrência 11',
 'Valor total — ocorrência 11 (2 decimais)',
 284, 299, 16, 'MONETARY', 2, false, false, 284),

-- Bloco 12 — Ocorrência 12 (300-321)
(v_rt_trl_ret, 'QTD_OC_12', 'Qtd. Registros — Ocorrência 12',
 'Quantidade de registros — ocorrência 12',
 300, 305, 6, 'NUM', 0, false, false, 300),
(v_rt_trl_ret, 'VL_OC_12',  'Valor — Ocorrência 12',
 'Valor total — ocorrência 12 (2 decimais)',
 306, 321, 16, 'MONETARY', 2, false, false, 306),

-- Bloco 13 — Ocorrência 25 (322-343)
(v_rt_trl_ret, 'QTD_OC_25', 'Qtd. Registros — Ocorrência 25',
 'Quantidade de registros — ocorrência 25',
 322, 327, 6, 'NUM', 0, false, false, 322),
(v_rt_trl_ret, 'VL_OC_25',  'Valor — Ocorrência 25',
 'Valor total — ocorrência 25 (2 decimais)',
 328, 343, 16, 'MONETARY', 2, false, false, 328),

-- Brancos entre contadores e rateios
(v_rt_trl_ret, 'BRANCOS_344_362', 'Brancos', 'Preencher com brancos',
 344, 362, 19, 'ALPHA', 0, false, true, 344),

-- Totalizadores de rateio
(v_rt_trl_ret, 'QTD_RATEIOS', 'Qtd. Total dos Rateios Efetuados',
 'Quantidade total de rateios de crédito efetuados',
 363, 374, 12, 'NUM', 0, false, false, 363),
(v_rt_trl_ret, 'VL_RATEIOS',  'Valor Total dos Rateios Efetuados',
 'Valor total dos rateios de crédito efetuados (2 decimais)',
 375, 385, 11, 'MONETARY', 2, false, false, 375),

-- Brancos finais
(v_rt_trl_ret, 'BRANCOS_386_394', 'Brancos', 'Preencher com brancos',
 386, 394, 9, 'ALPHA', 0, false, true, 386);

END $$;
