DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_export('stores', project_path || '/db/export_data/data/Stores_Mini_New.csv', ',');
  END
$$;
