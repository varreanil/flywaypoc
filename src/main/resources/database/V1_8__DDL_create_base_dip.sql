--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: app_deidentified; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA app_deidentified;


ALTER SCHEMA app_deidentified OWNER TO catalyze;

--
-- Name: app_identified; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA app_identified;


ALTER SCHEMA app_identified OWNER TO catalyze;

--
-- Name: base_deidentified; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA base_deidentified;


ALTER SCHEMA base_deidentified OWNER TO catalyze;

--
-- Name: base_identified; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA base_identified;


ALTER SCHEMA base_identified OWNER TO catalyze;

--
-- Name: cleansed_deidentified; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA cleansed_deidentified;


ALTER SCHEMA cleansed_deidentified OWNER TO catalyze;

--
-- Name: cleansed_identified; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA cleansed_identified;


ALTER SCHEMA cleansed_identified OWNER TO catalyze;

--
-- Name: dip_configuration; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA dip_configuration;


ALTER SCHEMA dip_configuration OWNER TO catalyze;

--
-- Name: ib_listing_service; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA ib_listing_service;


ALTER SCHEMA ib_listing_service OWNER TO catalyze;

--
-- Name: work_deidentified; Type: SCHEMA; Schema: -; Owner: catalyze
--

CREATE SCHEMA work_deidentified;


ALTER SCHEMA work_deidentified OWNER TO catalyze;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: appannie_download_insert_trigger(); Type: FUNCTION; Schema: base_deidentified; Owner: catalyze
--

CREATE FUNCTION base_deidentified.appannie_download_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.date_key >= DATE '2017-01-01' AND NEW.date_key < DATE '2018-01-01') THEN
        INSERT INTO base_deidentified.appannie_download_y2017 VALUES (NEW.*);
    ELSIF (NEW.date_key >= DATE '2018-01-01' AND NEW.date_key < DATE '2019-01-01') THEN
        INSERT INTO base_deidentified.appannie_download_y2018 VALUES (NEW.*);
    ELSIF (NEW.date_key >= DATE '2019-01-01' AND NEW.date_key < DATE '2020-01-01') THEN
        INSERT INTO base_deidentified.appannie_download_y2019 VALUES (NEW.*);
    ELSIF (NEW.date_key >= DATE '2020-01-01' AND NEW.date_key < DATE '2021-01-01') THEN
        INSERT INTO base_deidentified.appannie_download_y2020 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'date_key out of range. Fix the base_deidentified.appannie_download_insert_trigger() function!';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION base_deidentified.appannie_download_insert_trigger() OWNER TO catalyze;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: appannie_download; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.appannie_download (
    account_id integer NOT NULL,
    product_id bigint NOT NULL,
    country character(2) NOT NULL,
    date_key date NOT NULL,
    download_data jsonb NOT NULL
);


ALTER TABLE base_deidentified.appannie_download OWNER TO catalyze;

--
-- Name: appannie_product; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.appannie_product (
    account_id integer NOT NULL,
    product_id bigint NOT NULL,
    date_key date NOT NULL,
    product_data jsonb NOT NULL,
    status boolean DEFAULT true NOT NULL
);


ALTER TABLE base_deidentified.appannie_product OWNER TO catalyze;

--
-- Name: app_download_metrics; Type: VIEW; Schema: app_deidentified; Owner: catalyze
--

CREATE VIEW app_deidentified.app_download_metrics AS
 SELECT tj.account_id,
    tj.market_label,
    tj.product_label,
    tj.download_date,
    tj.download_count
   FROM ( SELECT t2.account_id,
            t2.product_name AS product_label,
            t2.market AS market_label,
            t1.date_key AS download_date,
            sum(((((t1.download_data -> 'units'::text) -> 'product'::text) ->> 'downloads'::text))::integer) AS download_count
           FROM base_deidentified.appannie_download t1,
            ( SELECT appannie_product.account_id,
                    appannie_product.product_id,
                    (appannie_product.product_data ->> 'product_name'::text) AS product_name,
                    (appannie_product.product_data ->> 'market'::text) AS market,
                    max(appannie_product.date_key) AS date_key
                   FROM base_deidentified.appannie_product
                  WHERE ((appannie_product.product_data ->> 'status'::text) = 'true'::text)
                  GROUP BY appannie_product.account_id, appannie_product.product_id, (appannie_product.product_data ->> 'product_name'::text), (appannie_product.product_data ->> 'market'::text)) t2
          WHERE ((t2.account_id = t1.account_id) AND (t2.product_id = t1.product_id))
          GROUP BY t2.account_id, t2.product_name, t2.market, t1.date_key) tj;


ALTER TABLE app_deidentified.app_download_metrics OWNER TO catalyze;

--
-- Name: ga_session; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.ga_session (
    full_visitor_id numeric NOT NULL,
    visit_id integer NOT NULL,
    user_id uuid,
    date_key date NOT NULL,
    app_id character varying(100),
    app_name character varying(50),
    app_version character varying(50),
    session_data jsonb NOT NULL
);


ALTER TABLE base_deidentified.ga_session OWNER TO catalyze;

--
-- Name: app_ga_session_metrics; Type: VIEW; Schema: app_deidentified; Owner: catalyze
--

CREATE VIEW app_deidentified.app_ga_session_metrics AS
 SELECT ga_session.app_id AS product_label,
    ga_session.app_version AS product_version,
    ga_session.full_visitor_id,
    ((ga_session.session_data ->> 'date'::text))::date AS session_date,
    count(*) AS session_count,
    sum((((ga_session.session_data -> 'totals'::text) ->> 'newVisits'::text))::integer) AS new_user_count,
    sum((((ga_session.session_data -> 'totals'::text) ->> 'timeOnSite'::text))::integer) AS session_duration
   FROM base_deidentified.ga_session
  WHERE ((((ga_session.session_data -> 'totals'::text) ->> 'visits'::text))::integer = 1)
  GROUP BY ga_session.app_id, ga_session.app_version, ga_session.full_visitor_id, ((ga_session.session_data ->> 'date'::text))::date;


ALTER TABLE app_deidentified.app_ga_session_metrics OWNER TO catalyze;

--
-- Name: app_product_metrics_annual; Type: TABLE; Schema: app_deidentified; Owner: catalyze
--

CREATE TABLE app_deidentified.app_product_metrics_annual (
    product_label character varying(50) NOT NULL,
    year_number smallint NOT NULL,
    registered_user_count integer NOT NULL,
    download_count integer NOT NULL,
    ga_session_count integer NOT NULL,
    ga_user_count integer NOT NULL,
    ga_new_user_count integer NOT NULL,
    ga_average_session_duration integer NOT NULL,
    ga_session_count_per_user numeric(10,2) NOT NULL,
    ga_session_duration bigint NOT NULL
);


ALTER TABLE app_deidentified.app_product_metrics_annual OWNER TO catalyze;

--
-- Name: app_product_metrics_monthly; Type: TABLE; Schema: app_deidentified; Owner: catalyze
--

CREATE TABLE app_deidentified.app_product_metrics_monthly (
    product_label character varying(50) NOT NULL,
    year_number smallint NOT NULL,
    month_number smallint NOT NULL,
    year_month_label character varying(50) NOT NULL,
    registered_user_count integer NOT NULL,
    download_count integer NOT NULL,
    ga_session_count integer NOT NULL,
    ga_user_count integer NOT NULL,
    ga_new_user_count integer NOT NULL,
    ga_average_session_duration integer NOT NULL,
    ga_session_count_per_user numeric(10,2) NOT NULL,
    ga_session_duration bigint NOT NULL
);


