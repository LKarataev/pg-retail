DROP VIEW IF EXISTS periods CASCADE;
CREATE VIEW periods AS
WITH
  customer_group_first_last_purchase
    AS (SELECT ph.customer_id               AS customer_id,
               ph.group_id                  AS group_id,
               MIN(ph.transaction_datetime) AS first,
               MAX(ph.transaction_datetime) AS last,
               COUNT(*)                     AS group_purchase
        FROM purchase_history ph
        GROUP BY ph.customer_id, ph.group_id),
  min_discount
    AS (SELECT c.customer_id                      AS customer_id,
               s.group_id                         AS group_id,
               MIN(ch.sku_discount / ch.sku_summ) AS value
        FROM transactions t
          NATURAL JOIN cards c
          NATURAL JOIN checks ch
          NATURAL JOIN sku s
        WHERE t.transaction_datetime < (SELECT analysis_formation
                                        FROM date_of_analysis_formation
                                        LIMIT 1)
          AND ch.sku_discount::NUMERIC <> 0
        GROUP BY c.customer_id, s.group_id)
SELECT p.customer_id        AS customer_id,
       p.group_id           AS group_id,
       p.first              AS first_group_purchase_date,
       p.last               AS last_group_purchase_date,
       p.group_purchase     AS group_purchase,
       (fnc_numeric_interval(p.last - p.first) + 1) /
       p.group_purchase     AS group_frequency,
       COALESCE(m.value, 0) AS group_min_discount
FROM customer_group_first_last_purchase p
  LEFT JOIN min_discount m
    ON m.customer_id = p.customer_id
    AND m.group_id = p.group_id
ORDER BY p.customer_id, p.group_id;
