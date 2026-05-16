-- ============================================================
-- LayoutBank — Migration 003: CNAB 400 Remessa e Retorno (Itaú)
--
-- Substitui o layout CNAB400 genérico existente por dois layouts
-- distintos e completos, baseados no Manual Itaú CNAB 400 (mar/2025):
--   CNAB400_REMESSA — arquivo de cobrança enviado ao banco
--   CNAB400_RETORNO — arquivo de retorno recebido do banco
--
-- Posições 1-based conforme o manual oficial.
-- ============================================================

-- ============================================================
-- 0. Ajusta coluna format e CHECK constraint para aceitar os novos formatos
-- ============================================================
-- Aumenta o tamanho da coluna format de VARCHAR(10) para VARCHAR(20)
-- para acomodar os novos nomes CNAB400_REMESSA e CNAB400_RETORNO
ALTER TABLE cnab_layouts ALTER COLUMN format TYPE VARCHAR(20);

ALTER TABLE cnab_layouts DROP CONSTRAINT IF EXISTS chk_format;
ALTER TABLE cnab_layouts ADD CONSTRAINT chk_format
  CHECK (format IN ('CNAB240', 'CNAB400', 'CNAB400_REMESSA', 'CNAB400_RETORNO'));

-- ============================================================
-- 1. Remove layout(s) antigos com format = 'CNAB400' do Itaú
--    (cascade remove record_types e field_definitions)
-- ============================================================
DELETE FROM cnab_layouts
WHERE format = 'CNAB400'
  AND bank_id = (SELECT id FROM banks WHERE code = '341');

-- ============================================================
-- 2. Insere os novos layouts e todos os tipos de registro
-- ============================================================
DO $$
DECLARE
  v_bank_id         UUID;
  v_layout_rem_id   UUID;
  v_layout_ret_id   UUID;
  v_rt_id           UUID;

BEGIN

SELECT id INTO v_bank_id FROM banks WHERE code = '341';

IF v_bank_id IS NULL THEN
  RAISE EXCEPTION 'Banco Itaú (341) não encontrado. Execute a migration 002 primeiro.';
END IF;

-- ===========================================================
-- LAYOUT: CNAB400_REMESSA
-- ===========================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB400_REMESSA',
  '2025.03',
  'Itaú CNAB 400 - Cobrança Remessa',
  400,
  'latin1',
  'Arquivo de remessa de cobranças enviado ao Itaú. Manual CNAB 400 março/2025.'
)
RETURNING id INTO v_layout_rem_id;

-- -----------------------------------------------------------
-- REMESSA: HEADER (tipo 0, pos 1='0', pos 2='1')
-- -----------------------------------------------------------
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_rem_id, 'HEADER', 'Header do Arquivo de Remessa', 'HEADER',
  1, 1, '0',
  2, 2, '1',
  1
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',    'Tipo de Registro',           '0 = Header',                         1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'OPERACAO',         'Código de Operação',         '1 = Remessa',                         2,   2,   1, 'NUM',   0, true,  false,  2),
(v_rt_id, 'LITERAL_REMESSA',  'Literal Remessa',            'Valor fixo: REMESSA',                 3,   9,   7, 'ALPHA', 0, true,  false,  3),
(v_rt_id, 'COD_SERVICO',      'Código de Serviço',          '01 = Cobrança',                      10,  11,   2, 'NUM',   0, true,  false,  4),
(v_rt_id, 'LITERAL_SERVICO',  'Literal Serviço',            'Valor fixo: COBRANCA',               12,  26,  15, 'ALPHA', 0, true,  false,  5),
(v_rt_id, 'AGENCIA',          'Agência',                    'Número da agência sem dígito',        27,  30,   4, 'NUM',   0, true,  false,  6),
(v_rt_id, 'ZEROS',            'Zeros',                      'Preencher com zeros',                 31,  32,   2, 'NUM',   0, false, true,   7),
(v_rt_id, 'CONTA',            'Conta Corrente',             'Número da conta sem dígito',          33,  37,   5, 'NUM',   0, true,  false,  8),
(v_rt_id, 'DAC',              'DAC',                        'Dígito de auto-conferência',          38,  38,   1, 'NUM',   0, true,  false,  9),
(v_rt_id, 'BRANCOS_1',        'Brancos',                    'Preencher com brancos',               39,  46,   8, 'ALPHA', 0, false, true,  10),
(v_rt_id, 'NOME_EMPRESA',     'Nome da Empresa',            'Nome do cedente',                     47,  76,  30, 'ALPHA', 0, true,  false, 11),
(v_rt_id, 'COD_BANCO',        'Código do Banco',            '341 = Itaú',                         77,  79,   3, 'NUM',   0, true,  false, 12),
(v_rt_id, 'NOME_BANCO',       'Nome do Banco',              'BANCO ITAU SA',                      80,  94,  15, 'ALPHA', 0, true,  false, 13),
(v_rt_id, 'DT_GERACAO',       'Data de Geração',            'Formato DDMMAA',                     95, 100,   6, 'DATE',  0, true,  false, 14),
(v_rt_id, 'BRANCOS_2',        'Brancos',                    'Preencher com brancos',              101, 394, 294, 'ALPHA', 0, false, true,  15),
(v_rt_id, 'SEQ_ARQUIVO',      'Nº Sequencial do Arquivo',   'Número sequencial do arquivo',       395, 400,   6, 'NUM',   0, true,  false, 16);

