-- ============================================================
-- LayoutBank — Migration 002: Seed Itaú CNAB 240 e CNAB 400
--
-- Posições baseadas na especificação FEBRABAN/Itaú:
--   CNAB 240: Manual Técnico FEBRABAN v10.4
--   CNAB 400: Manual de Cobrança Itaú v15
-- Todas as posições são 1-based conforme FEBRABAN.
-- ============================================================

DO $$
DECLARE
  v_bank_id        UUID;
  v_layout_240_id  UUID;
  v_layout_400_id  UUID;
  v_rt_id          UUID;

BEGIN

-- ============================================================
-- BANCO
-- ============================================================
INSERT INTO banks (code, name, short_name)
VALUES ('341', 'Itaú Unibanco S.A.', 'itau')
RETURNING id INTO v_bank_id;

-- ============================================================
-- LAYOUT CNAB 240
-- ============================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB240',
  '10.4',
  'Itaú CNAB 240 - Pagamento de Títulos',
  240,
  'latin1',
  'Pagamento de boletos e títulos. Serviço 20. Segmento J.'
)
RETURNING id INTO v_layout_240_id;

-- ============================================================
-- CNAB 240 — HEADER DE ARQUIVO (tipo 0, pos 8 = ''0'')
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_240_id, 'HEADER_ARQUIVO', 'Header de Arquivo', 'HEADER', 8, 8, '0', 1)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',        'Código do Banco',                  'Código COMPE do banco (341 = Itaú)',                     1,   3,   3, 'NUM',   true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',     'Lote de Serviço',                  'Preencher com ''0000'' no Header de Arquivo',            4,   7,   4, 'NUM',   true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',    'Tipo de Registro',                 '0 = Header de Arquivo',                                  8,   8,   1, 'NUM',   true,  false, 3),
(v_rt_id, 'FILLER_1',         'Uso Exclusivo FEBRABAN/CNAB',      'Preencher com brancos',                                  9,  17,   9, 'ALPHA', false, true,  4),
(v_rt_id, 'TIPO_INSCRICAO',   'Tipo de Inscrição da Empresa',     '1 = CPF, 2 = CNPJ',                                     18,  18,   1, 'NUM',   true,  false, 5),
(v_rt_id, 'NUM_INSCRICAO',    'CNPJ / CPF da Empresa',            'CNPJ (14 dígitos) ou CPF (11 + 3 zeros à esquerda)',    19,  32,  14, 'NUM',   true,  false, 6),
(v_rt_id, 'COD_CONVENIO',     'Código do Convênio no Banco',      'Código do convênio firmado com o banco',                33,  52,  20, 'ALPHA', true,  false, 7),
(v_rt_id, 'NOME_EMPRESA',     'Nome da Empresa',                  'Nome da empresa cedente',                               53,  72,  20, 'ALPHA', true,  false, 8),
(v_rt_id, 'NOME_BANCO',       'Nome do Banco',                    'ITAU UNIBANCO S.A.',                                    73, 102,  30, 'ALPHA', true,  false, 9),
(v_rt_id, 'COD_COMPE',        'Código COMPE',                     'Preencher com brancos',                                103, 105,   3, 'ALPHA', false, true,  10),
(v_rt_id, 'FILLER_2',         'Uso Exclusivo FEBRABAN',           'Preencher com branco',                                 106, 106,   1, 'ALPHA', false, true,  11),
(v_rt_id, 'AGENCIA',          'Agência Mantenedora da Conta',     'Número da agência sem dígito',                         107, 110,   4, 'NUM',   true,  false, 12),
(v_rt_id, 'DIG_AGENCIA',      'Dígito Verificador da Agência',    'Dígito verificador da agência',                        111, 111,   1, 'ALPHA', true,  false, 13),
(v_rt_id, 'CONTA_CORRENTE',   'Número da Conta Corrente',         'Número da conta sem dígito',                           112, 131,  20, 'NUM',   true,  false, 14),
(v_rt_id, 'DIG_CONTA',        'Dígito Verificador da Conta',      'Dígito verificador da conta',                          132, 132,   1, 'NUM',   true,  false, 15),
(v_rt_id, 'DIG_AGENCIA_CONTA','Dígito Verificador Agência/Conta', 'Dígito verificador conjunto agência/conta',            133, 133,   1, 'ALPHA', false, false, 16),
(v_rt_id, 'INFO_COMPL',       'Informação Complementar',          'Uso exclusivo da empresa',                             134, 143,  10, 'ALPHA', false, true,  17),
(v_rt_id, 'COD_REM_RET',      'Código Remessa/Retorno',           '1 = Remessa, 2 = Retorno',                             144, 144,   1, 'NUM',   true,  false, 18),
(v_rt_id, 'DT_GERACAO',       'Data de Geração do Arquivo',       'Formato DDMMAAAA',                                     145, 152,   8, 'DATE',  true,  false, 19),
(v_rt_id, 'HR_GERACAO',       'Hora de Geração do Arquivo',       'Formato HHMMSS',                                       153, 158,   6, 'NUM',   true,  false, 20),
(v_rt_id, 'SEQ_ARQUIVO',      'Número Sequencial do Arquivo',     'Número sequencial controlado pela empresa',            159, 164,   6, 'NUM',   true,  false, 21),
(v_rt_id, 'VERSAO_LAYOUT',    'Versão do Layout do Arquivo',      '103 = CNAB 240 v10.3, 104 = v10.4',                   165, 166,   2, 'NUM',   true,  false, 22),
(v_rt_id, 'DENSIDADE',        'Densidade de Gravação',            'Preencher com zeros',                                  167, 171,   5, 'NUM',   false, true,  23),
(v_rt_id, 'RESERVADO_BANCO',  'Uso Reservado do Banco',           'Preencher com brancos',                                172, 191,  20, 'ALPHA', false, true,  24),
(v_rt_id, 'RESERVADO_EMP',    'Uso Reservado da Empresa',         'Preencher com brancos',                                192, 211,  20, 'ALPHA', false, true,  25),
(v_rt_id, 'FILLER_FIM',       'Uso Exclusivo FEBRABAN/CNAB',      'Preencher com brancos',                                212, 240,  29, 'ALPHA', false, true,  26);

