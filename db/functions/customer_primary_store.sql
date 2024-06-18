-- Определяет id основного магазина клиента

CREATE OR REPLACE FUNCTION fnc_customer_primary_store(p_customer_id INTEGER)
  RETURNS INTEGER AS
$$
WITH
  last_visits AS (SELECT DISTINCT t.transaction_store_id AS id,
                                  t.transaction_datetime,
                                  t.customer_card_id
                  FROM transactions t
                  WHERE t.customer_card_id IN (SELECT customer_card_id
                                               FROM cards
                                               WHERE customer_id = p_customer_id)
                    AND t.transaction_datetime < (SELECT analysis_formation
                                                  FROM date_of_analysis_formation
                                                  LIMIT 1)
                  ORDER BY t.transaction_datetime DESC
                  LIMIT 3),
  most_visits AS (SELECT DISTINCT t.transaction_store_id      AS transaction_store_id,
                                  COUNT(t.transaction_id)     AS count_transaction,
                                  MAX(t.transaction_datetime) AS visit_date
                  FROM transactions t
                  WHERE t.customer_card_id IN (SELECT customer_card_id
                                               FROM cards
                                               WHERE customer_id = p_customer_id)
                    AND t.transaction_datetime < (SELECT analysis_formation
                                                  FROM date_of_analysis_formation
                                                  LIMIT 1)
                  GROUP BY transaction_store_id)
SELECT CASE
         WHEN (SELECT MAX(id)
               FROM last_visits) = (SELECT MIN(id)
                                    FROM last_visits)
           THEN (SELECT MAX(id)
                 FROM last_visits)
         ELSE (SELECT v.transaction_store_id
               FROM most_visits v
               WHERE v.count_transaction = (SELECT MAX(count_transaction)
                                            FROM most_visits)
               ORDER BY v.visit_date DESC
               LIMIT 1)
         END AS customer_primary_store
$$ LANGUAGE sql;
