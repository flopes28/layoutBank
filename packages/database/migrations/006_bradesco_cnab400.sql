-- ============================================================
-- LayoutBank — Migration 006: Bradesco CNAB 400 Remessa e Retorno
--
-- Adiciona banco Bradesco (237) e dois layouts completos:
--   CNAB400_REMESSA — arquivo de cobrança enviado ao Bradesco
--   CNAB400_RETORNO — arquivo de retorno recebido do Bradesco
--
-- Baseado no Manual de Procedimentos Operacionais - Cobrança
-- Bradesco CNAB 400, Agosto/2022.
-- Posições 1-based conforme o manual oficial.
-- ============================================================

DO $$
DECLARE
  v_bank_id         UUID;
  v_layout_rem_id   UUID;
  v_layout_ret_id   UUID;
  v_rt_id           UUID;

BEGIN

-- ============================================================
-- 0. Banco Bradesco
-- ============================================================
INSERT INTO banks (code, name, short_name)
VALUES ('237', 'Banco Bradesco S.A.', 'bradesco')
ON CONFLICT (code) DO NOTHING;

SELECT id INTO v_bank_id FROM banks WHERE code = '237';

IF v_bank_id IS NULL THEN
  RAISE EXCEPTION 'Falha ao inserir ou localizar banco Bradesco (237).';
END IF;

-- ============================================================
-- 1. LAYOUT: CNAB400_REMESSA (Bradesco)
-- ============================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB400_REMESSA',
  '2022.08',
  'Bradesco CNAB 400 - Cobrança Remessa',
  400,
  'latin1',
  'Arquivo de remessa de cobranças enviado ao Bradesco. Manual CNAB 400 Agosto/2022.'
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
(v_rt_id, 'TIPO_REGISTRO',     'Tipo de Registro',             '0 = Header',                                  1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'OPERACAO',          'Código de Operação',           '1 = Remessa',                                  2,   2,   1, 'NUM',   0, true,  false,  2),
(v_rt_id, 'LITERAL_REMESSA',   'Literal Remessa',              'Valor fixo: REMESSA',                          3,   9,   7, 'ALPHA', 0, true,  false,  3),
(v_rt_id, 'COD_SERVICO',       'Código de Serviço',            '01 = Cobrança',                               10,  11,   2, 'NUM',   0, true,  false,  4),
(v_rt_id, 'LITERAL_SERVICO',   'Literal Serviço',              'Valor fixo: COBRANCA',                        12,  26,  15, 'ALPHA', 0, true,  false,  5),
(v_rt_id, 'COD_EMPRESA',       'Código da Empresa',            'Código da empresa no Bradesco (ag+conta+DV)', 27,  46,  20, 'ALPHA', 0, true,  false,  6),
(v_rt_id, 'NOME_EMPRESA',      'Nome da Empresa',              'Nome do cedente',                             47,  76,  30, 'ALPHA', 0, true,  false,  7),
(v_rt_id, 'COD_BANCO',         'Código do Banco',              '237 = Bradesco',                              77,  79,   3, 'NUM',   0, true,  false,  8),
(v_rt_id, 'NOME_BANCO',        'Nome do Banco',                'BRADESCO',                                    80,  94,  15, 'ALPHA', 0, true,  false,  9),
(v_rt_id, 'DT_GERACAO',        'Data de Geração',              'Formato DDMMAA',                              95, 100,   6, 'DATE',  0, true,  false, 10),
(v_rt_id, 'BRANCOS_1',         'Brancos',                      'Preencher com brancos',                      101, 107,   7, 'ALPHA', 0, false, true,  11),
(v_rt_id, 'DENSIDADE',         'Densidade de Gravação',        'Ex: 01600 BPI',                              108, 117,  10, 'NUM',   0, false, false, 12),
(v_rt_id, 'NRO_SEQ_REMESSA',   'Nº Sequencial da Remessa',    'Número sequencial do arquivo',               118, 124,   7, 'NUM',   0, false, false, 13),
(v_rt_id, 'BRANCOS_2',         'Brancos',                      'Preencher com brancos',                      125, 394, 270, 'ALPHA', 0, false, true,  14),
(v_rt_id, 'SEQ_ARQUIVO',       'Nº Sequencial do Arquivo',    'Sequencial deste registro',                  395, 400,   6, 'NUM',   0, true,  false, 15);