-- ============================================================
-- CNAB 240 — HEADER DE LOTE (tipo 1, pos 8 = ''1'')
-- Serviço 20 = Pagamento de Títulos
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_240_id, 'HEADER_LOTE', 'Header de Lote', 'HEADER', 8, 8, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',       'Código do Banco',                   'Código COMPE do banco',                              1,   3,   3, 'NUM',   true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',    'Lote de Serviço',                   'Número sequencial do lote no arquivo',               4,   7,   4, 'NUM',   true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',   'Tipo de Registro',                  '1 = Header de Lote',                                 8,   8,   1, 'NUM',   true,  false, 3),
(v_rt_id, 'TIPO_OPERACAO',   'Tipo de Operação',                  'C = Crédito (Pagamento)',                            9,   9,   1, 'ALPHA', true,  false, 4),
(v_rt_id, 'TIPO_SERVICO',    'Tipo de Serviço',                   '20 = Pagamento de Títulos',                         10,  11,   2, 'NUM',   true,  false, 5),
(v_rt_id, 'FILLER_1',        'Uso Exclusivo FEBRABAN',            'Preencher com brancos',                              12,  13,   2, 'ALPHA', false, true,  6),
(v_rt_id, 'VERSAO_LOTE',     'Versão do Layout do Lote',          'Versão do layout do lote',                          14,  16,   3, 'NUM',   true,  false, 7),
(v_rt_id, 'FILLER_2',        'Uso Exclusivo FEBRABAN',            'Preencher com branco',                               17,  17,   1, 'ALPHA', false, true,  8),
(v_rt_id, 'TIPO_INSCRICAO',  'Tipo de Inscrição da Empresa',      '1 = CPF, 2 = CNPJ',                                 18,  18,   1, 'NUM',   true,  false, 9),
(v_rt_id, 'NUM_INSCRICAO',   'CNPJ / CPF da Empresa',             'CNPJ ou CPF da empresa',                            19,  32,  14, 'NUM',   true,  false, 10),
(v_rt_id, 'COD_CONVENIO',    'Código do Convênio no Banco',       'Código do convênio firmado com o banco',            33,  52,  20, 'ALPHA', true,  false, 11),
(v_rt_id, 'NOME_EMPRESA',    'Nome da Empresa',                   'Nome da empresa cedente',                           53,  72,  20, 'ALPHA', true,  false, 12),
(v_rt_id, 'INFO_COMPL',      'Informação Complementar',           'Finalidade do lote (uso da empresa)',               73, 102,  30, 'ALPHA', false, true,  13),
(v_rt_id, 'NUM_REM_RET',     'Número Retorno/Remessa',            'Número sequencial do arquivo',                     103, 112,  10, 'NUM',   true,  false, 14),
(v_rt_id, 'DT_GRAVACAO',     'Data de Gravação',                  'Data de geração do arquivo (DDMMAAAA)',            113, 120,   8, 'DATE',  true,  false, 15),
(v_rt_id, 'DT_CREDITO',      'Data do Crédito',                   'Data prevista para o crédito (DDMMAAAA)',          121, 128,   8, 'DATE',  false, false, 16),
(v_rt_id, 'FILLER_FIM',      'Uso Exclusivo FEBRABAN/CNAB',       'Preencher com brancos',                            129, 240, 112, 'ALPHA', false, true,  17);

