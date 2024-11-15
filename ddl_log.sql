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
      INSERT INTO public.DEFIR_ddl_log
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

      INSERT INTO  public.DEFIR_ddl_log
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
-- Name: defir_ddl_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.defir_ddl_log (
    "LogId" integer NOT NULL,
    "LogDate" timestamp without time zone NOT NULL,
    "ClassId" integer,
    "ObjId" integer,
    "ObjsubId" integer,
    "ClientAddr" inet,
    "UserName" character varying(256),
    "EventType" character varying(100),
    "ObjectType" text,
    "SchemaName" text,
    "ObjectName" text,
    "Command" text,
    "CommandTag" text,
    "CommandText" text,
    "ApplicationName" character varying
);


ALTER TABLE public.defir_ddl_log OWNER TO postgres;

--
-- Name: ddl_log_LogId_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.defir_ddl_log ALTER COLUMN "LogId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."ddl_log_LogId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


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
-- Name: defir_ddl_log PK_DDL_Log_LogId; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.defir_ddl_log
    ADD CONSTRAINT "PK_DDL_Log_LogId" PRIMARY KEY ("LogId");


--
-- Name: fourth_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX fourth_id_idx ON public.forth USING btree (id);


--
-- Name: DEFIR_ddl_log_create; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER "DEFIR_ddl_log_create" ON ddl_command_end
   EXECUTE FUNCTION public."DEFIR_ddl_log_record_add"();


ALTER EVENT TRIGGER "DEFIR_ddl_log_create" OWNER TO postgres;

--
-- Name: DEFIR_ddl_log_drop; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER "DEFIR_ddl_log_drop" ON sql_drop
   EXECUTE FUNCTION public."DEFIR_ddl_log_record_add"();


ALTER EVENT TRIGGER "DEFIR_ddl_log_drop" OWNER TO postgres;

--
-- PostgreSQL database dump complete
--

