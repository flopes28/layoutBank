-- ============================================================
-- LayoutBank — Migration 005: Itaú CNAB 240 Cobrança Bancária
--
-- Adiciona dois layouts distintos para o Itaú 240 Cobrança:
--   CNAB240_COBRANCA_REM — Remessa (empresa → banco)
--   CNAB240_COBRANCA_RET — Retorno (banco → empresa)
--
-- Baseado em: Manual FEBRABAN Cobrança Bancária CNAB 240, Jan/2017
-- Posições 1-based conforme FEBRABAN. Serviço 01 = Cobrança.
-- ============================================================

-- ============================================================
-- 0. Ajusta coluna format e CHECK constraint
-- ============================================================
ALTER TABLE cnab_layouts ALTER COLUMN format TYPE VARCHAR(30);

ALTER TABLE cnab_layouts DROP CONSTRAINT IF EXISTS chk_format;
ALTER TABLE cnab_layouts ADD CONSTRAINT chk_format
  CHECK (format IN (
    'CNAB240',
    'CNAB400',
    'CNAB400_REMESSA',
    'CNAB400_RETORNO',
    'CNAB240_COBRANCA_REM',
    'CNAB240_COBRANCA_RET'
  ));

-- ============================================================
-- 1. Insere os layouts e todos os tipos de registro + campos
-- ============================================================
DO $$
DECLARE
  v_bank_id        UUID;
  v_layout_rem_id  UUID;
  v_layout_ret_id  UUID;
  v_rt_id          UUID;

BEGIN

SELECT id INTO v_bank_id FROM banks WHERE code = '341';

-- ============================================================
-- LAYOUT: CNAB240 Cobrança Remessa
-- ============================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB240_COBRANCA_REM',
  '2017.01',
  'Itaú CNAB 240 - Cobrança Bancária Remessa',
  240,
  'latin1',
  'Cobrança bancária remessa. Serviço 01. Segmentos P, Q, R. FEBRABAN Jan/2017.'
)
RETURNING id INTO v_layout_rem_id;

-- ============================================================
-- REMESSA — HEADER DE ARQUIVO (tipo 0)
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'HEADER_ARQUIVO', 'Header de Arquivo', 'HEADER', 8, 8, '0', 1)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',          'Código do Banco',                  'Código COMPE do banco (341 = Itaú)',                        1,   3,   3, 'NUM',   true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',       'Lote de Serviço',                  'Preencher com ''0000'' no Header de Arquivo',               4,   7,   4, 'NUM',   true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',      'Tipo de Registro',                 '0 = Header de Arquivo',                                    8,   8,   1, 'NUM',   true,  false, 3),
(v_rt_id, 'FILLER_1',           'Uso Exclusivo FEBRABAN/CNAB',      'Preencher com brancos',                                    9,  17,   9, 'ALPHA', false, true,  4),
(v_rt_id, 'TIPO_INSCRICAO',     'Tipo de Inscrição da Empresa',     '1 = CPF, 2 = CNPJ',                                       18,  18,   1, 'NUM',   true,  false, 5),
(v_rt_id, 'NUM_INSCRICAO',      'CNPJ / CPF da Empresa',            'CNPJ (14 dígitos) ou CPF (11 + 3 zeros à esquerda)',       19,  32,  14, 'NUM',   true,  false, 6),
(v_rt_id, 'COD_CONVENIO',       'Código do Convênio no Banco',      'Código de convênio de cobrança firmado com o Itaú',        33,  52,  20, 'ALPHA', true,  false, 7),
(v_rt_id, 'NOME_EMPRESA',       'Nome da Empresa',                  'Nome do cedente (empresa)',                                53,  72,  20, 'ALPHA', true,  false, 8),
(v_rt_id, 'NOME_BANCO',         'Nome do Banco',                    'ITAU UNIBANCO S.A.',                                      73, 102,  30, 'ALPHA', true,  false, 9),
(v_rt_id, 'COD_COMPE',          'Código COMPE / Uso Banco',         'Uso exclusivo do banco',                                 103, 105,   3, 'ALPHA', false, true,  10),
(v_rt_id, 'FILLER_2',           'Uso Exclusivo FEBRABAN',           'Preencher com branco',                                   106, 106,   1, 'ALPHA', false, true,  11),
(v_rt_id, 'AGENCIA',            'Agência Mantenedora da Conta',     'Número da agência sem dígito',                           107, 110,   4, 'NUM',   true,  false, 12),
(v_rt_id, 'DIG_AGENCIA',        'Dígito Verificador da Agência',    'Dígito verificador da agência',                          111, 111,   1, 'ALPHA', true,  false, 13),
(v_rt_id, 'CONTA_CORRENTE',     'Número da Conta Corrente',         'Número da conta corrente sem dígito',                    112, 131,  20, 'NUM',   true,  false, 14),
(v_rt_id, 'DIG_CONTA',          'Dígito Verificador da Conta',      'Dígito verificador da conta',                            132, 132,   1, 'ALPHA', true,  false, 15),
(v_rt_id, 'DIG_AGENCIA_CONTA',  'Dígito Verificador Ag/Conta',      'Dígito verificador conjunto agência/conta',              133, 133,   1, 'ALPHA', false, false, 16),
(v_rt_id, 'INFO_COMPL',         'Informação Complementar',          'Uso exclusivo da empresa (9 posições)',                  134, 142,   9, 'ALPHA', false, true,  17),
(v_rt_id, 'COD_REM_RET',        'Código Remessa/Retorno',           '1 = Remessa, 2 = Retorno',                               143, 143,   1, 'NUM',   true,  false, 18),
(v_rt_id, 'DT_GERACAO',         'Data de Geração do Arquivo',       'Formato DDMMAAAA',                                       144, 151,   8, 'DATE',  true,  false, 19),
(v_rt_id, 'HR_GERACAO',         'Hora de Geração do Arquivo',       'Formato HHMMSS',                                         152, 157,   6, 'NUM',   true,  false, 20),
(v_rt_id, 'SEQ_ARQUIVO',        'Número Sequencial do Arquivo',     'Sequencial controlado pela empresa',                     158, 163,   6, 'NUM',   true,  false, 21),
(v_rt_id, 'VERSAO_LAYOUT',      'Versão do Layout do Arquivo',      '081 = Cobrança FEBRABAN Jan/2017',                       164, 165,   2, 'NUM',   true,  false, 22),
(v_rt_id, 'DENSIDADE',          'Densidade de Gravação',            'Preencher com zeros',                                    166, 170,   5, 'NUM',   false, true,  23),
(v_rt_id, 'RESERVADO_BANCO',    'Uso Reservado do Banco',           'Preencher com brancos',                                  171, 190,  20, 'ALPHA', false, true,  24),
(v_rt_id, 'RESERVADO_EMP',      'Uso Reservado da Empresa',         'Preencher com brancos',                                  191, 210,  20, 'ALPHA', false, true,  25),
(v_rt_id, 'FILLER_FIM',         'Uso Exclusivo FEBRABAN/CNAB',      'Preencher com brancos',                                  211, 240,  30, 'ALPHA', false, true,  26);