-- ============================================================
-- CNAB 240 — DETALHE SEGMENTO J (tipo 3, pos 8=''3'', pos 14=''J'')
-- ============================================================
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_240_id, 'DETALHE_J', 'Detalhe Segmento J - Pagamento de Boleto', 'DETAIL',
  8, 8, '3',
  14, 14, 'J',
  3
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',      'Código do Banco',                    'Código COMPE do banco',                              1,   3,   3, 'NUM',       0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',   'Lote de Serviço',                    'Número do lote ao qual pertence o registro',         4,   7,   4, 'NUM',       0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',                   '3 = Detalhe',                                        8,   8,   1, 'NUM',       0, true,  false, 3),
(v_rt_id, 'SEQ_REGISTRO',   'Nº Sequencial do Registro no Lote', 'Sequencial dentro do lote, iniciando em 1',           9,  13,   5, 'NUM',       0, true,  false, 4),
(v_rt_id, 'COD_SEGMENTO',   'Código de Segmento',                 'J = Pagamento de boleto de cobrança',               14,  14,   1, 'ALPHA',     0, true,  false, 5),
(v_rt_id, 'TIPO_MOVIMENTO', 'Tipo de Movimento',                  '0 = Inclusão, 5 = Alteração, 9 = Exclusão',         15,  15,   1, 'NUM',       0, true,  false, 6),
(v_rt_id, 'COD_INSTRUCAO',  'Código de Instrução para Movimento', '00 = Inclusão de registro detalhe liberado',         16,  17,   2, 'NUM',       0, true,  false, 7),
(v_rt_id, 'COD_BARRAS',     'Código de Barras do Título',         'Linha digitável ou código de barras (44 posições)',  18,  61,  44, 'NUM',       0, true,  false, 8),
(v_rt_id, 'NOME_CEDENTE',   'Nome do Cedente',                    'Nome do beneficiário do boleto',                    62,  94,  33, 'ALPHA',     0, true,  false, 9),
(v_rt_id, 'DT_VENCIMENTO',  'Data do Vencimento',                 'Data de vencimento do título (DDMMAAAA)',           95, 102,   8, 'DATE',      0, true,  false, 10),
(v_rt_id, 'VL_NOMINAL',     'Valor Nominal do Título',            'Valor original do boleto (2 casas decimais)',       103, 116,  14, 'MONETARY',  2, true,  false, 11),
(v_rt_id, 'VL_DESCONTO',    'Valor do Desconto + Abatimento',     'Soma de desconto e abatimento (2 casas decimais)',  117, 130,  14, 'MONETARY',  2, false, false, 12),
(v_rt_id, 'VL_MORA',        'Valor da Mora + Multa',              'Soma de mora e multa (2 casas decimais)',           131, 144,  14, 'MONETARY',  2, false, false, 13),
(v_rt_id, 'DT_PAGAMENTO',   'Data do Pagamento',                  'Data efetiva de pagamento (DDMMAAAA)',              145, 152,   8, 'DATE',      0, true,  false, 14),
(v_rt_id, 'VL_PAGAMENTO',   'Valor do Pagamento',                 'Valor efetivo do pagamento (2 casas decimais)',     153, 166,  14, 'MONETARY',  2, true,  false, 15),
(v_rt_id, 'DOC_EMPRESA',    'Nº do Documento — Empresa',          'Número do documento atribuído pela empresa',        167, 181,  15, 'ALPHA',     0, false, false, 16),
(v_rt_id, 'DOC_BANCO',      'Nº do Documento — Banco',            'Número do documento atribuído pelo banco',          182, 196,  15, 'ALPHA',     0, false, false, 17),
(v_rt_id, 'FILLER_1',       'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                             197, 202,   6, 'ALPHA',     0, false, true,  18),
(v_rt_id, 'COD_CAMARA',     'Código da Câmara Centralizadora',    '18 = TED, 700 = DOC, 000 = Boleto',                203, 209,   7, 'NUM',       0, false, false, 19),
(v_rt_id, 'FILLER_FIM',     'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                             210, 240,  31, 'ALPHA',     0, false, true,  20);

-- ============================================================
-- CNAB 240 — TRAILER DE LOTE (tipo 5, pos 8 = ''5'')
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_240_id, 'TRAILER_LOTE', 'Trailer de Lote', 'TRAILER', 8, 8, '5', 4)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, validation_rules, sort_order) VALUES
(v_rt_id, 'COD_BANCO',     'Código do Banco',                  'Código COMPE do banco',                              1,   3,   3, 'NUM',      0, true,  false, NULL, 1),
(v_rt_id, 'LOTE_SERVICO',  'Lote de Serviço',                  'Número do lote',                                     4,   7,   4, 'NUM',      0, true,  false, NULL, 2),
(v_rt_id, 'TIPO_REGISTRO', 'Tipo de Registro',                 '5 = Trailer de Lote',                                8,   8,   1, 'NUM',      0, true,  false, NULL, 3),
(v_rt_id, 'FILLER_1',      'Uso Exclusivo FEBRABAN',           'Preencher com brancos',                              9,  17,   9, 'ALPHA',    0, false, true,  NULL, 4),
(v_rt_id, 'QTD_REGISTROS', 'Quantidade de Registros no Lote',  'Total de registros incluindo header e trailer',     18,  23,   6, 'NUM',      0, true,  false, '{"crossRecord": "lote_count"}', 5),
(v_rt_id, 'SOMA_VALORES',  'Somatória dos Valores',            'Soma total dos valores pagos no lote (2 decimais)', 24,  41,  18, 'MONETARY', 2, true,  false, NULL, 6),
(v_rt_id, 'SOMA_MOEDAS',   'Somatória de Moedas',              'Quantidade de moedas do lote (5 decimais)',         42,  59,  18, 'MONETARY', 5, false, false, NULL, 7),
(v_rt_id, 'NUM_AVISO',     'Número do Aviso de Débito',        'Número do aviso de débito emitido pelo banco',      60,  65,   6, 'NUM',      0, false, false, NULL, 8),
(v_rt_id, 'FILLER_FIM',    'Uso Exclusivo FEBRABAN/CNAB',      'Preencher com brancos',                             66, 240, 175, 'ALPHA',    0, false, true,  NULL, 9);

