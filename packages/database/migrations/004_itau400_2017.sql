-- Ajusta layouts Itaú CNAB 400 para refletir manual de Janeiro/2017
-- Remove tipos de registro introduzidos após 2017 (BoleCode/Pix)

DO $$
DECLARE
  v_remessa_id UUID;
  v_retorno_id  UUID;
BEGIN
  SELECT l.id INTO v_remessa_id
  FROM cnab_layouts l
  JOIN banks b ON b.id = l.bank_id
  WHERE b.code = '341' AND l.format = 'CNAB400_REMESSA';

  SELECT l.id INTO v_retorno_id
  FROM cnab_layouts l
  JOIN banks b ON b.id = l.bank_id
  WHERE b.code = '341' AND l.format = 'CNAB400_RETORNO';

  -- Remove DETALHE_BOLECODE (Tipo 3 — BoleCode/Pix) da remessa
  DELETE FROM field_definitions
  WHERE record_type_id IN (
    SELECT id FROM record_types
    WHERE layout_id = v_remessa_id AND code = 'DETALHE_BOLECODE'
  );
  DELETE FROM record_types
  WHERE layout_id = v_remessa_id AND code = 'DETALHE_BOLECODE';

  -- Remove BOLECODE_RET (Tipo 3 — BoleCode/Pix) do retorno
  DELETE FROM field_definitions
  WHERE record_type_id IN (
    SELECT id FROM record_types
    WHERE layout_id = v_retorno_id AND code = 'BOLECODE_RET'
  );
  DELETE FROM record_types
  WHERE layout_id = v_retorno_id AND code = 'BOLECODE_RET';

  -- Atualiza versão e nome para refletir manual de Jan/2017
  UPDATE cnab_layouts
  SET version = '2017.01',
      name    = 'Itaú CNAB 400 - Cobrança Remessa'
  WHERE id = v_remessa_id;

  UPDATE cnab_layouts
  SET version = '2017.01',
      name    = 'Itaú CNAB 400 - Cobrança Retorno'
  WHERE id = v_retorno_id;

END $$;
