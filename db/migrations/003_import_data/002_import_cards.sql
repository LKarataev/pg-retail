DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_import('cards', project_path || '/db/initial_data/Cards_Mini.csv', ',');
  END
$$;