-- -----------------------------------------------------------
-- REMESSA: DETALHE_BOLETO (tipo 1, pos 1='1')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'DETALHE_BOLETO', 'Detalhe - Registro de Boleto', 'DETAIL', 1, 1, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',              '1 = Detalhe',                                   1,   1,   1, 'NUM',      0, true,  false,  1),
(v_rt_id, 'COD_INSCRICAO',       'Código de Inscrição',           '01=CPF, 02=CNPJ do cedente',                    2,   3,   2, 'NUM',      0, true,  false,  2),
(v_rt_id, 'NUM_INSCRICAO',       'Número de Inscrição',           'CPF ou CNPJ do cedente',                        4,  17,  14, 'NUM',      0, true,  false,  3),
(v_rt_id, 'AGENCIA',             'Agência',                       'Número da agência sem dígito',                 18,  21,   4, 'NUM',      0, true,  false,  4),
(v_rt_id, 'ZEROS',               'Zeros',                         'Preencher com zeros',                          22,  23,   2, 'NUM',      0, false, true,   5),
(v_rt_id, 'CONTA',               'Conta Corrente',                'Número da conta sem dígito',                   24,  28,   5, 'NUM',      0, true,  false,  6),
(v_rt_id, 'DAC',                 'DAC',                           'Dígito de auto-conferência da conta',          29,  29,   1, 'NUM',      0, true,  false,  7),
(v_rt_id, 'BRANCOS_1',           'Brancos',                       'Preencher com brancos',                        30,  30,   1, 'ALPHA',    0, false, true,   8),
(v_rt_id, 'NRO_CONTROLE',        'Número de Controle',            'Número de controle do participante',           31,  37,   7, 'NUM',      0, false, false,  9),
(v_rt_id, 'USO_EMPRESA',         'Uso da Empresa',                'Identificação do título na empresa',           38,  62,  25, 'ALPHA',    0, false, false, 10),
(v_rt_id, 'BRANCOS_2',           'Brancos',                       'Uso do banco (preencher com brancos)',         63,  70,   8, 'ALPHA',    0, false, true,  11),
(v_rt_id, 'NOSSO_NUMERO',        'Nosso Número',                  'Número do título no Bradesco (11 dígitos)',    71,  81,  11, 'NUM',      0, true,  false, 12),
(v_rt_id, 'DIGITO_NN',           'Dígito do Nosso Número',        'Dígito verificador do nosso número (Mod.11)', 82,  82,   1, 'NUM',      0, true,  false, 13),
(v_rt_id, 'BRANCOS_3',           'Brancos',                       'Uso do banco (preencher com brancos)',         83,  93,  11, 'ALPHA',    0, false, true,  14),
(v_rt_id, 'CARTEIRA',            'Carteira',                      'Código da carteira de cobrança',              94,  96,   3, 'NUM',      0, true,  false, 15),
(v_rt_id, 'BRANCOS_4',           'Brancos',                       'Uso do banco (preencher com brancos)',         97, 107,  11, 'ALPHA',    0, false, true,  16),
(v_rt_id, 'ACEITE',              'Aceite',                        'A=Aceite, N=Sem aceite',                      108, 108,   1, 'ALPHA',    0, true,  false, 17),
(v_rt_id, 'COD_OCORRENCIA',      'Código de Ocorrência',          '01=Entrada, 02=Baixa, 05=Alteração Vcto',    109, 110,   2, 'NUM',      0, true,  false, 18),
(v_rt_id, 'NRO_DOCUMENTO',       'Número do Documento',           'Número do documento da empresa',             111, 120,  10, 'ALPHA',    0, false, false, 19),
(v_rt_id, 'VENCIMENTO',          'Data de Vencimento',            'Formato DDMMAA',                             121, 126,   6, 'DATE',     0, true,  false, 20),
(v_rt_id, 'VL_BOLETO',           'Valor do Boleto',               'Valor do título (2 decimais implícitos)',     127, 139,  13, 'MONETARY', 2, true,  false, 21),
(v_rt_id, 'COD_BANCO',           'Código do Banco',               'Banco cobrador',                             140, 142,   3, 'NUM',      0, false, false, 22),
(v_rt_id, 'AG_COBRADORA',        'Agência Cobradora',             'Agência encarregada da cobrança',            143, 147,   5, 'NUM',      0, false, false, 23),
(v_rt_id, 'ESPECIE',             'Espécie do Documento',          '01=DM, 02=NP, 03=NS, 05=RC, etc.',           148, 149,   2, 'NUM',      0, true,  false, 24),
(v_rt_id, 'ACEITE_2',            'Aceite',                        'A=Aceite, N=Sem aceite',                      150, 150,   1, 'ALPHA',    0, true,  false, 25),
(v_rt_id, 'DT_EMISSAO',          'Data de Emissão',               'Formato DDMMAA',                             151, 156,   6, 'DATE',     0, true,  false, 26),
(v_rt_id, 'INSTRUCAO_1',         '1ª Instrução',                  'Primeira instrução de cobrança',             157, 158,   2, 'NUM',      0, false, false, 27),
(v_rt_id, 'INSTRUCAO_2',         '2ª Instrução',                  'Segunda instrução de cobrança',              159, 160,   2, 'NUM',      0, false, false, 28),
(v_rt_id, 'JUROS_1_DIA',         'Juros por Dia',                 'Valor de mora diária (2 decimais)',           161, 173,  13, 'MONETARY', 2, false, false, 29),
(v_rt_id, 'DESCONTO_ATE',        'Data Limite Desconto',          'Formato DDMMAA (000000 = sem desconto)',      174, 179,   6, 'DATE',     0, false, false, 30),
(v_rt_id, 'VL_DESCONTO',         'Valor do Desconto',             'Valor do desconto (2 decimais)',             180, 192,  13, 'MONETARY', 2, false, false, 31),
(v_rt_id, 'VL_IOF',              'Valor do IOF',                  'Valor do IOF (2 decimais)',                  193, 205,  13, 'MONETARY', 2, false, false, 32),
(v_rt_id, 'ABATIMENTO',          'Valor de Abatimento',           'Valor do abatimento (2 decimais)',           206, 218,  13, 'MONETARY', 2, false, false, 33),
(v_rt_id, 'COD_INSCRICAO_PAG',   'Cód. Inscrição Pagador',        '01=CPF, 02=CNPJ',                           219, 220,   2, 'NUM',      0, true,  false, 34),
(v_rt_id, 'NUM_INSCRICAO_PAG',   'Nº Inscrição Pagador',          'CPF ou CNPJ do pagador',                    221, 234,  14, 'NUM',      0, true,  false, 35),
(v_rt_id, 'NOME_SACADO',         'Nome do Sacado',                'Nome do pagador (40 chars)',                 235, 274,  40, 'ALPHA',    0, true,  false, 36),
(v_rt_id, 'LOGRADOURO',          'Logradouro',                    'Endereço do pagador',                       275, 314,  40, 'ALPHA',    0, false, false, 37),
(v_rt_id, 'BAIRRO',              'Bairro',                        'Bairro do pagador',                         315, 326,  12, 'ALPHA',    0, false, false, 38),
(v_rt_id, 'CEP',                 'CEP',                           'CEP do pagador (8 dígitos)',                 327, 334,   8, 'NUM',      0, false, false, 39),
(v_rt_id, 'CIDADE',              'Cidade',                        'Cidade do pagador',                         335, 349,  15, 'ALPHA',    0, false, false, 40),
(v_rt_id, 'UF',                  'UF',                            'Estado do pagador',                         350, 351,   2, 'ALPHA',    0, false, false, 41),
(v_rt_id, 'BENEF_FINAL',         'Beneficiário Final / Sacador',  'Nome do sacador/avalista ou beneficiário',  352, 381,  30, 'ALPHA',    0, false, false, 42),
(v_rt_id, 'BRANCOS_5',           'Brancos',                       'Preencher com brancos',                     382, 391,  10, 'ALPHA',    0, false, true,  43),
(v_rt_id, 'PRAZO',               'Prazo',                         'Prazo para protesto/baixa',                 392, 393,   2, 'NUM',      0, false, false, 44),
(v_rt_id, 'BRANCOS_6',           'Brancos',                       'Preencher com brancos',                     394, 394,   1, 'ALPHA',    0, false, true,  45),
(v_rt_id, 'SEQ_REGISTRO',        'Nº Sequencial do Registro',     'Sequencial no arquivo',                     395, 400,   6, 'NUM',      0, true,  false, 46);