-- ============================================================
-- CNAB 240 — TRAILER DE ARQUIVO (tipo 9, pos 8 = ''9'')
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_240_id, 'TRAILER_ARQUIVO', 'Trailer de Arquivo', 'TRAILER', 8, 8, '9', 5)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, validation_rules, sort_order) VALUES
(v_rt_id, 'COD_BANCO',     'Código do Banco',                    'Código COMPE do banco',                                1,   3,   3, 'NUM',  true,  false, NULL, 1),
(v_rt_id, 'LOTE_SERVICO',  'Lote de Serviço',                    'Preencher com 9999',                                   4,   7,   4, 'NUM',  true,  false, NULL, 2),
(v_rt_id, 'TIPO_REGISTRO', 'Tipo de Registro',                   '9 = Trailer de Arquivo',                               8,   8,   1, 'NUM',  true,  false, NULL, 3),
(v_rt_id, 'FILLER_1',      'Uso Exclusivo FEBRABAN',             'Preencher com brancos',                                9,  17,   9, 'ALPHA', false, true,  NULL, 4),
(v_rt_id, 'QTD_LOTES',     'Quantidade de Lotes do Arquivo',     'Total de lotes no arquivo',                           18,  23,   6, 'NUM',  true,  false, '{"crossRecord": "total_lotes"}', 5),
(v_rt_id, 'QTD_REGISTROS', 'Quantidade de Registros do Arquivo', 'Total de registros no arquivo incluindo header e trailer', 24, 29, 6, 'NUM', true, false, '{"crossRecord": "total_registros"}', 6),
(v_rt_id, 'QTD_CONTAS',    'Quantidade de Contas (Futura)',      'Uso futuro — preencher com zeros',                    30,  35,   6, 'NUM',  false, true,  NULL, 7),
(v_rt_id, 'FILLER_FIM',    'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                               36, 240, 205, 'ALPHA', false, true,  NULL, 8);

-- ============================================================
-- LAYOUT CNAB 400
-- ============================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB400',
  '15.0',
  'Itaú CNAB 400 - Cobrança (Remessa)',
  400,
  'latin1',
  'Cobrança simples, sem registro e com registro. Layout Itaú v15.'
)
RETURNING id INTO v_layout_400_id;