-- -----------------------------------------------------------
-- REMESSA: DETALHE_BOLETO (tipo 1, pos 1='1')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'DETALHE_BOLETO', 'Detalhe - Registro de Boleto', 'DETAIL', 1, 1, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',              '1 = Detalhe Boleto',                           1,   1,   1, 'NUM',      0, true,  false,  1),
(v_rt_id, 'COD_INSCRICAO',       'Código de Inscrição',           '01=CPF, 02=CNPJ',                              2,   3,   2, 'NUM',      0, true,  false,  2),
(v_rt_id, 'NUM_INSCRICAO',       'Número de Inscrição',           'CPF ou CNPJ do cedente',                       4,  17,  14, 'NUM',      0, true,  false,  3),
(v_rt_id, 'AGENCIA',             'Agência',                       'Número da agência sem dígito',                18,  21,   4, 'NUM',      0, true,  false,  4),
(v_rt_id, 'ZEROS',               'Zeros',                         'Preencher com zeros',                         22,  23,   2, 'NUM',      0, false, true,   5),
(v_rt_id, 'CONTA',               'Conta Corrente',                'Número da conta sem dígito',                  24,  28,   5, 'NUM',      0, true,  false,  6),
(v_rt_id, 'DAC',                 'DAC',                           'Dígito de auto-conferência',                  29,  29,   1, 'NUM',      0, true,  false,  7),
(v_rt_id, 'BRANCOS_1',           'Brancos',                       'Preencher com brancos',                       30,  33,   4, 'ALPHA',    0, false, true,   8),
(v_rt_id, 'INSTRUCAO_ALEGACAO',  'Instrução/Alegação',            'Código de instrução/alegação',                34,  37,   4, 'NUM',      0, false, false,  9),
(v_rt_id, 'USO_EMPRESA',         'Uso da Empresa',                'Identificação do título na empresa',           38,  62,  25, 'ALPHA',    0, false, false, 10),
(v_rt_id, 'NOSSO_NUMERO',        'Nosso Número',                  'Número do título no banco',                   63,  70,   8, 'NUM',      0, true,  false, 11),
(v_rt_id, 'QTDE_MOEDA',          'Quantidade de Moeda',           '9(08)V9(5) — quantidade de moeda',            71,  83,  13, 'NUM',      0, false, false, 12),
(v_rt_id, 'NRO_CARTEIRA',        'Número da Carteira',            'Número da carteira de cobrança',              84,  86,   3, 'NUM',      0, true,  false, 13),
(v_rt_id, 'USO_BANCO',           'Uso do Banco',                  'Uso exclusivo Itaú — brancos',                87, 107,  21, 'ALPHA',    0, false, true,  14),
(v_rt_id, 'CARTEIRA',            'Carteira',                      'Código da carteira (letra)',                 108, 108,   1, 'ALPHA',    0, true,  false, 15),
(v_rt_id, 'COD_OCORRENCIA',      'Código de Ocorrência',          '01=Entrada, 02=Baixa, etc.',                 109, 110,   2, 'NUM',      0, true,  false, 16),
(v_rt_id, 'NRO_DOCUMENTO',       'Número do Documento',           'Número do documento da empresa',             111, 120,  10, 'ALPHA',    0, false, false, 17),
(v_rt_id, 'VENCIMENTO',          'Data de Vencimento',            'Formato DDMMAA',                             121, 126,   6, 'DATE',     0, true,  false, 18),
(v_rt_id, 'VL_BOLETO',           'Valor do Boleto',               'Valor do título (2 decimais implícitos)',     127, 139,  13, 'MONETARY', 2, true,  false, 19),
(v_rt_id, 'COD_BANCO',           'Código do Banco',               'Código do banco cobrador',                   140, 142,   3, 'NUM',      0, false, false, 20),
(v_rt_id, 'AG_COBRADORA',        'Agência Cobradora',             'Agência encarregada da cobrança',            143, 147,   5, 'NUM',      0, false, false, 21),
(v_rt_id, 'ESPECIE',             'Espécie do Documento',          'DM=Duplicata, NP=Nota Promissória, etc.',    148, 149,   2, 'ALPHA',    0, true,  false, 22),
(v_rt_id, 'ACEITE',              'Aceite',                        'A=Aceite, N=Sem aceite',                     150, 150,   1, 'ALPHA',    0, true,  false, 23),
(v_rt_id, 'DT_EMISSAO',          'Data de Emissão',               'Formato DDMMAA',                             151, 156,   6, 'DATE',     0, true,  false, 24),
(v_rt_id, 'INSTRUCAO_1',         '1ª Instrução',                  'Primeira instrução de cobrança',             157, 158,   2, 'ALPHA',    0, false, false, 25),
(v_rt_id, 'INSTRUCAO_2',         '2ª Instrução',                  'Segunda instrução de cobrança',              159, 160,   2, 'ALPHA',    0, false, false, 26),
(v_rt_id, 'JUROS_1_DIA',         'Juros por Dia',                 'Valor de mora diária (2 decimais)',           161, 173,  13, 'MONETARY', 2, false, false, 27),
(v_rt_id, 'DESCONTO_ATE',        'Data Limite Desconto',          'Formato DDMMAA',                             174, 179,   6, 'DATE',     0, false, false, 28),
(v_rt_id, 'VL_DESCONTO',         'Valor do Desconto',             'Valor do desconto (2 decimais)',             180, 192,  13, 'MONETARY', 2, false, false, 29),
(v_rt_id, 'VL_IOF',              'Valor do IOF',                  'Valor do IOF (2 decimais)',                  193, 205,  13, 'MONETARY', 2, false, false, 30),
(v_rt_id, 'ABATIMENTO',          'Valor de Abatimento',           'Valor do abatimento (2 decimais)',           206, 218,  13, 'MONETARY', 2, false, false, 31),
(v_rt_id, 'COD_INSCRICAO_PAG',   'Cód. Inscrição Pagador',        '01=CPF, 02=CNPJ',                           219, 220,   2, 'NUM',      0, true,  false, 32),
(v_rt_id, 'NUM_INSCRICAO_PAG',   'Nº Inscrição Pagador',          'CPF ou CNPJ do pagador',                    221, 234,  14, 'NUM',      0, true,  false, 33),
(v_rt_id, 'NOME_SACADO',         'Nome do Sacado',                'Nome do pagador',                           235, 264,  30, 'ALPHA',    0, true,  false, 34),
(v_rt_id, 'FILLER',              'Filler',                        'Uso exclusivo Itaú — brancos',              265, 274,  10, 'ALPHA',    0, false, true,  35),
(v_rt_id, 'LOGRADOURO',          'Logradouro',                    'Endereço do pagador',                       275, 314,  40, 'ALPHA',    0, false, false, 36),
(v_rt_id, 'BAIRRO',              'Bairro',                        'Bairro do pagador',                         315, 326,  12, 'ALPHA',    0, false, false, 37),
(v_rt_id, 'CEP',                 'CEP',                           'CEP do pagador (8 dígitos)',                 327, 334,   8, 'NUM',      0, false, false, 38),
(v_rt_id, 'CIDADE',              'Cidade',                        'Cidade do pagador',                         335, 349,  15, 'ALPHA',    0, false, false, 39),
(v_rt_id, 'UF',                  'UF',                            'Estado do pagador',                         350, 351,   2, 'ALPHA',    0, false, false, 40),
(v_rt_id, 'BENEF_FINAL',         'Beneficiário Final',            'Nome do sacador/avalista',                  352, 381,  30, 'ALPHA',    0, false, false, 41),
(v_rt_id, 'BRANCOS_2',           'Brancos',                       'Preencher com brancos',                     382, 385,   4, 'ALPHA',    0, false, true,  42),
(v_rt_id, 'DT_MORA',             'Data de Mora',                  'Formato DDMMAA',                            386, 391,   6, 'DATE',     0, false, false, 43),
(v_rt_id, 'PRAZO',               'Prazo',                         'Prazo para protesto/baixa',                 392, 393,   2, 'NUM',      0, false, false, 44),
(v_rt_id, 'BRANCOS_3',           'Brancos',                       'Preencher com brancos',                     394, 394,   1, 'ALPHA',    0, false, true,  45),
(v_rt_id, 'SEQ_REGISTRO',        'Nº Sequencial do Registro',     'Sequencial no arquivo',                     395, 400,   6, 'NUM',      0, true,  false, 46);

