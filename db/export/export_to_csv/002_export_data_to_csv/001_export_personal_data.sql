DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_export('personal_data', project_path || '/db/export_data/data/Personal_Data_Mini_New.csv', ',');
  END
$$;