-- ============================================================
-- CNAB 400 — HEADER (tipo 0, pos 1 = ''0'')
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_400_id, 'HEADER', 'Header do Arquivo', 'HEADER', 1, 1, '0', 1)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',   'Tipo de Registro',               '0 = Header de Arquivo',                                  1,   1,   1, 'NUM',   true,  false, 1),
(v_rt_id, 'COD_OPERACAO',    'Código de Operação',             '1 = Remessa',                                            2,   2,   1, 'NUM',   true,  false, 2),
(v_rt_id, 'LITERAL_REM',     'Literal Remessa',                '"REMESSA"',                                              3,   9,   7, 'ALPHA', true,  false, 3),
(v_rt_id, 'COD_SERVICO',     'Código de Serviço',              '1 = Cobrança',                                          10,  10,   1, 'NUM',   true,  false, 4),
(v_rt_id, 'LITERAL_COB',     'Literal Cobrança',               '"COBRANCA"',                                            11,  15,   5, 'ALPHA', false, false, 5),
(v_rt_id, 'AGENCIA',         'Agência Cedente',                'Número da agência sem dígito verificador',              16,  21,   6, 'NUM',   true,  false, 6),
(v_rt_id, 'ZEROS_1',         'Zeros',                          'Preencher com zeros',                                   22,  22,   1, 'NUM',   false, true,  7),
(v_rt_id, 'CONTA_CORRENTE',  'Conta Corrente',                 'Número da conta corrente sem dígito',                   23,  30,   8, 'NUM',   true,  false, 8),
(v_rt_id, 'DAC',             'DAC',                            'Dígito de auto-conferência da agência/conta',           31,  31,   1, 'NUM',   true,  false, 9),
(v_rt_id, 'FILLER_1',        'Uso Exclusivo Itaú',             'Preencher com brancos',                                 32,  46,  15, 'ALPHA', false, true,  10),
(v_rt_id, 'NOME_EMPRESA',    'Nome da Empresa',                'Nome do cedente',                                       47,  76,  30, 'ALPHA', true,  false, 11),
(v_rt_id, 'NOME_BANCO',      'Nome do Banco',                  '"BANCO ITAU SA"',                                       77,  94,  18, 'ALPHA', true,  false, 12),
(v_rt_id, 'FILLER_2',        'Uso Exclusivo Itaú',             'Preencher com branco',                                  95,  95,   1, 'ALPHA', false, true,  13),
(v_rt_id, 'COD_REM_RET',     'Código Remessa/Retorno',         '1 = Remessa, 2 = Retorno',                              96,  96,   1, 'NUM',   true,  false, 14),
(v_rt_id, 'DT_GERACAO',      'Data de Geração do Arquivo',     'Formato DDMMAAAA',                                      97, 104,   8, 'DATE',  true,  false, 15),
(v_rt_id, 'FILLER_FIM',      'Uso Exclusivo Itaú',             'Preencher com brancos',                                105, 394, 290, 'ALPHA', false, true,  16),
(v_rt_id, 'SEQ_ARQUIVO',     'Nº Sequencial do Arquivo',       'Número sequencial do arquivo',                         395, 400,   6, 'NUM',   true,  false, 17);

