DROP TABLE IF EXISTS sku CASCADE;
CREATE TABLE sku
(
  sku_id   INTEGER PRIMARY KEY,
  sku_name VARCHAR NOT NULL
    CHECK ( sku_name ~ '^[[:print:]]*$' ),
  group_id INTEGER NOT NULL
    REFERENCES groups_sku (group_id)
      ON UPDATE CASCADE
);
