DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_import('date_of_analysis_formation', project_path || '/db/initial_data/Date_Of_Analysis_Formation.csv', ',');
  END
$$;