-- ============================================================
-- CNAB 400 — DETALHE (tipo 1, pos 1 = ''1'')
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_400_id, 'DETALHE', 'Detalhe do Arquivo', 'DETAIL', 1, 1, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',   'Tipo de Registro',               '1 = Detalhe',                                            1,   1,   1, 'NUM',       0, true,  false, 1),
(v_rt_id, 'COD_OCORRENCIA',  'Código de Ocorrência',           '01=Entrada Título, 02=Pedido Baixa, ...',                2,   3,   2, 'NUM',       0, true,  false, 2),
(v_rt_id, 'NUM_DOCUMENTO',   'Número do Documento',            'Número atribuído pela empresa',                          4,  17,  14, 'ALPHA',     0, false, false, 3),
(v_rt_id, 'AGENCIA',         'Agência Cedente',                'Número da agência sem dígito',                          18,  22,   5, 'NUM',       0, true,  false, 4),
(v_rt_id, 'ZEROS_1',         'Zeros',                          'Preencher com zeros',                                   23,  23,   1, 'NUM',       0, false, true,  5),
(v_rt_id, 'CONTA_CORRENTE',  'Conta Corrente',                 'Número da conta sem dígito',                            24,  30,   7, 'NUM',       0, true,  false, 6),
(v_rt_id, 'DAC',             'DAC',                            'Dígito de auto-conferência',                            31,  31,   1, 'NUM',       0, true,  false, 7),
(v_rt_id, 'FILLER_1',        'Uso Exclusivo Itaú',             'Preencher com brancos',                                 32,  32,   1, 'ALPHA',     0, false, true,  8),
(v_rt_id, 'NOSSO_NUMERO',    'Nosso Número',                   'Número do título no banco',                             33,  46,  14, 'NUM',       0, true,  false, 9),
(v_rt_id, 'FILLER_2',        'Uso Exclusivo Itaú',             'Preencher com brancos',                                 47,  62,  16, 'ALPHA',     0, false, true,  10),
(v_rt_id, 'VL_ABATIMENTO',   'Valor de Abatimento',            'Valor do abatimento (2 decimais)',                      63,  73,  11, 'MONETARY',  2, false, false, 11),
(v_rt_id, 'IND_DESCONTO',    'Indicativo de Desconto',         'A = Valor fixo, B = Percentual',                        74,  74,   1, 'ALPHA',     0, false, false, 12),
(v_rt_id, 'DT_DESCONTO',     'Data para Desconto',             'Data limite para desconto (DDMMAA)',                    75,  80,   6, 'DATE',      0, false, false, 13),
(v_rt_id, 'VL_DESCONTO',     'Valor do Desconto',              'Valor do desconto (2 decimais)',                        81,  92,  12, 'MONETARY',  2, false, false, 14),
(v_rt_id, 'VL_IOF',          'Valor do IOF',                   'Valor do IOF a recolher (2 decimais)',                  93, 104,  12, 'MONETARY',  2, false, false, 15),
(v_rt_id, 'VL_MORA',         'Valor da Mora',                  'Mora por dia de atraso (2 decimais)',                  105, 116,  12, 'MONETARY',  2, false, false, 16),
(v_rt_id, 'DOC_EMPRESA',     'Número do Documento — Empresa',  'Número do documento/pedido da empresa',                117, 126,  10, 'ALPHA',     0, false, false, 17),
(v_rt_id, 'DT_VENCIMENTO',   'Data de Vencimento',             'Data de vencimento do título (DDMMAAAA)',              127, 134,   8, 'DATE',      0, true,  false, 18),
(v_rt_id, 'VL_NOMINAL',      'Valor Nominal do Título',        'Valor do boleto (2 decimais)',                         135, 146,  12, 'MONETARY',  2, true,  false, 19),
(v_rt_id, 'BANCO_COBRADOR',  'Banco Cobrador',                 'Código do banco cobrador',                             147, 149,   3, 'NUM',       0, false, false, 20),
(v_rt_id, 'AGENCIA_COB',     'Agência Cobradora',              'Agência da cobrança',                                  150, 154,   5, 'NUM',       0, false, false, 21),
(v_rt_id, 'ESPECIE_DOC',     'Espécie do Documento',           'DM=Duplicata, NP=Nota Promissória, RC=Recibo',         155, 156,   2, 'ALPHA',     0, true,  false, 22),
(v_rt_id, 'ACEITE',          'Aceite',                         'A = Aceite, N = Sem aceite',                           157, 157,   1, 'ALPHA',     0, true,  false, 23),
(v_rt_id, 'DT_EMISSAO',      'Data de Emissão',                'Data de emissão do título (DDMMAAAA)',                 158, 165,   8, 'DATE',      0, true,  false, 24),
(v_rt_id, 'INSTRUCAO_1',     '1ª Instrução de Cobrança',       '06=Protestar, 09=Baixar, 00=Sem instrução',           166, 167,   2, 'NUM',       0, true,  false, 25),
(v_rt_id, 'INSTRUCAO_2',     '2ª Instrução de Cobrança',       'Segunda instrução de cobrança',                        168, 169,   2, 'NUM',       0, true,  false, 26),
(v_rt_id, 'VL_MORA_DIA',     'Valor por Dia de Mora',          'Valor de mora diária (2 decimais)',                    170, 181,  12, 'MONETARY',  2, false, false, 27),
(v_rt_id, 'DT_LIM_DESC',     'Data Limite para Desconto',      'Data limite (DDMMAAAA)',                               182, 189,   8, 'DATE',      0, false, false, 28),
(v_rt_id, 'VL_DESC_BONIF',   'Valor Desconto/Bonificação',     'Valor do desconto/bonificação (2 decimais)',           190, 201,  12, 'MONETARY',  2, false, false, 29),
(v_rt_id, 'CNPJ_CPF_SAC',    'CNPJ/CPF do Sacado',             'CNPJ (14) ou CPF (11)',                               202, 212,  11, 'NUM',       0, true,  false, 30),
(v_rt_id, 'NOME_SACADO',     'Nome do Sacado',                 'Nome do pagador',                                      213, 252,  40, 'ALPHA',     0, true,  false, 31),
(v_rt_id, 'FILLER_3',        'Uso Exclusivo Itaú',             'Preencher com brancos',                                253, 274,  22, 'ALPHA',     0, false, true,  32),
(v_rt_id, 'ENDERECO_SAC',    'Endereço do Sacado',             'Rua, número, complemento',                             275, 314,  40, 'ALPHA',     0, false, false, 33),
(v_rt_id, 'BAIRRO_SAC',      'Bairro do Sacado',               'Bairro do sacado',                                    315, 326,  12, 'ALPHA',     0, false, false, 34),
(v_rt_id, 'CEP_SAC',         'CEP do Sacado',                  'CEP sem hífen (8 dígitos)',                            327, 332,   6, 'NUM',       0, false, false, 35),
(v_rt_id, 'CIDADE_SAC',      'Cidade do Sacado',               'Cidade do sacado',                                    333, 344,  12, 'ALPHA',     0, false, false, 36),
(v_rt_id, 'UF_SAC',          'UF do Sacado',                   'Estado do sacado (2 letras)',                          345, 346,   2, 'ALPHA',     0, false, false, 37),
(v_rt_id, 'MENSAGEM',        'Mensagem / Uso do Banco',        'Mensagem no boleto ou dados para o banco',            347, 394,  48, 'ALPHA',     0, false, false, 38),
(v_rt_id, 'SEQ_REGISTRO',    'Nº Sequencial do Registro',      'Número sequencial no arquivo',                        395, 400,   6, 'NUM',       0, true,  false, 39);