-- -----------------------------------------------------------
-- REMESSA: DETALHE_MULTA (tipo 2, pos 1='2') — opcional
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'DETALHE_MULTA', 'Detalhe - Instrução de Multa', 'DETAIL', 1, 1, '2', 3)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',         '2 = Detalhe Multa',                1,   1,   1, 'NUM',      0, true,  false,  1),
(v_rt_id, 'COD_MULTA',      'Código de Multa',          '1=Valor fixo, 2=Percentual',       2,   2,   1, 'NUM',      0, true,  false,  2),
(v_rt_id, 'DT_MULTA',       'Data da Multa',            'Formato DDMMAAAA',                 3,  10,   8, 'DATE',     0, true,  false,  3),
(v_rt_id, 'MULTA',          'Valor/Percentual da Multa','Valor ou % da multa (2 decimais)', 11,  23,  13, 'MONETARY', 2, true,  false,  4),
(v_rt_id, 'BRANCOS',        'Brancos',                  'Preencher com brancos',            24, 394, 371, 'ALPHA',    0, false, true,   5),
(v_rt_id, 'SEQ_REGISTRO',   'Nº Sequencial do Registro','Sequencial no arquivo',           395, 400,   6, 'NUM',      0, true,  false,  6);

-- -----------------------------------------------------------
-- REMESSA: DETALHE_BOLECODE (tipo 3, pos 1='3') — opcional
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'DETALHE_BOLECODE', 'Detalhe - BoleCode (Pix QR Code)', 'DETAIL', 1, 1, '3', 4)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',         '3 = Detalhe BoleCode',              1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'CHAVE_PIX',      'Chave Pix',                'Chave Pix do beneficiário',          2,  78,  77, 'ALPHA', 0, true,  false,  2),
(v_rt_id, 'ID_LOCATION',    'ID de Location',           'Identificador de location Pix',     79, 142,  64, 'NUM',   0, false, false,  3),
(v_rt_id, 'BRANCOS',        'Brancos',                  'Preencher com brancos',             143, 394, 252, 'ALPHA', 0, false, true,   4),
(v_rt_id, 'SEQ_REGISTRO',   'Nº Sequencial do Registro','Sequencial no arquivo',            395, 400,   6, 'NUM',   0, true,  false,  5);