ALTER TABLE app_deidentified.app_product_metrics_monthly OWNER TO catalyze;

--
-- Name: app_user_dormancy_details; Type: TABLE; Schema: app_deidentified; Owner: catalyze
--

CREATE TABLE app_deidentified.app_user_dormancy_details (
    user_id uuid NOT NULL,
    product_label character varying(50) NOT NULL,
    last_modified_date date NOT NULL
);


ALTER TABLE app_deidentified.app_user_dormancy_details OWNER TO catalyze;

--
-- Name: app_user_dormancy_summary; Type: VIEW; Schema: app_deidentified; Owner: catalyze
--

CREATE VIEW app_deidentified.app_user_dormancy_summary AS
 SELECT t1.product_label,
    t1.dormancy_label,
    sum(t1.user_count) AS user_count
   FROM ( SELECT app_user_dormancy_details.product_label,
                CASE
                    WHEN ((('now'::text)::date - app_user_dormancy_details.last_modified_date) > 45) THEN 'Dormant'::text
                    ELSE 'Non Dormant'::text
                END AS dormancy_label,
            1 AS user_count
           FROM app_deidentified.app_user_dormancy_details
          WHERE ((app_user_dormancy_details.product_label)::text = ANY ((ARRAY['HPI Corporate Athlete Journey'::character varying, 'Health Partner for Knees & Hips'::character varying, 'Health Partner for Weight Loss Surgery'::character varying, '7 Minute Workout'::character varying])::text[]))) t1
  GROUP BY t1.product_label, t1.dormancy_label;


ALTER TABLE app_deidentified.app_user_dormancy_summary OWNER TO catalyze;

