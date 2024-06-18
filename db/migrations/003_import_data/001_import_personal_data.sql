DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_import('personal_data', project_path || '/db/initial_data/Personal_Data_Mini.csv', ',');
  END
$$;