-- -----------------------------------------------------------
-- REMESSA: DETALHE_RATEIO (tipo 4, pos 1='4') — opcional
--          Estrutura complexa; cadastrado sem campos detalhados
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'DETALHE_RATEIO', 'Detalhe - Rateio de Crédito (estrutura complexa)', 'DETAIL', 1, 1, '4', 5);

-- -----------------------------------------------------------
-- REMESSA: DETALHE_EMAIL (tipo 5, pos 1='5') — opcional
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'DETALHE_EMAIL', 'Detalhe - E-mail e Dados do Pagador', 'DETAIL', 1, 1, '5', 6)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',      'Tipo de Registro',             '5 = Detalhe Email',                   1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'EMAIL_PAGADOR',      'E-mail do Pagador',            'Endereço de e-mail do pagador',        2, 121, 120, 'ALPHA', 0, false, false,  2),
(v_rt_id, 'COD_INSCRICAO_BF',   'Cód. Inscrição Benef. Final',  '01=CPF, 02=CNPJ',                    122, 123,   2, 'NUM',   0, false, false,  3),
(v_rt_id, 'NUM_INSCRICAO_BF',   'Nº Inscrição Benef. Final',    'CPF ou CNPJ do beneficiário final',  124, 137,  14, 'NUM',   0, false, false,  4),
(v_rt_id, 'LOGRADOURO_BF',      'Logradouro Benef. Final',      'Endereço do beneficiário final',     138, 177,  40, 'ALPHA', 0, false, false,  5),
(v_rt_id, 'BAIRRO_BF',          'Bairro Benef. Final',          'Bairro do beneficiário final',       178, 189,  12, 'ALPHA', 0, false, false,  6),
(v_rt_id, 'CEP_BF',             'CEP Benef. Final',             'CEP do beneficiário final',          190, 197,   8, 'NUM',   0, false, false,  7),
(v_rt_id, 'CIDADE_BF',          'Cidade Benef. Final',          'Cidade do beneficiário final',       198, 212,  15, 'ALPHA', 0, false, false,  8),
(v_rt_id, 'UF_BF',              'UF Benef. Final',              'Estado do beneficiário final',       213, 214,   2, 'ALPHA', 0, false, false,  9),
(v_rt_id, 'BRANCOS',            'Brancos',                      'Preencher com brancos',              215, 394, 180, 'ALPHA', 0, false, true,  10),
(v_rt_id, 'SEQ_REGISTRO',       'Nº Sequencial do Registro',    'Sequencial no arquivo',              395, 400,   6, 'NUM',   0, true,  false, 11);

