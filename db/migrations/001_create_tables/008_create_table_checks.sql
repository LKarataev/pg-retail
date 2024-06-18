DROP TABLE IF EXISTS checks CASCADE;
CREATE TABLE checks
(
  transaction_id INTEGER NOT NULL
    REFERENCES transactions (transaction_id)
      ON UPDATE CASCADE,
  sku_id         INTEGER NOT NULL
    REFERENCES sku (sku_id)
      ON UPDATE CASCADE,
  sku_amount     NUMERIC NOT NULL,
  sku_summ       NUMERIC NOT NULL,
  sku_summ_paid  NUMERIC NOT NULL,
  sku_discount   NUMERIC NOT NULL
);
