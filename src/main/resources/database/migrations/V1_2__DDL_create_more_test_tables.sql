CREATE SEQUENCE seq_mstr_job_id START 1;

CREATE TABLE mstr_job_info
(
    mstr_job_id INTEGER NOT NULL DEFAULT nextval('seq_mstr_job_id'::regclass),
    app_nm CHARACTER VARYING(500),
    proj_nm CHARACTER VARYING(500),
    oper_co_cd CHARACTER VARYING(500),
    fran_nm CHARACTER VARYING(500),
    subj_area CHARACTER VARYING(500),
    data_dom CHARACTER VARYING(500),
    soc CHARACTER VARYING(500),
    mstr_job_nm CHARACTER VARYING(500),
    mstr_job_desc CHARACTER VARYING(500),
    schd_job_nm CHARACTER VARYING(500),
    src_layer CHARACTER VARYING(500),
    trgt_layer CHARACTER VARYING(500),
    run_freq CHARACTER VARYING(500),
    crt_by CHARACTER VARYING(100),
    crt_dttm TIMESTAMP(6) WITH TIME ZONE,
    updt_by CHARACTER VARYING(100),
    updt_dttm TIMESTAMP(6) WITH TIME ZONE,
    is_mstr_act CHARACTER VARYING(1)
);

ALTER TABLE mstr_job_info
ADD CONSTRAINT mstr_job_info_pk
PRIMARY KEY (mstr_job_id);

CREATE UNIQUE INDEX mstr_job_info_idx
ON mstr_job_info
USING btree
(
mstr_job_nm
);