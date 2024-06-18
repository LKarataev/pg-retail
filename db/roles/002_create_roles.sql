CREATE ROLE administrator;
CREATE ROLE visitor;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO visitor;
GRANT USAGE ON SCHEMA public TO visitor;

GRANT ALL ON ALL TABLES IN SCHEMA public TO administrator;
GRANT ALL ON SCHEMA public TO administrator;
