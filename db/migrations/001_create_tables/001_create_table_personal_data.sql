DROP TABLE IF EXISTS personal_data CASCADE;
CREATE TABLE personal_data
(
  customer_id            INTEGER PRIMARY KEY,
  customer_name          VARCHAR NOT NULL
    CHECK (customer_name ~ '^[A-ZА-ЯЁ][-a-zа-яё ]*$'),
  customer_surname       VARCHAR NOT NULL
    CHECK (customer_name ~ '^[A-ZА-ЯЁ][-a-zа-яё ]*$'),
  customer_primary_email VARCHAR NOT NULL
    CHECK (customer_primary_email ~ CONCAT(
      '^[a-zA-Z0-9.!#$%&''*+\/=?^_`{|}~-]+@[a-zA-Z0-9]',
      '(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9]',
      '(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$')),
  customer_primary_phone VARCHAR NOT NULL
    CHECK (customer_primary_phone ~ '^[+][7][0-9]{10}$')
);
