REVOKE ALL ON ALL TABLES IN SCHEMA public FROM administrator, visitor;
REVOKE ALL ON SCHEMA public FROM administrator, visitor;
DROP ROLE IF EXISTS administrator, visitor;
