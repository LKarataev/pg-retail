-- Считает количество времени, прошедшего с даты предыдущей транзакции клиента

CREATE OR REPLACE FUNCTION fnc_customer_inactive_period(p_customer_id INTEGER)
  RETURNS NUMERIC AS
$$
WITH
  analysis AS (SELECT analysis_formation AS f_date
               FROM date_of_analysis_formation
               LIMIT 1)
SELECT fnc_numeric_interval((SELECT *
                             FROM analysis) - MAX(t.transaction_datetime))
FROM transactions t
  NATURAL JOIN cards c
WHERE c.customer_id = p_customer_id
  AND t.transaction_datetime <= (SELECT *
                                 FROM analysis)
$$ LANGUAGE sql;