-- -----------------------------------------------------------
-- REMESSA: TRAILER (tipo 9, pos 1='9')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'TRAILER', 'Trailer do Arquivo de Remessa', 'TRAILER', 1, 1, '9', 3)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',          '9 = Trailer',            1,   1,   1, 'NUM',   0, true,  false, 1),
(v_rt_id, 'BRANCOS',        'Brancos',                   'Preencher com brancos',   2, 394, 393, 'ALPHA', 0, false, true,  2),
(v_rt_id, 'SEQ_REGISTRO',   'Nº Sequencial do Registro', 'Sequencial no arquivo', 395, 400,   6, 'NUM',   0, true,  false, 3);


-- ============================================================
-- 2. LAYOUT: CNAB400_RETORNO (Bradesco)
-- ============================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB400_RETORNO',
  '2022.08',
  'Bradesco CNAB 400 - Cobrança Retorno',
  400,
  'latin1',
  'Arquivo de retorno de cobranças recebido do Bradesco. Manual CNAB 400 Agosto/2022.'
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
(v_rt_id, 'TIPO_REGISTRO',    'Tipo de Registro',           '0 = Header',                            1,   1,   1, 'NUM',   0, true,  false,  1),
(v_rt_id, 'COD_RETORNO',      'Código de Retorno',          '2 = Retorno',                            2,   2,   1, 'NUM',   0, true,  false,  2),
(v_rt_id, 'LITERAL_RETORNO',  'Literal Retorno',            'Valor fixo: RETORNO',                    3,   9,   7, 'ALPHA', 0, true,  false,  3),
(v_rt_id, 'COD_SERVICO',      'Código de Serviço',          '01 = Cobrança',                         10,  11,   2, 'NUM',   0, true,  false,  4),
(v_rt_id, 'LITERAL_SERVICO',  'Literal Serviço',            'Valor fixo: COBRANCA',                  12,  26,  15, 'ALPHA', 0, true,  false,  5),
(v_rt_id, 'COD_EMPRESA',      'Código da Empresa',          'Código da empresa no Bradesco',         27,  46,  20, 'ALPHA', 0, true,  false,  6),
(v_rt_id, 'NOME_EMPRESA',     'Nome da Empresa',            'Nome do cedente',                       47,  76,  30, 'ALPHA', 0, true,  false,  7),
(v_rt_id, 'COD_BANCO',        'Código do Banco',            '237 = Bradesco',                        77,  79,   3, 'NUM',   0, true,  false,  8),
(v_rt_id, 'NOME_BANCO',       'Nome do Banco',              'BRADESCO',                              80,  94,  15, 'ALPHA', 0, true,  false,  9),
(v_rt_id, 'DT_GERACAO',       'Data de Geração',            'Formato DDMMAA',                        95, 100,   6, 'DATE',  0, true,  false, 10),
(v_rt_id, 'DENSIDADE',        'Densidade de Gravação',      'Densidade da mídia (ex: 01600)',       101, 108,   8, 'NUM',   0, false, false, 11),
(v_rt_id, 'BRANCOS_1',        'Brancos',                    'Preencher com brancos',                109, 379, 271, 'ALPHA', 0, false, true,  12),
(v_rt_id, 'DT_CREDITO',       'Data de Crédito',            'Data do crédito ao cedente (DDMMAA)',  380, 385,   6, 'DATE',  0, false, false, 13),
(v_rt_id, 'BRANCOS_2',        'Brancos',                    'Preencher com brancos',                386, 394,   9, 'ALPHA', 0, false, true,  14),
(v_rt_id, 'SEQ_REGISTRO',     'Nº Sequencial do Registro',  'Sequencial no arquivo',               395, 400,   6, 'NUM',   0, true,  false, 15);