-- -----------------------------------------------------------
-- REMESSA: TRAILER (tipo 9, pos 1='9')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'TRAILER', 'Trailer do Arquivo de Remessa', 'TRAILER', 1, 1, '9', 7)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',         '9 = Trailer',                       1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'BRANCOS',        'Brancos',                  'Preencher com brancos',              2, 394, 393, 'ALPHA', 0, false, true,   2),
(v_rt_id, 'SEQ_REGISTRO',   'Nº Sequencial do Registro','Sequencial no arquivo',            395, 400,   6, 'NUM',   0, true,  false,  3);


-- ===========================================================
-- LAYOUT: CNAB400_RETORNO
-- ===========================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB400_RETORNO',
  '2025.03',
  'Itaú CNAB 400 - Cobrança Retorno',
  400,
  'latin1',
  'Arquivo de retorno de cobranças recebido do Itaú. Manual CNAB 400 março/2025.'
)
RETURNING id INTO v_layout_ret_id;

-- -----------------------------------------------------------
-- RETORNO: HEADER (tipo 0, pos 1='0', pos 2='2')
-- -----------------------------------------------------------
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_ret_id, 'HEADER', 'Header do Arquivo de Retorno', 'HEADER',
  1, 1, '0',
  2, 2, '2',
  1
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',    'Tipo de Registro',            '0 = Header',                             1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'COD_RETORNO',      'Código de Retorno',           '2 = Retorno',                             2,   2,   1, 'NUM',   0, true,  false,  2),
(v_rt_id, 'LITERAL_RETORNO',  'Literal Retorno',             'Valor fixo: RETORNO',                     3,   9,   7, 'ALPHA', 0, true,  false,  3),
(v_rt_id, 'COD_SERVICO',      'Código de Serviço',           '01 = Cobrança',                          10,  11,   2, 'NUM',   0, true,  false,  4),
(v_rt_id, 'LITERAL_SERVICO',  'Literal Serviço',             'Valor fixo: COBRANCA',                   12,  26,  15, 'ALPHA', 0, true,  false,  5),
(v_rt_id, 'AGENCIA',          'Agência',                     'Número da agência sem dígito',            27,  30,   4, 'NUM',   0, true,  false,  6),
(v_rt_id, 'ZEROS',            'Zeros',                       'Preencher com zeros',                     31,  32,   2, 'NUM',   0, false, true,   7),
(v_rt_id, 'CONTA',            'Conta Corrente',              'Número da conta sem dígito',              33,  37,   5, 'NUM',   0, true,  false,  8),
(v_rt_id, 'DAC',              'DAC',                         'Dígito de auto-conferência',              38,  38,   1, 'NUM',   0, true,  false,  9),
(v_rt_id, 'BRANCOS_1',        'Brancos',                     'Preencher com brancos',                   39,  46,   8, 'ALPHA', 0, false, true,  10),
(v_rt_id, 'NOME_EMPRESA',     'Nome da Empresa',             'Nome do cedente',                         47,  76,  30, 'ALPHA', 0, true,  false, 11),
(v_rt_id, 'COD_BANCO',        'Código do Banco',             '341 = Itaú',                             77,  79,   3, 'NUM',   0, true,  false, 12),
(v_rt_id, 'NOME_BANCO',       'Nome do Banco',               'BANCO ITAU SA',                          80,  94,  15, 'ALPHA', 0, true,  false, 13),
(v_rt_id, 'DT_GERACAO',       'Data de Geração',             'Formato DDMMAA',                         95, 100,   6, 'DATE',  0, true,  false, 14),
(v_rt_id, 'DENSIDADE',        'Densidade de Gravação',       'Densidade da mídia',                    101, 105,   5, 'NUM',   0, false, false, 15),
(v_rt_id, 'UNID_DENSIDADE',   'Unidade de Densidade',        'BPI = bytes por polegada',              106, 108,   3, 'ALPHA', 0, false, false, 16),
(v_rt_id, 'NRO_SEQ_ARQ',      'Nº Sequencial do Arquivo',   'Número de sequência do arquivo',         109, 113,   5, 'NUM',   0, false, false, 17),
(v_rt_id, 'DT_CREDITO',       'Data de Crédito',             'Formato DDMMAA',                        114, 119,   6, 'DATE',  0, false, false, 18),
(v_rt_id, 'BRANCOS_2',        'Brancos',                     'Preencher com brancos',                 120, 394, 275, 'ALPHA', 0, false, true,  19),
(v_rt_id, 'SEQ_REGISTRO',     'Nº Sequencial do Registro',   'Sequencial no arquivo',                 395, 400,   6, 'NUM',   0, true,  false, 20);

