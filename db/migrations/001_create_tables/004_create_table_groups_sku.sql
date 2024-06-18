DROP TABLE IF EXISTS groups_sku CASCADE;
CREATE TABLE groups_sku
(
  group_id   INTEGER PRIMARY KEY,
  group_name VARCHAR NOT NULL
    CHECK ( group_name ~ '^[[:print:]]*$' )
);
