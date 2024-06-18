DROP TABLE IF EXISTS transactions CASCADE;
CREATE TABLE transactions
(
  transaction_id       INTEGER PRIMARY KEY,
  customer_card_id     INTEGER   NOT NULL
    REFERENCES cards (customer_card_id)
      ON UPDATE CASCADE,
  transaction_summ     NUMERIC   NOT NULL,
  transaction_datetime TIMESTAMP NOT NULL,
  transaction_store_id INTEGER   NOT NULL
);
