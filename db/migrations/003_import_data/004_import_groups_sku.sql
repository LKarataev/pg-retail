DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_import('groups_sku', project_path || '/db/initial_data/Groups_SKU_Mini.csv', ',');
  END
$$;
