DROP TABLE IF EXISTS stores CASCADE;
CREATE TABLE stores
(
  transaction_store_id INTEGER,
  sku_id               INTEGER NOT NULL
    REFERENCES sku (sku_id)
      ON UPDATE CASCADE,
  sku_purchase_price   NUMERIC NOT NULL,
  sku_retail_price     NUMERIC NOT NULL
);