-- -----------------------------------------------------------
-- RETORNO: TRANSACAO (tipo 1, pos 1='1')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'TRANSACAO', 'Detalhe - Transação de Retorno', 'DETAIL', 1, 1, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',              '1 = Transação',                                 1,   1,   1, 'NUM',      0, true,  false,  1),
(v_rt_id, 'COD_INSCRICAO',       'Código de Inscrição',           '01=CPF, 02=CNPJ do cedente',                    2,   3,   2, 'NUM',      0, true,  false,  2),
(v_rt_id, 'NUM_INSCRICAO',       'Número de Inscrição',           'CPF ou CNPJ do cedente',                        4,  17,  14, 'NUM',      0, true,  false,  3),
(v_rt_id, 'AGENCIA',             'Agência',                       'Número da agência',                            18,  21,   4, 'NUM',      0, true,  false,  4),
(v_rt_id, 'ZEROS',               'Zeros',                         'Preencher com zeros',                          22,  23,   2, 'NUM',      0, false, true,   5),
(v_rt_id, 'CONTA',               'Conta Corrente',                'Número da conta',                              24,  28,   5, 'NUM',      0, true,  false,  6),
(v_rt_id, 'DAC',                 'DAC',                           'Dígito de auto-conferência da conta',          29,  29,   1, 'NUM',      0, true,  false,  7),
(v_rt_id, 'BRANCOS_1',           'Brancos',                       'Preencher com brancos',                        30,  30,   1, 'ALPHA',    0, false, true,   8),
(v_rt_id, 'NRO_CONTROLE',        'Número de Controle',            'Número de controle do participante',           31,  37,   7, 'NUM',      0, false, false,  9),
(v_rt_id, 'USO_EMPRESA',         'Uso da Empresa',                'Identificação do título na empresa',           38,  62,  25, 'ALPHA',    0, false, false, 10),
(v_rt_id, 'BRANCOS_2',           'Brancos',                       'Uso do banco',                                 63,  70,   8, 'ALPHA',    0, false, true,  11),
(v_rt_id, 'NOSSO_NUMERO',        'Nosso Número',                  'Número do título cedente (11 dígitos)',        71,  81,  11, 'NUM',      0, true,  false, 12),
(v_rt_id, 'DIGITO_NN',           'Dígito do Nosso Número',        'Dígito verificador nosso número',             82,  82,   1, 'NUM',      0, true,  false, 13),
(v_rt_id, 'BRANCOS_3',           'Brancos',                       'Uso do banco',                                 83,  93,  11, 'ALPHA',    0, false, true,  14),
(v_rt_id, 'CARTEIRA',            'Carteira',                      'Código da carteira de cobrança',              94,  96,   3, 'NUM',      0, true,  false, 15),
(v_rt_id, 'BRANCOS_4',           'Brancos',                       'Uso do banco',                                 97, 108,  12, 'ALPHA',    0, false, true,  16),
(v_rt_id, 'COD_OCORRENCIA',      'Código de Ocorrência',          'Código do evento (02=Conf., 06=Liquid., etc)', 109, 110,   2, 'NUM',      0, true,  false, 17),
(v_rt_id, 'DT_OCORRENCIA',       'Data da Ocorrência',            'Formato DDMMAA',                              111, 116,   6, 'DATE',     0, true,  false, 18),
(v_rt_id, 'NRO_DOCUMENTO',       'Número do Documento',           'Número do documento da empresa',              117, 126,  10, 'ALPHA',    0, false, false, 19),
(v_rt_id, 'NOSSO_NUMERO_BANCO',  'Nosso Número Banco',            'Nosso número emitido pelo banco (20 chars)',  127, 146,  20, 'NUM',      0, false, false, 20),
(v_rt_id, 'VENCIMENTO',          'Data de Vencimento',            'Formato DDMMAA',                              147, 152,   6, 'DATE',     0, true,  false, 21),
(v_rt_id, 'VL_BOLETO',           'Valor do Boleto',               'Valor original do título (2 decimais)',        153, 165,  13, 'MONETARY', 2, true,  false, 22),
(v_rt_id, 'COD_BANCO',           'Código do Banco',               'Banco cobrador',                              166, 168,   3, 'NUM',      0, false, false, 23),
(v_rt_id, 'AG_COBRADORA',        'Agência Cobradora',             'Agência que cobrou',                          169, 173,   5, 'NUM',      0, false, false, 24),
(v_rt_id, 'ESPECIE',             'Espécie',                       'Espécie do documento',                        174, 175,   2, 'NUM',      0, false, false, 25),
(v_rt_id, 'TARIFA',              'Tarifa Bancária',               'Valor da tarifa bancária (2 decimais)',       176, 188,  13, 'MONETARY', 2, false, false, 26),
(v_rt_id, 'BRANCOS_5',           'Brancos',                       'Uso do banco',                                189, 214,  26, 'ALPHA',    0, false, true,  27),
(v_rt_id, 'VL_IOF',              'Valor do IOF',                  'IOF a recolher (2 decimais)',                215, 227,  13, 'MONETARY', 2, false, false, 28),
(v_rt_id, 'VL_ABATIMENTO',       'Valor de Abatimento',           'Abatimento concedido (2 decimais)',           228, 240,  13, 'MONETARY', 2, false, false, 29),
(v_rt_id, 'VL_DESCONTO',         'Valor do Desconto',             'Desconto concedido (2 decimais)',             241, 253,  13, 'MONETARY', 2, false, false, 30),
(v_rt_id, 'VL_PAGO',             'Valor Pago',                    'Valor principal recebido (2 decimais)',       254, 266,  13, 'MONETARY', 2, true,  false, 31),
(v_rt_id, 'VL_JUROS_MORA',       'Valor Juros/Mora',              'Juros e mora recebidos (2 decimais)',         267, 279,  13, 'MONETARY', 2, false, false, 32),
(v_rt_id, 'OUTROS_CREDITOS',     'Outros Créditos',               'Outros créditos recebidos (2 decimais)',      280, 292,  13, 'MONETARY', 2, false, false, 33),
(v_rt_id, 'BRANCOS_6',           'Brancos',                       'Uso do banco',                                293, 295,   3, 'ALPHA',    0, false, true,  34),
(v_rt_id, 'DT_CREDITO',          'Data de Crédito',               'Data do crédito ao cedente (DDMMAA)',         296, 301,   6, 'DATE',     0, false, false, 35),
(v_rt_id, 'BRANCOS_7',           'Brancos',                       'Uso do banco',                                302, 311,  10, 'ALPHA',    0, false, true,  36),
(v_rt_id, 'INSTR_CANCELADA',     'Instrução Cancelada',           'Instrução cancelada pelo banco',             312, 315,   4, 'NUM',      0, false, false, 37),
(v_rt_id, 'BRANCOS_8',           'Brancos',                       'Uso do banco',                                316, 318,   3, 'ALPHA',    0, false, true,  38),
(v_rt_id, 'MOTIVOS_REJEICAO',    'Motivos de Rejeição',           'Código(s) dos motivos de rejeição (10)',     319, 328,  10, 'ALPHA',    0, false, false, 39),
(v_rt_id, 'NOME_PAGADOR',        'Nome do Pagador',               'Nome do sacado',                             329, 358,  30, 'ALPHA',    0, false, false, 40),
(v_rt_id, 'BRANCOS_9',           'Brancos',                       'Uso do banco',                                359, 368,  10, 'ALPHA',    0, false, true,  41),
(v_rt_id, 'SACADOR',             'Sacador/Avalista',              'Nome do sacador ou avalista',                369, 383,  15, 'ALPHA',    0, false, false, 42),
(v_rt_id, 'BRANCOS_10',          'Brancos',                       'Uso do banco',                                384, 392,   9, 'ALPHA',    0, false, true,  43),
(v_rt_id, 'COD_LIQUIDACAO',      'Código de Liquidação',          'Forma de liquidação do título',              393, 394,   2, 'ALPHA',    0, false, false, 44),
(v_rt_id, 'SEQ_REGISTRO',        'Nº Sequencial do Registro',     'Sequencial no arquivo',                      395, 400,   6, 'NUM',      0, true,  false, 45);