-- -----------------------------------------------------------
-- RETORNO: TRANSACAO (tipo 1, pos 1='1')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'TRANSACAO', 'Detalhe - Transação de Retorno', 'DETAIL', 1, 1, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',              '1 = Transação',                               1,   1,   1, 'NUM',      0, true,  false,  1),
(v_rt_id, 'COD_INSCRICAO',       'Código de Inscrição',           '01=CPF, 02=CNPJ',                             2,   3,   2, 'NUM',      0, true,  false,  2),
(v_rt_id, 'NUM_INSCRICAO',       'Número de Inscrição',           'CPF ou CNPJ do cedente',                      4,  17,  14, 'NUM',      0, true,  false,  3),
(v_rt_id, 'AGENCIA',             'Agência',                       'Número da agência sem dígito',               18,  21,   4, 'NUM',      0, true,  false,  4),
(v_rt_id, 'ZEROS',               'Zeros',                         'Preencher com zeros',                        22,  23,   2, 'NUM',      0, false, true,   5),
(v_rt_id, 'CONTA',               'Conta Corrente',                'Número da conta sem dígito',                 24,  28,   5, 'NUM',      0, true,  false,  6),
(v_rt_id, 'DAC',                 'DAC',                           'Dígito de auto-conferência',                 29,  29,   1, 'NUM',      0, true,  false,  7),
(v_rt_id, 'BRANCOS_1',           'Brancos',                       'Preencher com brancos',                      30,  37,   8, 'ALPHA',    0, false, true,   8),
(v_rt_id, 'USO_EMPRESA',         'Uso da Empresa',                'Identificação do título na empresa',          38,  62,  25, 'ALPHA',    0, false, false,  9),
(v_rt_id, 'NOSSO_NUMERO',        'Nosso Número',                  'Número do título no banco',                  63,  70,   8, 'NUM',      0, true,  false, 10),
(v_rt_id, 'BRANCOS_2',           'Brancos',                       'Preencher com brancos',                      71,  82,  12, 'ALPHA',    0, false, true,  11),
(v_rt_id, 'CARTEIRA',            'Carteira',                      'Código da carteira',                         83,  85,   3, 'NUM',      0, true,  false, 12),
(v_rt_id, 'NOSSO_NUMERO_2',      'Nosso Número 2',                'Nosso número campo complementar',            86,  93,   8, 'NUM',      0, false, false, 13),
(v_rt_id, 'DAC_NOSSO_NUM',       'DAC Nosso Número',              'Dígito verificador do nosso número',         94,  94,   1, 'NUM',      0, false, false, 14),
(v_rt_id, 'BRANCOS_3',           'Brancos',                       'Preencher com brancos',                      95, 107,  13, 'ALPHA',    0, false, true,  15),
(v_rt_id, 'CARTEIRA_COD',        'Código da Carteira',            'Código da carteira (letra)',                108, 108,   1, 'ALPHA',    0, true,  false, 16),
(v_rt_id, 'COD_OCORRENCIA',      'Código de Ocorrência',          'Código do evento ocorrido',                 109, 110,   2, 'NUM',      0, true,  false, 17),
(v_rt_id, 'DT_OCORRENCIA',       'Data da Ocorrência',            'Formato DDMMAA',                            111, 116,   6, 'DATE',     0, true,  false, 18),
(v_rt_id, 'NRO_DOCUMENTO',       'Número do Documento',           'Número do documento da empresa',            117, 126,  10, 'ALPHA',    0, false, false, 19),
(v_rt_id, 'NOSSO_NUMERO_CONF',   'Nosso Número Confirmado',       'Nosso número confirmado pelo banco',        127, 134,   8, 'NUM',      0, false, false, 20),
(v_rt_id, 'BRANCOS_4',           'Brancos',                       'Preencher com brancos',                     135, 146,  12, 'ALPHA',    0, false, true,  21),
(v_rt_id, 'VENCIMENTO',          'Data de Vencimento',            'Formato DDMMAA',                            147, 152,   6, 'DATE',     0, true,  false, 22),
(v_rt_id, 'VL_BOLETO',           'Valor do Boleto',               'Valor do título (2 decimais)',               153, 165,  13, 'MONETARY', 2, true,  false, 23),
(v_rt_id, 'COD_BANCO',           'Código do Banco',               'Banco cobrador',                            166, 168,   3, 'NUM',      0, false, false, 24),
(v_rt_id, 'AG_COBRADORA',        'Agência Cobradora',             'Agência da cobrança',                       169, 172,   4, 'NUM',      0, false, false, 25),
(v_rt_id, 'DAC_AG_COB',          'DAC Agência Cobradora',         'Dígito verificador da agência cobradora',   173, 173,   1, 'NUM',      0, false, false, 26),
(v_rt_id, 'ESPECIE',             'Espécie',                       'Espécie do documento',                      174, 175,   2, 'NUM',      0, false, false, 27),
(v_rt_id, 'TARIFA',              'Tarifa',                        'Valor da tarifa bancária (2 decimais)',      176, 188,  13, 'MONETARY', 2, false, false, 28),
(v_rt_id, 'BRANCOS_5',           'Brancos',                       'Preencher com brancos',                     189, 214,  26, 'ALPHA',    0, false, true,  29),
(v_rt_id, 'VL_IOF',              'Valor do IOF',                  'IOF a recolher (2 decimais)',               215, 227,  13, 'MONETARY', 2, false, false, 30),
(v_rt_id, 'VL_ABATIMENTO',       'Valor de Abatimento',           'Abatimento concedido (2 decimais)',         228, 240,  13, 'MONETARY', 2, false, false, 31),
(v_rt_id, 'VL_DESCONTO',         'Valor do Desconto',             'Desconto concedido (2 decimais)',            241, 253,  13, 'MONETARY', 2, false, false, 32),
(v_rt_id, 'VL_PRINCIPAL',        'Valor Principal',               'Valor principal recebido (2 decimais)',      254, 266,  13, 'MONETARY', 2, true,  false, 33),
(v_rt_id, 'VL_JUROS_MORA',       'Valor Juros/Mora',              'Juros e mora recebidos (2 decimais)',        267, 279,  13, 'MONETARY', 2, false, false, 34),
(v_rt_id, 'OUTROS_CREDITO',      'Outros Créditos',               'Outros créditos recebidos (2 decimais)',     280, 292,  13, 'MONETARY', 2, false, false, 35),
(v_rt_id, 'BOLETO_DDA',          'Indicador Boleto DDA',          'S=DDA, N=Não DDA',                          293, 293,   1, 'ALPHA',    0, false, false, 36),
(v_rt_id, 'BRANCOS_6',           'Brancos',                       'Preencher com brancos',                     294, 295,   2, 'ALPHA',    0, false, true,  37),
(v_rt_id, 'DT_CREDITO',          'Data de Crédito',               'Formato DDMMAA',                            296, 301,   6, 'DATE',     0, false, false, 38),
(v_rt_id, 'INSTR_CANCELADA',     'Instrução Cancelada',           'Instrução cancelada pelo banco',            302, 305,   4, 'NUM',      0, false, false, 39),
(v_rt_id, 'BRANCOS_7',           'Brancos',                       'Preencher com brancos',                     306, 311,   6, 'ALPHA',    0, false, true,  40),
(v_rt_id, 'ZEROS',               'Zeros',                         'Preencher com zeros',                       312, 324,  13, 'NUM',      0, false, true,  41),
(v_rt_id, 'NOME_PAGADOR',        'Nome do Pagador',               'Nome do sacado',                            325, 354,  30, 'ALPHA',    0, false, false, 42),
(v_rt_id, 'BRANCOS_8',           'Brancos',                       'Preencher com brancos',                     355, 375,  21, 'ALPHA',    0, false, true,  43),
(v_rt_id, 'ERROS',               'Erros',                         'Códigos de erro da ocorrência',             376, 385,  10, 'ALPHA',    0, false, false, 44),
(v_rt_id, 'BRANCOS_9',           'Brancos',                       'Preencher com brancos',                     386, 392,   7, 'ALPHA',    0, false, true,  45),
(v_rt_id, 'COD_LIQUIDACAO',      'Código de Liquidação',          'Forma de liquidação do título',             393, 394,   2, 'ALPHA',    0, false, false, 46),
(v_rt_id, 'SEQ_REGISTRO',        'Nº Sequencial do Registro',     'Sequencial no arquivo',                     395, 400,   6, 'NUM',      0, true,  false, 47);

