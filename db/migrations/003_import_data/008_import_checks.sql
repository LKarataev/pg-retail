DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_import('checks', project_path || '/db/initial_data/Checks_Mini.csv', ',');
  END
$$;
