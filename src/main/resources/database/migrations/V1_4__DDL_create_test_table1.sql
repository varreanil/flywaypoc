CREATE TABLE poc_test1 (
  key VARCHAR(64),
  value VARCHAR(255),
  PRIMARY KEY(key)
);

ALTER TABLE poc_test1 OWNER TO flywaydemo;