DROP TABLE IF EXISTS cards CASCADE;
CREATE TABLE cards
(
  customer_card_id INTEGER PRIMARY KEY,
  customer_id      INTEGER NOT NULL
    REFERENCES personal_data (customer_id)
      ON UPDATE CASCADE
);