-- ============================================================
-- CNAB 400 — TRAILER (tipo 9, pos 1 = ''9'')
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_400_id, 'TRAILER', 'Trailer do Arquivo', 'TRAILER', 1, 1, '9', 3)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, validation_rules, sort_order) VALUES
(v_rt_id, 'TIPO_REGISTRO',   'Tipo de Registro',               '9 = Trailer de Arquivo',                                 1,   1,   1, 'NUM',      0, true,  false, NULL, 1),
(v_rt_id, 'COD_BANCO',       'Código do Banco',                'Código COMPE — 341 = Itaú',                              2,   7,   6, 'ALPHA',    0, true,  false, NULL, 2),
(v_rt_id, 'QTD_REGISTROS',   'Quantidade de Registros',        'Total de registros no arquivo',                          8,  17,  10, 'NUM',      0, true,  false, '{"crossRecord": "total_registros"}', 3),
(v_rt_id, 'VL_TOTAL',        'Valor Total dos Títulos',        'Soma de todos os valores nominais (2 decimais)',         18,  29,  12, 'MONETARY', 2, true,  false, NULL, 4),
(v_rt_id, 'FILLER_FIM',      'Uso Exclusivo Itaú',             'Preencher com brancos',                                  30, 394, 365, 'ALPHA',    0, false, true,  NULL, 5),
(v_rt_id, 'SEQ_ARQUIVO',     'Nº Sequencial do Arquivo',       'Número sequencial do arquivo',                          395, 400,   6, 'NUM',      0, true,  false, NULL, 6);

END $$;