--
-- Name: healthstore_applicationprofile; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_applicationprofile (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_applicationprofile OWNER TO catalyze;

--
-- Name: app_user_registration; Type: VIEW; Schema: app_deidentified; Owner: catalyze
--

CREATE VIEW app_deidentified.app_user_registration AS
 SELECT healthstore_applicationprofile.user_id,
    healthstore_applicationprofile.product AS product_label,
    (healthstore_applicationprofile.created_date_time)::date AS created_date
   FROM base_deidentified.healthstore_applicationprofile
  WHERE (healthstore_applicationprofile.object_version = 1);


ALTER TABLE app_deidentified.app_user_registration OWNER TO catalyze;

--
-- Name: appannie_account; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.appannie_account (
    account_id integer NOT NULL,
    date_key date NOT NULL,
    account_data jsonb NOT NULL
);


ALTER TABLE base_deidentified.appannie_account OWNER TO catalyze;

--
-- Name: appannie_download_y2017; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.appannie_download_y2017 (
    CONSTRAINT appannie_download_y2017_date_key_check CHECK (((date_key >= '2017-01-01'::date) AND (date_key < '2018-01-01'::date)))
)
INHERITS (base_deidentified.appannie_download);


ALTER TABLE base_deidentified.appannie_download_y2017 OWNER TO catalyze;

--
-- Name: appannie_download_y2018; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.appannie_download_y2018 (
    CONSTRAINT appannie_download_y2018_date_key_check CHECK (((date_key >= '2018-01-01'::date) AND (date_key < '2019-01-01'::date)))
)
INHERITS (base_deidentified.appannie_download);


ALTER TABLE base_deidentified.appannie_download_y2018 OWNER TO catalyze;

--
-- Name: appannie_download_y2019; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.appannie_download_y2019 (
    CONSTRAINT appannie_download_y2019_date_key_check CHECK (((date_key >= '2019-01-01'::date) AND (date_key < '2020-01-01'::date)))
)
INHERITS (base_deidentified.appannie_download);


ALTER TABLE base_deidentified.appannie_download_y2019 OWNER TO catalyze;

--
-- Name: appannie_download_y2020; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.appannie_download_y2020 (
    CONSTRAINT appannie_download_y2020_date_key_check CHECK (((date_key >= '2020-01-01'::date) AND (date_key < '2021-01-01'::date)))
)
INHERITS (base_deidentified.appannie_download);


ALTER TABLE base_deidentified.appannie_download_y2020 OWNER TO catalyze;

--
-- Name: healthstore_abdominalpain; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_abdominalpain (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_abdominalpain OWNER TO catalyze;

--
-- Name: healthstore_actionresponse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_actionresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_actionresponse OWNER TO catalyze;

--
-- Name: healthstore_activityprogram; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_activityprogram (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_activityprogram OWNER TO catalyze;

--
-- Name: healthstore_allergysymptoms; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_allergysymptoms (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_allergysymptoms OWNER TO catalyze;

--
-- Name: healthstore_applicationevent; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_applicationevent (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_applicationevent OWNER TO catalyze;

--
-- Name: healthstore_applicationlogin; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_applicationlogin (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_applicationlogin OWNER TO catalyze;

--
-- Name: healthstore_applicationpreference; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_applicationpreference (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_applicationpreference OWNER TO catalyze;

--
-- Name: healthstore_appointmentresponse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_appointmentresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_appointmentresponse OWNER TO catalyze;

--
-- Name: healthstore_assessmentchain; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_assessmentchain (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_assessmentchain OWNER TO catalyze;

--
-- Name: healthstore_assessmentresponse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_assessmentresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_assessmentresponse OWNER TO catalyze;

--
-- Name: healthstore_award; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_award (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_award OWNER TO catalyze;

--
-- Name: healthstore_behavioraltrigger; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_behavioraltrigger (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_behavioraltrigger OWNER TO catalyze;

--
-- Name: healthstore_bloodpressure; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_bloodpressure (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_bloodpressure OWNER TO catalyze;

--
-- Name: healthstore_bodymeasurement; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_bodymeasurement (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_bodymeasurement OWNER TO catalyze;

--
-- Name: healthstore_bookmarkset; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_bookmarkset (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_bookmarkset OWNER TO catalyze;

--
-- Name: healthstore_bowelmovement; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_bowelmovement (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_bowelmovement OWNER TO catalyze;

--
-- Name: healthstore_caremoduleassignment; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_caremoduleassignment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_caremoduleassignment OWNER TO catalyze;

--
-- Name: healthstore_careplanassignment; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_careplanassignment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_careplanassignment OWNER TO catalyze;

--
-- Name: healthstore_challengeresponse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_challengeresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_challengeresponse OWNER TO catalyze;

--
-- Name: healthstore_cigarettesmoked; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_cigarettesmoked (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_cigarettesmoked OWNER TO catalyze;

--
-- Name: healthstore_condition; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_condition (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_condition OWNER TO catalyze;

--
-- Name: healthstore_cpeptide; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_cpeptide (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_cpeptide OWNER TO catalyze;

--
-- Name: healthstore_creactiveprotein; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_creactiveprotein (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_creactiveprotein OWNER TO catalyze;

--
-- Name: healthstore_dailyactivities; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_dailyactivities (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_dailyactivities OWNER TO catalyze;

--
-- Name: healthstore_dailycigaretteintake; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_dailycigaretteintake (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_dailycigaretteintake OWNER TO catalyze;

--
-- Name: healthstore_dailyroutine; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_dailyroutine (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_dailyroutine OWNER TO catalyze;

--
-- Name: healthstore_deviceuse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_deviceuse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_deviceuse OWNER TO catalyze;

--
-- Name: healthstore_documentacceptance; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_documentacceptance (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_documentacceptance OWNER TO catalyze;

--
-- Name: healthstore_educationresponse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_educationresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_educationresponse OWNER TO catalyze;

--
-- Name: healthstore_energylevel; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_energylevel (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_energylevel OWNER TO catalyze;

--
-- Name: healthstore_exercise; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_exercise (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_exercise OWNER TO catalyze;

--
-- Name: healthstore_fecalcalprotectin; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_fecalcalprotectin (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_fecalcalprotectin OWNER TO catalyze;

--
-- Name: healthstore_fitnesslevel; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_fitnesslevel (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_fitnesslevel OWNER TO catalyze;

--
-- Name: healthstore_fluidintake; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_fluidintake (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_fluidintake OWNER TO catalyze;

--
-- Name: healthstore_hba1c; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_hba1c (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_hba1c OWNER TO catalyze;

--
-- Name: healthstore_height; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_height (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_height OWNER TO catalyze;

--
-- Name: healthstore_importedobject; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_importedobject (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_importedobject OWNER TO catalyze;

--
-- Name: healthstore_insulin; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_insulin (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_insulin OWNER TO catalyze;

--
-- Name: healthstore_journalentry; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_journalentry (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_journalentry OWNER TO catalyze;

--
-- Name: healthstore_meal; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_meal (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_meal OWNER TO catalyze;

--
-- Name: healthstore_mealrating; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_mealrating (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_mealrating OWNER TO catalyze;

--
-- Name: healthstore_medicationadministration; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_medicationadministration (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_medicationadministration OWNER TO catalyze;

--
-- Name: healthstore_medicationrefillstatus; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_medicationrefillstatus (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_medicationrefillstatus OWNER TO catalyze;

--
-- Name: healthstore_medicationschedule; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_medicationschedule (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_medicationschedule OWNER TO catalyze;

--
-- Name: healthstore_mood; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_mood (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_mood OWNER TO catalyze;

--
-- Name: healthstore_nausea; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_nausea (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_nausea OWNER TO catalyze;

--
-- Name: healthstore_notificationresponse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_notificationresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_notificationresponse OWNER TO catalyze;

--
-- Name: healthstore_optin; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_optin (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_optin OWNER TO catalyze;

--
-- Name: healthstore_oralglucosetolerancetest; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_oralglucosetolerancetest (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_oralglucosetolerancetest OWNER TO catalyze;

--
-- Name: healthstore_pain; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_pain (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_pain OWNER TO catalyze;

--
-- Name: healthstore_plasmabloodglucose; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_plasmabloodglucose (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_plasmabloodglucose OWNER TO catalyze;

--
-- Name: healthstore_procedureperformed; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_procedureperformed (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_procedureperformed OWNER TO catalyze;

--
-- Name: healthstore_progress; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_progress (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_progress OWNER TO catalyze;

--
-- Name: healthstore_prostatespecificantigen; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_prostatespecificantigen (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_prostatespecificantigen OWNER TO catalyze;

--
-- Name: healthstore_pulse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_pulse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_pulse OWNER TO catalyze;

--
-- Name: healthstore_questionnaireresponse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_questionnaireresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_questionnaireresponse OWNER TO catalyze;

--
-- Name: healthstore_scheduledaction; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledaction (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledaction OWNER TO catalyze;

--
-- Name: healthstore_scheduledactiviy; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledactiviy (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledactiviy OWNER TO catalyze;

--
-- Name: healthstore_scheduledappointment; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledappointment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledappointment OWNER TO catalyze;

--
-- Name: healthstore_scheduledassessment; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledassessment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledassessment OWNER TO catalyze;

--
-- Name: healthstore_scheduledchallenge; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledchallenge (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledchallenge OWNER TO catalyze;

--
-- Name: healthstore_scheduleddeviceuse; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduleddeviceuse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduleddeviceuse OWNER TO catalyze;

--
-- Name: healthstore_schedulededucation; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_schedulededucation (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_schedulededucation OWNER TO catalyze;

--
-- Name: healthstore_scheduledmedication; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledmedication (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledmedication OWNER TO catalyze;

--
-- Name: healthstore_schedulednotification; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_schedulednotification (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_schedulednotification OWNER TO catalyze;

--
-- Name: healthstore_scheduledprocedure; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledprocedure (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledprocedure OWNER TO catalyze;

--
-- Name: healthstore_scheduledquestionnaire; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_scheduledquestionnaire (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_scheduledquestionnaire OWNER TO catalyze;

--
-- Name: healthstore_selfassessment; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_selfassessment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_selfassessment OWNER TO catalyze;

--
-- Name: healthstore_selfmonitoredbloodglucose; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_selfmonitoredbloodglucose (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_selfmonitoredbloodglucose OWNER TO catalyze;

--
-- Name: healthstore_sleep; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_sleep (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_sleep OWNER TO catalyze;

--
-- Name: healthstore_therapeuticdose; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_therapeuticdose (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_therapeuticdose OWNER TO catalyze;

--
-- Name: healthstore_tracker; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_tracker (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_tracker OWNER TO catalyze;

--
-- Name: healthstore_triglycerides; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_triglycerides (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_triglycerides OWNER TO catalyze;

--
-- Name: healthstore_user; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_user (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_user OWNER TO catalyze;

--
-- Name: healthstore_usertokens; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_usertokens (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_usertokens OWNER TO catalyze;

--
-- Name: healthstore_waterintake; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_waterintake (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_waterintake OWNER TO catalyze;

--
-- Name: healthstore_weight; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_weight (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_weight OWNER TO catalyze;

--
-- Name: healthstore_wellbeingstate; Type: TABLE; Schema: base_deidentified; Owner: catalyze
--

CREATE TABLE base_deidentified.healthstore_wellbeingstate (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_deidentified.healthstore_wellbeingstate OWNER TO catalyze;

--
-- Name: bct_event_7mw; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.bct_event_7mw (
    hash_key uuid NOT NULL,
    recipient_id uuid NOT NULL,
    actor_id uuid,
    date_key date NOT NULL,
    bct_event_date date NOT NULL,
    event_type character varying(25) NOT NULL,
    event_sub_type character varying(25),
    event_id character varying(500),
    file_content jsonb NOT NULL
);


ALTER TABLE base_identified.bct_event_7mw OWNER TO catalyze;

--
-- Name: healthstore_actionresponse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_actionresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_actionresponse OWNER TO catalyze;

--
-- Name: healthstore_activityprogram; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_activityprogram (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_activityprogram OWNER TO catalyze;

--
-- Name: healthstore_applicationlogin; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_applicationlogin (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_applicationlogin OWNER TO catalyze;

--
-- Name: healthstore_applicationpreference; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_applicationpreference (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_applicationpreference OWNER TO catalyze;

--
-- Name: healthstore_applicationprofile; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_applicationprofile (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_applicationprofile OWNER TO catalyze;

--
-- Name: healthstore_appointmentresponse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_appointmentresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_appointmentresponse OWNER TO catalyze;

--
-- Name: healthstore_assessmentresponse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_assessmentresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_assessmentresponse OWNER TO catalyze;

--
-- Name: healthstore_bloodpressure; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_bloodpressure (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_bloodpressure OWNER TO catalyze;

--
-- Name: healthstore_bookmarkset; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_bookmarkset (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_bookmarkset OWNER TO catalyze;

--
-- Name: healthstore_caremoduleassignment; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_caremoduleassignment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_caremoduleassignment OWNER TO catalyze;

--
-- Name: healthstore_dailycigaretteintake; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_dailycigaretteintake (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_dailycigaretteintake OWNER TO catalyze;

--
-- Name: healthstore_dailyroutine; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_dailyroutine (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_dailyroutine OWNER TO catalyze;

--
-- Name: healthstore_deviceuse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_deviceuse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_deviceuse OWNER TO catalyze;

--
-- Name: healthstore_documentacceptance; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_documentacceptance (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_documentacceptance OWNER TO catalyze;

--
-- Name: healthstore_educationresponse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_educationresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_educationresponse OWNER TO catalyze;

--
-- Name: healthstore_energylevel; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_energylevel (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_energylevel OWNER TO catalyze;

--
-- Name: healthstore_exercise; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_exercise (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_exercise OWNER TO catalyze;

--
-- Name: healthstore_fitnesslevel; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_fitnesslevel (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_fitnesslevel OWNER TO catalyze;

--
-- Name: healthstore_hba1c; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_hba1c (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_hba1c OWNER TO catalyze;

--
-- Name: healthstore_importedobject; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_importedobject (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_importedobject OWNER TO catalyze;

--
-- Name: healthstore_meal; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_meal (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_meal OWNER TO catalyze;

--
-- Name: healthstore_mealrating; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_mealrating (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_mealrating OWNER TO catalyze;

--
-- Name: healthstore_medicationadministration; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_medicationadministration (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_medicationadministration OWNER TO catalyze;

--
-- Name: healthstore_medicationrefillstatus; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_medicationrefillstatus (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_medicationrefillstatus OWNER TO catalyze;

--
-- Name: healthstore_mood; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_mood (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_mood OWNER TO catalyze;

--
-- Name: healthstore_nausea; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_nausea (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_nausea OWNER TO catalyze;

--
-- Name: healthstore_notificationresponse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_notificationresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_notificationresponse OWNER TO catalyze;

--
-- Name: healthstore_optin; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_optin (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_optin OWNER TO catalyze;

--
-- Name: healthstore_pain; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_pain (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_pain OWNER TO catalyze;

--
-- Name: healthstore_progress; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_progress (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_progress OWNER TO catalyze;

--
-- Name: healthstore_prostatespecificantigen; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_prostatespecificantigen (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_prostatespecificantigen OWNER TO catalyze;

--
-- Name: healthstore_questionnaireresponse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_questionnaireresponse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_questionnaireresponse OWNER TO catalyze;

--
-- Name: healthstore_scheduledaction; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_scheduledaction (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_scheduledaction OWNER TO catalyze;

--
-- Name: healthstore_scheduledappointment; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_scheduledappointment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_scheduledappointment OWNER TO catalyze;

--
-- Name: healthstore_scheduledassessment; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_scheduledassessment (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_scheduledassessment OWNER TO catalyze;

--
-- Name: healthstore_scheduleddeviceuse; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_scheduleddeviceuse (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_scheduleddeviceuse OWNER TO catalyze;

--
-- Name: healthstore_scheduledmedication; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_scheduledmedication (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_scheduledmedication OWNER TO catalyze;

--
-- Name: healthstore_schedulednotification; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_schedulednotification (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_schedulednotification OWNER TO catalyze;

--
-- Name: healthstore_selfmonitoredbloodglucose; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_selfmonitoredbloodglucose (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_selfmonitoredbloodglucose OWNER TO catalyze;

--
-- Name: healthstore_sleep; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_sleep (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_sleep OWNER TO catalyze;

--
-- Name: healthstore_tracker; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_tracker (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_tracker OWNER TO catalyze;

--
-- Name: healthstore_user; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_user (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_user OWNER TO catalyze;

--
-- Name: healthstore_usertokens; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_usertokens (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_usertokens OWNER TO catalyze;

--
-- Name: healthstore_waterintake; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_waterintake (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_waterintake OWNER TO catalyze;

--
-- Name: healthstore_weight; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_weight (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_weight OWNER TO catalyze;

--
-- Name: healthstore_wellbeingstate; Type: TABLE; Schema: base_identified; Owner: catalyze
--

CREATE TABLE base_identified.healthstore_wellbeingstate (
    file_content jsonb,
    date_key date,
    schema_version character varying(5),
    product character varying(100),
    user_id uuid,
    object_id uuid,
    object_version integer,
    created_date_time timestamp with time zone,
    last_modified_date_time timestamp with time zone
);


ALTER TABLE base_identified.healthstore_wellbeingstate OWNER TO catalyze;

--
-- Name: appannie_download; Type: TABLE; Schema: cleansed_deidentified; Owner: catalyze
--

CREATE TABLE cleansed_deidentified.appannie_download (
    account_id integer NOT NULL,
    product_id bigint NOT NULL,
    country character(2) NOT NULL,
    date_key date NOT NULL,
    product_label character varying(50) NOT NULL,
    download_data jsonb NOT NULL
);


ALTER TABLE cleansed_deidentified.appannie_download OWNER TO catalyze;

--
-- Name: ga_session; Type: TABLE; Schema: cleansed_deidentified; Owner: catalyze
--

CREATE TABLE cleansed_deidentified.ga_session (
    full_visitor_id bigint NOT NULL,
    visit_id integer NOT NULL,
    user_id uuid,
    date_key date NOT NULL,
    app_id character varying(100),
    app_name character varying(50),
    app_version character varying(50),
    product_label character varying(50) NOT NULL,
    session_data jsonb NOT NULL
);


ALTER TABLE cleansed_deidentified.ga_session OWNER TO catalyze;

--
-- Name: healthstore_applicationprofile; Type: TABLE; Schema: cleansed_identified; Owner: catalyze
--

CREATE TABLE cleansed_identified.healthstore_applicationprofile (
    object_id uuid NOT NULL,
    object_version integer NOT NULL,
    file_content jsonb NOT NULL,
    date_key date NOT NULL,
    schema_version character varying(5) NOT NULL,
    product_label character varying(50) NOT NULL,
    user_id uuid NOT NULL,
    created_date_time timestamp with time zone NOT NULL,
    last_modified_date_time timestamp with time zone NOT NULL
);


ALTER TABLE cleansed_identified.healthstore_applicationprofile OWNER TO catalyze;

--
-- Name: dip_migrations; Type: TABLE; Schema: dip_configuration; Owner: catalyze
--

CREATE TABLE dip_configuration.dip_migrations (
    file_name character varying(200) NOT NULL,
    last_modified_date timestamp with time zone DEFAULT now()
);


ALTER TABLE dip_configuration.dip_migrations OWNER TO catalyze;

--
-- Name: workflow_history; Type: TABLE; Schema: dip_configuration; Owner: catalyze
--

CREATE TABLE dip_configuration.workflow_history (
    id integer NOT NULL,
    name character varying(256) NOT NULL,
    started_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone,
    num_records_processed bigint
);


ALTER TABLE dip_configuration.workflow_history OWNER TO catalyze;

--
-- Name: workflow_history_id_seq; Type: SEQUENCE; Schema: dip_configuration; Owner: catalyze
--

CREATE SEQUENCE dip_configuration.workflow_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dip_configuration.workflow_history_id_seq OWNER TO catalyze;

--
-- Name: workflow_history_id_seq; Type: SEQUENCE OWNED BY; Schema: dip_configuration; Owner: catalyze
--

ALTER SEQUENCE dip_configuration.workflow_history_id_seq OWNED BY dip_configuration.workflow_history.id;


--
-- Name: listed_dates; Type: TABLE; Schema: ib_listing_service; Owner: catalyze
--

CREATE TABLE ib_listing_service.listed_dates (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    date_listed date NOT NULL,
    prefix character varying(1024) NOT NULL,
    num_keys_listed integer NOT NULL
);


ALTER TABLE ib_listing_service.listed_dates OWNER TO catalyze;

--
-- Name: listed_dates_id_seq; Type: SEQUENCE; Schema: ib_listing_service; Owner: catalyze
--

CREATE SEQUENCE ib_listing_service.listed_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ib_listing_service.listed_dates_id_seq OWNER TO catalyze;

--
-- Name: listed_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: ib_listing_service; Owner: catalyze
--

ALTER SEQUENCE ib_listing_service.listed_dates_id_seq OWNED BY ib_listing_service.listed_dates.id;


--
-- Name: listing_configs; Type: TABLE; Schema: ib_listing_service; Owner: catalyze
--

CREATE TABLE ib_listing_service.listing_configs (
    name character varying(64) NOT NULL,
    start_date date NOT NULL,
    end_date date,
    prefix_template character varying(1024),
    target_exchange character varying(255)
);


ALTER TABLE ib_listing_service.listing_configs OWNER TO catalyze;

--
-- Name: work_product_metrics_annual; Type: TABLE; Schema: work_deidentified; Owner: catalyze
--

CREATE TABLE work_deidentified.work_product_metrics_annual (
    product_label character varying(50) NOT NULL,
    year_number smallint NOT NULL,
    registered_user_count integer NOT NULL,
    download_count integer NOT NULL,
    ga_session_count integer NOT NULL,
    ga_user_count integer NOT NULL,
    ga_new_user_count integer NOT NULL,
    ga_average_session_duration integer NOT NULL,
    ga_session_count_per_user numeric(10,2) NOT NULL,
    ga_session_duration bigint NOT NULL
);


ALTER TABLE work_deidentified.work_product_metrics_annual OWNER TO catalyze;

--
-- Name: work_product_metrics_monthly; Type: TABLE; Schema: work_deidentified; Owner: catalyze
--

CREATE TABLE work_deidentified.work_product_metrics_monthly (
    product_label character varying(50) NOT NULL,
    year_number smallint NOT NULL,
    month_number smallint NOT NULL,
    year_month_label character varying(50) NOT NULL,
    registered_user_count integer NOT NULL,
    download_count integer NOT NULL,
    ga_session_count integer NOT NULL,
    ga_user_count integer NOT NULL,
    ga_new_user_count integer NOT NULL,
    ga_average_session_duration integer NOT NULL,
    ga_session_count_per_user numeric(10,2) NOT NULL,
    ga_session_duration bigint NOT NULL
);


ALTER TABLE work_deidentified.work_product_metrics_monthly OWNER TO catalyze;

--
-- Name: workflow_history id; Type: DEFAULT; Schema: dip_configuration; Owner: catalyze
--

ALTER TABLE ONLY dip_configuration.workflow_history ALTER COLUMN id SET DEFAULT nextval('dip_configuration.workflow_history_id_seq'::regclass);


--
-- Name: listed_dates id; Type: DEFAULT; Schema: ib_listing_service; Owner: catalyze
--

ALTER TABLE ONLY ib_listing_service.listed_dates ALTER COLUMN id SET DEFAULT nextval('ib_listing_service.listed_dates_id_seq'::regclass);


--
-- Name: app_product_metrics_annual xpkapp_product_metrics_annual; Type: CONSTRAINT; Schema: app_deidentified; Owner: catalyze
--

ALTER TABLE ONLY app_deidentified.app_product_metrics_annual
    ADD CONSTRAINT xpkapp_product_metrics_annual PRIMARY KEY (product_label, year_number);


--
-- Name: app_product_metrics_monthly xpkapp_product_metrics_monthly; Type: CONSTRAINT; Schema: app_deidentified; Owner: catalyze
--

ALTER TABLE ONLY app_deidentified.app_product_metrics_monthly
    ADD CONSTRAINT xpkapp_product_metrics_monthly PRIMARY KEY (product_label, year_number, month_number);


--
-- Name: app_user_dormancy_details xpkapp_user_dormancy_details; Type: CONSTRAINT; Schema: app_deidentified; Owner: catalyze
--

ALTER TABLE ONLY app_deidentified.app_user_dormancy_details
    ADD CONSTRAINT xpkapp_user_dormancy_details PRIMARY KEY (user_id, product_label);


--
-- Name: appannie_account xpkapp_annie_account; Type: CONSTRAINT; Schema: base_deidentified; Owner: catalyze
--

ALTER TABLE ONLY base_deidentified.appannie_account
    ADD CONSTRAINT xpkapp_annie_account PRIMARY KEY (account_id, date_key);


--
-- Name: appannie_product xpkapp_annie_product; Type: CONSTRAINT; Schema: base_deidentified; Owner: catalyze
--

ALTER TABLE ONLY base_deidentified.appannie_product
    ADD CONSTRAINT xpkapp_annie_product PRIMARY KEY (account_id, product_id, date_key);


--
-- Name: ga_session xpkga_session; Type: CONSTRAINT; Schema: base_deidentified; Owner: catalyze
--

ALTER TABLE ONLY base_deidentified.ga_session
    ADD CONSTRAINT xpkga_session PRIMARY KEY (full_visitor_id, visit_id);


--
-- Name: bct_event_7mw bct_event_7mw_pkey; Type: CONSTRAINT; Schema: base_identified; Owner: catalyze
--

ALTER TABLE ONLY base_identified.bct_event_7mw
    ADD CONSTRAINT bct_event_7mw_pkey PRIMARY KEY (hash_key);


--
-- Name: appannie_download appannie_download_pkey; Type: CONSTRAINT; Schema: cleansed_deidentified; Owner: catalyze
--

ALTER TABLE ONLY cleansed_deidentified.appannie_download
    ADD CONSTRAINT appannie_download_pkey PRIMARY KEY (account_id, product_id, country, date_key);


--
-- Name: healthstore_applicationprofile healthstore_applicationprofile_pkey; Type: CONSTRAINT; Schema: cleansed_identified; Owner: catalyze
--

ALTER TABLE ONLY cleansed_identified.healthstore_applicationprofile
    ADD CONSTRAINT healthstore_applicationprofile_pkey PRIMARY KEY (object_id, object_version);


--
-- Name: dip_migrations dip_migrations_pkey; Type: CONSTRAINT; Schema: dip_configuration; Owner: catalyze
--

ALTER TABLE ONLY dip_configuration.dip_migrations
    ADD CONSTRAINT dip_migrations_pkey PRIMARY KEY (file_name);


--
-- Name: workflow_history workflow_history_pkey; Type: CONSTRAINT; Schema: dip_configuration; Owner: catalyze
--

ALTER TABLE ONLY dip_configuration.workflow_history
    ADD CONSTRAINT workflow_history_pkey PRIMARY KEY (id);


--
-- Name: listed_dates listed_dates_pkey; Type: CONSTRAINT; Schema: ib_listing_service; Owner: catalyze
--

ALTER TABLE ONLY ib_listing_service.listed_dates
    ADD CONSTRAINT listed_dates_pkey PRIMARY KEY (id);


--
-- Name: listing_configs listing_configs_pkey; Type: CONSTRAINT; Schema: ib_listing_service; Owner: catalyze
--

ALTER TABLE ONLY ib_listing_service.listing_configs
    ADD CONSTRAINT listing_configs_pkey PRIMARY KEY (name);


--
-- Name: work_product_metrics_annual work_product_metrics_annual_pkey; Type: CONSTRAINT; Schema: work_deidentified; Owner: catalyze
--

ALTER TABLE ONLY work_deidentified.work_product_metrics_annual
    ADD CONSTRAINT work_product_metrics_annual_pkey PRIMARY KEY (product_label, year_number);


--
-- Name: work_product_metrics_monthly work_product_metrics_monthly_pkey; Type: CONSTRAINT; Schema: work_deidentified; Owner: catalyze
--

ALTER TABLE ONLY work_deidentified.work_product_metrics_monthly
    ADD CONSTRAINT work_product_metrics_monthly_pkey PRIMARY KEY (product_label, year_number, month_number);


--
-- Name: xie1app_annie_download; Type: INDEX; Schema: base_deidentified; Owner: catalyze
--

CREATE INDEX xie1app_annie_download ON base_deidentified.appannie_download USING btree (date_key);


--
-- Name: workflow_history_name_idx; Type: INDEX; Schema: dip_configuration; Owner: catalyze
--

CREATE INDEX workflow_history_name_idx ON dip_configuration.workflow_history USING btree (name);


--
-- Name: workflow_history_started_at_idx; Type: INDEX; Schema: dip_configuration; Owner: catalyze
--

CREATE INDEX workflow_history_started_at_idx ON dip_configuration.workflow_history USING btree (started_at);


--
-- Name: listed_dates_date_listed_idx; Type: INDEX; Schema: ib_listing_service; Owner: catalyze
--

CREATE INDEX listed_dates_date_listed_idx ON ib_listing_service.listed_dates USING btree (date_listed);


--
-- Name: listed_dates_name_idx; Type: INDEX; Schema: ib_listing_service; Owner: catalyze
--

CREATE INDEX listed_dates_name_idx ON ib_listing_service.listed_dates USING btree (name);


--
-- Name: appannie_download insert_appannie_download; Type: TRIGGER; Schema: base_deidentified; Owner: catalyze
--

CREATE TRIGGER insert_appannie_download BEFORE INSERT ON base_deidentified.appannie_download FOR EACH ROW EXECUTE PROCEDURE base_deidentified.appannie_download_insert_trigger();


--
-- Name: SCHEMA app_deidentified; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA app_deidentified TO read_only_group;


--
-- Name: SCHEMA app_identified; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA app_identified TO read_only_group;


--
-- Name: SCHEMA base_deidentified; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA base_deidentified TO read_only_group;


--
-- Name: SCHEMA base_identified; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA base_identified TO read_only_group;


--
-- Name: SCHEMA cleansed_deidentified; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA cleansed_deidentified TO read_only_group;


--
-- Name: SCHEMA cleansed_identified; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA cleansed_identified TO read_only_group;


--
-- Name: SCHEMA dip_configuration; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA dip_configuration TO read_only_group;


--
-- Name: SCHEMA ib_listing_service; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA ib_listing_service TO read_only_group;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA public TO read_only_group;


--
-- Name: SCHEMA work_deidentified; Type: ACL; Schema: -; Owner: catalyze
--

GRANT USAGE ON SCHEMA work_deidentified TO read_only_group;


--
-- Name: TABLE appannie_download; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.appannie_download TO read_only_group;


--
-- Name: TABLE appannie_product; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.appannie_product TO read_only_group;


--
-- Name: TABLE app_download_metrics; Type: ACL; Schema: app_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE app_deidentified.app_download_metrics TO read_only_group;


--
-- Name: TABLE ga_session; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.ga_session TO read_only_group;


--
-- Name: TABLE app_ga_session_metrics; Type: ACL; Schema: app_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE app_deidentified.app_ga_session_metrics TO read_only_group;


--
-- Name: TABLE app_product_metrics_annual; Type: ACL; Schema: app_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE app_deidentified.app_product_metrics_annual TO read_only_group;


--
-- Name: TABLE app_product_metrics_monthly; Type: ACL; Schema: app_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE app_deidentified.app_product_metrics_monthly TO read_only_group;


--
-- Name: TABLE app_user_dormancy_details; Type: ACL; Schema: app_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE app_deidentified.app_user_dormancy_details TO read_only_group;


--
-- Name: TABLE app_user_dormancy_summary; Type: ACL; Schema: app_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE app_deidentified.app_user_dormancy_summary TO read_only_group;


--
-- Name: TABLE healthstore_applicationprofile; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_applicationprofile TO read_only_group;


--
-- Name: TABLE app_user_registration; Type: ACL; Schema: app_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE app_deidentified.app_user_registration TO read_only_group;


--
-- Name: TABLE appannie_account; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.appannie_account TO read_only_group;


--
-- Name: TABLE appannie_download_y2017; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.appannie_download_y2017 TO read_only_group;


--
-- Name: TABLE appannie_download_y2018; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.appannie_download_y2018 TO read_only_group;


--
-- Name: TABLE appannie_download_y2019; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.appannie_download_y2019 TO read_only_group;


--
-- Name: TABLE appannie_download_y2020; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.appannie_download_y2020 TO read_only_group;


--
-- Name: TABLE healthstore_abdominalpain; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_abdominalpain TO read_only_group;


--
-- Name: TABLE healthstore_actionresponse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_actionresponse TO read_only_group;


--
-- Name: TABLE healthstore_activityprogram; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_activityprogram TO read_only_group;


--
-- Name: TABLE healthstore_allergysymptoms; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_allergysymptoms TO read_only_group;


--
-- Name: TABLE healthstore_applicationevent; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_applicationevent TO read_only_group;


--
-- Name: TABLE healthstore_applicationlogin; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_applicationlogin TO read_only_group;


--
-- Name: TABLE healthstore_applicationpreference; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_applicationpreference TO read_only_group;


--
-- Name: TABLE healthstore_appointmentresponse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_appointmentresponse TO read_only_group;


--
-- Name: TABLE healthstore_assessmentchain; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_assessmentchain TO read_only_group;


--
-- Name: TABLE healthstore_assessmentresponse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_assessmentresponse TO read_only_group;


--
-- Name: TABLE healthstore_award; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_award TO read_only_group;


--
-- Name: TABLE healthstore_behavioraltrigger; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_behavioraltrigger TO read_only_group;


--
-- Name: TABLE healthstore_bloodpressure; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_bloodpressure TO read_only_group;


--
-- Name: TABLE healthstore_bodymeasurement; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_bodymeasurement TO read_only_group;


--
-- Name: TABLE healthstore_bookmarkset; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_bookmarkset TO read_only_group;


--
-- Name: TABLE healthstore_bowelmovement; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_bowelmovement TO read_only_group;


--
-- Name: TABLE healthstore_caremoduleassignment; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_caremoduleassignment TO read_only_group;


--
-- Name: TABLE healthstore_careplanassignment; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_careplanassignment TO read_only_group;


--
-- Name: TABLE healthstore_challengeresponse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_challengeresponse TO read_only_group;


--
-- Name: TABLE healthstore_cigarettesmoked; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_cigarettesmoked TO read_only_group;


--
-- Name: TABLE healthstore_condition; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_condition TO read_only_group;


--
-- Name: TABLE healthstore_cpeptide; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_cpeptide TO read_only_group;


--
-- Name: TABLE healthstore_creactiveprotein; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_creactiveprotein TO read_only_group;


--
-- Name: TABLE healthstore_dailyactivities; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_dailyactivities TO read_only_group;


--
-- Name: TABLE healthstore_dailycigaretteintake; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_dailycigaretteintake TO read_only_group;


--
-- Name: TABLE healthstore_dailyroutine; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_dailyroutine TO read_only_group;


--
-- Name: TABLE healthstore_deviceuse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_deviceuse TO read_only_group;


--
-- Name: TABLE healthstore_documentacceptance; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_documentacceptance TO read_only_group;


--
-- Name: TABLE healthstore_educationresponse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_educationresponse TO read_only_group;


--
-- Name: TABLE healthstore_energylevel; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_energylevel TO read_only_group;


--
-- Name: TABLE healthstore_exercise; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_exercise TO read_only_group;


--
-- Name: TABLE healthstore_fecalcalprotectin; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_fecalcalprotectin TO read_only_group;


--
-- Name: TABLE healthstore_fitnesslevel; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_fitnesslevel TO read_only_group;


--
-- Name: TABLE healthstore_fluidintake; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_fluidintake TO read_only_group;


--
-- Name: TABLE healthstore_hba1c; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_hba1c TO read_only_group;


--
-- Name: TABLE healthstore_height; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_height TO read_only_group;


--
-- Name: TABLE healthstore_importedobject; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_importedobject TO read_only_group;


--
-- Name: TABLE healthstore_insulin; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_insulin TO read_only_group;


--
-- Name: TABLE healthstore_journalentry; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_journalentry TO read_only_group;


--
-- Name: TABLE healthstore_meal; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_meal TO read_only_group;


--
-- Name: TABLE healthstore_mealrating; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_mealrating TO read_only_group;


--
-- Name: TABLE healthstore_medicationadministration; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_medicationadministration TO read_only_group;


--
-- Name: TABLE healthstore_medicationrefillstatus; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_medicationrefillstatus TO read_only_group;


--
-- Name: TABLE healthstore_medicationschedule; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_medicationschedule TO read_only_group;


--
-- Name: TABLE healthstore_mood; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_mood TO read_only_group;


--
-- Name: TABLE healthstore_nausea; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_nausea TO read_only_group;


--
-- Name: TABLE healthstore_notificationresponse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_notificationresponse TO read_only_group;


--
-- Name: TABLE healthstore_optin; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_optin TO read_only_group;


--
-- Name: TABLE healthstore_oralglucosetolerancetest; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_oralglucosetolerancetest TO read_only_group;


--
-- Name: TABLE healthstore_pain; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_pain TO read_only_group;


--
-- Name: TABLE healthstore_plasmabloodglucose; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_plasmabloodglucose TO read_only_group;


--
-- Name: TABLE healthstore_procedureperformed; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_procedureperformed TO read_only_group;


--
-- Name: TABLE healthstore_progress; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_progress TO read_only_group;


--
-- Name: TABLE healthstore_prostatespecificantigen; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_prostatespecificantigen TO read_only_group;


--
-- Name: TABLE healthstore_pulse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_pulse TO read_only_group;


--
-- Name: TABLE healthstore_questionnaireresponse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_questionnaireresponse TO read_only_group;


--
-- Name: TABLE healthstore_scheduledaction; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledaction TO read_only_group;


--
-- Name: TABLE healthstore_scheduledactiviy; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledactiviy TO read_only_group;


--
-- Name: TABLE healthstore_scheduledappointment; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledappointment TO read_only_group;


--
-- Name: TABLE healthstore_scheduledassessment; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledassessment TO read_only_group;


--
-- Name: TABLE healthstore_scheduledchallenge; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledchallenge TO read_only_group;


--
-- Name: TABLE healthstore_scheduleddeviceuse; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduleddeviceuse TO read_only_group;


--
-- Name: TABLE healthstore_schedulededucation; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_schedulededucation TO read_only_group;


--
-- Name: TABLE healthstore_scheduledmedication; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledmedication TO read_only_group;


--
-- Name: TABLE healthstore_schedulednotification; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_schedulednotification TO read_only_group;


--
-- Name: TABLE healthstore_scheduledprocedure; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledprocedure TO read_only_group;


--
-- Name: TABLE healthstore_scheduledquestionnaire; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_scheduledquestionnaire TO read_only_group;


--
-- Name: TABLE healthstore_selfassessment; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_selfassessment TO read_only_group;


--
-- Name: TABLE healthstore_selfmonitoredbloodglucose; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_selfmonitoredbloodglucose TO read_only_group;


--
-- Name: TABLE healthstore_sleep; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_sleep TO read_only_group;


--
-- Name: TABLE healthstore_therapeuticdose; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_therapeuticdose TO read_only_group;


--
-- Name: TABLE healthstore_tracker; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_tracker TO read_only_group;


--
-- Name: TABLE healthstore_triglycerides; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_triglycerides TO read_only_group;


--
-- Name: TABLE healthstore_user; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_user TO read_only_group;


--
-- Name: TABLE healthstore_usertokens; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_usertokens TO read_only_group;


--
-- Name: TABLE healthstore_waterintake; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_waterintake TO read_only_group;


--
-- Name: TABLE healthstore_weight; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_weight TO read_only_group;


--
-- Name: TABLE healthstore_wellbeingstate; Type: ACL; Schema: base_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE base_deidentified.healthstore_wellbeingstate TO read_only_group;


--
-- Name: TABLE bct_event_7mw; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.bct_event_7mw TO read_only_group;


--
-- Name: TABLE healthstore_actionresponse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_actionresponse TO read_only_group;


--
-- Name: TABLE healthstore_activityprogram; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_activityprogram TO read_only_group;


--
-- Name: TABLE healthstore_applicationlogin; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_applicationlogin TO read_only_group;


--
-- Name: TABLE healthstore_applicationpreference; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_applicationpreference TO read_only_group;


--
-- Name: TABLE healthstore_applicationprofile; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_applicationprofile TO read_only_group;


--
-- Name: TABLE healthstore_appointmentresponse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_appointmentresponse TO read_only_group;


--
-- Name: TABLE healthstore_assessmentresponse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_assessmentresponse TO read_only_group;


--
-- Name: TABLE healthstore_bloodpressure; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_bloodpressure TO read_only_group;


--
-- Name: TABLE healthstore_bookmarkset; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_bookmarkset TO read_only_group;


--
-- Name: TABLE healthstore_caremoduleassignment; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_caremoduleassignment TO read_only_group;


--
-- Name: TABLE healthstore_dailycigaretteintake; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_dailycigaretteintake TO read_only_group;


--
-- Name: TABLE healthstore_dailyroutine; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_dailyroutine TO read_only_group;


--
-- Name: TABLE healthstore_deviceuse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_deviceuse TO read_only_group;


--
-- Name: TABLE healthstore_documentacceptance; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_documentacceptance TO read_only_group;


--
-- Name: TABLE healthstore_educationresponse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_educationresponse TO read_only_group;


--
-- Name: TABLE healthstore_energylevel; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_energylevel TO read_only_group;


--
-- Name: TABLE healthstore_exercise; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_exercise TO read_only_group;


--
-- Name: TABLE healthstore_fitnesslevel; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_fitnesslevel TO read_only_group;


--
-- Name: TABLE healthstore_hba1c; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_hba1c TO read_only_group;


--
-- Name: TABLE healthstore_importedobject; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_importedobject TO read_only_group;


--
-- Name: TABLE healthstore_meal; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_meal TO read_only_group;


--
-- Name: TABLE healthstore_mealrating; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_mealrating TO read_only_group;


--
-- Name: TABLE healthstore_medicationadministration; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_medicationadministration TO read_only_group;


--
-- Name: TABLE healthstore_medicationrefillstatus; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_medicationrefillstatus TO read_only_group;


--
-- Name: TABLE healthstore_mood; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_mood TO read_only_group;


--
-- Name: TABLE healthstore_nausea; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_nausea TO read_only_group;


--
-- Name: TABLE healthstore_notificationresponse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_notificationresponse TO read_only_group;


--
-- Name: TABLE healthstore_optin; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_optin TO read_only_group;


--
-- Name: TABLE healthstore_pain; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_pain TO read_only_group;


--
-- Name: TABLE healthstore_progress; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_progress TO read_only_group;


--
-- Name: TABLE healthstore_prostatespecificantigen; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_prostatespecificantigen TO read_only_group;


--
-- Name: TABLE healthstore_questionnaireresponse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_questionnaireresponse TO read_only_group;


--
-- Name: TABLE healthstore_scheduledaction; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_scheduledaction TO read_only_group;


--
-- Name: TABLE healthstore_scheduledappointment; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_scheduledappointment TO read_only_group;


--
-- Name: TABLE healthstore_scheduledassessment; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_scheduledassessment TO read_only_group;


--
-- Name: TABLE healthstore_scheduleddeviceuse; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_scheduleddeviceuse TO read_only_group;


--
-- Name: TABLE healthstore_scheduledmedication; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_scheduledmedication TO read_only_group;


--
-- Name: TABLE healthstore_schedulednotification; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_schedulednotification TO read_only_group;


--
-- Name: TABLE healthstore_selfmonitoredbloodglucose; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_selfmonitoredbloodglucose TO read_only_group;


--
-- Name: TABLE healthstore_sleep; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_sleep TO read_only_group;


--
-- Name: TABLE healthstore_tracker; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_tracker TO read_only_group;


--
-- Name: TABLE healthstore_user; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_user TO read_only_group;


--
-- Name: TABLE healthstore_usertokens; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_usertokens TO read_only_group;


--
-- Name: TABLE healthstore_waterintake; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_waterintake TO read_only_group;


--
-- Name: TABLE healthstore_weight; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_weight TO read_only_group;


--
-- Name: TABLE healthstore_wellbeingstate; Type: ACL; Schema: base_identified; Owner: catalyze
--

GRANT SELECT ON TABLE base_identified.healthstore_wellbeingstate TO read_only_group;


--
-- Name: TABLE appannie_download; Type: ACL; Schema: cleansed_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE cleansed_deidentified.appannie_download TO read_only_group;


--
-- Name: TABLE ga_session; Type: ACL; Schema: cleansed_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE cleansed_deidentified.ga_session TO read_only_group;


--
-- Name: TABLE healthstore_applicationprofile; Type: ACL; Schema: cleansed_identified; Owner: catalyze
--

GRANT SELECT ON TABLE cleansed_identified.healthstore_applicationprofile TO read_only_group;


--
-- Name: TABLE dip_migrations; Type: ACL; Schema: dip_configuration; Owner: catalyze
--

GRANT SELECT ON TABLE dip_configuration.dip_migrations TO read_only_group;


--
-- Name: TABLE workflow_history; Type: ACL; Schema: dip_configuration; Owner: catalyze
--

GRANT SELECT ON TABLE dip_configuration.workflow_history TO read_only_group;


--
-- Name: SEQUENCE workflow_history_id_seq; Type: ACL; Schema: dip_configuration; Owner: catalyze
--

GRANT SELECT ON SEQUENCE dip_configuration.workflow_history_id_seq TO read_only_group;


--
-- Name: TABLE listed_dates; Type: ACL; Schema: ib_listing_service; Owner: catalyze
--

GRANT SELECT ON TABLE ib_listing_service.listed_dates TO read_only_group;


--
-- Name: SEQUENCE listed_dates_id_seq; Type: ACL; Schema: ib_listing_service; Owner: catalyze
--

GRANT SELECT ON SEQUENCE ib_listing_service.listed_dates_id_seq TO read_only_group;


--
-- Name: TABLE listing_configs; Type: ACL; Schema: ib_listing_service; Owner: catalyze
--

GRANT SELECT ON TABLE ib_listing_service.listing_configs TO read_only_group;


--
-- Name: TABLE work_product_metrics_annual; Type: ACL; Schema: work_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE work_deidentified.work_product_metrics_annual TO read_only_group;


--
-- Name: TABLE work_product_metrics_monthly; Type: ACL; Schema: work_deidentified; Owner: catalyze
--

GRANT SELECT ON TABLE work_deidentified.work_product_metrics_monthly TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: app_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_deidentified REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_deidentified GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: app_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_deidentified REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_deidentified GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: app_identified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_identified REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_identified GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: app_identified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_identified REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA app_identified GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: base_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_deidentified REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_deidentified GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: base_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_deidentified REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_deidentified GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: base_identified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_identified REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_identified GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: base_identified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_identified REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA base_identified GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: cleansed_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_deidentified REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_deidentified GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: cleansed_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_deidentified REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_deidentified GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: cleansed_identified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_identified REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_identified GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: cleansed_identified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_identified REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA cleansed_identified GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: dip_configuration; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA dip_configuration REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA dip_configuration GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: dip_configuration; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA dip_configuration REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA dip_configuration GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: ib_listing_service; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA ib_listing_service REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA ib_listing_service GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: ib_listing_service; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA ib_listing_service REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA ib_listing_service GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA public REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA public GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA public REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA public GRANT SELECT ON TABLES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: work_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA work_deidentified REVOKE ALL ON SEQUENCES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA work_deidentified GRANT USAGE ON SEQUENCES  TO read_only_group;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: work_deidentified; Owner: catalyze
--

ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA work_deidentified REVOKE ALL ON TABLES  FROM catalyze;
ALTER DEFAULT PRIVILEGES FOR ROLE catalyze IN SCHEMA work_deidentified GRANT SELECT ON TABLES  TO read_only_group;


--
-- PostgreSQL database dump complete
--