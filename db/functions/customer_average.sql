-- Считает значение среднего чека клиента

CREATE OR REPLACE FUNCTION fnc_customer_average(p_customer_id INTEGER)
  RETURNS NUMERIC AS
$$
SELECT COALESCE(AVG(t.transaction_summ), 0)
FROM transactions t
  NATURAL JOIN cards c
WHERE c.customer_id = p_customer_id
  AND t.transaction_datetime < (SELECT analysis_formation
                                FROM date_of_analysis_formation
                                LIMIT 1)
$$ LANGUAGE sql;