-- ============================================================
-- REMESSA — HEADER DE LOTE (tipo 1, operação R, serviço 01)
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'HEADER_LOTE', 'Header de Lote - Cobrança Remessa', 'HEADER', 8, 8, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',      'Código do Banco',                   'Código COMPE do banco',                              1,   3,   3, 'NUM',   true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',   'Lote de Serviço',                   'Número sequencial do lote',                          4,   7,   4, 'NUM',   true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',                  '1 = Header de Lote',                                 8,   8,   1, 'NUM',   true,  false, 3),
(v_rt_id, 'TIPO_OPERACAO',  'Tipo de Operação',                  'R = Remessa (cobrança enviada ao banco)',            9,   9,   1, 'ALPHA', true,  false, 4),
(v_rt_id, 'TIPO_SERVICO',   'Tipo de Serviço',                   '01 = Cobrança',                                     10,  11,   2, 'NUM',   true,  false, 5),
(v_rt_id, 'FILLER_1',       'Uso Exclusivo FEBRABAN',            'Preencher com brancos',                             12,  13,   2, 'ALPHA', false, true,  6),
(v_rt_id, 'VERSAO_LOTE',    'Versão do Layout do Lote',          'Versão do layout do lote',                          14,  16,   3, 'NUM',   true,  false, 7),
(v_rt_id, 'FILLER_2',       'Uso Exclusivo FEBRABAN',            'Preencher com branco',                              17,  17,   1, 'ALPHA', false, true,  8),
(v_rt_id, 'TIPO_INSCRICAO', 'Tipo de Inscrição da Empresa',      '1 = CPF, 2 = CNPJ',                                 18,  18,   1, 'NUM',   true,  false, 9),
(v_rt_id, 'NUM_INSCRICAO',  'CNPJ / CPF da Empresa',             'CNPJ ou CPF da empresa cedente',                    19,  32,  14, 'NUM',   true,  false, 10),
(v_rt_id, 'COD_CONVENIO',   'Código do Convênio no Banco',       'Código do convênio de cobrança',                    33,  52,  20, 'ALPHA', true,  false, 11),
(v_rt_id, 'NOME_EMPRESA',   'Nome da Empresa',                   'Nome do cedente',                                   53,  72,  20, 'ALPHA', true,  false, 12),
(v_rt_id, 'INFO_COMPL',     'Informação Complementar',           'Finalidade do lote / uso da empresa',               73, 102,  30, 'ALPHA', false, true,  13),
(v_rt_id, 'NUM_REMESSA',    'Número da Remessa',                 'Número sequencial do arquivo de remessa',          103, 112,  10, 'NUM',   true,  false, 14),
(v_rt_id, 'DT_GRAVACAO',    'Data de Gravação',                  'Data de geração do arquivo (DDMMAAAA)',            113, 120,   8, 'DATE',  true,  false, 15),
(v_rt_id, 'DT_CREDITO',     'Data do Crédito',                   'Data prevista para o crédito (DDMMAAAA)',          121, 128,   8, 'DATE',  false, false, 16),
(v_rt_id, 'FILLER_FIM',     'Uso Exclusivo FEBRABAN/CNAB',       'Preencher com brancos',                            129, 240, 112, 'ALPHA', false, true,  17);

