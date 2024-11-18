--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- Name: DEFIR_ddl_log_record_add(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."DEFIR_ddl_log_record_add"() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _command_text  Text          = current_query();    -- Текст SQL инструкции
    _date          TimeStamp     = now();              -- Текущая дата
    _client_addr   Inet          = inet_client_addr(); -- IP адрес клиента, с которого запущена SQL инструкция
    _user_name     VarChar(256)  = current_user;       -- Имя пользователя, от которого запущена SQL инструкция
    _tg_event      Text          = TG_event;           -- Имя события
    _tg_tag        Text          = TG_tag;             -- SQL команда

  BEGIN
	IF _tg_event  = 'sql_drop'
    THEN
      INSERT INTO postgres.public.DEFIR_ddl_log
      (
         "LogDate",
         "ClassId",
         "ObjId",
         "ObjsubId",
         "ClientAddr",
         "UserName",
         "EventType",
         "ObjectType",
         "SchemaName",
         "ObjectName",
         "Command",
         "CommandTag",
         "CommandText",
	 "ApplicationName"
      )
      SELECT
        _date,
        D.classid,
        D.objid,
        D.objsubid,
        _client_addr,
        _user_name,
        _tg_event,
        D.object_type,
        D.schema_name,
        D.object_identity,
        _tg_tag,
		_tg_tag,
      	_command_text,
        (SELECT application_name 
             FROM pg_stat_activity
            WHERE pid = pg_backend_pid())
      FROM pg_event_trigger_dropped_objects() D
      WHERE D.schema_name NOT IN
       (
         'pg_temp',
         'pg_toast'
       ) AND D.object_type <> 'type';

    ELSE

      INSERT INTO  postgres.public.DEFIR_ddl_log
      (
         "LogDate",
         "ClassId",
         "ObjId",
         "ObjsubId",
         "ClientAddr",
         "UserName",
         "EventType",
         "ObjectType",
         "SchemaName",
         "ObjectName",
         "Command",
         "CommandTag",
         "CommandText",
		 "ApplicationName"
	
      )
      SELECT
        _date,
        D.classid,
        D.objid,
        D.objsubid,
        _client_addr,
        _user_name,
        _tg_event,
        D.object_type,
        D.schema_name,
        D.object_identity,
        _tg_tag,
        D.command_tag,
        _command_text,
        (SELECT application_name 
             FROM pg_stat_activity
            WHERE pid = pg_backend_pid())
      FROM pg_event_trigger_ddl_commands() D
      WHERE D.schema_name NOT IN
       (
         'pg_temp',
         'pg_toast'
       );

    END IF;

  END;

  $$;


ALTER FUNCTION public."DEFIR_ddl_log_record_add"() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: forth; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forth (
    id bigint,
    name character varying(50),
    active boolean
);


ALTER TABLE public.forth OWNER TO postgres;

--
-- Name: third; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.third (
    id integer,
    name character varying(50),
    active boolean
);


ALTER TABLE public.third OWNER TO postgres;

--
-- Name: fourth_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX fourth_id_idx ON public.forth USING btree (id);


--
-- PostgreSQL database dump complete
--