-- -----------------------------------------------------------
-- RETORNO: TRAILER (tipo 9, pos 1='9')
-- -----------------------------------------------------------
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'TRAILER', 'Trailer do Arquivo de Retorno', 'TRAILER', 1, 1, '9', 3)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',          '9 = Trailer',                           1,   1,   1, 'NUM',      0, true,  false,  1),
(v_rt_id, 'COD_RETORNO',    'Código de Retorno',         '2 = Retorno',                            2,   2,   1, 'NUM',      0, true,  false,  2),
(v_rt_id, 'COD_SERVICO',    'Código de Serviço',         'Código do serviço',                      3,   4,   2, 'NUM',      0, true,  false,  3),
(v_rt_id, 'COD_BANCO',      'Código do Banco',           '237 = Bradesco',                         5,   7,   3, 'NUM',      0, true,  false,  4),
(v_rt_id, 'BRANCOS_1',      'Brancos',                   'Preencher com brancos',                   8,  17,  10, 'ALPHA',    0, false, true,   5),
(v_rt_id, 'QTD_TITULOS',    'Quantidade de Títulos',     'Total de títulos no arquivo',            18,  25,   8, 'NUM',      0, true,  false,  6),
(v_rt_id, 'VL_TOTAL',       'Valor Total',               'Valor total dos títulos (2 decimais)',   26,  39,  14, 'MONETARY', 2, true,  false,  7),
(v_rt_id, 'BRANCOS_2',      'Brancos',                   'Preencher com brancos',                  40, 394, 355, 'ALPHA',    0, false, true,   8),
(v_rt_id, 'SEQ_REGISTRO',   'Nº Sequencial do Registro', 'Sequencial no arquivo',                395, 400,   6, 'NUM',      0, true,  false,  9);

END $$;
