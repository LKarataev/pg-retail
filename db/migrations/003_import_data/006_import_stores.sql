DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_import('stores', project_path || '/db/initial_data/Stores_Mini.csv', ',');
  END
$$;
