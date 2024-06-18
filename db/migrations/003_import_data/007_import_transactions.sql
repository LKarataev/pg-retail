DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_import('transactions', project_path || '/db/initial_data/Transactions_Mini.csv', ',');
  END
$$;
