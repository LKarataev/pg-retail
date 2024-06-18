-- Считает значение частоты транзакций клиента (в среднем)

CREATE OR REPLACE FUNCTION fnc_customer_frequency(p_customer_id INTEGER)
  RETURNS NUMERIC AS
$$
SELECT fnc_numeric_interval(MAX(t.transaction_datetime) - MIN(t.transaction_datetime))
         / COUNT(*)
FROM transactions t
  NATURAL JOIN cards c
WHERE c.customer_id = p_customer_id
  AND t.transaction_datetime < (SELECT analysis_formation
                                FROM date_of_analysis_formation
                                LIMIT 1)
$$ LANGUAGE sql;