-- -----------------------------------------------------------
-- RETORNO: BOLECODE_RET (tipo 3, pos 1='3') — opcional
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'BOLECODE_RET', 'Detalhe - BoleCode Retorno (Pix QR Code)', 'DETAIL', 1, 1, '3', 3)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',         '3 = BoleCode Retorno',              1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'EMV_QR_CODE',    'EMV QR Code',              'Dados do QR Code Pix (EMV)',         2, 391, 390, 'ALPHA', 0, false, false,  2),
(v_rt_id, 'COD_ERRO_PIX',   'Código de Erro Pix',       'Código de erro Pix (se houver)',    392, 394,   3, 'ALPHA', 0, false, false,  3),
(v_rt_id, 'SEQ_REGISTRO',   'Nº Sequencial do Registro','Sequencial no arquivo',            395, 400,   6, 'NUM',   0, true,  false,  4);

-- -----------------------------------------------------------
-- RETORNO: DETALHE_OPC (tipo 4, pos 1='4') — opcional
--          Registro opcional sem campos padronizados definidos no manual
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'DETALHE_OPC', 'Detalhe Opcional (uso futuro)', 'DETAIL', 1, 1, '4', 4);

-- -----------------------------------------------------------
-- RETORNO: TRAILER (tipo 9, pos 1='9')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'TRAILER', 'Trailer do Arquivo de Retorno', 'TRAILER', 1, 1, '9', 5)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',         'Tipo de Registro',              '9 = Trailer',                            1,   1,   1, 'NUM',      0, true,  false,  1),
(v_rt_id, 'COD_RETORNO',           'Código de Retorno',             '2 = Retorno',                             2,   2,   1, 'NUM',      0, true,  false,  2),
(v_rt_id, 'COD_SERVICO',           'Código de Serviço',             'Código do serviço',                       3,   4,   2, 'NUM',      0, true,  false,  3),
(v_rt_id, 'COD_BANCO',             'Código do Banco',               '341 = Itaú',                              5,   7,   3, 'NUM',      0, true,  false,  4),
(v_rt_id, 'BRANCOS_1',             'Brancos',                       'Preencher com brancos',                   8,  17,  10, 'ALPHA',    0, false, true,   5),
(v_rt_id, 'QTD_BOLETOS_SIMPLES',   'Qtd. Boletos Simples',          'Quantidade de cobranças simples',        18,  25,   8, 'NUM',      0, false, false,  6),
(v_rt_id, 'VL_TOTAL_SIMPLES',      'Valor Total Simples',           'Valor total cobranças simples (2 dec.)',  26,  39,  14, 'MONETARY', 2, false, false,  7),
(v_rt_id, 'AVISO_BANCARIO',        'Aviso Bancário',                'Número do aviso bancário',               40,  47,   8, 'ALPHA',    0, false, false,  8),
(v_rt_id, 'BRANCOS_2',             'Brancos',                       'Preencher com brancos',                  48,  57,  10, 'ALPHA',    0, false, true,   9),
(v_rt_id, 'QTD_BOLETOS_VINC',      'Qtd. Boletos Vinculados',       'Quantidade de cobranças vinculadas',      58,  65,   8, 'NUM',      0, false, false, 10),
(v_rt_id, 'VL_TOTAL_VINC',         'Valor Total Vinculados',        'Valor total cobranças vinculadas (2 dec.)',66, 79,  14, 'MONETARY', 2, false, false, 11),
(v_rt_id, 'AVISO_BANCARIO_2',      'Aviso Bancário 2',              'Número do aviso bancário (vinculados)',   80,  87,   8, 'ALPHA',    0, false, false, 12),
(v_rt_id, 'BRANCOS_3',             'Brancos',                       'Preencher com brancos',                  88, 177,  90, 'ALPHA',    0, false, true,  13),
(v_rt_id, 'QTD_BOLETOS_DIR',       'Qtd. Boletos Diretos',          'Quantidade de cobranças diretas',       178, 185,   8, 'NUM',      0, false, false, 14),
(v_rt_id, 'VL_TOTAL_DIR',          'Valor Total Diretos',           'Valor total cobranças diretas (2 dec.)', 186, 199,  14, 'MONETARY', 2, false, false, 15),
(v_rt_id, 'AVISO_BANCARIO_3',      'Aviso Bancário 3',              'Número do aviso bancário (diretos)',     200, 207,   8, 'ALPHA',    0, false, false, 16),
(v_rt_id, 'CONTROLE_ARQ',          'Controle do Arquivo',           'Número de controle do arquivo',         208, 212,   5, 'NUM',      0, false, false, 17),
(v_rt_id, 'QTD_DETALHES',          'Quantidade de Detalhes',        'Total de registros tipo 1',             213, 220,   8, 'NUM',      0, true,  false, 18),
(v_rt_id, 'VL_TOTAL_INF',          'Valor Total Informado',         'Valor total informado (2 decimais)',     221, 234,  14, 'MONETARY', 2, false, false, 19),
(v_rt_id, 'BRANCOS_4',             'Brancos',                       'Preencher com brancos',                 235, 394, 160, 'ALPHA',    0, false, true,  20),
(v_rt_id, 'SEQ_REGISTRO',          'Nº Sequencial do Registro',     'Sequencial no arquivo',                 395, 400,   6, 'NUM',      0, true,  false, 21);

END $$;
