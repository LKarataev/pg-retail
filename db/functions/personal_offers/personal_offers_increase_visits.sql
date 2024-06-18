DROP FUNCTION IF EXISTS fnc_personal_offers_increase_visits;
CREATE FUNCTION
  fnc_personal_offers_increase_visits(first TIMESTAMP,
                                      last TIMESTAMP,
                                      added_transactions INTEGER,
                                      max_churn_index NUMERIC,
                                      max_discount_share NUMERIC,
                                      margin_value NUMERIC)
  RETURNS TABLE
          (
            CUSTOMER_ID                 INTEGER,
            START_DATE                  TIMESTAMP,
            END_DATE                    TIMESTAMP,
            REQUIRED_TRANSACTIONS_COUNT NUMERIC,
            GROUP_NAME                  VARCHAR,
            OFFER_DISCOUNT_DEPTH        NUMERIC
          )
  LANGUAGE sql
AS
$$
WITH
  tb_group_margin AS
    (SELECT DISTINCT c.customer_id                                 AS customer_id,
                     c.group_id                                    AS group_id,
                     AVG((c.group_summ_paid - c.group_cost) / c.group_summ_paid)
                     OVER (PARTITION BY c.customer_id, c.group_id) AS group_average_margin
     FROM purchase_history c),
  offer_condition
    AS (SELECT g.customer_id                                        AS customer_id,
               g.group_id                                           AS group_id,
               g.group_affinity_index                               AS group_affinity_index,
               CEILING(20 * g.group_minimum_discount) / 20::NUMERIC AS offer_discount_depth,
               MAX(g.group_affinity_index) OVER
                 (PARTITION BY g.customer_id)                       AS max_group_affinity_index
        FROM groups g
        NATURAL JOIN tb_group_margin marg
        WHERE g.group_churn_rate <= max_churn_index
          AND g.group_discount_share <= max_discount_share / 100::NUMERIC
          AND margin_value / 100::NUMERIC * marg.group_average_margin
          > CEILING(20 * g.group_minimum_discount) / 20::NUMERIC
          AND g.group_minimum_discount > 0)
SELECT DISTINCT o.customer_id,
                first,
                last,
                ROUND(fnc_numeric_interval(last - first)
                  / c.customer_frequency) + added_transactions,
                gs.group_name,
                o.offer_discount_depth * 100
FROM customers c
  NATURAL INNER JOIN offer_condition o
  NATURAL INNER JOIN groups_sku gs
WHERE o.group_affinity_index = o.max_group_affinity_index
ORDER BY o.customer_id;
$$;