-- ============================================================
-- REMESSA — DETALHE SEGMENTO P (tipo 3, segmento P)
-- Dados do título: agência/conta cedente, nosso número, vencimento, valor
-- ============================================================
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_rem_id, 'DETALHE_P', 'Detalhe Segmento P - Dados do Título (Remessa)', 'DETAIL',
  8, 8, '3',
  14, 14, 'P',
  3
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',           'Código do Banco',                    'Código COMPE do banco',                                  1,   3,   3, 'NUM',      0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',        'Lote de Serviço',                    'Número do lote ao qual pertence o registro',             4,   7,   4, 'NUM',      0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',                   '3 = Detalhe',                                            8,   8,   1, 'NUM',      0, true,  false, 3),
(v_rt_id, 'SEQ_REGISTRO',        'Nº Sequencial do Registro no Lote', 'Sequencial dentro do lote, iniciando em 1',               9,  13,   5, 'NUM',      0, true,  false, 4),
(v_rt_id, 'COD_SEGMENTO',        'Código do Segmento',                 'P = Dados do Título',                                   14,  14,   1, 'ALPHA',    0, true,  false, 5),
(v_rt_id, 'TIPO_MOVIMENTO',      'Tipo de Movimento',                  '0 = Inclusão, 5 = Alteração, 9 = Exclusão',             15,  15,   1, 'NUM',      0, true,  false, 6),
(v_rt_id, 'COD_INSTRUCAO',       'Código de Instrução para Movimento', '01 = Inclusão de registro',                             16,  17,   2, 'NUM',      0, true,  false, 7),
(v_rt_id, 'AGENCIA',             'Agência Mantenedora da Conta',       'Agência da conta do cedente (sem dígito)',              18,  22,   5, 'NUM',      0, true,  false, 8),
(v_rt_id, 'DIG_AGENCIA',         'Dígito Verificador da Agência',      'Dígito verificador da agência',                        23,  23,   1, 'ALPHA',    0, true,  false, 9),
(v_rt_id, 'CONTA_CORRENTE',      'Número da Conta Corrente',           'Conta do cedente sem dígito',                          24,  38,  15, 'NUM',      0, true,  false, 10),
(v_rt_id, 'DIG_CONTA',           'Dígito Verificador da Conta',        'Dígito verificador da conta',                          39,  39,   1, 'ALPHA',    0, true,  false, 11),
(v_rt_id, 'DIG_AGENCIA_CONTA',   'Dígito Verificador Ag/Conta',        'Dígito verificador conjunto agência/conta',            40,  40,   1, 'ALPHA',    0, false, false, 12),
(v_rt_id, 'NOSSO_NUMERO',        'Identificação do Título no Banco',   'Nosso Número (8 dígitos Itaú)',                        41,  48,   8, 'NUM',      0, true,  false, 13),
(v_rt_id, 'TIPO_CARTEIRA',       'Tipo da Carteira',                   '1 = Cobrança Simples, 3 = Caucionada, 4 = Descontada', 49,  49,   1, 'NUM',      0, true,  false, 14),
(v_rt_id, 'FORMA_CADASTRO',      'Forma de Cadastramento do Título',   '1 = Com cadastramento (Eletrônico), 2 = Sem',          50,  50,   1, 'NUM',      0, true,  false, 15),
(v_rt_id, 'TIPO_DOCUMENTO',      'Tipo do Documento',                  '1 = Tradicional, 2 = Escritural',                      51,  51,   1, 'NUM',      0, false, false, 16),
(v_rt_id, 'TIPO_EMISSAO',        'Identificação da Emissão do Boleto', '1 = Banco emite, 2 = Empresa emite',                   52,  52,   1, 'NUM',      0, true,  false, 17),
(v_rt_id, 'TIPO_DISTRIBUICAO',   'Identificação da Distribuição',      '1 = Banco distribui, 2 = Empresa distribui',           53,  53,   1, 'NUM',      0, true,  false, 18),
(v_rt_id, 'SEU_NUMERO',          'Número do Documento — Empresa',      'Número do documento atribuído pela empresa',           54,  68,  15, 'ALPHA',    0, true,  false, 19),
(v_rt_id, 'JUROS_MORA_CODIGO',   'Código do Juro de Mora',             '1 = Valor/dia, 2 = Taxa mensal, 3 = Isento',           69,  69,   1, 'NUM',      0, false, false, 20),
(v_rt_id, 'DT_JUROS_MORA',       'Data do Juro de Mora',               'Data a partir da qual incide juro (DDMMAAAA)',         70,  77,   8, 'DATE',     0, false, false, 21),
(v_rt_id, 'DT_VENCIMENTO',       'Data de Vencimento do Título',       'Data de vencimento do título (DDMMAAAA)',              78,  85,   8, 'DATE',     0, true,  false, 22),
(v_rt_id, 'VL_TITULO',           'Valor Nominal do Título',            '9(13)V9(2) — valor do título com 2 casas decimais',    86, 100,  15, 'MONETARY', 2, true,  false, 23),
(v_rt_id, 'AGENCIA_COBRADORA',   'Agência Cobradora',                  'Código da agência cobradora (banco destino)',         101, 105,   5, 'NUM',      0, false, false, 24),
(v_rt_id, 'DIG_AGENCIA_COB',     'Dígito Agência Cobradora',           'Dígito verificador da agência cobradora',             106, 106,   1, 'ALPHA',    0, false, false, 25),
(v_rt_id, 'ESPECIE_TITULO',      'Espécie do Título',                  '01=DM, 02=NP, 03=NS, 04=ME, 05=REC, 99=Outros',      107, 108,   2, 'NUM',      0, true,  false, 26),
(v_rt_id, 'ACEITE',              'Aceite',                             'A = Aceite, N = Não Aceite',                          109, 109,   1, 'ALPHA',    0, true,  false, 27),
(v_rt_id, 'DT_EMISSAO',          'Data de Emissão do Título',          'Data de emissão do título (DDMMAAAA)',                110, 117,   8, 'DATE',     0, true,  false, 28),
(v_rt_id, 'DESCONTO_CODIGO',     'Código do Desconto',                 '0=Sem, 1=Valor fixo até data, 2=Percentual',         118, 118,   1, 'NUM',      0, false, false, 29),
(v_rt_id, 'DT_DESCONTO',         'Data do Desconto',                   'Data limite para desconto (DDMMAAAA)',                119, 126,   8, 'DATE',     0, false, false, 30),
(v_rt_id, 'VL_DESCONTO',         'Valor / % do Desconto',              '9(13)V9(2) — valor ou percentual do desconto',       127, 141,  15, 'MONETARY', 2, false, false, 31),
(v_rt_id, 'ABATIMENTO_CODIGO',   'Código do Abatimento',               '0 = Sem, 1 = Com abatimento',                        142, 142,   1, 'NUM',      0, false, false, 32),
(v_rt_id, 'DT_ABATIMENTO',       'Data do Abatimento',                 'Data do abatimento (DDMMAAAA)',                       143, 150,   8, 'DATE',     0, false, false, 33),
(v_rt_id, 'VL_ABATIMENTO',       'Valor do Abatimento',                '9(13)V9(2) — valor do abatimento',                   151, 165,  15, 'MONETARY', 2, false, false, 34),
(v_rt_id, 'PROTESTO_CODIGO',     'Código para Protesto',               '1 = Protestar dias corridos, 3 = Não protestar',     166, 166,   1, 'NUM',      0, false, false, 35),
(v_rt_id, 'PRAZO_PROTESTO',      'Número de Dias para Protesto',       'Número de dias para protesto após vencimento',        167, 168,   2, 'NUM',      0, false, false, 36),
(v_rt_id, 'DEVOLUCAO_CODIGO',    'Código para Devolução/Baixa',        '1 = Devolver após N dias, 2 = Não devolver',         169, 169,   1, 'NUM',      0, false, false, 37),
(v_rt_id, 'PRAZO_DEVOLUCAO',     'Número de Dias para Devolução',      'Número de dias para devolução/baixa automática',     170, 171,   2, 'NUM',      0, false, false, 38),
(v_rt_id, 'COD_MOEDA',           'Código da Moeda',                    '09 = Real (R$)',                                      172, 174,   3, 'NUM',      0, true,  false, 39),
(v_rt_id, 'FILLER_FIM',          'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                               175, 240,  66, 'ALPHA',    0, false, true,  40);

-- ============================================================
-- REMESSA — DETALHE SEGMENTO Q (tipo 3, segmento Q)
-- Dados do pagador (sacado) e avalista
-- ============================================================
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_rem_id, 'DETALHE_Q', 'Detalhe Segmento Q - Dados do Pagador (Remessa)', 'DETAIL',
  8, 8, '3',
  14, 14, 'Q',
  4
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',           'Código do Banco',                    'Código COMPE do banco',                                  1,   3,   3, 'NUM',   0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',        'Lote de Serviço',                    'Número do lote',                                         4,   7,   4, 'NUM',   0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',                   '3 = Detalhe',                                            8,   8,   1, 'NUM',   0, true,  false, 3),
(v_rt_id, 'SEQ_REGISTRO',        'Nº Sequencial do Registro no Lote', 'Sequencial dentro do lote',                               9,  13,   5, 'NUM',   0, true,  false, 4),
(v_rt_id, 'COD_SEGMENTO',        'Código do Segmento',                 'Q = Dados do Pagador',                                  14,  14,   1, 'ALPHA', 0, true,  false, 5),
(v_rt_id, 'TIPO_MOVIMENTO',      'Tipo de Movimento',                  '0 = Inclusão',                                          15,  15,   1, 'NUM',   0, true,  false, 6),
(v_rt_id, 'COD_INSTRUCAO',       'Código de Instrução',                '01 = Inclusão de registro',                             16,  17,   2, 'NUM',   0, true,  false, 7),
(v_rt_id, 'TIPO_INSCRICAO_PAG',  'Tipo de Inscrição do Pagador',       '1 = CPF, 2 = CNPJ',                                     18,  18,   1, 'NUM',   0, true,  false, 8),
(v_rt_id, 'NUM_INSCRICAO_PAG',   'CPF / CNPJ do Pagador',              'CPF (11 dígitos) ou CNPJ (14 dígitos) do sacado',       19,  32,  14, 'NUM',   0, true,  false, 9),
(v_rt_id, 'NOME_PAGADOR',        'Nome do Pagador',                    'Nome / Razão social do sacado',                         33,  72,  40, 'ALPHA', 0, true,  false, 10),
(v_rt_id, 'ENDERECO_PAGADOR',    'Endereço do Pagador',                'Endereço completo (logradouro, número, complemento)',    73, 112,  40, 'ALPHA', 0, true,  false, 11),
(v_rt_id, 'BAIRRO_PAGADOR',      'Bairro do Pagador',                  'Bairro do sacado',                                     113, 127,  15, 'ALPHA', 0, false, false, 12),
(v_rt_id, 'CEP_PAGADOR',         'CEP do Pagador',                     'CEP sem hífen (8 dígitos)',                             128, 135,   8, 'NUM',   0, true,  false, 13),
(v_rt_id, 'CIDADE_PAGADOR',      'Cidade do Pagador',                  'Município do sacado',                                  136, 150,  15, 'ALPHA', 0, true,  false, 14),
(v_rt_id, 'UF_PAGADOR',          'UF do Pagador',                      'Sigla do estado do sacado',                            151, 152,   2, 'ALPHA', 0, true,  false, 15),
(v_rt_id, 'TIPO_INSCRICAO_AVA',  'Tipo de Inscrição do Avalista',      '0 = Não tem, 1 = CPF, 2 = CNPJ',                       153, 153,   1, 'NUM',   0, false, false, 16),
(v_rt_id, 'NUM_INSCRICAO_AVA',   'CPF / CNPJ do Avalista',             'CPF ou CNPJ do avalista/sacador',                      154, 167,  14, 'NUM',   0, false, false, 17),
(v_rt_id, 'NOME_AVALISTA',       'Nome do Avalista',                   'Nome do avalista ou sacador',                          168, 207,  40, 'ALPHA', 0, false, false, 18),
(v_rt_id, 'COD_BANCO_CORRESP',   'Código do Banco Correspondente',     'Código do banco correspondente',                       208, 210,   3, 'NUM',   0, false, false, 19),
(v_rt_id, 'NOSSO_NUM_CORRESP',   'Nosso Número no Banco Correspondente','Identificação do título no banco correspondente',     211, 220,  10, 'ALPHA', 0, false, false, 20),
(v_rt_id, 'FILLER_FIM',          'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                                221, 240,  20, 'ALPHA', 0, false, true,  21);

-- ============================================================
-- REMESSA — DETALHE SEGMENTO R (tipo 3, segmento R) — opcional
-- Descontos adicionais, mora/multa e mensagens ao pagador
-- ============================================================
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_rem_id, 'DETALHE_R', 'Detalhe Segmento R - Descontos / Mora / Mensagens (Remessa)', 'DETAIL',
  8, 8, '3',
  14, 14, 'R',
  5
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',       'Código do Banco',              'Código COMPE do banco',                               1,   3,   3, 'NUM',      0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',    'Lote de Serviço',              'Número do lote',                                      4,   7,   4, 'NUM',      0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',   'Tipo de Registro',             '3 = Detalhe',                                         8,   8,   1, 'NUM',      0, true,  false, 3),
(v_rt_id, 'SEQ_REGISTRO',    'Nº Sequencial no Lote',       'Sequencial dentro do lote',                            9,  13,   5, 'NUM',      0, true,  false, 4),
(v_rt_id, 'COD_SEGMENTO',    'Código do Segmento',           'R = Descontos/Mora/Multa/Mensagens',                  14,  14,   1, 'ALPHA',    0, true,  false, 5),
(v_rt_id, 'TIPO_MOVIMENTO',  'Tipo de Movimento',            '0 = Inclusão',                                        15,  15,   1, 'NUM',      0, true,  false, 6),
(v_rt_id, 'COD_INSTRUCAO',   'Código de Instrução',          '01 = Inclusão',                                       16,  17,   2, 'NUM',      0, true,  false, 7),
(v_rt_id, 'DESC2_CODIGO',    'Código do 2º Desconto',        '0=Sem, 1=Valor fixo até data, 2=Percentual',         18,  18,   1, 'NUM',      0, false, false, 8),
(v_rt_id, 'DT_DESC2',        'Data do 2º Desconto',          'Data limite para 2º desconto (DDMMAAAA)',             19,  26,   8, 'DATE',     0, false, false, 9),
(v_rt_id, 'VL_DESC2',        'Valor / % do 2º Desconto',     '9(13)V9(2) — valor ou percentual',                   27,  41,  15, 'MONETARY', 2, false, false, 10),
(v_rt_id, 'DESC3_CODIGO',    'Código do 3º Desconto',        '0=Sem, 1=Valor fixo até data, 2=Percentual',         42,  42,   1, 'NUM',      0, false, false, 11),
(v_rt_id, 'DT_DESC3',        'Data do 3º Desconto',          'Data limite para 3º desconto (DDMMAAAA)',             43,  50,   8, 'DATE',     0, false, false, 12),
(v_rt_id, 'VL_DESC3',        'Valor / % do 3º Desconto',     '9(13)V9(2) — valor ou percentual',                   51,  65,  15, 'MONETARY', 2, false, false, 13),
(v_rt_id, 'MORA_CODIGO',     'Código de Mora / Multa',       '1=Valor/dia, 2=Taxa mensal, 3=Isento',               66,  66,   1, 'NUM',      0, false, false, 14),
(v_rt_id, 'DT_MORA',         'Data de Mora / Multa',         'Data a partir da qual incide mora (DDMMAAAA)',        67,  74,   8, 'DATE',     0, false, false, 15),
(v_rt_id, 'VL_MORA',         'Valor / % de Mora / Multa',    '9(13)V9(2)',                                         75,  89,  15, 'MONETARY', 2, false, false, 16),
(v_rt_id, 'COD_INSTRUCAO1',  'Código da 1ª Instrução',       'Instrução ao banco (ex: 06 = Protestar)',            90,  91,   2, 'NUM',      0, false, false, 17),
(v_rt_id, 'COD_INSTRUCAO2',  'Código da 2ª Instrução',       'Instrução ao banco',                                 92,  93,   2, 'NUM',      0, false, false, 18),
(v_rt_id, 'MENSAGEM_1',      'Mensagem ao Pagador — linha 1', 'Texto livre para impressão no boleto (linha 1)',    94, 133,  40, 'ALPHA',    0, false, false, 19),
(v_rt_id, 'MENSAGEM_2',      'Mensagem ao Pagador — linha 2', 'Texto livre para impressão no boleto (linha 2)',   134, 173,  40, 'ALPHA',    0, false, false, 20),
(v_rt_id, 'MENSAGEM_3',      'Mensagem ao Pagador — linha 3', 'Texto livre para impressão no boleto (linha 3)',   174, 213,  40, 'ALPHA',    0, false, false, 21),
(v_rt_id, 'FILLER_FIM',      'Uso Exclusivo FEBRABAN/CNAB',  'Preencher com brancos',                             214, 240,  27, 'ALPHA',    0, false, true,  22);

-- ============================================================
-- REMESSA — TRAILER DE LOTE (tipo 5)
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'TRAILER_LOTE', 'Trailer de Lote', 'TRAILER', 8, 8, '5', 6)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',           'Código do Banco',                      'Código COMPE do banco',                                1,   3,   3, 'NUM',      0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',        'Lote de Serviço',                      'Número do lote',                                       4,   7,   4, 'NUM',      0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',                     '5 = Trailer de Lote',                                  8,   8,   1, 'NUM',      0, true,  false, 3),
(v_rt_id, 'FILLER_1',            'Uso Exclusivo FEBRABAN',               'Preencher com brancos',                                9,  17,   9, 'ALPHA',    0, false, true,  4),
(v_rt_id, 'QTDE_REGISTROS',      'Quantidade de Registros no Lote',      'Total de registros incluindo header e trailer',       18,  23,   6, 'NUM',      0, true,  false, 5),
(v_rt_id, 'QTD_COBR_SIMPLES',    'Qtd. Títulos Cobrança Simples',        'Quantidade de títulos de cobrança simples',           24,  29,   6, 'NUM',      0, false, false, 6),
(v_rt_id, 'VLR_COBR_SIMPLES',    'Valor Total Cobrança Simples',         '9(15)V9(2) — valor total cobrança simples',           30,  46,  17, 'MONETARY', 2, false, false, 7),
(v_rt_id, 'QTD_COBR_CAUCIO',     'Qtd. Títulos Cobrança Caucionada',     'Quantidade de títulos de cobrança caucionada',        47,  52,   6, 'NUM',      0, false, false, 8),
(v_rt_id, 'VLR_COBR_CAUCIO',     'Valor Total Cobrança Caucionada',      '9(15)V9(2) — valor total cobrança caucionada',       53,  69,  17, 'MONETARY', 2, false, false, 9),
(v_rt_id, 'QTD_COBR_DESCT',      'Qtd. Títulos Cobrança Descontada',     'Quantidade de títulos de cobrança descontada',       70,  75,   6, 'NUM',      0, false, false, 10),
(v_rt_id, 'VLR_COBR_DESCT',      'Valor Total Cobrança Descontada',      '9(15)V9(2) — valor total cobrança descontada',      76,  92,  17, 'MONETARY', 2, false, false, 11),
(v_rt_id, 'NUM_AVISO',           'Número do Aviso de Débito',            'Número do aviso emitido pelo banco',                  93,  98,   6, 'NUM',      0, false, false, 12),
(v_rt_id, 'FILLER_FIM',          'Uso Exclusivo FEBRABAN/CNAB',          'Preencher com brancos',                               99, 240, 142, 'ALPHA',    0, false, true,  13);

-- ============================================================
-- REMESSA — TRAILER DE ARQUIVO (tipo 9)
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_rem_id, 'TRAILER_ARQUIVO', 'Trailer de Arquivo', 'TRAILER', 8, 8, '9', 7)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',      'Código do Banco',                    'Código COMPE do banco',                                1,   3,   3, 'NUM',  true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',   'Lote de Serviço',                    'Preencher com 9999',                                   4,   7,   4, 'NUM',  true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',                   '9 = Trailer de Arquivo',                               8,   8,   1, 'NUM',  true,  false, 3),
(v_rt_id, 'FILLER_1',       'Uso Exclusivo FEBRABAN',             'Preencher com brancos',                                9,  17,   9, 'ALPHA', false, true,  4),
(v_rt_id, 'TOTAL_LOTES',    'Quantidade de Lotes do Arquivo',     'Total de lotes no arquivo',                           18,  23,   6, 'NUM',  true,  false, 5),
(v_rt_id, 'TOTAL_REGISTROS','Quantidade de Registros do Arquivo', 'Total incluindo header e trailer de arquivo',         24,  29,   6, 'NUM',  true,  false, 6),
(v_rt_id, 'TOTAL_CONTAS',   'Quantidade de Contas (Uso Futuro)',  'Preencher com zeros',                                 30,  35,   6, 'NUM',  false, true,  7),
(v_rt_id, 'FILLER_FIM',     'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                               36, 240, 205, 'ALPHA', false, true,  8);

-- ============================================================
-- LAYOUT: CNAB240 Cobrança Retorno
-- ============================================================
INSERT INTO cnab_layouts (bank_id, format, version, name, line_length, encoding, notes)
VALUES (
  v_bank_id,
  'CNAB240_COBRANCA_RET',
  '2017.01',
  'Itaú CNAB 240 - Cobrança Bancária Retorno',
  240,
  'latin1',
  'Cobrança bancária retorno. Serviço 01. Segmentos T, U. FEBRABAN Jan/2017.'
)
RETURNING id INTO v_layout_ret_id;

-- ============================================================
-- RETORNO — HEADER DE ARQUIVO (tipo 0) — mesma estrutura da remessa
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'HEADER_ARQUIVO', 'Header de Arquivo', 'HEADER', 8, 8, '0', 1)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',          'Código do Banco',                  'Código COMPE do banco (341 = Itaú)',                        1,   3,   3, 'NUM',   true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',       'Lote de Serviço',                  'Preencher com ''0000'' no Header de Arquivo',               4,   7,   4, 'NUM',   true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',      'Tipo de Registro',                 '0 = Header de Arquivo',                                    8,   8,   1, 'NUM',   true,  false, 3),
(v_rt_id, 'FILLER_1',           'Uso Exclusivo FEBRABAN/CNAB',      'Preencher com brancos',                                    9,  17,   9, 'ALPHA', false, true,  4),
(v_rt_id, 'TIPO_INSCRICAO',     'Tipo de Inscrição da Empresa',     '1 = CPF, 2 = CNPJ',                                       18,  18,   1, 'NUM',   true,  false, 5),
(v_rt_id, 'NUM_INSCRICAO',      'CNPJ / CPF da Empresa',            'CNPJ (14 dígitos) ou CPF (11 + 3 zeros à esquerda)',       19,  32,  14, 'NUM',   true,  false, 6),
(v_rt_id, 'COD_CONVENIO',       'Código do Convênio no Banco',      'Código de convênio de cobrança',                          33,  52,  20, 'ALPHA', true,  false, 7),
(v_rt_id, 'NOME_EMPRESA',       'Nome da Empresa',                  'Nome do cedente',                                         53,  72,  20, 'ALPHA', true,  false, 8),
(v_rt_id, 'NOME_BANCO',         'Nome do Banco',                    'ITAU UNIBANCO S.A.',                                      73, 102,  30, 'ALPHA', true,  false, 9),
(v_rt_id, 'COD_COMPE',          'Código COMPE / Uso Banco',         'Uso exclusivo do banco',                                 103, 105,   3, 'ALPHA', false, true,  10),
(v_rt_id, 'FILLER_2',           'Uso Exclusivo FEBRABAN',           'Preencher com branco',                                   106, 106,   1, 'ALPHA', false, true,  11),
(v_rt_id, 'AGENCIA',            'Agência Mantenedora da Conta',     'Número da agência sem dígito',                           107, 110,   4, 'NUM',   true,  false, 12),
(v_rt_id, 'DIG_AGENCIA',        'Dígito Verificador da Agência',    'Dígito verificador da agência',                          111, 111,   1, 'ALPHA', true,  false, 13),
(v_rt_id, 'CONTA_CORRENTE',     'Número da Conta Corrente',         'Número da conta corrente sem dígito',                    112, 131,  20, 'NUM',   true,  false, 14),
(v_rt_id, 'DIG_CONTA',          'Dígito Verificador da Conta',      'Dígito verificador da conta',                            132, 132,   1, 'ALPHA', true,  false, 15),
(v_rt_id, 'DIG_AGENCIA_CONTA',  'Dígito Verificador Ag/Conta',      'Dígito verificador conjunto agência/conta',              133, 133,   1, 'ALPHA', false, false, 16),
(v_rt_id, 'INFO_COMPL',         'Informação Complementar',          'Uso exclusivo da empresa (9 posições)',                  134, 142,   9, 'ALPHA', false, true,  17),
(v_rt_id, 'COD_REM_RET',        'Código Remessa/Retorno',           '1 = Remessa, 2 = Retorno',                               143, 143,   1, 'NUM',   true,  false, 18),
(v_rt_id, 'DT_GERACAO',         'Data de Geração do Arquivo',       'Formato DDMMAAAA',                                       144, 151,   8, 'DATE',  true,  false, 19),
(v_rt_id, 'HR_GERACAO',         'Hora de Geração do Arquivo',       'Formato HHMMSS',                                         152, 157,   6, 'NUM',   true,  false, 20),
(v_rt_id, 'SEQ_ARQUIVO',        'Número Sequencial do Arquivo',     'Sequencial controlado pela empresa',                     158, 163,   6, 'NUM',   true,  false, 21),
(v_rt_id, 'VERSAO_LAYOUT',      'Versão do Layout do Arquivo',      '081 = Cobrança FEBRABAN Jan/2017',                       164, 165,   2, 'NUM',   true,  false, 22),
(v_rt_id, 'DENSIDADE',          'Densidade de Gravação',            'Preencher com zeros',                                    166, 170,   5, 'NUM',   false, true,  23),
(v_rt_id, 'RESERVADO_BANCO',    'Uso Reservado do Banco',           'Preencher com brancos',                                  171, 190,  20, 'ALPHA', false, true,  24),
(v_rt_id, 'RESERVADO_EMP',      'Uso Reservado da Empresa',         'Preencher com brancos',                                  191, 210,  20, 'ALPHA', false, true,  25),
(v_rt_id, 'FILLER_FIM',         'Uso Exclusivo FEBRABAN/CNAB',      'Preencher com brancos',                                  211, 240,  30, 'ALPHA', false, true,  26);

