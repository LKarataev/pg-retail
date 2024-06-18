DO
$$
  DECLARE
    project_path VARCHAR := 'C:/GitProjects/pg-retail';  --  базовый путь к директории проекта
  BEGIN
    CALL prc_export('groups_sku', project_path || '/db/export_data/data/Groups_SKU_Mini_New.csv', ',');
  END
$$;
