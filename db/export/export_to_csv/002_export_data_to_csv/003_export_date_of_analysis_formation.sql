DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_export('date_of_analysis_formation', project_path || '/db/export_data/data/Date_Of_Analysis_Formation_New.csv', ',');
  END
$$;