-- ============================================================
-- RETORNO — HEADER DE LOTE (tipo 1, operação T, serviço 01)
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'HEADER_LOTE', 'Header de Lote - Cobrança Retorno', 'HEADER', 8, 8, '1', 2)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',      'Código do Banco',                   'Código COMPE do banco',                              1,   3,   3, 'NUM',   true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',   'Lote de Serviço',                   'Número sequencial do lote',                          4,   7,   4, 'NUM',   true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',  'Tipo de Registro',                  '1 = Header de Lote',                                 8,   8,   1, 'NUM',   true,  false, 3),
(v_rt_id, 'TIPO_OPERACAO',  'Tipo de Operação',                  'T = Retorno (cobrança recebida do banco)',            9,   9,   1, 'ALPHA', true,  false, 4),
(v_rt_id, 'TIPO_SERVICO',   'Tipo de Serviço',                   '01 = Cobrança',                                     10,  11,   2, 'NUM',   true,  false, 5),
(v_rt_id, 'FILLER_1',       'Uso Exclusivo FEBRABAN',            'Preencher com brancos',                             12,  13,   2, 'ALPHA', false, true,  6),
(v_rt_id, 'VERSAO_LOTE',    'Versão do Layout do Lote',          'Versão do layout do lote',                          14,  16,   3, 'NUM',   true,  false, 7),
(v_rt_id, 'FILLER_2',       'Uso Exclusivo FEBRABAN',            'Preencher com branco',                              17,  17,   1, 'ALPHA', false, true,  8),
(v_rt_id, 'TIPO_INSCRICAO', 'Tipo de Inscrição da Empresa',      '1 = CPF, 2 = CNPJ',                                 18,  18,   1, 'NUM',   true,  false, 9),
(v_rt_id, 'NUM_INSCRICAO',  'CNPJ / CPF da Empresa',             'CNPJ ou CPF da empresa cedente',                    19,  32,  14, 'NUM',   true,  false, 10),
(v_rt_id, 'COD_CONVENIO',   'Código do Convênio no Banco',       'Código do convênio de cobrança',                    33,  52,  20, 'ALPHA', true,  false, 11),
(v_rt_id, 'NOME_EMPRESA',   'Nome da Empresa',                   'Nome do cedente',                                   53,  72,  20, 'ALPHA', true,  false, 12),
(v_rt_id, 'INFO_COMPL',     'Informação Complementar',           'Uso do banco',                                      73, 102,  30, 'ALPHA', false, true,  13),
(v_rt_id, 'NUM_RETORNO',    'Número do Retorno',                 'Número sequencial do arquivo de retorno',          103, 112,  10, 'NUM',   true,  false, 14),
(v_rt_id, 'DT_GRAVACAO',    'Data de Gravação',                  'Data de geração do retorno (DDMMAAAA)',            113, 120,   8, 'DATE',  true,  false, 15),
(v_rt_id, 'DT_CREDITO',     'Data do Crédito',                   'Data em que o banco creditou (DDMMAAAA)',          121, 128,   8, 'DATE',  false, false, 16),
(v_rt_id, 'FILLER_FIM',     'Uso Exclusivo FEBRABAN/CNAB',       'Preencher com brancos',                            129, 240, 112, 'ALPHA', false, true,  17);

