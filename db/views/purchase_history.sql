DROP VIEW IF EXISTS purchase_history CASCADE;
CREATE VIEW purchase_history AS
SELECT DISTINCT cd.customer_id                             AS customer_id,
                t.transaction_id                           AS transaction_id,
                t.transaction_datetime                     AS transaction_datetime,
                s.group_id                                 AS group_id,
                SUM(st.sku_purchase_price * ch.sku_amount) AS group_cost,
                SUM(ch.sku_summ)                           AS group_summ,
                SUM(ch.sku_summ_paid)                      AS group_summ_paid
FROM cards cd
  NATURAL JOIN transactions t
  NATURAL JOIN checks ch
  NATURAL JOIN sku s
  NATURAL JOIN stores st
WHERE t.transaction_datetime < (SELECT analysis_formation
                                FROM date_of_analysis_formation
                                LIMIT 1)
GROUP BY cd.customer_id, t.transaction_id, t.transaction_datetime, s.group_id
ORDER BY cd.customer_id, s.group_id, t.transaction_datetime DESC;
