--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: juris360; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE juris360 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Portuguese_Brazil.1252';


ALTER DATABASE juris360 OWNER TO postgres;

\connect juris360

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: pgstattuple; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgstattuple WITH SCHEMA public;


--
-- Name: EXTENSION pgstattuple; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgstattuple IS 'show tuple-level statistics';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: archive_old_comunicacoes(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.archive_old_comunicacoes(days_old integer DEFAULT 365) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    archive_date DATE;
    archived_count INTEGER;
BEGIN
    archive_date := CURRENT_DATE - (days_old || ' days')::INTERVAL;
    
    -- Criar tabela de arquivo se nÃ£o existir
    CREATE TABLE IF NOT EXISTS public.comunicacoes_archive (
        LIKE public.comunicacoes INCLUDING ALL
    );
    
    -- Mover dados antigos para arquivo
    INSERT INTO public.comunicacoes_archive
    SELECT * FROM public.comunicacoes 
    WHERE data_disponibilizacao < archive_date;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    -- Remover dados antigos da tabela principal
    DELETE FROM public.comunicacoes 
    WHERE data_disponibilizacao < archive_date;
    
    RETURN format('Arquivados %s registros anteriores a %s. Execute VACUUM FULL manualmente para recuperar espaÃ§o.', 
                  archived_count, archive_date);
END;
$$;


ALTER FUNCTION public.archive_old_comunicacoes(days_old integer) OWNER TO postgres;

--
-- Name: FUNCTION archive_old_comunicacoes(days_old integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.archive_old_comunicacoes(days_old integer) IS 'Arquiva dados antigos da tabela comunicacoes para comunicacoes_archive e executa VACUUM FULL';


--
-- Name: auto_create_daily_partition(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auto_create_daily_partition() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Criar partiÃ§Ã£o para amanhÃ£
    PERFORM public.create_comunicacoes_partition(CURRENT_DATE + INTERVAL '1 day');
    
    -- Criar partiÃ§Ã£o para depois de amanhÃ£ (backup)
    PERFORM public.create_comunicacoes_partition(CURRENT_DATE + INTERVAL '2 days');
    
    RETURN 'PartiÃ§Ãµes automÃ¡ticas criadas: ' || 
           to_char(CURRENT_DATE + INTERVAL '1 day', 'YYYY-MM-DD') || ', ' ||
           to_char(CURRENT_DATE + INTERVAL '2 days', 'YYYY-MM-DD');
END;
$$;


ALTER FUNCTION public.auto_create_daily_partition() OWNER TO postgres;

--
-- Name: FUNCTION auto_create_daily_partition(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.auto_create_daily_partition() IS 'FunÃ§Ã£o para execuÃ§Ã£o automÃ¡tica diÃ¡ria - cria partiÃ§Ãµes futuras';


--
-- Name: cleanup_duplicate_comunicacoes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_duplicate_comunicacoes() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Remover duplicatas baseado em hash
    DELETE FROM public.comunicacoes a
    USING public.comunicacoes b
    WHERE a.id > b.id 
      AND a.hash = b.hash 
      AND a.hash IS NOT NULL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN format('Removidas %s comunicaÃ§Ãµes duplicadas', deleted_count);
END;
$$;


ALTER FUNCTION public.cleanup_duplicate_comunicacoes() OWNER TO postgres;

--
-- Name: FUNCTION cleanup_duplicate_comunicacoes(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.cleanup_duplicate_comunicacoes() IS 'Remove comunicaÃ§Ãµes duplicadas baseado no campo hash';


--
-- Name: create_comunicacoes_partition(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_comunicacoes_partition(partition_date date) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    -- Nome da partiÃ§Ã£o baseado na data
    partition_name := 'comunicacoes_' || to_char(partition_date, 'YYYY_MM_DD');
    
    -- Definir range da partiÃ§Ã£o (diÃ¡rio)
    start_date := partition_date;
    end_date := partition_date + INTERVAL '1 day';
    
    -- Criar partiÃ§Ã£o se nÃ£o existir
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I 
        PARTITION OF public.comunicacoes_partitioned
        FOR VALUES FROM (%L) TO (%L)',
        partition_name, start_date, end_date);
    
    -- Criar Ã­ndices especÃ­ficos na partiÃ§Ã£o
    EXECUTE format('
        CREATE INDEX IF NOT EXISTS %I 
        ON public.%I (data_disponibilizacao, numero_processo)',
        'idx_' || partition_name || '_data_processo', partition_name);
        
    RETURN 'PartiÃ§Ã£o ' || partition_name || ' criada com sucesso';
END;
$$;


ALTER FUNCTION public.create_comunicacoes_partition(partition_date date) OWNER TO postgres;

--
-- Name: FUNCTION create_comunicacoes_partition(partition_date date); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.create_comunicacoes_partition(partition_date date) IS 'Cria partiÃ§Ã£o diÃ¡ria para a tabela comunicacoes_partitioned';


--
-- Name: fn_atualizar_status_item(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_atualizar_status_item() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Atualizar status baseado em pagamento e vencimento
    IF NEW.valor_pago >= NEW.valor_total THEN
        NEW.status := 'PAGO';
    ELSIF NEW.valor_pago > 0 AND NEW.valor_pago < NEW.valor_total THEN
        NEW.status := 'PARCIAL';
    ELSIF NEW.data_vencimento < CURRENT_DATE THEN
        NEW.status := 'ATRASADO';
    ELSE
        NEW.status := 'PENDENTE';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_atualizar_status_item() OWNER TO postgres;

--
-- Name: fn_atualizar_valor_recebido_contrato(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_atualizar_valor_recebido_contrato() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Atualizar valor_recebido do contrato quando um item for pago
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE fin_contratos
        SET valor_recebido = (
            SELECT COALESCE(SUM(valor_pago), 0)
            FROM fin_itens
            WHERE id_contrato = NEW.id_contrato
        ),
        atualizado_em = NOW()
        WHERE id_contrato = NEW.id_contrato;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_atualizar_valor_recebido_contrato() OWNER TO postgres;

--
-- Name: fn_gerar_parcelas(uuid, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_gerar_parcelas(p_id_contrato uuid, p_data_primeira_parcela date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_contrato RECORD;
    v_parcela INTEGER;
    v_data_vencimento DATE;
    v_mes_offset INTEGER;
BEGIN
    -- Buscar dados do contrato
    SELECT * INTO v_contrato FROM fin_contratos WHERE id_contrato = p_id_contrato;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contrato não encontrado: %', p_id_contrato;
    END IF;
    
    IF v_contrato.numero_parcelas IS NULL OR v_contrato.numero_parcelas <= 0 THEN
        RAISE EXCEPTION 'Número de parcelas inválido';
    END IF;
    
    -- Gerar parcelas
    FOR v_parcela IN 1..v_contrato.numero_parcelas LOOP
        v_mes_offset := v_parcela - 1;
        v_data_vencimento := p_data_primeira_parcela + (v_mes_offset || ' months')::INTERVAL;
        
        INSERT INTO fin_itens (
            id_contrato,
            tipo_item,
            numero_item,
            descricao,
            data_vencimento,
            valor_principal
        ) VALUES (
            p_id_contrato,
            'PARCELA',
            v_parcela,
            'Parcela ' || v_parcela || ' de ' || v_contrato.numero_parcelas,
            v_data_vencimento,
            v_contrato.valor_parcela_base
        );
    END LOOP;
    
    RETURN v_contrato.numero_parcelas;
END;
$$;


ALTER FUNCTION public.fn_gerar_parcelas(p_id_contrato uuid, p_data_primeira_parcela date) OWNER TO postgres;

--
-- Name: FUNCTION fn_gerar_parcelas(p_id_contrato uuid, p_data_primeira_parcela date); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_gerar_parcelas(p_id_contrato uuid, p_data_primeira_parcela date) IS 'Gera parcelas automaticamente para um contrato';


--
-- Name: fn_metricas_empresa(uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_metricas_empresa(p_empresa uuid, p_days integer DEFAULT 30) RETURNS TABLE(id_empresa uuid, processos_com_vinculo integer, comunicacoes_total integer, primeira_disponibilizacao date, ultima_disponibilizacao date, processos_ultimos_nd integer, processos_sem_partes integer)
    LANGUAGE sql
    AS $$
  SELECT
    p_empresa AS id_empresa,
    COUNT(*) AS processos_com_vinculo,
    SUM(COALESCE(p.qtd_comunicacoes, 0)) AS comunicacoes_total,
    MIN(p.data_primeira_disponibilizacao) AS primeira_disponibilizacao,
    MAX(p.data_ultima_disponibilizacao)   AS ultima_disponibilizacao,
    COUNT(*) FILTER (
      WHERE p.data_ultima_disponibilizacao IS NOT NULL
        AND p.data_ultima_disponibilizacao >= current_date - p_days
    ) AS processos_ultimos_nd,
    COUNT(*) FILTER (
      WHERE (array_length(p.partes_ativas, 1)   IS NULL OR array_length(p.partes_ativas, 1)   = 0)
        AND (array_length(p.partes_passivas, 1) IS NULL OR array_length(p.partes_passivas, 1) = 0)
    ) AS processos_sem_partes
  FROM public.processos p
  WHERE p.id_empresa = p_empresa;
$$;


ALTER FUNCTION public.fn_metricas_empresa(p_empresa uuid, p_days integer) OWNER TO postgres;

--
-- Name: fn_registrar_historico(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_registrar_historico() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_descricao TEXT;
    v_tipo_acao VARCHAR(50);
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_tipo_acao := 'CRIACAO';
        v_descricao := 'Registro criado';
    ELSIF TG_OP = 'UPDATE' THEN
        v_tipo_acao := 'ALTERACAO';
        v_descricao := 'Registro alterado';
    ELSIF TG_OP = 'DELETE' THEN
        v_tipo_acao := 'EXCLUSAO';
        v_descricao := 'Registro excluído';
    END IF;
    
    INSERT INTO fin_historico (
        tabela_origem,
        id_registro,
        tipo_acao,
        descricao,
        valores_anteriores,
        valores_novos,
        usuario
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id_contrato, NEW.id_lancamento_avulso, NEW.id_item, NEW.id_pagamento, OLD.id_contrato, OLD.id_lancamento_avulso, OLD.id_item, OLD.id_pagamento),
        v_tipo_acao,
        v_descricao,
        CASE WHEN TG_OP != 'INSERT' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP != 'DELETE' THEN row_to_json(NEW) ELSE NULL END,
        current_user
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.fn_registrar_historico() OWNER TO postgres;

--
-- Name: fn_sync_processo_tb_advogado_comunicado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sync_processo_tb_advogado_comunicado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_numero text;
BEGIN
  -- Buscar numero_processo: preferir NEW.numero_processo, senÃ£o do comunicado
  IF NEW.numero_processo IS NOT NULL THEN
    v_numero := NEW.numero_processo;
  ELSE
    SELECT c.numero_processo INTO v_numero FROM public.comunicacoes c WHERE c.id = NEW.comunicado_id;
  END IF;

  IF NEW.id_empresa IS NULL OR v_numero IS NULL THEN
    RETURN NULL;
  END IF;

  PERFORM public.fn_upsert_processo(NEW.id_empresa, v_numero);
  RETURN NULL; -- AFTER INSERT
END;
$$;


ALTER FUNCTION public.fn_sync_processo_tb_advogado_comunicado() OWNER TO postgres;

--
-- Name: fn_sync_tem_vinculo_tb_advogado_comunicado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sync_tem_vinculo_tb_advogado_comunicado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.comunicado_id IS NOT NULL THEN
      UPDATE public.comunicacoes c
         SET tem_vinculo = 1
       WHERE c.id = NEW.comunicado_id;
    END IF;
    RETURN NULL;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.comunicado_id IS NOT NULL THEN
      UPDATE public.comunicacoes c
         SET tem_vinculo = CASE
           WHEN EXISTS (
             SELECT 1 FROM public.tb_advogado_comunicado t
              WHERE t.comunicado_id = OLD.comunicado_id
           ) THEN 1 ELSE 0 END
       WHERE c.id = OLD.comunicado_id;
    END IF;
    RETURN NULL;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_sync_tem_vinculo_tb_advogado_comunicado() OWNER TO postgres;

--
-- Name: fn_upsert_processo(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_upsert_processo(p_empresa uuid, p_numero text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  WITH base AS (
    SELECT
      t.id_empresa,
      c.numero_processo,
      MIN(c.data_disponibilizacao) AS data_primeira,
      MAX(c.data_disponibilizacao) AS data_ultima,
      COUNT(DISTINCT c.id) AS qtd_comunicacoes,
      (ARRAY_AGG(c.id ORDER BY c.data_disponibilizacao DESC, c.id DESC))[1]   AS ultimo_comunicado_id,
      (ARRAY_AGG(c.link ORDER BY c.data_disponibilizacao DESC, c.id DESC))[1] AS ultimo_link
    FROM public.tb_advogado_comunicado t
    JOIN public.comunicacoes c ON c.id = t.comunicado_id
    WHERE c.numero_processo = p_numero AND t.id_empresa = p_empresa
    GROUP BY t.id_empresa, c.numero_processo
  ), ultimo AS (
    SELECT
      b.id_empresa, b.numero_processo,
      c.sigla_tribunal, c.id_orgao, c.nome_orgao, c.nome_classe,
      c.codigo_classe, c.tipo_documento, c.tipo_comunicacao
    FROM base b
    JOIN public.comunicacoes c ON c.id = b.ultimo_comunicado_id
  ), partes AS (
    SELECT
      t.id_empresa,
      c.numero_processo,
      COALESCE(ARRAY_AGG(DISTINCT d.nome) FILTER (WHERE d.nome IS NOT NULL AND lower(COALESCE(d.polo, '')) IN ('a','ativo')), ARRAY[]::text[])   AS partes_ativas,
      COALESCE(ARRAY_AGG(DISTINCT d.nome) FILTER (WHERE d.nome IS NOT NULL AND lower(COALESCE(d.polo, '')) IN ('p','passivo')), ARRAY[]::text[]) AS partes_passivas
    FROM public.tb_advogado_comunicado t
    JOIN public.comunicacoes c ON c.id = t.comunicado_id
    LEFT JOIN public.comunicacao_destinatarios d ON d.comunicacao_id = c.id
    WHERE c.numero_processo = p_numero AND t.id_empresa = p_empresa
    GROUP BY t.id_empresa, c.numero_processo
  )
  INSERT INTO public.processos (
    id_empresa, numero_processo,
    sigla_tribunal, id_orgao, nome_orgao, nome_classe, codigo_classe,
    tipo_documento, tipo_comunicacao,
    data_primeira_disponibilizacao, data_ultima_disponibilizacao, qtd_comunicacoes,
    ultimo_comunicado_id, ultimo_link,
    partes_ativas, partes_passivas
  )
  SELECT
    b.id_empresa, b.numero_processo,
    u.sigla_tribunal, u.id_orgao, u.nome_orgao, u.nome_classe, u.codigo_classe,
    u.tipo_documento, u.tipo_comunicacao,
    b.data_primeira, b.data_ultima, b.qtd_comunicacoes,
    b.ultimo_comunicado_id, b.ultimo_link,
    p.partes_ativas, p.partes_passivas
  FROM base b
  LEFT JOIN ultimo u ON u.id_empresa = b.id_empresa AND u.numero_processo = b.numero_processo
  LEFT JOIN partes p ON p.id_empresa = b.id_empresa AND p.numero_processo = b.numero_processo
  ON CONFLICT (id_empresa, numero_processo) DO UPDATE SET
    sigla_tribunal = EXCLUDED.sigla_tribunal,
    id_orgao       = EXCLUDED.id_orgao,
    nome_orgao     = EXCLUDED.nome_orgao,
    nome_classe    = EXCLUDED.nome_classe,
    codigo_classe  = EXCLUDED.codigo_classe,
    tipo_documento = EXCLUDED.tipo_documento,
    tipo_comunicacao = EXCLUDED.tipo_comunicacao,
    data_primeira_disponibilizacao = LEAST(public.processos.data_primeira_disponibilizacao, EXCLUDED.data_primeira_disponibilizacao),
    data_ultima_disponibilizacao   = GREATEST(public.processos.data_ultima_disponibilizacao, EXCLUDED.data_ultima_disponibilizacao),
    qtd_comunicacoes     = EXCLUDED.qtd_comunicacoes,
    ultimo_comunicado_id = EXCLUDED.ultimo_comunicado_id,
    ultimo_link          = EXCLUDED.ultimo_link,
    partes_ativas        = COALESCE(EXCLUDED.partes_ativas, public.processos.partes_ativas),
    partes_passivas      = COALESCE(EXCLUDED.partes_passivas, public.processos.partes_passivas),
    updated_at           = now();
END;
$$;


ALTER FUNCTION public.fn_upsert_processo(p_empresa uuid, p_numero text) OWNER TO postgres;

--
-- Name: fn_vincula_advogado_comunicado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_vincula_advogado_comunicado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_com_id integer;
  v_numero_processo text;
  v_new_digits text;
  v_new_nome_norm text;
BEGIN
  IF NEW.comunicacao_id IS NULL THEN
    RETURN NULL;
  END IF;
  v_com_id := NEW.comunicacao_id::integer;
  SELECT c.numero_processo INTO v_numero_processo
    FROM public.comunicacoes c
   WHERE c.id = v_com_id;

  -- Passo 1: match exato por OAB+UF
  INSERT INTO public.tb_advogado_comunicado (
    advogado_id, comunicado_id,
    consulta_oab_num, consulta_oab_uf, consulta_nome,
    encontrado_oab_num, encontrado_oab_uf, encontrado_nome,
    numero_processo, id_empresa, data
  )
  SELECT a.id,
         v_com_id,
         NEW.numero_oab,
         NEW.uf_oab,
         NEW.nome_advogado,
         a.oab_numero,
         a.oab_uf,
         a.nome_advogado,
         v_numero_processo,
         a.id_empresa,
         now()
    FROM public.tb_advogado a
   WHERE a.oab_numero = NEW.numero_oab
     AND a.oab_uf     = NEW.uf_oab
     AND NOT EXISTS (
       SELECT 1 FROM public.tb_advogado_comunicado t
        WHERE t.advogado_id  = a.id
          AND t.comunicado_id = v_com_id
     );

  -- Passo 2: dÃ­gitos do OAB + mesma UF + similaridade de nome (Levenshtein)
  v_new_digits := regexp_replace(NEW.numero_oab, '[^0-9]', '', 'g');
  v_new_nome_norm := lower(unaccent(btrim(regexp_replace(regexp_replace(NEW.nome_advogado, '[^[:alnum:] ]', '', 'g'), '[[:space:]]+', ' ', 'g'))));

  WITH candidatos AS (
    SELECT a.id,
           a.oab_numero,
           a.oab_uf,
           a.id_empresa,
           lower(unaccent(btrim(regexp_replace(regexp_replace(a.nome_advogado, '[^[:alnum:] ]', '', 'g'), '[[:space:]]+', ' ', 'g')))) AS nome_norm
      FROM public.tb_advogado a
     WHERE a.oab_uf = NEW.uf_oab
       AND regexp_replace(a.oab_numero, '[^0-9]', '', 'g') = v_new_digits
  ), scored AS (
    SELECT c.id,
           c.oab_numero,
           c.oab_uf,
           c.id_empresa,
           c.nome_norm,
           (c.nome_norm = v_new_nome_norm) AS is_exact_name,
           CASE
             WHEN GREATEST(length(c.nome_norm), length(v_new_nome_norm)) > 0 THEN
               1.0 - (levenshtein(c.nome_norm, v_new_nome_norm)::numeric /
                      GREATEST(length(c.nome_norm), length(v_new_nome_norm))::numeric)
             ELSE 0.0
           END AS score,
           COUNT(*) OVER () AS cand_count,
           ROW_NUMBER() OVER (ORDER BY (c.nome_norm = v_new_nome_norm) DESC, 
                                      CASE
                                        WHEN GREATEST(length(c.nome_norm), length(v_new_nome_norm)) > 0 THEN
                                          1.0 - (levenshtein(c.nome_norm, v_new_nome_norm)::numeric /
                                                 GREATEST(length(c.nome_norm), length(v_new_nome_norm))::numeric)
                                        ELSE 0.0
                                      END DESC,
                                      c.id ASC) AS rn
     FROM candidatos c
  )
  INSERT INTO public.tb_advogado_comunicado (
    advogado_id, comunicado_id,
    consulta_oab_num, consulta_oab_uf, consulta_nome,
    encontrado_oab_num, encontrado_oab_uf, encontrado_nome,
    numero_processo, id_empresa, data
  )
  SELECT s.id,
         v_com_id,
         NEW.numero_oab,
         NEW.uf_oab,
         NEW.nome_advogado,
         s.oab_numero,
         s.oab_uf,
         (SELECT a.nome_advogado FROM public.tb_advogado a WHERE a.id = s.id),
         v_numero_processo,
         s.id_empresa,
         now()
     FROM scored s
   WHERE s.rn = 1
     AND s.score >= 0.80
     AND NOT EXISTS (
       SELECT 1 FROM public.tb_advogado_comunicado t
        WHERE t.advogado_id  = s.id
          AND t.comunicado_id = v_com_id
     );

  -- Garantir um registro por comunicado em tab_comunicado_fala
  CREATE UNIQUE INDEX IF NOT EXISTS uq_tab_comunicado_fala_comunicado_id
    ON public.tab_comunicado_fala (comunicado_id)
    WHERE comunicado_id IS NOT NULL;
  INSERT INTO public.tab_comunicado_fala (
    data_hora, data_disponibilizacao, numero_processo,
    comunicado_id, comunicado_codigo, ia_text_status, ia_voice_status
  )
  SELECT now(), c.data_disponibilizacao, c.numero_processo,
         v_com_id, v_com_id, 0, 0
    FROM public.comunicacoes c
   WHERE c.id = v_com_id
     AND EXISTS (
       SELECT 1 FROM public.tb_advogado_comunicado t
        WHERE t.comunicado_id = v_com_id
     )
     AND NOT EXISTS (
       SELECT 1 FROM public.tab_comunicado_fala f
        WHERE f.comunicado_id = v_com_id
     );

  RETURN NULL; -- AFTER INSERT
END;
$$;


ALTER FUNCTION public.fn_vincula_advogado_comunicado() OWNER TO postgres;

--
-- Name: fn_vincula_por_tb_advogado(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_vincula_por_tb_advogado(p_advogado_id integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Passo 1 (batch): OAB+UF (match exato)
  INSERT INTO public.tb_advogado_comunicado (
    advogado_id, comunicado_id,
    consulta_oab_num, consulta_oab_uf, consulta_nome,
    encontrado_oab_num, encontrado_oab_uf, encontrado_nome,
    numero_processo, id_empresa, data
  )
  SELECT a.id,
         ca.comunicacao_id::integer,
         ca.numero_oab,
         ca.uf_oab,
         ca.nome_advogado,
         a.oab_numero,
         a.oab_uf,
         a.nome_advogado,
         c.numero_processo,
         a.id_empresa,
         now()
    FROM public.tb_advogado a
    JOIN public.comunicacao_advogados ca
      ON a.oab_numero = ca.numero_oab
     AND a.oab_uf     = ca.uf_oab
    LEFT JOIN public.comunicacoes c ON c.id = ca.comunicacao_id::integer
   WHERE (p_advogado_id IS NULL OR a.id = p_advogado_id)
     AND NOT EXISTS (
       SELECT 1 FROM public.tb_advogado_comunicado t
        WHERE t.advogado_id  = a.id
          AND t.comunicado_id = ca.comunicacao_id::integer
     );

  -- Passo 2 (batch): dÃ­gitos + UF + similaridade de nome
  WITH pares AS (
    SELECT a.id AS advogado_id,
           a.id_empresa AS id_empresa,
           a.oab_numero AS a_oab_num,
           a.oab_uf     AS a_oab_uf,
           a.nome_advogado AS a_nome,
           ca.numero_oab AS ca_oab_num,
           ca.uf_oab     AS ca_oab_uf,
           ca.nome_advogado AS ca_nome,
           lower(unaccent(btrim(regexp_replace(regexp_replace(a.nome_advogado, '[^\w\s]', '', 'g'), '\s+', ' ', 'g')))) AS a_nome_norm,
           lower(unaccent(btrim(regexp_replace(regexp_replace(ca.nome_advogado, '[^[:alnum:] ]', '', 'g'), '[[:space:]]+', ' ', 'g')))) AS ca_nome_norm,
           ca.comunicacao_id AS ca_id
      FROM public.tb_advogado a
      JOIN public.comunicacao_advogados ca
        ON regexp_replace(a.oab_numero, '[^0-9]', '', 'g') = regexp_replace(ca.numero_oab, '[^0-9]', '', 'g')
       AND a.oab_uf = ca.uf_oab
     WHERE (p_advogado_id IS NULL OR a.id = p_advogado_id)
  ), scored AS (
    SELECT advogado_id,
           ca_id::integer AS comunicado_id,
           a_oab_num, a_oab_uf, a_nome,
           ca_oab_num, ca_oab_uf, ca_nome,
           id_empresa,
           (SELECT c.numero_processo FROM public.comunicacoes c WHERE c.id = ca_id::integer) AS numero_processo,
           COUNT(*) OVER (PARTITION BY ca_id) AS cand_count,
           CASE
             WHEN GREATEST(length(a_nome_norm), length(ca_nome_norm)) > 0 THEN
               1.0 - (levenshtein(a_nome_norm, ca_nome_norm)::numeric /
                      GREATEST(length(a_nome_norm), length(ca_nome_norm))::numeric)
             ELSE 0.0
           END AS score,
           ROW_NUMBER() OVER (
             PARTITION BY ca_id, ca_oab_num, ca_oab_uf, ca_nome
             ORDER BY (a_nome_norm = ca_nome_norm) DESC,
                      CASE WHEN GREATEST(length(a_nome_norm), length(ca_nome_norm)) > 0 THEN
                        1.0 - (levenshtein(a_nome_norm, ca_nome_norm)::numeric /
                               GREATEST(length(a_nome_norm), length(ca_nome_norm))::numeric)
                      ELSE 0.0 END DESC,
                      advogado_id ASC
           ) AS rn
      FROM pares
  )
  INSERT INTO public.tb_advogado_comunicado (
    advogado_id, comunicado_id,
    consulta_oab_num, consulta_oab_uf, consulta_nome,
    encontrado_oab_num, encontrado_oab_uf, encontrado_nome,
    numero_processo, id_empresa, data
  )
  SELECT s.advogado_id,
         s.comunicado_id,
         s.ca_oab_num,
         s.ca_oab_uf,
         s.ca_nome,
         s.a_oab_num,
         s.a_oab_uf,
         s.a_nome,
         s.numero_processo,
         s.id_empresa,
         now()
     FROM scored s
   WHERE s.rn = 1
     AND s.score >= 0.80
     AND NOT EXISTS (
       SELECT 1 FROM public.tb_advogado_comunicado t
        WHERE t.advogado_id  = s.advogado_id
          AND t.comunicado_id = s.comunicado_id
     );

  -- Inserir em tab_comunicado_fala para comunicados vinculados (evitar duplicidade)
  INSERT INTO public.tab_comunicado_fala (
    data_hora, data_disponibilizacao, numero_processo,
    comunicado_id, comunicado_codigo, ia_text_status, ia_voice_status
  )
  SELECT now(), c.data_disponibilizacao, c.numero_processo,
         t.comunicado_id, t.comunicado_id, 0, 0
    FROM (
      SELECT DISTINCT t.comunicado_id
        FROM public.tb_advogado_comunicado t
       WHERE t.comunicado_id IS NOT NULL
    ) t
    JOIN public.comunicacoes c
      ON c.id = t.comunicado_id
   WHERE NOT EXISTS (
     SELECT 1 FROM public.tab_comunicado_fala f
      WHERE f.comunicado_id = t.comunicado_id
   );
END;
$$;


ALTER FUNCTION public.fn_vincula_por_tb_advogado(p_advogado_id integer) OWNER TO postgres;

--
-- Name: maintenance_comunicacoes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.maintenance_comunicacoes() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    result_text TEXT := '';
    rec_count INTEGER;
    table_size TEXT;
BEGIN
    -- Atualizar estatísticas
    EXECUTE 'ANALYZE public.comunicacoes';
    
    -- Obter estatísticas atuais
    SELECT COUNT(*), pg_size_pretty(pg_total_relation_size('public.comunicacoes'))
    INTO rec_count, table_size
    FROM public.comunicacoes;
    
    result_text := format('Manutenção concluída. Registros: %s, Tamanho: %s', 
                         rec_count, table_size);
    
    RETURN result_text;
END;
$$;


ALTER FUNCTION public.maintenance_comunicacoes() OWNER TO postgres;

--
-- Name: FUNCTION maintenance_comunicacoes(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.maintenance_comunicacoes() IS 'Executa manutenÃ§Ã£o automÃ¡tica: limpeza de duplicatas, vacuum e analyze';


--
-- Name: migrate_comunicacoes_to_partition(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.migrate_comunicacoes_to_partition(start_date date, end_date date DEFAULT NULL::date) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    migrated_count INTEGER;
    actual_end_date DATE;
BEGIN
    -- Se end_date nÃ£o fornecido, usar start_date + 1 dia
    actual_end_date := COALESCE(end_date, start_date + INTERVAL '1 day');
    
    -- Garantir que a partiÃ§Ã£o existe
    PERFORM public.create_comunicacoes_partition(start_date);
    
    -- Inserir dados na partiÃ§Ã£o
    INSERT INTO public.comunicacoes_partitioned
    SELECT * FROM public.comunicacoes 
    WHERE data_disponibilizacao >= start_date 
      AND data_disponibilizacao < actual_end_date;
    
    GET DIAGNOSTICS migrated_count = ROW_COUNT;
    
    RETURN format('Migrados %s registros de %s a %s', 
                  migrated_count, start_date, actual_end_date);
END;
$$;


ALTER FUNCTION public.migrate_comunicacoes_to_partition(start_date date, end_date date) OWNER TO postgres;

--
-- Name: tenant_allowed(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tenant_allowed(emp_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT emp_id = current_setting('app.current_tenant')::uuid
    AND emp_id IN (
      SELECT ue.id_empresa
      FROM usuario_empresas ue
      WHERE ue.id_usuario = current_setting('app.current_user')::uuid
    );
$$;


ALTER FUNCTION public.tenant_allowed(emp_id uuid) OWNER TO postgres;

--
-- Name: trg_roles_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_roles_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.atualizado_em := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_roles_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: advogados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advogados (
    id integer NOT NULL,
    nome text NOT NULL,
    numero_oab text,
    uf_oab text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.advogados OWNER TO postgres;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    id_audit bigint NOT NULL,
    id_empresa uuid,
    tabela text NOT NULL,
    operacao character(1) NOT NULL,
    registro_id uuid,
    dados_anteriores jsonb,
    dados_novos jsonb,
    usuario_id uuid,
    ocorrido_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT audit_log_operacao_check CHECK ((operacao = ANY (ARRAY['I'::bpchar, 'U'::bpchar, 'D'::bpchar])))
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: audit_log_id_audit_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_log_id_audit_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_id_audit_seq OWNER TO postgres;

--
-- Name: audit_log_id_audit_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_id_audit_seq OWNED BY public.audit_log.id_audit;


--
-- Name: compromissos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compromissos (
    id_compromisso uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    id_usuario uuid NOT NULL,
    titulo text NOT NULL,
    local text,
    data_inicio timestamp with time zone NOT NULL,
    data_fim timestamp with time zone,
    participantes jsonb,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    tipo_evento character varying(20) DEFAULT 'evento'::character varying,
    status character varying(20) DEFAULT 'agendado'::character varying,
    processo_vinculado uuid,
    configuracao_alertas jsonb DEFAULT '{}'::jsonb,
    sincronizar_google boolean DEFAULT false,
    prioridade character varying(10) DEFAULT 'media'::character varying,
    descricao text,
    observacoes text,
    CONSTRAINT compromissos_prioridade_check CHECK (((prioridade)::text = ANY ((ARRAY['baixa'::character varying, 'media'::character varying, 'alta'::character varying, 'critica'::character varying])::text[]))),
    CONSTRAINT compromissos_status_check CHECK (((status)::text = ANY ((ARRAY['agendado'::character varying, 'confirmado'::character varying, 'realizado'::character varying, 'cancelado'::character varying, 'adiado'::character varying])::text[]))),
    CONSTRAINT compromissos_tipo_evento_check CHECK (((tipo_evento)::text = ANY ((ARRAY['audiencia'::character varying, 'prazo'::character varying, 'evento'::character varying, 'tarefa'::character varying])::text[])))
);


ALTER TABLE public.compromissos OWNER TO postgres;

--
-- Name: comunicacao_advogados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comunicacao_advogados (
    id bigint NOT NULL,
    numero_processo text NOT NULL,
    comunicacao_id bigint NOT NULL,
    advogado_id integer,
    nome_advogado text,
    numero_oab text,
    uf_oab text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.comunicacao_advogados OWNER TO postgres;

--
-- Name: comunicacao_advogados_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comunicacao_advogados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comunicacao_advogados_id_seq OWNER TO postgres;

--
-- Name: comunicacao_advogados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comunicacao_advogados_id_seq OWNED BY public.comunicacao_advogados.id;


--
-- Name: comunicacao_destinatarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comunicacao_destinatarios (
    id bigint NOT NULL,
    numero_processo text NOT NULL,
    comunicacao_id bigint NOT NULL,
    nome text,
    polo text
);


ALTER TABLE public.comunicacao_destinatarios OWNER TO postgres;

--
-- Name: comunicacao_destinatarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comunicacao_destinatarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comunicacao_destinatarios_id_seq OWNER TO postgres;

--
-- Name: comunicacao_destinatarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comunicacao_destinatarios_id_seq OWNED BY public.comunicacao_destinatarios.id;


--
-- Name: comunicacoes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comunicacoes (
    id bigint NOT NULL,
    data_disponibilizacao date,
    data_envio date,
    sigla_tribunal text,
    id_orgao integer,
    tipo_comunicacao text,
    tipo_documento text,
    numero_processo text,
    nome_classe text,
    codigo_classe integer,
    status text,
    ativo boolean DEFAULT true,
    numeroprocessocommascara text,
    nome_orgao text,
    texto text,
    worker_id text,
    data_coleta date,
    created_at timestamp without time zone DEFAULT now(),
    link text,
    hash text,
    meiocompleto text,
    tem_vinculo integer DEFAULT 0 NOT NULL,
    motivo_cancelamento text,
    data_cancelamento date,
    meio text,
    numerocomunicacao integer,
    "json" text
)
WITH (autovacuum_vacuum_scale_factor='0.01', autovacuum_analyze_scale_factor='0.005', autovacuum_vacuum_cost_delay='10', autovacuum_vacuum_cost_limit='2000', autovacuum_freeze_min_age='50000000', autovacuum_freeze_max_age='200000000');


ALTER TABLE public.comunicacoes OWNER TO postgres;

--
-- Name: configuracoes_alertas_padrao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuracoes_alertas_padrao (
    id_config uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tipo_evento character varying(20) NOT NULL,
    minutos_antes integer NOT NULL,
    tipo_alerta character varying(20) NOT NULL,
    ativo boolean DEFAULT true,
    criado_em timestamp with time zone DEFAULT now()
);


ALTER TABLE public.configuracoes_alertas_padrao OWNER TO postgres;

--
-- Name: contas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contas (
    id_conta uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    nome_conta text NOT NULL,
    tipo_conta text NOT NULL,
    saldo numeric(14,2) DEFAULT 0 NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT contas_tipo_conta_check CHECK ((tipo_conta = ANY (ARRAY['conta_corrente'::text, 'caixa'::text, 'outro'::text])))
);


ALTER TABLE public.contas OWNER TO postgres;

--
-- Name: documentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documentos (
    id_documento uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    id_processo uuid,
    id_pessoa uuid,
    tipo_documento text,
    url text NOT NULL,
    tamanho_bytes bigint,
    hash text,
    metadata jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.documentos OWNER TO postgres;

--
-- Name: empresas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empresas (
    id_empresa uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nome text NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    proc_inicial text,
    plan_id integer,
    dt_termino_acesso date,
    status text,
    stripe_cliente_id text,
    stripe_assinatura_id text,
    vl_assinatura numeric,
    nome_fantasia text,
    cnpj text,
    ie text,
    im text,
    email text,
    telefone text,
    celular text,
    cep text,
    endereco text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    estado text,
    site text,
    logo text,
    timezone text,
    language text,
    notification_email text,
    updated_at timestamp with time zone
);


ALTER TABLE public.empresas OWNER TO postgres;

--
-- Name: evento_alertas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evento_alertas (
    id_alerta uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_compromisso uuid NOT NULL,
    id_usuario uuid NOT NULL,
    minutos_antes integer NOT NULL,
    tipo_alerta character varying(20) NOT NULL,
    mensagem_personalizada text,
    ativo boolean DEFAULT true,
    enviado boolean DEFAULT false,
    enviado_em timestamp with time zone,
    tentativas_envio integer DEFAULT 0,
    erro_envio text,
    criado_em timestamp with time zone DEFAULT now(),
    CONSTRAINT evento_alertas_minutos_antes_check CHECK ((minutos_antes > 0)),
    CONSTRAINT evento_alertas_tipo_alerta_check CHECK (((tipo_alerta)::text = ANY ((ARRAY['email'::character varying, 'sms'::character varying, 'push'::character varying, 'sistema'::character varying])::text[])))
);


ALTER TABLE public.evento_alertas OWNER TO postgres;

--
-- Name: evento_documentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evento_documentos (
    id_documento uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_compromisso uuid NOT NULL,
    nome_arquivo text NOT NULL,
    nome_original text NOT NULL,
    caminho_arquivo text NOT NULL,
    tipo_documento character varying(50) DEFAULT 'documento'::character varying,
    tipo_mime character varying(100),
    tamanho_bytes bigint,
    hash_arquivo text,
    versao integer DEFAULT 1,
    id_usuario_upload uuid,
    anexado_em timestamp with time zone DEFAULT now(),
    observacoes text,
    CONSTRAINT evento_documentos_tipo_documento_check CHECK (((tipo_documento)::text = ANY ((ARRAY['peticao'::character varying, 'procuracao'::character varying, 'documento_apoio'::character varying, 'ata'::character varying, 'sentenca'::character varying, 'outro'::character varying])::text[])))
);


ALTER TABLE public.evento_documentos OWNER TO postgres;

--
-- Name: evento_participantes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evento_participantes (
    id_participante uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_compromisso uuid NOT NULL,
    id_pessoa uuid,
    nome_participante text NOT NULL,
    email_participante text,
    telefone_participante text,
    papel character varying(50) DEFAULT 'participante'::character varying,
    status_confirmacao character varying(20) DEFAULT 'pendente'::character varying,
    confirmado_em timestamp with time zone,
    observacoes text,
    criado_em timestamp with time zone DEFAULT now(),
    CONSTRAINT evento_participantes_papel_check CHECK (((papel)::text = ANY ((ARRAY['organizador'::character varying, 'advogado'::character varying, 'cliente'::character varying, 'testemunha'::character varying, 'perito'::character varying, 'juiz'::character varying, 'promotor'::character varying, 'participante'::character varying])::text[]))),
    CONSTRAINT evento_participantes_status_confirmacao_check CHECK (((status_confirmacao)::text = ANY ((ARRAY['pendente'::character varying, 'confirmado'::character varying, 'recusado'::character varying, 'tentativo'::character varying])::text[])))
);


ALTER TABLE public.evento_participantes OWNER TO postgres;

--
-- Name: evento_recorrencia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evento_recorrencia (
    id_recorrencia uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_compromisso_pai uuid NOT NULL,
    padrao_recorrencia character varying(20) NOT NULL,
    intervalo integer DEFAULT 1,
    dias_semana jsonb,
    dia_mes integer,
    data_fim_recorrencia date,
    max_ocorrencias integer,
    excecoes jsonb DEFAULT '[]'::jsonb,
    fuso_horario character varying(50) DEFAULT 'America/Sao_Paulo'::character varying,
    ativo boolean DEFAULT true,
    criado_em timestamp with time zone DEFAULT now(),
    CONSTRAINT evento_recorrencia_dia_mes_check CHECK (((dia_mes >= 1) AND (dia_mes <= 31))),
    CONSTRAINT evento_recorrencia_intervalo_check CHECK ((intervalo > 0)),
    CONSTRAINT evento_recorrencia_padrao_recorrencia_check CHECK (((padrao_recorrencia)::text = ANY ((ARRAY['diario'::character varying, 'semanal'::character varying, 'mensal'::character varying, 'anual'::character varying, 'personalizado'::character varying])::text[])))
);


ALTER TABLE public.evento_recorrencia OWNER TO postgres;

--
-- Name: fin_comprovantes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fin_comprovantes (
    id_comprovante uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_pagamento uuid,
    id_lancamento_avulso uuid,
    tipo_comprovante character varying(50),
    nome_arquivo character varying(255) NOT NULL,
    caminho_arquivo character varying(500) NOT NULL,
    tipo_arquivo character varying(50),
    tamanho_bytes bigint,
    hash_arquivo character varying(64),
    descricao text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por character varying(100),
    CONSTRAINT chk_referencia_comprovante CHECK ((((id_pagamento IS NOT NULL) AND (id_lancamento_avulso IS NULL)) OR ((id_pagamento IS NULL) AND (id_lancamento_avulso IS NOT NULL))))
);


ALTER TABLE public.fin_comprovantes OWNER TO postgres;

--
-- Name: TABLE fin_comprovantes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.fin_comprovantes IS 'Comprovantes e documentos anexados';


--
-- Name: fin_contratos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fin_contratos (
    id_contrato uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_processo uuid NOT NULL,
    id_empresa uuid NOT NULL,
    tipo_contrato character varying(50) NOT NULL,
    subtipo character varying(50),
    numero_contrato character varying(100),
    descricao text NOT NULL,
    data_contrato date NOT NULL,
    data_inicio_vigencia date,
    data_fim_vigencia date,
    parte_contratante character varying(200),
    cpf_cnpj_contratante character varying(20),
    valor_total numeric(15,2) DEFAULT 0 NOT NULL,
    valor_recebido numeric(15,2) DEFAULT 0 NOT NULL,
    valor_pendente numeric(15,2) GENERATED ALWAYS AS ((valor_total - valor_recebido)) STORED,
    numero_parcelas integer,
    valor_parcela_base numeric(15,2),
    dia_vencimento integer,
    data_primeira_parcela date,
    taxa_juros_mes numeric(5,2) DEFAULT 0,
    taxa_multa_atraso numeric(5,2) DEFAULT 0,
    percentual_desconto numeric(5,2) DEFAULT 0,
    status character varying(30) DEFAULT 'ATIVO'::character varying,
    dados_especificos jsonb,
    observacoes text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por character varying(100),
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por character varying(100),
    CONSTRAINT chk_dia_vencimento CHECK (((dia_vencimento IS NULL) OR ((dia_vencimento >= 1) AND (dia_vencimento <= 31)))),
    CONSTRAINT chk_status_contrato CHECK (((status)::text = ANY ((ARRAY['ATIVO'::character varying, 'QUITADO'::character varying, 'CANCELADO'::character varying, 'SUSPENSO'::character varying, 'INADIMPLENTE'::character varying])::text[]))),
    CONSTRAINT chk_tipo_contrato CHECK (((tipo_contrato)::text = ANY ((ARRAY['ACORDO_PARCELAS'::character varying, 'HONORARIOS'::character varying, 'PRESTACAO_SERVICOS'::character varying])::text[]))),
    CONSTRAINT chk_valores_contrato CHECK (((valor_total >= (0)::numeric) AND (valor_recebido >= (0)::numeric)))
);


ALTER TABLE public.fin_contratos OWNER TO postgres;

--
-- Name: TABLE fin_contratos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.fin_contratos IS 'Contratos financeiros vinculados a processos (acordos, honorários)';


--
-- Name: COLUMN fin_contratos.tipo_contrato; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.fin_contratos.tipo_contrato IS 'ACORDO_PARCELAS, HONORARIOS, PRESTACAO_SERVICOS';


--
-- Name: COLUMN fin_contratos.dados_especificos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.fin_contratos.dados_especificos IS 'Dados específicos do tipo em formato JSON';


--
-- Name: fin_historico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fin_historico (
    id_historico uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tabela_origem character varying(50) NOT NULL,
    id_registro uuid NOT NULL,
    tipo_acao character varying(50) NOT NULL,
    descricao text NOT NULL,
    valores_anteriores jsonb,
    valores_novos jsonb,
    data_acao timestamp without time zone DEFAULT now(),
    usuario character varying(100),
    ip_usuario character varying(50),
    CONSTRAINT chk_tabela_origem_hist CHECK (((tabela_origem)::text = ANY ((ARRAY['fin_contratos'::character varying, 'fin_lancamentos_avulsos'::character varying, 'fin_itens'::character varying, 'fin_pagamentos'::character varying])::text[])))
);


ALTER TABLE public.fin_historico OWNER TO postgres;

--
-- Name: TABLE fin_historico; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.fin_historico IS 'Log de auditoria de todas as operações financeiras';


--
-- Name: fin_itens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fin_itens (
    id_item uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_contrato uuid,
    id_lancamento_avulso uuid,
    tipo_item character varying(50) NOT NULL,
    numero_item integer NOT NULL,
    descricao text,
    data_vencimento date NOT NULL,
    data_pagamento date,
    data_competencia date,
    valor_principal numeric(15,2) NOT NULL,
    valor_juros numeric(15,2) DEFAULT 0,
    valor_multa numeric(15,2) DEFAULT 0,
    valor_desconto numeric(15,2) DEFAULT 0,
    valor_total numeric(15,2) GENERATED ALWAYS AS ((((valor_principal + valor_juros) + valor_multa) - valor_desconto)) STORED,
    valor_pago numeric(15,2) DEFAULT 0,
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    dados_especificos jsonb,
    observacoes text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por character varying(100),
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por character varying(100),
    CONSTRAINT chk_referencia_item CHECK ((((id_contrato IS NOT NULL) AND (id_lancamento_avulso IS NULL)) OR ((id_contrato IS NULL) AND (id_lancamento_avulso IS NOT NULL)))),
    CONSTRAINT chk_status_item CHECK (((status)::text = ANY ((ARRAY['PENDENTE'::character varying, 'PAGO'::character varying, 'ATRASADO'::character varying, 'PARCIAL'::character varying, 'CANCELADO'::character varying])::text[]))),
    CONSTRAINT chk_tipo_item CHECK (((tipo_item)::text = ANY ((ARRAY['PARCELA'::character varying, 'HONORARIO'::character varying, 'DESPESA'::character varying, 'CUSTA'::character varying])::text[]))),
    CONSTRAINT chk_valores_item CHECK (((valor_principal >= (0)::numeric) AND (valor_juros >= (0)::numeric) AND (valor_multa >= (0)::numeric) AND (valor_desconto >= (0)::numeric) AND (valor_pago >= (0)::numeric)))
);


ALTER TABLE public.fin_itens OWNER TO postgres;

--
-- Name: TABLE fin_itens; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.fin_itens IS 'Itens financeiros individuais (parcelas, honorários, despesas, custas)';


--
-- Name: COLUMN fin_itens.numero_item; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.fin_itens.numero_item IS 'Número sequencial dentro do contrato (1, 2, 3...)';


--
-- Name: fin_lancamentos_avulsos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fin_lancamentos_avulsos (
    id_lancamento_avulso uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_processo uuid NOT NULL,
    id_empresa uuid NOT NULL,
    tipo_lancamento character varying(50) NOT NULL,
    categoria character varying(100),
    descricao text NOT NULL,
    numero_documento character varying(100),
    data_lancamento date NOT NULL,
    data_vencimento date,
    data_pagamento date,
    data_reembolso date,
    valor_original numeric(15,2) NOT NULL,
    valor_pago numeric(15,2) DEFAULT 0,
    valor_reembolsado numeric(15,2) DEFAULT 0,
    pago_por character varying(100),
    reembolsavel boolean DEFAULT false,
    status_pagamento character varying(30) DEFAULT 'PENDENTE'::character varying,
    status_reembolso character varying(30),
    nome_fornecedor character varying(200),
    cpf_cnpj_fornecedor character varying(20),
    dados_especificos jsonb,
    observacoes text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por character varying(100),
    atualizado_em timestamp without time zone DEFAULT now(),
    atualizado_por character varying(100),
    CONSTRAINT chk_pago_por CHECK (((pago_por IS NULL) OR ((pago_por)::text = ANY ((ARRAY['ESCRITORIO'::character varying, 'CLIENTE'::character varying, 'TERCEIRO'::character varying])::text[])))),
    CONSTRAINT chk_status_pagamento CHECK (((status_pagamento)::text = ANY ((ARRAY['PENDENTE'::character varying, 'PAGO'::character varying, 'REEMBOLSADO'::character varying, 'PARCIAL'::character varying, 'CANCELADO'::character varying])::text[]))),
    CONSTRAINT chk_tipo_lancamento CHECK (((tipo_lancamento)::text = ANY ((ARRAY['DESPESA_REEMBOLSAVEL'::character varying, 'CUSTA_PROCESSUAL'::character varying, 'HONORARIO_PONTUAL'::character varying])::text[]))),
    CONSTRAINT chk_valores_lancamento_avulso CHECK (((valor_original >= (0)::numeric) AND (valor_pago >= (0)::numeric) AND (valor_reembolsado >= (0)::numeric)))
);


ALTER TABLE public.fin_lancamentos_avulsos OWNER TO postgres;

--
-- Name: TABLE fin_lancamentos_avulsos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.fin_lancamentos_avulsos IS 'Lançamentos financeiros avulsos (despesas, custas, honorários pontuais)';


--
-- Name: COLUMN fin_lancamentos_avulsos.tipo_lancamento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.fin_lancamentos_avulsos.tipo_lancamento IS 'DESPESA_REEMBOLSAVEL, CUSTA_PROCESSUAL, HONORARIO_PONTUAL';


--
-- Name: fin_pagamentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fin_pagamentos (
    id_pagamento uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_item uuid,
    id_lancamento_avulso uuid,
    tipo_transacao character varying(30) NOT NULL,
    data_pagamento date NOT NULL,
    valor_pago numeric(15,2) NOT NULL,
    forma_pagamento character varying(50),
    banco character varying(100),
    agencia character varying(20),
    conta character varying(30),
    numero_documento character varying(100),
    pagador character varying(200),
    cpf_cnpj_pagador character varying(20),
    beneficiario character varying(200),
    cpf_cnpj_beneficiario character varying(20),
    conciliado boolean DEFAULT false,
    data_conciliacao date,
    observacoes text,
    criado_em timestamp without time zone DEFAULT now(),
    criado_por character varying(100),
    CONSTRAINT chk_referencia_pagamento CHECK ((((id_item IS NOT NULL) AND (id_lancamento_avulso IS NULL)) OR ((id_item IS NULL) AND (id_lancamento_avulso IS NOT NULL)))),
    CONSTRAINT chk_tipo_transacao CHECK (((tipo_transacao)::text = ANY ((ARRAY['RECEBIMENTO'::character varying, 'PAGAMENTO'::character varying])::text[]))),
    CONSTRAINT chk_valor_pagamento CHECK ((valor_pago > (0)::numeric))
);


ALTER TABLE public.fin_pagamentos OWNER TO postgres;

--
-- Name: TABLE fin_pagamentos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.fin_pagamentos IS 'Registro de pagamentos e recebimentos';


--
-- Name: COLUMN fin_pagamentos.tipo_transacao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.fin_pagamentos.tipo_transacao IS 'RECEBIMENTO (entrada) ou PAGAMENTO (saída)';


--
-- Name: movimentacoes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimentacoes (
    data_movimentacao timestamp with time zone NOT NULL,
    id_movimentacao bigint NOT NULL,
    id_empresa uuid NOT NULL,
    id_processo uuid NOT NULL,
    descricao text NOT NULL,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
)
PARTITION BY RANGE (data_movimentacao);


ALTER TABLE public.movimentacoes OWNER TO postgres;

--
-- Name: movimentacoes_id_movimentacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimentacoes_id_movimentacao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movimentacoes_id_movimentacao_seq OWNER TO postgres;

--
-- Name: movimentacoes_id_movimentacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimentacoes_id_movimentacao_seq OWNED BY public.movimentacoes.id_movimentacao;


--
-- Name: movimentacoes_2025_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimentacoes_2025_04 (
    data_movimentacao timestamp with time zone NOT NULL,
    id_movimentacao bigint DEFAULT nextval('public.movimentacoes_id_movimentacao_seq'::regclass) NOT NULL,
    id_empresa uuid NOT NULL,
    id_processo uuid NOT NULL,
    descricao text NOT NULL,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.movimentacoes_2025_04 OWNER TO postgres;

--
-- Name: orgaos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orgaos (
    id_orgao uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_tribunal uuid,
    id integer,
    nome text,
    sigla_tribunal text
);


ALTER TABLE public.orgaos OWNER TO postgres;

--
-- Name: permissoes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissoes (
    id_permissao integer NOT NULL,
    nome_permissao text NOT NULL,
    descricao text
);


ALTER TABLE public.permissoes OWNER TO postgres;

--
-- Name: permissoes_id_permissao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissoes_id_permissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissoes_id_permissao_seq OWNER TO postgres;

--
-- Name: permissoes_id_permissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissoes_id_permissao_seq OWNED BY public.permissoes.id_permissao;


--
-- Name: pessoas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pessoas (
    id_pessoa uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    tipo_pessoa text NOT NULL,
    nome text NOT NULL,
    cpf_cnpj text,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    perfil text,
    apelido text,
    rg text,
    ctps text,
    pis text,
    titulo_eleitor text,
    cnh text,
    passaporte text,
    reservista text,
    ie text,
    im text,
    simples_nacional text,
    foto text
);


ALTER TABLE public.pessoas OWNER TO postgres;

--
-- Name: pessoas_email; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pessoas_email (
    id_email uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_pessoa uuid,
    tipo text,
    email text,
    id_empresa uuid
);


ALTER TABLE public.pessoas_email OWNER TO postgres;

--
-- Name: pessoas_endereco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pessoas_endereco (
    id_endereco uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_pessoa uuid,
    id_empresa uuid,
    tipo_endereco text,
    cep text,
    logradouro text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    uf text,
    pais text,
    latitude text,
    longitude text,
    ativo boolean,
    data_criacao timestamp with time zone,
    data_atualizacao timestamp with time zone,
    validado_em time with time zone,
    CONSTRAINT tipo_endereco CHECK ((tipo_endereco = ANY (ARRAY['Residencial'::text, 'Comercial'::text])))
);


ALTER TABLE public.pessoas_endereco OWNER TO postgres;

--
-- Name: pessoas_site; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pessoas_site (
    id_site uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_pessoa uuid,
    id_empresa uuid,
    site text
);


ALTER TABLE public.pessoas_site OWNER TO postgres;

--
-- Name: pessoas_telefone; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pessoas_telefone (
    id_pessoa uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid,
    tipo text,
    numero text
);


ALTER TABLE public.pessoas_telefone OWNER TO postgres;

--
-- Name: processos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processos (
    id_processo uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    numero_processo text NOT NULL,
    data_distribuicao date,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL,
    titulo text,
    instancia text,
    juizo text,
    vara text,
    foro text,
    acao text,
    url_tribunal text,
    objeto text,
    valor_causa numeric(10,2),
    valor_condenacao numeric(10,2),
    observacoes text,
    responsavel text,
    acesso text,
    pasta text,
    numeroprocessocommascara text,
    siglatribunal text,
    nomeclasse text,
    sigla_tribunal text,
    id_orgao integer,
    nome_orgao text,
    nome_classe text,
    codigo_classe integer,
    tipo_documento text,
    tipo_comunicacao text,
    data_primeira_disponibilizacao date,
    data_ultima_disponibilizacao date,
    qtd_comunicacoes integer,
    ultimo_comunicado_id integer,
    ultimo_link text,
    partes_ativas text[],
    partes_passivas text[],
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.processos OWNER TO postgres;

--
-- Name: processos_pessoas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processos_pessoas (
    id_processo uuid NOT NULL,
    id_pessoa uuid NOT NULL,
    papel text NOT NULL,
    custom_fields jsonb,
    tipo text
);


ALTER TABLE public.processos_pessoas OWNER TO postgres;

--
-- Name: publicacoes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publicacoes (
    data_publicacao date NOT NULL,
    id_publicacao bigint NOT NULL,
    id_empresa uuid NOT NULL,
    id_processo uuid NOT NULL,
    descricao text,
    status text DEFAULT 'NÃO TRATADA'::text NOT NULL,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
)
PARTITION BY RANGE (data_publicacao);


ALTER TABLE public.publicacoes OWNER TO postgres;

--
-- Name: publicacoes_id_publicacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publicacoes_id_publicacao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.publicacoes_id_publicacao_seq OWNER TO postgres;

--
-- Name: publicacoes_id_publicacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publicacoes_id_publicacao_seq OWNED BY public.publicacoes.id_publicacao;


--
-- Name: publicacoes_2025_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publicacoes_2025_04 (
    data_publicacao date NOT NULL,
    id_publicacao bigint DEFAULT nextval('public.publicacoes_id_publicacao_seq'::regclass) NOT NULL,
    id_empresa uuid NOT NULL,
    id_processo uuid NOT NULL,
    descricao text,
    status text DEFAULT 'NÃO TRATADA'::text NOT NULL,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.publicacoes_2025_04 OWNER TO postgres;

--
-- Name: role_permissoes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permissoes (
    id_role integer NOT NULL,
    id_permissao integer NOT NULL
);


ALTER TABLE public.role_permissoes OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id_role uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    nome_role text NOT NULL,
    descricao text,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: tab_amazons3; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tab_amazons3 (
    codigo integer NOT NULL,
    cod_empresa integer,
    servidor_nome text,
    servidor_url text,
    obj_caminho text,
    obj_nome text,
    tabela text,
    cod_registro integer,
    obj_nome_original text,
    obj_tamanho integer,
    obj_tipo text,
    obj_url text,
    amz_bucket text,
    amz_date text,
    amz_etag text,
    amz_server text,
    amz_x_amz_id_2 text,
    amz_x_amz_request_id text,
    amz_headers text,
    tag integer,
    id_remoto integer
);


ALTER TABLE public.tab_amazons3 OWNER TO postgres;

--
-- Name: tab_amazons3_codigo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tab_amazons3 ALTER COLUMN codigo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_amazons3_codigo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tab_cnaoab; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tab_cnaoab (
    codigo integer NOT NULL,
    adv_codigo integer,
    oab text,
    oab_numero text,
    oab_uf text,
    url_consulta text,
    consulta_cna text,
    consulta_getdetail text,
    consulta_renderdetail text,
    detailurl_get text,
    detailurl_render text,
    nome text,
    tipoinscoab text,
    nomesocial text,
    email text,
    data timestamp without time zone,
    arquivo_foto text,
    url_foto text
);


ALTER TABLE public.tab_cnaoab OWNER TO postgres;

--
-- Name: tab_comunicado_fala; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tab_comunicado_fala (
    codigo integer NOT NULL,
    data_hora timestamp without time zone,
    data_disponibilizacao date,
    numero_processo text,
    comunicado_id bigint,
    comunicado_codigo integer,
    arquivo_mp3 text,
    url_mp3 text,
    ia_json text,
    ia_mensagem_prazo text,
    ia_resumo_decisao text,
    ia_ato_cabivel text,
    ia_prazo_dias integer DEFAULT 0,
    ia_prazo_estimado date,
    ia_fundamentacao_prazo text,
    ia_trecho_relevante text,
    ia_aviso_legal text,
    texto text,
    mp3_duracao_sec numeric(15,4),
    mp3_tamanho_kb numeric(15,4),
    engine_ai_text text,
    engine_ai_text_model text,
    engine_ia_text_prompttokens integer,
    engine_ia_text_completiontokens integer,
    engine_ia_text_estimatedcost numeric(15,10),
    engine_ai_voice text,
    engine_ai_voice_model text,
    engine_ai_voice_region text,
    ia_text_status integer,
    ia_voice_status integer,
    ia_prazo_encontrado boolean
);


ALTER TABLE public.tab_comunicado_fala OWNER TO postgres;

--
-- Name: tab_comunicado_fala_codigo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tab_comunicado_fala ALTER COLUMN codigo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_comunicado_fala_codigo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.taggings (
    id_taggings uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    taggable_type text NOT NULL,
    taggable_id uuid NOT NULL,
    id_tag uuid NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.taggings OWNER TO postgres;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tags (
    id_tag uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    nome_tag text NOT NULL,
    descricao text,
    id_tag_pai uuid,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    tag_system text DEFAULT false,
    color text
);


ALTER TABLE public.tags OWNER TO postgres;

--
-- Name: tarefas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tarefas (
    id_tarefa uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    titulo text NOT NULL,
    descricao text,
    prioridade smallint DEFAULT 0 NOT NULL,
    data_inicio timestamp with time zone,
    prazo timestamp with time zone,
    sla_interval interval,
    id_usuario_atribuido uuid,
    status text NOT NULL,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tarefas_status_check CHECK ((status = ANY (ARRAY['pendente'::text, 'em_andamento'::text, 'concluida'::text])))
);


ALTER TABLE public.tarefas OWNER TO postgres;

--
-- Name: tb_advogado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_advogado (
    id integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT now(),
    plan_id integer,
    tipo_pessoa text,
    documento text,
    nome_user text,
    nome_advogado text,
    oab_tipo_inscricao integer,
    oab text,
    oab_numero text,
    oab_uf text,
    token text,
    remotejid text,
    remotelid text,
    ativo integer DEFAULT 1,
    id_empresa uuid,
    id_usuario uuid,
    email text,
    especialidade text,
    dt_cadastro timestamp with time zone DEFAULT now(),
    biografia text,
    lid text
);


ALTER TABLE public.tb_advogado OWNER TO postgres;

--
-- Name: tb_advogado_comunicado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_advogado_comunicado (
    id integer NOT NULL,
    envio_wp integer DEFAULT 0,
    envio_wp_data timestamp without time zone,
    envio_wp_status text,
    advogado_id integer,
    data timestamp without time zone,
    data_disponibilizacao date,
    data_de date,
    data_ate date,
    comunicado_codigo integer,
    comunicado_id bigint,
    consulta_oab_num text,
    consulta_oab_uf text,
    consulta_nome text,
    encontrado_oab_num text,
    encontrado_oab_uf text,
    encontrado_nome text,
    numero_processo text,
    lido_data timestamp without time zone,
    estrela_audio_data timestamp without time zone,
    estrela_resumo_data timestamp without time zone,
    estrela_resumo integer DEFAULT 0,
    estrela_audio integer DEFAULT 0,
    lido integer DEFAULT 0,
    id_empresa uuid
);


ALTER TABLE public.tb_advogado_comunicado OWNER TO postgres;

--
-- Name: tb_advogado_comunicado_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tb_advogado_comunicado ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tb_advogado_comunicado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tb_advogado_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tb_advogado ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tb_advogado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tb_api_consulta_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_api_consulta_log (
    codigo uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    data date,
    nome_advogado text,
    oab_completa text,
    ob_numero text,
    oab_uf text,
    url_request text,
    result_status integer,
    result_erro integer,
    data_hora_request time with time zone,
    data_hora_resquest_fim timestamp with time zone,
    status integer DEFAULT 0
);


ALTER TABLE public.tb_api_consulta_log OWNER TO postgres;

--
-- Name: tb_consulta_erro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_consulta_erro (
    codigo integer NOT NULL,
    adv_codigo integer,
    data date,
    hora time without time zone,
    oab text,
    erro_descricao text
);


ALTER TABLE public.tb_consulta_erro OWNER TO postgres;

--
-- Name: tb_consulta_ok; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_consulta_ok (
    codigo integer NOT NULL,
    adv_codigo integer,
    comunicado_id bigint,
    data date,
    hora time without time zone,
    oab text
);


ALTER TABLE public.tb_consulta_ok OWNER TO postgres;

--
-- Name: tb_crm_usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_crm_usuarios (
    codigo integer NOT NULL,
    nome text,
    senha text,
    administrador text,
    codiemp integer,
    externo boolean DEFAULT false,
    ip_conexao text,
    email text,
    master boolean DEFAULT false,
    confsenha text,
    codifunc integer,
    senha_antiga text,
    senha_anterior text,
    id_grupo integer,
    avatar text,
    dtcadastro date,
    img text,
    user_active boolean
);


ALTER TABLE public.tb_crm_usuarios OWNER TO postgres;

--
-- Name: tb_crm_usuarios_restri; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_crm_usuarios_restri (
    codiuser integer NOT NULL,
    codiemp integer,
    menus text DEFAULT '0'::text NOT NULL,
    usuarios text DEFAULT '0'::text NOT NULL,
    clientes text DEFAULT '0'::text NOT NULL,
    clientes_revisoes text,
    funcionarios text DEFAULT '0'::text NOT NULL,
    produtos text,
    relatorios text,
    empresas text,
    rcracing text,
    reportmenuclientes text,
    system_config text,
    fornecedores text,
    clientes_searchcustom text
);


ALTER TABLE public.tb_crm_usuarios_restri OWNER TO postgres;

--
-- Name: tb_eventos_google; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_eventos_google (
    codigo integer NOT NULL,
    id_evento text NOT NULL,
    adv_codigo integer,
    titulo text,
    descricao text,
    local_evento text,
    data_inicio timestamp without time zone,
    data_fim timestamp without time zone,
    fuso_horario text,
    url text,
    status text,
    tipo_evento text,
    organizador text,
    criador text,
    token text,
    id_compromisso uuid,
    ultima_sincronizacao timestamp with time zone DEFAULT now(),
    sincronizacao_ativa boolean DEFAULT true,
    erro_sincronizacao text
);


ALTER TABLE public.tb_eventos_google OWNER TO postgres;

--
-- Name: tb_f_categoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_f_categoria (
    id_categoria integer NOT NULL,
    descricao text,
    id_usuario integer
);


ALTER TABLE public.tb_f_categoria OWNER TO postgres;

--
-- Name: tb_f_lancamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_f_lancamento (
    id_lancamento integer NOT NULL,
    descricao text,
    valor numeric(12,2),
    tipo text,
    id_categoria integer,
    dt_lancamento date,
    id_usuario integer
);


ALTER TABLE public.tb_f_lancamento OWNER TO postgres;

--
-- Name: tb_feriados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_feriados (
    codigo integer NOT NULL,
    descricao text,
    data date,
    facultativo text,
    municipal integer,
    estadual integer,
    federal integer,
    tipo text,
    tipo_do_feriado text
);


ALTER TABLE public.tb_feriados OWNER TO postgres;

--
-- Name: tb_google_auth; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_google_auth (
    id_usuario integer NOT NULL,
    user_codigo integer,
    email text NOT NULL,
    nome text,
    access_token text,
    refresh_token text,
    expires_at timestamp without time zone,
    refresh_expires_at timestamp without time zone,
    token_type text,
    id_token text,
    scope text,
    criado_em timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    atualizado_em timestamp without time zone,
    "json" jsonb,
    user_token text
);


ALTER TABLE public.tb_google_auth OWNER TO postgres;

--
-- Name: tb_google_auth_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tb_google_auth_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_google_auth_id_usuario_seq OWNER TO postgres;

--
-- Name: tb_google_auth_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tb_google_auth_id_usuario_seq OWNED BY public.tb_google_auth.id_usuario;


--
-- Name: tb_juris_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_juris_features (
    feature_id integer NOT NULL,
    feature_code text NOT NULL,
    description text NOT NULL,
    quantidade_usa integer DEFAULT 0,
    quantidade integer,
    descricao_interna text,
    is_ai boolean DEFAULT false
);


ALTER TABLE public.tb_juris_features OWNER TO postgres;

--
-- Name: tb_juris_features_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tb_juris_features_feature_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_juris_features_feature_id_seq OWNER TO postgres;

--
-- Name: tb_juris_features_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tb_juris_features_feature_id_seq OWNED BY public.tb_juris_features.feature_id;


--
-- Name: tb_juris_licenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_juris_licenses (
    license_id integer NOT NULL,
    user_id integer NOT NULL,
    plan_id integer NOT NULL,
    start_date date NOT NULL,
    expiry_date date NOT NULL,
    license_key text NOT NULL,
    status smallint DEFAULT 1
);


ALTER TABLE public.tb_juris_licenses OWNER TO postgres;

--
-- Name: tb_juris_licenses_license_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tb_juris_licenses_license_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_juris_licenses_license_id_seq OWNER TO postgres;

--
-- Name: tb_juris_licenses_license_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tb_juris_licenses_license_id_seq OWNED BY public.tb_juris_licenses.license_id;


--
-- Name: tb_juris_plan_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_juris_plan_features (
    plan_feature_id integer NOT NULL,
    plan_id integer NOT NULL,
    feature_id integer NOT NULL,
    feature_code text,
    is_ai boolean DEFAULT false
);


ALTER TABLE public.tb_juris_plan_features OWNER TO postgres;

--
-- Name: tb_juris_plan_features_plan_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tb_juris_plan_features ALTER COLUMN plan_feature_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tb_juris_plan_features_plan_feature_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tb_juris_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_juris_plans (
    plan_id integer NOT NULL,
    plan_name text NOT NULL,
    price_monthly numeric(10,2) NOT NULL,
    price_yearly numeric(10,2),
    is_active boolean DEFAULT true,
    qtd_processos integer,
    qtd_usuarios integer,
    qtd_oab integer,
    qtd_gb_nuvem integer,
    stripe_produto_id_mensal text,
    stripe_produto_id_anual text,
    dias integer DEFAULT 30
);


ALTER TABLE public.tb_juris_plans OWNER TO postgres;

--
-- Name: tb_juris_plans_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tb_juris_plans_plan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_juris_plans_plan_id_seq OWNER TO postgres;

--
-- Name: tb_juris_plans_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tb_juris_plans_plan_id_seq OWNED BY public.tb_juris_plans.plan_id;


--
-- Name: tb_link_acesso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_link_acesso (
    codigo integer NOT NULL,
    id_adv integer,
    id_link integer,
    token text,
    data_hora timestamp without time zone,
    origem text,
    forwardedip text,
    useragent text,
    session_id text,
    info text
);


ALTER TABLE public.tb_link_acesso OWNER TO postgres;

--
-- Name: tb_monitoramento_registro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_monitoramento_registro (
    codigo integer NOT NULL,
    data date,
    hora time without time zone,
    adv_oab text,
    quantidade integer,
    menssagem text,
    resultado text,
    resultado_erro text,
    resultado_json jsonb
);


ALTER TABLE public.tb_monitoramento_registro OWNER TO postgres;

--
-- Name: tb_processo_comunicados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_processo_comunicados (
    codigo integer NOT NULL,
    empresa_codigo integer,
    processo_codigo integer,
    adv_codigo integer,
    comunicado_id integer,
    comunicado_numero integer
);


ALTER TABLE public.tb_processo_comunicados OWNER TO postgres;

--
-- Name: tb_processo_comunicados_codigo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tb_processo_comunicados ALTER COLUMN codigo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tb_processo_comunicados_codigo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tb_whatsapp_validar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_whatsapp_validar (
    codigo integer NOT NULL,
    remotejid text,
    codigo_validar text,
    data_hora timestamp without time zone,
    data_hora_validado timestamp without time zone,
    "LOG" text,
    sistema_origem text,
    token text,
    oab_numero text,
    oab_uf text,
    validado integer
);


ALTER TABLE public.tb_whatsapp_validar OWNER TO postgres;

--
-- Name: tb_whatsapp_validar_codigo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tb_whatsapp_validar ALTER COLUMN codigo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tb_whatsapp_validar_codigo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: temp_code_verify; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.temp_code_verify (
    codigo uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    numero_1 text,
    numero_2 text,
    numero_3 text,
    numero_4 text,
    remotejid text,
    email text
);
ALTER TABLE ONLY public.temp_code_verify ALTER COLUMN remotejid SET STORAGE PLAIN;
ALTER TABLE ONLY public.temp_code_verify ALTER COLUMN email SET STORAGE PLAIN;


ALTER TABLE public.temp_code_verify OWNER TO postgres;

--
-- Name: transacoes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transacoes (
    id_transacao uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_empresa uuid NOT NULL,
    id_conta uuid NOT NULL,
    id_processo uuid,
    id_pessoa uuid,
    tipo text NOT NULL,
    valor numeric(14,2) NOT NULL,
    data_transacao timestamp with time zone NOT NULL,
    descricao text,
    custom_fields jsonb,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT transacoes_tipo_check CHECK ((tipo = ANY (ARRAY['receita'::text, 'despesa'::text])))
);


ALTER TABLE public.transacoes OWNER TO postgres;

--
-- Name: tribunais; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tribunais (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    sigla text,
    nome text
);


ALTER TABLE public.tribunais OWNER TO postgres;

--
-- Name: usuario_empresas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario_empresas (
    id_usuario uuid NOT NULL,
    id_empresa uuid NOT NULL,
    criado_em timestamp with time zone DEFAULT now()
);


ALTER TABLE public.usuario_empresas OWNER TO postgres;

--
-- Name: usuario_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario_roles (
    id_usuario uuid NOT NULL,
    id_role uuid NOT NULL,
    atribuido_em timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.usuario_roles OWNER TO postgres;

--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id_usuario uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nome text NOT NULL,
    email public.citext NOT NULL,
    senha text NOT NULL,
    dt_cadastro timestamp with time zone DEFAULT now() NOT NULL,
    ultimo_login timestamp with time zone,
    celular text,
    remotejid text,
    foto text,
    apelido text,
    senha_temporaria text,
    plan_id integer,
    status text,
    stripe_cliente_id text,
    stripe_assinatura_id text,
    vl_assinatura numeric,
    lid text,
    jid text,
    token text,
    dt_termino_acesso date,
    ativo integer DEFAULT 0,
    cargo text,
    enviar_whatsapp integer DEFAULT 0
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: v_comunicacoes_growth; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_comunicacoes_growth AS
 SELECT data_disponibilizacao AS data,
    count(*) AS total_registros,
    (((count(*))::numeric * 100.0) / sum(count(*)) OVER ()) AS percentual_total,
    pg_size_pretty((count(*) * (((pg_total_relation_size('public.comunicacoes'::regclass))::numeric / (( SELECT count(*) AS count
           FROM public.comunicacoes comunicacoes_1))::numeric))::bigint)) AS tamanho_estimado_dia,
    (avg(length(COALESCE(texto, ''::text))))::integer AS tamanho_medio_texto,
    count(DISTINCT numero_processo) AS processos_unicos,
    count(DISTINCT id_orgao) AS orgaos_distintos
   FROM public.comunicacoes
  WHERE (data_disponibilizacao >= (CURRENT_DATE - '30 days'::interval))
  GROUP BY data_disponibilizacao
  ORDER BY data_disponibilizacao DESC;


ALTER VIEW public.v_comunicacoes_growth OWNER TO postgres;

--
-- Name: VIEW v_comunicacoes_growth; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_comunicacoes_growth IS 'Mostra crescimento diÃ¡rio da tabela comunicacoes nos Ãºltimos 30 dias';


--
-- Name: v_comunicacoes_stats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_comunicacoes_stats AS
 SELECT data_disponibilizacao AS data,
    count(*) AS total_registros,
    pg_size_pretty(pg_total_relation_size('public.comunicacoes'::regclass)) AS tamanho_total,
    avg(length(COALESCE(texto, ''::text))) AS tamanho_medio_texto,
    count(*) FILTER (WHERE (data_disponibilizacao >= CURRENT_DATE)) AS registros_hoje,
    count(*) FILTER (WHERE (data_disponibilizacao >= (CURRENT_DATE - '7 days'::interval))) AS registros_semana
   FROM public.comunicacoes
  WHERE (data_disponibilizacao >= (CURRENT_DATE - '30 days'::interval))
  GROUP BY data_disponibilizacao
  ORDER BY data_disponibilizacao DESC;


ALTER VIEW public.v_comunicacoes_stats OWNER TO postgres;

--
-- Name: VIEW v_comunicacoes_stats; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_comunicacoes_stats IS 'EstatÃ­sticas gerais das tabelas comunicacoes e comunicacoes_archive';


--
-- Name: vw_fin_despesas_pendentes_reembolso; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_fin_despesas_pendentes_reembolso AS
 SELECT la.id_lancamento_avulso,
    p.id_processo,
    p.numero_processo,
    la.descricao,
    la.categoria,
    la.data_lancamento,
    la.valor_original,
    la.valor_reembolsado,
    (la.valor_original - la.valor_reembolsado) AS valor_pendente,
    la.nome_fornecedor,
    la.status_reembolso
   FROM (public.fin_lancamentos_avulsos la
     JOIN public.processos p ON ((p.id_processo = la.id_processo)))
  WHERE (((la.tipo_lancamento)::text = 'DESPESA_REEMBOLSAVEL'::text) AND (la.reembolsavel = true) AND (la.valor_reembolsado < la.valor_original))
  ORDER BY la.data_lancamento;


ALTER VIEW public.vw_fin_despesas_pendentes_reembolso OWNER TO postgres;

--
-- Name: VIEW vw_fin_despesas_pendentes_reembolso; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_fin_despesas_pendentes_reembolso IS 'Despesas aguardando reembolso do cliente';


--
-- Name: vw_fin_resumo_processo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_fin_resumo_processo AS
 SELECT p.id_processo,
    p.numero_processo,
    COALESCE(sum(c.valor_total) FILTER (WHERE ((c.tipo_contrato)::text = 'ACORDO_PARCELAS'::text)), (0)::numeric) AS total_acordos,
    COALESCE(sum(c.valor_recebido) FILTER (WHERE ((c.tipo_contrato)::text = 'ACORDO_PARCELAS'::text)), (0)::numeric) AS recebido_acordos,
    COALESCE(sum(c.valor_total) FILTER (WHERE ((c.tipo_contrato)::text = 'HONORARIOS'::text)), (0)::numeric) AS total_honorarios,
    COALESCE(sum(c.valor_recebido) FILTER (WHERE ((c.tipo_contrato)::text = 'HONORARIOS'::text)), (0)::numeric) AS recebido_honorarios,
    COALESCE(sum(la.valor_original) FILTER (WHERE ((la.tipo_lancamento)::text = 'DESPESA_REEMBOLSAVEL'::text)), (0)::numeric) AS total_despesas,
    COALESCE(sum(la.valor_reembolsado) FILTER (WHERE ((la.tipo_lancamento)::text = 'DESPESA_REEMBOLSAVEL'::text)), (0)::numeric) AS reembolsado_despesas,
    COALESCE(sum(la.valor_original) FILTER (WHERE ((la.tipo_lancamento)::text = 'CUSTA_PROCESSUAL'::text)), (0)::numeric) AS total_custas,
    COALESCE(sum(la.valor_pago) FILTER (WHERE ((la.tipo_lancamento)::text = 'CUSTA_PROCESSUAL'::text)), (0)::numeric) AS pago_custas,
    (COALESCE(sum(c.valor_total), (0)::numeric) + COALESCE(sum(la.valor_original) FILTER (WHERE (la.reembolsavel = true)), (0)::numeric)) AS total_a_receber,
    (COALESCE(sum(c.valor_recebido), (0)::numeric) + COALESCE(sum(la.valor_reembolsado), (0)::numeric)) AS total_recebido,
    COALESCE(sum(la.valor_original) FILTER (WHERE ((la.pago_por)::text = 'ESCRITORIO'::text)), (0)::numeric) AS total_pago_escritorio
   FROM ((public.processos p
     LEFT JOIN public.fin_contratos c ON ((c.id_processo = p.id_processo)))
     LEFT JOIN public.fin_lancamentos_avulsos la ON ((la.id_processo = p.id_processo)))
  GROUP BY p.id_processo, p.numero_processo;


ALTER VIEW public.vw_fin_resumo_processo OWNER TO postgres;

--
-- Name: VIEW vw_fin_resumo_processo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_fin_resumo_processo IS 'Resumo financeiro consolidado por processo';


--
-- Name: vw_metricas_empresas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_metricas_empresas AS
 SELECT id_empresa,
    count(*) AS processos_com_vinculo,
    sum(COALESCE(qtd_comunicacoes, 0)) AS comunicacoes_total,
    min(data_primeira_disponibilizacao) AS primeira_disponibilizacao,
    max(data_ultima_disponibilizacao) AS ultima_disponibilizacao,
    count(*) FILTER (WHERE ((data_ultima_disponibilizacao IS NOT NULL) AND (data_ultima_disponibilizacao >= (CURRENT_DATE - 7)))) AS processos_ultimos_7d,
    count(*) FILTER (WHERE ((data_ultima_disponibilizacao IS NOT NULL) AND (data_ultima_disponibilizacao >= (CURRENT_DATE - 30)))) AS processos_ultimos_30d,
    count(*) FILTER (WHERE (((array_length(partes_ativas, 1) IS NULL) OR (array_length(partes_ativas, 1) = 0)) AND ((array_length(partes_passivas, 1) IS NULL) OR (array_length(partes_passivas, 1) = 0)))) AS processos_sem_partes
   FROM public.processos p
  GROUP BY id_empresa;


ALTER VIEW public.vw_metricas_empresas OWNER TO postgres;

--
-- Name: vw_usuario_empresas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_usuario_empresas AS
 SELECT u.id_usuario,
    u.nome AS usuario_nome,
    e.id_empresa,
    e.nome AS empresa_nome
   FROM ((public.usuarios u
     JOIN public.usuario_empresas ue ON ((ue.id_usuario = u.id_usuario)))
     JOIN public.empresas e ON ((e.id_empresa = ue.id_empresa)));


ALTER VIEW public.vw_usuario_empresas OWNER TO postgres;

--
-- Name: movimentacoes_2025_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacoes ATTACH PARTITION public.movimentacoes_2025_04 FOR VALUES FROM ('2025-04-01 00:00:00-04') TO ('2025-05-01 00:00:00-04');


--
-- Name: publicacoes_2025_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publicacoes ATTACH PARTITION public.publicacoes_2025_04 FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');


--
-- Name: audit_log id_audit; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id_audit SET DEFAULT nextval('public.audit_log_id_audit_seq'::regclass);


--
-- Name: comunicacao_advogados id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comunicacao_advogados ALTER COLUMN id SET DEFAULT nextval('public.comunicacao_advogados_id_seq'::regclass);


--
-- Name: comunicacao_destinatarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comunicacao_destinatarios ALTER COLUMN id SET DEFAULT nextval('public.comunicacao_destinatarios_id_seq'::regclass);


--
-- Name: movimentacoes id_movimentacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacoes ALTER COLUMN id_movimentacao SET DEFAULT nextval('public.movimentacoes_id_movimentacao_seq'::regclass);


--
-- Name: permissoes id_permissao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissoes ALTER COLUMN id_permissao SET DEFAULT nextval('public.permissoes_id_permissao_seq'::regclass);


--
-- Name: publicacoes id_publicacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publicacoes ALTER COLUMN id_publicacao SET DEFAULT nextval('public.publicacoes_id_publicacao_seq'::regclass);


--
-- Name: tb_google_auth id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_google_auth ALTER COLUMN id_usuario SET DEFAULT nextval('public.tb_google_auth_id_usuario_seq'::regclass);


--
-- Name: tb_juris_features feature_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_features ALTER COLUMN feature_id SET DEFAULT nextval('public.tb_juris_features_feature_id_seq'::regclass);


--
-- Name: tb_juris_licenses license_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_licenses ALTER COLUMN license_id SET DEFAULT nextval('public.tb_juris_licenses_license_id_seq'::regclass);


--
-- Name: tb_juris_plans plan_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_plans ALTER COLUMN plan_id SET DEFAULT nextval('public.tb_juris_plans_plan_id_seq'::regclass);


--
-- Name: advogados advogados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advogados
    ADD CONSTRAINT advogados_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id_audit);


--
-- Name: compromissos compromissos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compromissos
    ADD CONSTRAINT compromissos_pkey PRIMARY KEY (id_compromisso);


--
-- Name: comunicacao_advogados comunicacao_advogados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comunicacao_advogados
    ADD CONSTRAINT comunicacao_advogados_pkey PRIMARY KEY (id);


--
-- Name: comunicacao_destinatarios comunicacao_destinatarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comunicacao_destinatarios
    ADD CONSTRAINT comunicacao_destinatarios_pkey PRIMARY KEY (id);


--
-- Name: comunicacoes comunicacoes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comunicacoes
    ADD CONSTRAINT comunicacoes_pkey PRIMARY KEY (id);


--
-- Name: configuracoes_alertas_padrao configuracoes_alertas_padrao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracoes_alertas_padrao
    ADD CONSTRAINT configuracoes_alertas_padrao_pkey PRIMARY KEY (id_config);


--
-- Name: contas contas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contas
    ADD CONSTRAINT contas_pkey PRIMARY KEY (id_conta);


--
-- Name: documentos documentos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT documentos_pkey PRIMARY KEY (id_documento);


--
-- Name: empresas empresas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresas
    ADD CONSTRAINT empresas_pkey PRIMARY KEY (id_empresa);


--
-- Name: evento_alertas evento_alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_alertas
    ADD CONSTRAINT evento_alertas_pkey PRIMARY KEY (id_alerta);


--
-- Name: evento_documentos evento_documentos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_documentos
    ADD CONSTRAINT evento_documentos_pkey PRIMARY KEY (id_documento);


--
-- Name: evento_participantes evento_participantes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_participantes
    ADD CONSTRAINT evento_participantes_pkey PRIMARY KEY (id_participante);


--
-- Name: evento_recorrencia evento_recorrencia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_recorrencia
    ADD CONSTRAINT evento_recorrencia_pkey PRIMARY KEY (id_recorrencia);


--
-- Name: fin_comprovantes fin_comprovantes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_comprovantes
    ADD CONSTRAINT fin_comprovantes_pkey PRIMARY KEY (id_comprovante);


--
-- Name: fin_contratos fin_contratos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_contratos
    ADD CONSTRAINT fin_contratos_pkey PRIMARY KEY (id_contrato);


--
-- Name: fin_historico fin_historico_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_historico
    ADD CONSTRAINT fin_historico_pkey PRIMARY KEY (id_historico);


--
-- Name: fin_itens fin_itens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_itens
    ADD CONSTRAINT fin_itens_pkey PRIMARY KEY (id_item);


--
-- Name: fin_lancamentos_avulsos fin_lancamentos_avulsos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_lancamentos_avulsos
    ADD CONSTRAINT fin_lancamentos_avulsos_pkey PRIMARY KEY (id_lancamento_avulso);


--
-- Name: fin_pagamentos fin_pagamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_pagamentos
    ADD CONSTRAINT fin_pagamentos_pkey PRIMARY KEY (id_pagamento);


--
-- Name: movimentacoes movimentacoes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacoes
    ADD CONSTRAINT movimentacoes_pkey PRIMARY KEY (data_movimentacao, id_movimentacao);


--
-- Name: movimentacoes_2025_04 movimentacoes_2025_04_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacoes_2025_04
    ADD CONSTRAINT movimentacoes_2025_04_pkey PRIMARY KEY (data_movimentacao, id_movimentacao);


--
-- Name: orgaos orgaos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgaos
    ADD CONSTRAINT orgaos_pkey PRIMARY KEY (id_orgao);


--
-- Name: permissoes permissoes_nome_permissao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissoes
    ADD CONSTRAINT permissoes_nome_permissao_key UNIQUE (nome_permissao);


--
-- Name: permissoes permissoes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissoes
    ADD CONSTRAINT permissoes_pkey PRIMARY KEY (id_permissao);


--
-- Name: pessoas_email pessoas_email_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoas_email
    ADD CONSTRAINT pessoas_email_pkey PRIMARY KEY (id_email);


--
-- Name: pessoas_endereco pessoas_endereco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoas_endereco
    ADD CONSTRAINT pessoas_endereco_pkey PRIMARY KEY (id_endereco);


--
-- Name: pessoas pessoas_perfil_pessoa_check; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.pessoas
    ADD CONSTRAINT pessoas_perfil_pessoa_check CHECK ((perfil = ANY (ARRAY['Parte'::text, 'Cliente'::text, 'Advogado'::text, 'Contato'::text]))) NOT VALID;


--
-- Name: pessoas pessoas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoas
    ADD CONSTRAINT pessoas_pkey PRIMARY KEY (id_pessoa);


--
-- Name: pessoas_site pessoas_site_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoas_site
    ADD CONSTRAINT pessoas_site_pkey PRIMARY KEY (id_site);


--
-- Name: pessoas_telefone pessoas_telefone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoas_telefone
    ADD CONSTRAINT pessoas_telefone_pkey PRIMARY KEY (id_pessoa);


--
-- Name: pessoas pessoas_tipo_pessoa_check; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.pessoas
    ADD CONSTRAINT pessoas_tipo_pessoa_check CHECK ((tipo_pessoa = ANY (ARRAY['Pessoa Física'::text, 'Pessoa Jurídica'::text]))) NOT VALID;


--
-- Name: processos_pessoas processos_pessoas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos_pessoas
    ADD CONSTRAINT processos_pessoas_pkey PRIMARY KEY (id_processo, id_pessoa, papel);


--
-- Name: processos processos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos
    ADD CONSTRAINT processos_pkey PRIMARY KEY (id_processo);


--
-- Name: publicacoes publicacoes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publicacoes
    ADD CONSTRAINT publicacoes_pkey PRIMARY KEY (data_publicacao, id_publicacao);


--
-- Name: publicacoes_2025_04 publicacoes_2025_04_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publicacoes_2025_04
    ADD CONSTRAINT publicacoes_2025_04_pkey PRIMARY KEY (data_publicacao, id_publicacao);


--
-- Name: role_permissoes role_permissoes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissoes
    ADD CONSTRAINT role_permissoes_pkey PRIMARY KEY (id_role, id_permissao);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_role);


--
-- Name: tab_amazons3 tab_amazons3_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tab_amazons3
    ADD CONSTRAINT tab_amazons3_pkey PRIMARY KEY (codigo);


--
-- Name: tab_cnaoab tab_cnaoab_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tab_cnaoab
    ADD CONSTRAINT tab_cnaoab_pkey PRIMARY KEY (codigo);


--
-- Name: tab_comunicado_fala tab_comunicado_fala_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tab_comunicado_fala
    ADD CONSTRAINT tab_comunicado_fala_pkey PRIMARY KEY (codigo);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id_taggings);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id_tag);


--
-- Name: tarefas tarefas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefas
    ADD CONSTRAINT tarefas_pkey PRIMARY KEY (id_tarefa);


--
-- Name: tb_advogado_comunicado tb_advogado_comunicado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_advogado_comunicado
    ADD CONSTRAINT tb_advogado_comunicado_pkey PRIMARY KEY (id);


--
-- Name: tb_advogado tb_advogado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_advogado
    ADD CONSTRAINT tb_advogado_pkey PRIMARY KEY (id);


--
-- Name: tb_api_consulta_log tb_api_consulta_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_api_consulta_log
    ADD CONSTRAINT tb_api_consulta_log_pkey PRIMARY KEY (codigo);


--
-- Name: tb_consulta_erro tb_consulta_erro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_consulta_erro
    ADD CONSTRAINT tb_consulta_erro_pkey PRIMARY KEY (codigo);


--
-- Name: tb_consulta_ok tb_consulta_ok_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_consulta_ok
    ADD CONSTRAINT tb_consulta_ok_pkey PRIMARY KEY (codigo);


--
-- Name: tb_crm_usuarios tb_crm_usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_crm_usuarios
    ADD CONSTRAINT tb_crm_usuarios_pkey PRIMARY KEY (codigo);


--
-- Name: tb_crm_usuarios_restri tb_crm_usuarios_restri_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_crm_usuarios_restri
    ADD CONSTRAINT tb_crm_usuarios_restri_pkey PRIMARY KEY (codiuser);


--
-- Name: tb_eventos_google tb_eventos_google_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_eventos_google
    ADD CONSTRAINT tb_eventos_google_pkey PRIMARY KEY (id_evento);


--
-- Name: tb_f_categoria tb_f_categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_f_categoria
    ADD CONSTRAINT tb_f_categoria_pkey PRIMARY KEY (id_categoria);


--
-- Name: tb_f_lancamento tb_f_lancamento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_f_lancamento
    ADD CONSTRAINT tb_f_lancamento_pkey PRIMARY KEY (id_lancamento);


--
-- Name: tb_feriados tb_feriados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_feriados
    ADD CONSTRAINT tb_feriados_pkey PRIMARY KEY (codigo);


--
-- Name: tb_google_auth tb_google_auth_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_google_auth
    ADD CONSTRAINT tb_google_auth_pkey PRIMARY KEY (id_usuario);


--
-- Name: tb_juris_features tb_juris_features_feature_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_features
    ADD CONSTRAINT tb_juris_features_feature_code_key UNIQUE (feature_code);


--
-- Name: tb_juris_features tb_juris_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_features
    ADD CONSTRAINT tb_juris_features_pkey PRIMARY KEY (feature_id);


--
-- Name: tb_juris_licenses tb_juris_licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_licenses
    ADD CONSTRAINT tb_juris_licenses_pkey PRIMARY KEY (license_id);


--
-- Name: tb_juris_plan_features tb_juris_plan_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_plan_features
    ADD CONSTRAINT tb_juris_plan_features_pkey PRIMARY KEY (plan_id, feature_id);


--
-- Name: tb_juris_plans tb_juris_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_plans
    ADD CONSTRAINT tb_juris_plans_pkey PRIMARY KEY (plan_id);


--
-- Name: tb_link_acesso tb_link_acesso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_link_acesso
    ADD CONSTRAINT tb_link_acesso_pkey PRIMARY KEY (codigo);


--
-- Name: tb_monitoramento_registro tb_monitoramento_registro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_monitoramento_registro
    ADD CONSTRAINT tb_monitoramento_registro_pkey PRIMARY KEY (codigo);


--
-- Name: tb_processo_comunicados tb_processo_comunicados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_processo_comunicados
    ADD CONSTRAINT tb_processo_comunicados_pkey PRIMARY KEY (codigo);


--
-- Name: tb_whatsapp_validar tb_whatsapp_validar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_whatsapp_validar
    ADD CONSTRAINT tb_whatsapp_validar_pkey PRIMARY KEY (codigo);


--
-- Name: temp_code_verify temp_register_empresa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.temp_code_verify
    ADD CONSTRAINT temp_register_empresa_pkey PRIMARY KEY (codigo);


--
-- Name: transacoes transacoes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transacoes
    ADD CONSTRAINT transacoes_pkey PRIMARY KEY (id_transacao);


--
-- Name: orgaos tribunais_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgaos
    ADD CONSTRAINT tribunais_id_unique UNIQUE (id);


--
-- Name: tribunais tribunais_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tribunais
    ADD CONSTRAINT tribunais_pkey PRIMARY KEY (id);


--
-- Name: tribunais tribunais_sigla_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tribunais
    ADD CONSTRAINT tribunais_sigla_unique UNIQUE (sigla);


--
-- Name: roles uq_roles_empresa_nome; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT uq_roles_empresa_nome UNIQUE (id_empresa, nome_role);


--
-- Name: usuario_empresas usuario_empresas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_empresas
    ADD CONSTRAINT usuario_empresas_pkey PRIMARY KEY (id_usuario, id_empresa);


--
-- Name: usuario_roles usuario_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_roles
    ADD CONSTRAINT usuario_roles_pkey PRIMARY KEY (id_usuario, id_role);


--
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: idx_advogados_oab_digits_uf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advogados_oab_digits_uf ON public.advogados USING btree (regexp_replace(numero_oab, '[^0-9]'::text, ''::text, 'g'::text), uf_oab);


--
-- Name: idx_advogados_oab_uf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advogados_oab_uf ON public.advogados USING btree (numero_oab, uf_oab);


--
-- Name: idx_com_adv_advogado_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_com_adv_advogado_id ON public.comunicacao_advogados USING btree (advogado_id);


--
-- Name: idx_com_adv_comunicacao_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_com_adv_comunicacao_id ON public.comunicacao_advogados USING btree (comunicacao_id);


--
-- Name: idx_com_adv_numero_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_com_adv_numero_processo ON public.comunicacao_advogados USING btree (numero_processo);


--
-- Name: idx_com_adv_oab_digits_uf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_com_adv_oab_digits_uf ON public.comunicacao_advogados USING btree (regexp_replace(numero_oab, '[^0-9]'::text, ''::text, 'g'::text), uf_oab);


--
-- Name: idx_com_adv_oab_uf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_com_adv_oab_uf ON public.comunicacao_advogados USING btree (numero_oab, uf_oab);


--
-- Name: idx_com_dest_comunicacao_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_com_dest_comunicacao_id ON public.comunicacao_destinatarios USING btree (comunicacao_id);


--
-- Name: idx_com_dest_numero_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_com_dest_numero_processo ON public.comunicacao_destinatarios USING btree (numero_processo);


--
-- Name: idx_compromissos_data_inicio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compromissos_data_inicio ON public.compromissos USING btree (data_inicio);


--
-- Name: idx_compromissos_empresa_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compromissos_empresa_data ON public.compromissos USING btree (id_empresa, data_inicio);


--
-- Name: idx_compromissos_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compromissos_processo ON public.compromissos USING btree (processo_vinculado);


--
-- Name: idx_compromissos_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compromissos_status ON public.compromissos USING btree (status);


--
-- Name: idx_compromissos_tipo_evento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compromissos_tipo_evento ON public.compromissos USING btree (tipo_evento);


--
-- Name: idx_comunicacoes_data_envio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_data_envio ON public.comunicacoes USING btree (data_envio);


--
-- Name: idx_comunicacoes_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_hash ON public.comunicacoes USING btree (hash) WHERE (hash IS NOT NULL);


--
-- Name: idx_comunicacoes_id_orgao; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_id_orgao ON public.comunicacoes USING btree (id_orgao);


--
-- Name: idx_comunicacoes_numero_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_numero_processo ON public.comunicacoes USING btree (numero_processo);


--
-- Name: idx_comunicacoes_orgao_data_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_orgao_data_processo ON public.comunicacoes USING btree (id_orgao, data_disponibilizacao DESC, numero_processo);


--
-- Name: idx_comunicacoes_processo_ativo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_processo_ativo ON public.comunicacoes USING btree (numero_processo, codigo_classe) WHERE (data_disponibilizacao >= '2025-07-25'::date);


--
-- Name: idx_comunicacoes_recentes; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_recentes ON public.comunicacoes USING btree (data_disponibilizacao, numero_processo) WHERE (data_disponibilizacao >= '2025-09-24'::date);


--
-- Name: idx_comunicacoes_sem_vinculo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_sem_vinculo ON public.comunicacoes USING btree (id) WHERE (tem_vinculo = 0);


--
-- Name: idx_comunicacoes_sigla_tribunal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_sigla_tribunal ON public.comunicacoes USING btree (sigla_tribunal);


--
-- Name: idx_comunicacoes_tem_vinculo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comunicacoes_tem_vinculo ON public.comunicacoes USING btree (tem_vinculo);


--
-- Name: idx_evento_alertas_compromisso; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_alertas_compromisso ON public.evento_alertas USING btree (id_compromisso);


--
-- Name: idx_evento_alertas_envio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_alertas_envio ON public.evento_alertas USING btree (enviado, enviado_em);


--
-- Name: idx_evento_alertas_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_alertas_usuario ON public.evento_alertas USING btree (id_usuario);


--
-- Name: idx_evento_documentos_compromisso; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_documentos_compromisso ON public.evento_documentos USING btree (id_compromisso);


--
-- Name: idx_evento_documentos_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_documentos_tipo ON public.evento_documentos USING btree (tipo_documento);


--
-- Name: idx_evento_participantes_compromisso; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_participantes_compromisso ON public.evento_participantes USING btree (id_compromisso);


--
-- Name: idx_evento_participantes_pessoa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_participantes_pessoa ON public.evento_participantes USING btree (id_pessoa);


--
-- Name: idx_evento_recorrencia_pai; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evento_recorrencia_pai ON public.evento_recorrencia USING btree (id_compromisso_pai);


--
-- Name: idx_fin_comprovantes_lancamento_avulso; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_comprovantes_lancamento_avulso ON public.fin_comprovantes USING btree (id_lancamento_avulso);


--
-- Name: idx_fin_comprovantes_pagamento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_comprovantes_pagamento ON public.fin_comprovantes USING btree (id_pagamento);


--
-- Name: idx_fin_contratos_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_contratos_data ON public.fin_contratos USING btree (data_contrato);


--
-- Name: idx_fin_contratos_empresa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_contratos_empresa ON public.fin_contratos USING btree (id_empresa);


--
-- Name: idx_fin_contratos_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_contratos_processo ON public.fin_contratos USING btree (id_processo);


--
-- Name: idx_fin_contratos_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_contratos_status ON public.fin_contratos USING btree (status);


--
-- Name: idx_fin_contratos_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_contratos_tipo ON public.fin_contratos USING btree (tipo_contrato);


--
-- Name: idx_fin_historico_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_historico_data ON public.fin_historico USING btree (data_acao);


--
-- Name: idx_fin_historico_registro; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_historico_registro ON public.fin_historico USING btree (tabela_origem, id_registro);


--
-- Name: idx_fin_historico_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_historico_tipo ON public.fin_historico USING btree (tipo_acao);


--
-- Name: idx_fin_itens_contrato; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_itens_contrato ON public.fin_itens USING btree (id_contrato);


--
-- Name: idx_fin_itens_lancamento_avulso; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_itens_lancamento_avulso ON public.fin_itens USING btree (id_lancamento_avulso);


--
-- Name: idx_fin_itens_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_itens_status ON public.fin_itens USING btree (status);


--
-- Name: idx_fin_itens_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_itens_tipo ON public.fin_itens USING btree (tipo_item);


--
-- Name: idx_fin_itens_vencimento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_itens_vencimento ON public.fin_itens USING btree (data_vencimento);


--
-- Name: idx_fin_lancamentos_avulsos_empresa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_lancamentos_avulsos_empresa ON public.fin_lancamentos_avulsos USING btree (id_empresa);


--
-- Name: idx_fin_lancamentos_avulsos_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_lancamentos_avulsos_processo ON public.fin_lancamentos_avulsos USING btree (id_processo);


--
-- Name: idx_fin_lancamentos_avulsos_reembolsavel; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_lancamentos_avulsos_reembolsavel ON public.fin_lancamentos_avulsos USING btree (reembolsavel);


--
-- Name: idx_fin_lancamentos_avulsos_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_lancamentos_avulsos_status ON public.fin_lancamentos_avulsos USING btree (status_pagamento);


--
-- Name: idx_fin_lancamentos_avulsos_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_lancamentos_avulsos_tipo ON public.fin_lancamentos_avulsos USING btree (tipo_lancamento);


--
-- Name: idx_fin_pagamentos_conciliado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_pagamentos_conciliado ON public.fin_pagamentos USING btree (conciliado);


--
-- Name: idx_fin_pagamentos_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_pagamentos_data ON public.fin_pagamentos USING btree (data_pagamento);


--
-- Name: idx_fin_pagamentos_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_pagamentos_item ON public.fin_pagamentos USING btree (id_item);


--
-- Name: idx_fin_pagamentos_lancamento_avulso; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_pagamentos_lancamento_avulso ON public.fin_pagamentos USING btree (id_lancamento_avulso);


--
-- Name: idx_fin_pagamentos_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fin_pagamentos_tipo ON public.fin_pagamentos USING btree (tipo_transacao);


--
-- Name: idx_pessoas_nome_fts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pessoas_nome_fts ON public.pessoas USING gin (to_tsvector('portuguese'::regconfig, nome));


--
-- Name: idx_processos_empresa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_processos_empresa ON public.processos USING btree (id_empresa);


--
-- Name: idx_processos_empresa_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_processos_empresa_data ON public.processos USING btree (id_empresa, data_ultima_disponibilizacao DESC);


--
-- Name: idx_processos_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_processos_numero ON public.processos USING btree (numero_processo);


--
-- Name: idx_taggings_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_taggings_entity ON public.taggings USING btree (taggable_type, taggable_id);


--
-- Name: idx_tarefas_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tarefas_usuario ON public.tarefas USING btree (id_usuario_atribuido);


--
-- Name: idx_tb_adv_comunicado_adv; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tb_adv_comunicado_adv ON public.tb_advogado_comunicado USING btree (advogado_id);


--
-- Name: idx_tb_advogado_oab; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tb_advogado_oab ON public.tb_advogado USING btree (oab);


--
-- Name: idx_tb_advogado_oab_digits_uf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tb_advogado_oab_digits_uf ON public.tb_advogado USING btree (regexp_replace(oab_numero, '[^0-9]'::text, ''::text, 'g'::text), oab_uf);


--
-- Name: idx_tb_advogado_oab_num_uf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tb_advogado_oab_num_uf ON public.tb_advogado USING btree (oab_numero, oab_uf);


--
-- Name: idx_tb_eventos_google_compromisso; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tb_eventos_google_compromisso ON public.tb_eventos_google USING btree (id_compromisso);


--
-- Name: idx_tb_eventos_google_sync; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tb_eventos_google_sync ON public.tb_eventos_google USING btree (ultima_sincronizacao);


--
-- Name: idx_transacoes_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transacoes_data ON public.transacoes USING btree (data_transacao);


--
-- Name: tab_comunicado_fala_comunicado_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tab_comunicado_fala_comunicado_id_idx ON public.tab_comunicado_fala USING btree (comunicado_id);


--
-- Name: tb_advogado_comunicado_adv_codigo_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tb_advogado_comunicado_adv_codigo_idx ON public.tb_advogado_comunicado USING btree (advogado_id);


--
-- Name: tb_advogado_oab_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tb_advogado_oab_idx ON public.tb_advogado USING btree (oab);


--
-- Name: tb_monitoramento_registro_adv_oab_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tb_monitoramento_registro_adv_oab_idx ON public.tb_monitoramento_registro USING btree (adv_oab);


--
-- Name: tb_monitoramento_registro_data_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tb_monitoramento_registro_data_idx ON public.tb_monitoramento_registro USING btree (data);


--
-- Name: tb_whatsapp_validar_codigo_validar_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tb_whatsapp_validar_codigo_validar_idx ON public.tb_whatsapp_validar USING btree (codigo_validar);


--
-- Name: tb_whatsapp_validar_remotejid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tb_whatsapp_validar_remotejid_idx ON public.tb_whatsapp_validar USING btree (remotejid);


--
-- Name: uq_com_adv_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_com_adv_unique ON public.comunicacao_advogados USING btree (comunicacao_id, numero_processo, nome_advogado, numero_oab, uf_oab);


--
-- Name: uq_processos_empresa_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_processos_empresa_processo ON public.processos USING btree (id_empresa, numero_processo);


--
-- Name: uq_tab_comunicado_fala_comunicado_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_tab_comunicado_fala_comunicado_id ON public.tab_comunicado_fala USING btree (comunicado_id) WHERE (comunicado_id IS NOT NULL);


--
-- Name: movimentacoes_2025_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.movimentacoes_pkey ATTACH PARTITION public.movimentacoes_2025_04_pkey;


--
-- Name: publicacoes_2025_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.publicacoes_pkey ATTACH PARTITION public.publicacoes_2025_04_pkey;


--
-- Name: roles roles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.trg_roles_updated_at();


--
-- Name: fin_itens trg_atualizar_status_item; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualizar_status_item BEFORE INSERT OR UPDATE ON public.fin_itens FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_status_item();


--
-- Name: fin_itens trg_atualizar_valor_recebido_contrato; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualizar_valor_recebido_contrato AFTER INSERT OR UPDATE ON public.fin_itens FOR EACH ROW WHEN ((new.id_contrato IS NOT NULL)) EXECUTE FUNCTION public.fn_atualizar_valor_recebido_contrato();


--
-- Name: fin_contratos trg_historico_contratos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_historico_contratos AFTER INSERT OR DELETE OR UPDATE ON public.fin_contratos FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_historico();


--
-- Name: fin_itens trg_historico_itens; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_historico_itens AFTER INSERT OR DELETE OR UPDATE ON public.fin_itens FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_historico();


--
-- Name: fin_lancamentos_avulsos trg_historico_lancamentos_avulsos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_historico_lancamentos_avulsos AFTER INSERT OR DELETE OR UPDATE ON public.fin_lancamentos_avulsos FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_historico();


--
-- Name: fin_pagamentos trg_historico_pagamentos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_historico_pagamentos AFTER INSERT OR DELETE OR UPDATE ON public.fin_pagamentos FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_historico();


--
-- Name: tb_advogado_comunicado trg_sync_processo_ins; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sync_processo_ins AFTER INSERT ON public.tb_advogado_comunicado FOR EACH ROW EXECUTE FUNCTION public.fn_sync_processo_tb_advogado_comunicado();


--
-- Name: tb_advogado_comunicado trg_sync_tem_vinculo_del; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sync_tem_vinculo_del AFTER DELETE ON public.tb_advogado_comunicado FOR EACH ROW EXECUTE FUNCTION public.fn_sync_tem_vinculo_tb_advogado_comunicado();


--
-- Name: tb_advogado_comunicado trg_sync_tem_vinculo_ins; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sync_tem_vinculo_ins AFTER INSERT ON public.tb_advogado_comunicado FOR EACH ROW EXECUTE FUNCTION public.fn_sync_tem_vinculo_tb_advogado_comunicado();


--
-- Name: comunicacao_advogados trg_vincula_advogado_comunicado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_vincula_advogado_comunicado AFTER INSERT ON public.comunicacao_advogados FOR EACH ROW EXECUTE FUNCTION public.fn_vincula_advogado_comunicado();


--
-- Name: compromissos compromissos_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compromissos
    ADD CONSTRAINT compromissos_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: compromissos compromissos_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compromissos
    ADD CONSTRAINT compromissos_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario);


--
-- Name: compromissos compromissos_processo_vinculado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compromissos
    ADD CONSTRAINT compromissos_processo_vinculado_fkey FOREIGN KEY (processo_vinculado) REFERENCES public.processos(id_processo);


--
-- Name: comunicacao_advogados comunicacao_advogados_advogado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comunicacao_advogados
    ADD CONSTRAINT comunicacao_advogados_advogado_id_fkey FOREIGN KEY (advogado_id) REFERENCES public.advogados(id);


--
-- Name: comunicacao_destinatarios comunicacao_destinatarios_comunicacao_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comunicacao_destinatarios
    ADD CONSTRAINT comunicacao_destinatarios_comunicacao_id_fkey FOREIGN KEY (comunicacao_id) REFERENCES public.comunicacoes(id);


--
-- Name: contas contas_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contas
    ADD CONSTRAINT contas_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: documentos documentos_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT documentos_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: documentos documentos_id_pessoa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT documentos_id_pessoa_fkey FOREIGN KEY (id_pessoa) REFERENCES public.pessoas(id_pessoa);


--
-- Name: documentos documentos_id_processo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT documentos_id_processo_fkey FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo);


--
-- Name: evento_alertas evento_alertas_id_compromisso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_alertas
    ADD CONSTRAINT evento_alertas_id_compromisso_fkey FOREIGN KEY (id_compromisso) REFERENCES public.compromissos(id_compromisso) ON DELETE CASCADE;


--
-- Name: evento_alertas evento_alertas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_alertas
    ADD CONSTRAINT evento_alertas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario);


--
-- Name: evento_documentos evento_documentos_id_compromisso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_documentos
    ADD CONSTRAINT evento_documentos_id_compromisso_fkey FOREIGN KEY (id_compromisso) REFERENCES public.compromissos(id_compromisso) ON DELETE CASCADE;


--
-- Name: evento_documentos evento_documentos_id_usuario_upload_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_documentos
    ADD CONSTRAINT evento_documentos_id_usuario_upload_fkey FOREIGN KEY (id_usuario_upload) REFERENCES public.usuarios(id_usuario);


--
-- Name: evento_participantes evento_participantes_id_compromisso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_participantes
    ADD CONSTRAINT evento_participantes_id_compromisso_fkey FOREIGN KEY (id_compromisso) REFERENCES public.compromissos(id_compromisso) ON DELETE CASCADE;


--
-- Name: evento_participantes evento_participantes_id_pessoa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_participantes
    ADD CONSTRAINT evento_participantes_id_pessoa_fkey FOREIGN KEY (id_pessoa) REFERENCES public.pessoas(id_pessoa);


--
-- Name: evento_recorrencia evento_recorrencia_id_compromisso_pai_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evento_recorrencia
    ADD CONSTRAINT evento_recorrencia_id_compromisso_pai_fkey FOREIGN KEY (id_compromisso_pai) REFERENCES public.compromissos(id_compromisso) ON DELETE CASCADE;


--
-- Name: fin_comprovantes fin_comprovantes_id_lancamento_avulso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_comprovantes
    ADD CONSTRAINT fin_comprovantes_id_lancamento_avulso_fkey FOREIGN KEY (id_lancamento_avulso) REFERENCES public.fin_lancamentos_avulsos(id_lancamento_avulso) ON DELETE CASCADE;


--
-- Name: fin_comprovantes fin_comprovantes_id_pagamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_comprovantes
    ADD CONSTRAINT fin_comprovantes_id_pagamento_fkey FOREIGN KEY (id_pagamento) REFERENCES public.fin_pagamentos(id_pagamento) ON DELETE CASCADE;


--
-- Name: fin_contratos fin_contratos_id_processo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_contratos
    ADD CONSTRAINT fin_contratos_id_processo_fkey FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo) ON DELETE CASCADE;


--
-- Name: fin_itens fin_itens_id_contrato_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_itens
    ADD CONSTRAINT fin_itens_id_contrato_fkey FOREIGN KEY (id_contrato) REFERENCES public.fin_contratos(id_contrato) ON DELETE CASCADE;


--
-- Name: fin_itens fin_itens_id_lancamento_avulso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_itens
    ADD CONSTRAINT fin_itens_id_lancamento_avulso_fkey FOREIGN KEY (id_lancamento_avulso) REFERENCES public.fin_lancamentos_avulsos(id_lancamento_avulso) ON DELETE CASCADE;


--
-- Name: fin_lancamentos_avulsos fin_lancamentos_avulsos_id_processo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_lancamentos_avulsos
    ADD CONSTRAINT fin_lancamentos_avulsos_id_processo_fkey FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo) ON DELETE CASCADE;


--
-- Name: fin_pagamentos fin_pagamentos_id_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_pagamentos
    ADD CONSTRAINT fin_pagamentos_id_item_fkey FOREIGN KEY (id_item) REFERENCES public.fin_itens(id_item) ON DELETE CASCADE;


--
-- Name: fin_pagamentos fin_pagamentos_id_lancamento_avulso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fin_pagamentos
    ADD CONSTRAINT fin_pagamentos_id_lancamento_avulso_fkey FOREIGN KEY (id_lancamento_avulso) REFERENCES public.fin_lancamentos_avulsos(id_lancamento_avulso) ON DELETE CASCADE;


--
-- Name: movimentacoes movimentacoes_id_processo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.movimentacoes
    ADD CONSTRAINT movimentacoes_id_processo_fkey FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo) ON DELETE CASCADE;


--
-- Name: pessoas pessoas_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoas
    ADD CONSTRAINT pessoas_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: processos processos_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos
    ADD CONSTRAINT processos_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: processos_pessoas processos_pessoas_id_pessoa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos_pessoas
    ADD CONSTRAINT processos_pessoas_id_pessoa_fkey FOREIGN KEY (id_pessoa) REFERENCES public.pessoas(id_pessoa) ON DELETE CASCADE;


--
-- Name: processos_pessoas processos_pessoas_id_processo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos_pessoas
    ADD CONSTRAINT processos_pessoas_id_processo_fkey FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo) ON DELETE CASCADE;


--
-- Name: publicacoes publicacoes_id_processo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.publicacoes
    ADD CONSTRAINT publicacoes_id_processo_fkey FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo);


--
-- Name: role_permissoes role_permissoes_id_permissao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissoes
    ADD CONSTRAINT role_permissoes_id_permissao_fkey FOREIGN KEY (id_permissao) REFERENCES public.permissoes(id_permissao);


--
-- Name: roles roles_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa) ON DELETE CASCADE;


--
-- Name: taggings taggings_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: taggings taggings_id_tag_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_id_tag_fkey FOREIGN KEY (id_tag) REFERENCES public.tags(id_tag);


--
-- Name: tags tags_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: tags tags_id_tag_pai_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_id_tag_pai_fkey FOREIGN KEY (id_tag_pai) REFERENCES public.tags(id_tag);


--
-- Name: tarefas tarefas_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefas
    ADD CONSTRAINT tarefas_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: tarefas tarefas_id_usuario_atribuido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefas
    ADD CONSTRAINT tarefas_id_usuario_atribuido_fkey FOREIGN KEY (id_usuario_atribuido) REFERENCES public.usuarios(id_usuario);


--
-- Name: tb_eventos_google tb_eventos_google_id_compromisso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_eventos_google
    ADD CONSTRAINT tb_eventos_google_id_compromisso_fkey FOREIGN KEY (id_compromisso) REFERENCES public.compromissos(id_compromisso);


--
-- Name: tb_f_lancamento tb_f_lancamento_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_f_lancamento
    ADD CONSTRAINT tb_f_lancamento_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.tb_f_categoria(id_categoria);


--
-- Name: tb_juris_licenses tb_juris_licenses_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_licenses
    ADD CONSTRAINT tb_juris_licenses_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.tb_juris_plans(plan_id);


--
-- Name: tb_juris_plan_features tb_juris_plan_features_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_plan_features
    ADD CONSTRAINT tb_juris_plan_features_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.tb_juris_features(feature_id);


--
-- Name: tb_juris_plan_features tb_juris_plan_features_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tb_juris_plan_features
    ADD CONSTRAINT tb_juris_plan_features_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.tb_juris_plans(plan_id);


--
-- Name: transacoes transacoes_id_conta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transacoes
    ADD CONSTRAINT transacoes_id_conta_fkey FOREIGN KEY (id_conta) REFERENCES public.contas(id_conta);


--
-- Name: transacoes transacoes_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transacoes
    ADD CONSTRAINT transacoes_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: transacoes transacoes_id_pessoa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transacoes
    ADD CONSTRAINT transacoes_id_pessoa_fkey FOREIGN KEY (id_pessoa) REFERENCES public.pessoas(id_pessoa);


--
-- Name: transacoes transacoes_id_processo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transacoes
    ADD CONSTRAINT transacoes_id_processo_fkey FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo);


--
-- Name: usuario_empresas usuario_empresas_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_empresas
    ADD CONSTRAINT usuario_empresas_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa) ON DELETE CASCADE;


--
-- Name: usuario_empresas usuario_empresas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_empresas
    ADD CONSTRAINT usuario_empresas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;


--
-- Name: usuario_roles usuario_roles_id_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_roles
    ADD CONSTRAINT usuario_roles_id_role_fkey FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON DELETE CASCADE;


--
-- Name: usuario_roles usuario_roles_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_roles
    ADD CONSTRAINT usuario_roles_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;


--
-- Name: processos isolamento_empresa_processo; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY isolamento_empresa_processo ON public.processos USING ((id_empresa = (current_setting('app.id_empresa'::text))::uuid));


--
-- Name: movimentacoes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.movimentacoes ENABLE ROW LEVEL SECURITY;

--
-- Name: pessoas; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.pessoas ENABLE ROW LEVEL SECURITY;

--
-- Name: processos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.processos ENABLE ROW LEVEL SECURITY;

--
-- Name: processos processos_tenant_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY processos_tenant_policy ON public.processos USING ((id_empresa IN ( SELECT ue.id_empresa
   FROM public.usuario_empresas ue
  WHERE (ue.id_usuario = (current_setting('"app.current_user"'::text))::uuid))));


--
-- Name: publicacoes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.publicacoes ENABLE ROW LEVEL SECURITY;

--
-- Name: tarefas; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.tarefas ENABLE ROW LEVEL SECURITY;

--
-- Name: movimentacoes tenant_rls_movimentacoes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenant_rls_movimentacoes ON public.movimentacoes USING (public.tenant_allowed(id_empresa)) WITH CHECK (public.tenant_allowed(id_empresa));


--
-- Name: pessoas tenant_rls_pessoas; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenant_rls_pessoas ON public.pessoas USING (public.tenant_allowed(id_empresa)) WITH CHECK (public.tenant_allowed(id_empresa));


--
-- Name: processos tenant_rls_processos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenant_rls_processos ON public.processos USING (public.tenant_allowed(id_empresa)) WITH CHECK (public.tenant_allowed(id_empresa));


--
-- Name: publicacoes tenant_rls_publicacoes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenant_rls_publicacoes ON public.publicacoes USING (public.tenant_allowed(id_empresa)) WITH CHECK (public.tenant_allowed(id_empresa));


--
-- Name: tarefas tenant_rls_tarefas; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenant_rls_tarefas ON public.tarefas USING (public.tenant_allowed(id_empresa)) WITH CHECK (public.tenant_allowed(id_empresa));


--
-- Name: transacoes tenant_rls_transacoes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenant_rls_transacoes ON public.transacoes USING (public.tenant_allowed(id_empresa)) WITH CHECK (public.tenant_allowed(id_empresa));


--
-- Name: transacoes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.transacoes ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