-- ============================================================
-- RETORNO — DETALHE SEGMENTO T (tipo 3, segmento T)
-- Dados do título no retorno: nosso número, vencimento, valor, ocorrência
-- ============================================================
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_ret_id, 'DETALHE_T', 'Detalhe Segmento T - Dados do Título (Retorno)', 'DETAIL',
  8, 8, '3',
  14, 14, 'T',
  3
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',         'Código do Banco',                    'Código COMPE do banco',                                 1,   3,   3, 'NUM',      0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',      'Lote de Serviço',                    'Número do lote',                                        4,   7,   4, 'NUM',      0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',     'Tipo de Registro',                   '3 = Detalhe',                                           8,   8,   1, 'NUM',      0, true,  false, 3),
(v_rt_id, 'SEQ_REGISTRO',      'Nº Sequencial do Registro no Lote', 'Sequencial dentro do lote',                              9,  13,   5, 'NUM',      0, true,  false, 4),
(v_rt_id, 'COD_SEGMENTO',      'Código do Segmento',                 'T = Dados do Título no Retorno',                       14,  14,   1, 'ALPHA',    0, true,  false, 5),
(v_rt_id, 'TIPO_MOVIMENTO',    'Tipo de Movimento',                  'Código de retorno do banco',                           15,  15,   1, 'NUM',      0, true,  false, 6),
(v_rt_id, 'COD_INSTRUCAO',     'Código de Instrução',                'Instrução do banco',                                   16,  17,   2, 'NUM',      0, false, false, 7),
(v_rt_id, 'AGENCIA',           'Agência Mantenedora da Conta',       'Agência da conta do cedente',                          18,  22,   5, 'NUM',      0, true,  false, 8),
(v_rt_id, 'DIG_AGENCIA',       'Dígito Verificador da Agência',      'Dígito da agência',                                    23,  23,   1, 'ALPHA',    0, true,  false, 9),
(v_rt_id, 'CONTA_CORRENTE',    'Número da Conta Corrente',           'Conta do cedente',                                     24,  38,  15, 'NUM',      0, true,  false, 10),
(v_rt_id, 'DIG_CONTA',         'Dígito Verificador da Conta',        'Dígito da conta',                                      39,  39,   1, 'ALPHA',    0, true,  false, 11),
(v_rt_id, 'DIG_AGENCIA_CONTA', 'Dígito Verificador Ag/Conta',        'Dígito conjunto agência/conta',                        40,  40,   1, 'ALPHA',    0, false, false, 12),
(v_rt_id, 'NOSSO_NUMERO',      'Identificação do Título no Banco',   'Nosso Número retornado pelo banco',                    41,  48,   8, 'NUM',      0, true,  false, 13),
(v_rt_id, 'TIPO_CARTEIRA',     'Tipo da Carteira',                   '1=Simples, 3=Caucionada, 4=Descontada',                49,  49,   1, 'NUM',      0, true,  false, 14),
(v_rt_id, 'SEU_NUMERO',        'Número do Documento — Empresa',      'Número do documento na empresa',                       50,  64,  15, 'ALPHA',    0, false, false, 15),
(v_rt_id, 'DT_VENCIMENTO',     'Data de Vencimento do Título',       'Data de vencimento (DDMMAAAA)',                        65,  72,   8, 'DATE',     0, true,  false, 16),
(v_rt_id, 'VL_TITULO',         'Valor Nominal do Título',            '9(13)V9(2) — valor original do título',                73,  87,  15, 'MONETARY', 2, true,  false, 17),
(v_rt_id, 'COD_BANCO_COB',     'Código do Banco Cobrador',           'Banco que realizou a cobrança',                        88,  90,   3, 'NUM',      0, false, false, 18),
(v_rt_id, 'AGENCIA_COB',       'Agência Cobradora',                  'Agência que cobrou o título',                          91,  95,   5, 'NUM',      0, false, false, 19),
(v_rt_id, 'DIG_AGENCIA_COB',   'Dígito Agência Cobradora',           'Dígito da agência cobradora',                          96,  96,   1, 'ALPHA',    0, false, false, 20),
(v_rt_id, 'ESPECIE_TITULO',    'Espécie do Título',                  '01=DM, 02=NP, 03=NS, 99=Outros',                       97,  98,   2, 'NUM',      0, false, false, 21),
(v_rt_id, 'ACEITE',            'Aceite',                             'A = Aceite, N = Não Aceite',                           99,  99,   1, 'ALPHA',    0, false, false, 22),
(v_rt_id, 'DT_EMISSAO',        'Data de Emissão do Título',          'Data de emissão (DDMMAAAA)',                          100, 107,   8, 'DATE',     0, false, false, 23),
(v_rt_id, 'COD_OCORRENCIA',    'Código da Ocorrência',               'Código retornado pelo banco (ex: 06=Liquidação)',     108, 112,   5, 'NUM',      0, true,  false, 24),
(v_rt_id, 'DT_OCORRENCIA',     'Data da Ocorrência',                 'Data em que a ocorrência foi registrada (DDMMAAAA)',  113, 120,   8, 'DATE',     0, true,  false, 25),
(v_rt_id, 'VL_DESCONTOS',      'Valor dos Descontos Concedidos',     '9(13)V9(2) — total de descontos',                    121, 135,  15, 'MONETARY', 2, false, false, 26),
(v_rt_id, 'VL_ABATIMENTO',     'Valor do Abatimento Concedido',      '9(13)V9(2) — total de abatimento',                   136, 150,  15, 'MONETARY', 2, false, false, 27),
(v_rt_id, 'VL_MORA_MULTA',     'Valor de Mora / Multa Cobrado',      '9(13)V9(2) — mora/multa cobrada',                    151, 165,  15, 'MONETARY', 2, false, false, 28),
(v_rt_id, 'VL_PAGAMENTO',      'Valor do Pagamento',                 '9(13)V9(2) — valor efetivamente pago',               166, 180,  15, 'MONETARY', 2, true,  false, 29),
(v_rt_id, 'VL_COBRADO',        'Valor Cobrado — Tarifa / Custas',    '9(13)V9(2) — tarifas e custas cobradas',             181, 195,  15, 'MONETARY', 2, false, false, 30),
(v_rt_id, 'VL_LIQUIDO',        'Valor Líquido Creditado',            '9(13)V9(2) — valor líquido creditado ao cedente',   196, 210,  15, 'MONETARY', 2, false, false, 31),
(v_rt_id, 'FILLER_1',          'Uso Exclusivo FEBRABAN',             'Preencher com brancos',                              211, 213,   3, 'ALPHA',    0, false, true,  32),
(v_rt_id, 'ERROS',             'Códigos dos Erros Identificados',    'Até 4 códigos de erro de 2 dígitos cada',            214, 221,   8, 'ALPHA',    0, false, false, 33),
(v_rt_id, 'COD_LIQUIDACAO',    'Código do Meio de Liquidação',       '01=Compensação, 02=Crédito cc, 03=DOC, 09=Outros',  222, 223,   2, 'NUM',      0, false, false, 34),
(v_rt_id, 'FILLER_FIM',        'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                              224, 240,  17, 'ALPHA',    0, false, true,  35);

-- ============================================================
-- RETORNO — DETALHE SEGMENTO U (tipo 3, segmento U)
-- Valores financeiros complementares: juros, desconto, data crédito
-- ============================================================
INSERT INTO record_types (
  layout_id, code, description, category,
  identifier_start, identifier_end, identifier_value,
  secondary_identifier_start, secondary_identifier_end, secondary_identifier_value,
  sort_order
)
VALUES (
  v_layout_ret_id, 'DETALHE_U', 'Detalhe Segmento U - Valores Complementares (Retorno)', 'DETAIL',
  8, 8, '3',
  14, 14, 'U',
  4
)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',           'Código do Banco',                    'Código COMPE do banco',                                 1,   3,   3, 'NUM',      0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',        'Lote de Serviço',                    'Número do lote',                                        4,   7,   4, 'NUM',      0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',       'Tipo de Registro',                   '3 = Detalhe',                                           8,   8,   1, 'NUM',      0, true,  false, 3),
(v_rt_id, 'SEQ_REGISTRO',        'Nº Sequencial do Registro no Lote', 'Sequencial dentro do lote',                              9,  13,   5, 'NUM',      0, true,  false, 4),
(v_rt_id, 'COD_SEGMENTO',        'Código do Segmento',                 'U = Valores Complementares',                            14,  14,   1, 'ALPHA',    0, true,  false, 5),
(v_rt_id, 'TIPO_MOVIMENTO',      'Tipo de Movimento',                  'Código de retorno do banco',                            15,  15,   1, 'NUM',      0, true,  false, 6),
(v_rt_id, 'COD_INSTRUCAO',       'Código de Instrução',                'Instrução do banco',                                    16,  17,   2, 'NUM',      0, false, false, 7),
(v_rt_id, 'VL_JUROS_MORA',       'Valor de Juros / Mora',              '9(13)V9(2) — juros de mora cobrados',                  18,  32,  15, 'MONETARY', 2, false, false, 8),
(v_rt_id, 'VL_DESCONTO',         'Valor do Desconto Concedido',        '9(13)V9(2) — desconto concedido pelo cedente',         33,  47,  15, 'MONETARY', 2, false, false, 9),
(v_rt_id, 'VL_ABATIMENTO',       'Valor do Abatimento',                '9(13)V9(2) — abatimento concedido',                    48,  62,  15, 'MONETARY', 2, false, false, 10),
(v_rt_id, 'VL_IOF',              'Valor do IOF Recolhido',             '9(13)V9(2) — IOF (para duplicatas)',                    63,  77,  15, 'MONETARY', 2, false, false, 11),
(v_rt_id, 'VL_PAGAMENTO',        'Valor do Pagamento',                 '9(13)V9(2) — valor pago pelo sacado',                  78,  92,  15, 'MONETARY', 2, true,  false, 12),
(v_rt_id, 'DT_PAGAMENTO',        'Data do Pagamento',                  'Data efetiva do pagamento (DDMMAAAA)',                  93, 100,   8, 'DATE',     0, true,  false, 13),
(v_rt_id, 'DT_CREDITO',          'Data do Crédito',                    'Data em que o banco creditou o cedente (DDMMAAAA)',    101, 108,   8, 'DATE',     0, true,  false, 14),
(v_rt_id, 'COD_OCORR_SACADO',    'Código da Ocorrência do Sacado',     'Ocorrência registrada pelo pagador junto ao banco',   109, 113,   5, 'NUM',      0, false, false, 15),
(v_rt_id, 'VL_OCORR_SACADO',     'Valor da Ocorrência do Sacado',      '9(13)V9(2) — valor relacionado à ocorrência sacado', 114, 128,  15, 'MONETARY', 2, false, false, 16),
(v_rt_id, 'DT_OCORR_SACADO',     'Data da Ocorrência do Sacado',       'Data da ocorrência do sacado (DDMMAAAA)',             129, 136,   8, 'DATE',     0, false, false, 17),
(v_rt_id, 'COD_BANCO_CORRESP',   'Código do Banco Correspondente',     'Banco correspondente',                               137, 139,   3, 'NUM',      0, false, false, 18),
(v_rt_id, 'NOSSO_NUM_CORRESP',   'Nosso Número no Banco Correspondente','Identificação do título no banco correspondente',   140, 149,  10, 'ALPHA',    0, false, false, 19),
(v_rt_id, 'VL_TARIFA',           'Valor da Tarifa / Custas',           '9(13)V9(2) — tarifas cobradas pelo banco',           150, 164,  15, 'MONETARY', 2, false, false, 20),
(v_rt_id, 'OUTROS_CREDITOS',     'Outros Créditos',                    '9(13)V9(2) — outros créditos / deduções',            165, 179,  15, 'MONETARY', 2, false, false, 21),
(v_rt_id, 'FILLER_FIM',          'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                              180, 240,  61, 'ALPHA',    0, false, true,  22);

-- ============================================================
-- RETORNO — TRAILER DE LOTE (tipo 5)
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'TRAILER_LOTE', 'Trailer de Lote', 'TRAILER', 8, 8, '5', 5)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, decimal_places, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',        'Código do Banco',                    'Código COMPE do banco',                                 1,   3,   3, 'NUM',      0, true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',     'Lote de Serviço',                    'Número do lote',                                        4,   7,   4, 'NUM',      0, true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',    'Tipo de Registro',                   '5 = Trailer de Lote',                                   8,   8,   1, 'NUM',      0, true,  false, 3),
(v_rt_id, 'FILLER_1',         'Uso Exclusivo FEBRABAN',             'Preencher com brancos',                                 9,  17,   9, 'ALPHA',    0, false, true,  4),
(v_rt_id, 'QTDE_REGISTROS',   'Quantidade de Registros no Lote',    'Total de registros incluindo header e trailer',        18,  23,   6, 'NUM',      0, true,  false, 5),
(v_rt_id, 'QTD_COBR_SIMPLES', 'Qtd. Títulos Cobrança Simples',      'Quantidade de títulos liquidados / retornados',        24,  29,   6, 'NUM',      0, false, false, 6),
(v_rt_id, 'VLR_COBR_SIMPLES', 'Valor Total Cobrança Simples',       '9(15)V9(2) — valor total liquidado/retornado',         30,  46,  17, 'MONETARY', 2, false, false, 7),
(v_rt_id, 'QTD_COBR_CAUCIO',  'Qtd. Títulos Cobrança Caucionada',   'Quantidade de títulos caucionados',                    47,  52,   6, 'NUM',      0, false, false, 8),
(v_rt_id, 'VLR_COBR_CAUCIO',  'Valor Total Cobrança Caucionada',    '9(15)V9(2) — valor total caucionado',                  53,  69,  17, 'MONETARY', 2, false, false, 9),
(v_rt_id, 'QTD_COBR_DESCT',   'Qtd. Títulos Cobrança Descontada',   'Quantidade de títulos descontados',                    70,  75,   6, 'NUM',      0, false, false, 10),
(v_rt_id, 'VLR_COBR_DESCT',   'Valor Total Cobrança Descontada',    '9(15)V9(2) — valor total descontado',                  76,  92,  17, 'MONETARY', 2, false, false, 11),
(v_rt_id, 'NUM_AVISO',        'Número do Aviso de Crédito',         'Número do aviso de crédito emitido pelo banco',         93,  98,   6, 'NUM',      0, false, false, 12),
(v_rt_id, 'FILLER_FIM',       'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                                 99, 240, 142, 'ALPHA',    0, false, true,  13);

-- ============================================================
-- RETORNO — TRAILER DE ARQUIVO (tipo 9)
-- ============================================================
INSERT INTO record_types (layout_id, code, description, category, identifier_start, identifier_end, identifier_value, sort_order)
VALUES (v_layout_ret_id, 'TRAILER_ARQUIVO', 'Trailer de Arquivo', 'TRAILER', 8, 8, '9', 6)
RETURNING id INTO v_rt_id;

INSERT INTO field_definitions (record_type_id, name, label, description, start_position, end_position, length, data_type, is_required, is_filler, sort_order) VALUES
(v_rt_id, 'COD_BANCO',       'Código do Banco',                    'Código COMPE do banco',                                1,   3,   3, 'NUM',  true,  false, 1),
(v_rt_id, 'LOTE_SERVICO',    'Lote de Serviço',                    'Preencher com 9999',                                   4,   7,   4, 'NUM',  true,  false, 2),
(v_rt_id, 'TIPO_REGISTRO',   'Tipo de Registro',                   '9 = Trailer de Arquivo',                               8,   8,   1, 'NUM',  true,  false, 3),
(v_rt_id, 'FILLER_1',        'Uso Exclusivo FEBRABAN',             'Preencher com brancos',                                9,  17,   9, 'ALPHA', false, true,  4),
(v_rt_id, 'TOTAL_LOTES',     'Quantidade de Lotes do Arquivo',     'Total de lotes no arquivo',                           18,  23,   6, 'NUM',  true,  false, 5),
(v_rt_id, 'TOTAL_REGISTROS', 'Quantidade de Registros do Arquivo', 'Total incluindo header e trailer de arquivo',         24,  29,   6, 'NUM',  true,  false, 6),
(v_rt_id, 'TOTAL_CONTAS',    'Quantidade de Contas (Uso Futuro)',  'Preencher com zeros',                                 30,  35,   6, 'NUM',  false, true,  7),
(v_rt_id, 'FILLER_FIM',      'Uso Exclusivo FEBRABAN/CNAB',        'Preencher com brancos',                               36, 240, 205, 'ALPHA', false, true,  8);

END $$;
