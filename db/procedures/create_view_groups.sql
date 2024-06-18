CREATE OR REPLACE PROCEDURE
  prc_create_view_groups(p_method INTEGER, p_value INTEGER) AS
$$
BEGIN
  DROP TABLE IF EXISTS tb_parameters CASCADE;
  DROP MATERIALIZED VIEW IF EXISTS groups CASCADE;

  CREATE TABLE tb_parameters AS
  SELECT analysis_formation AS af,
         p_method           AS method,
         p_value            AS value_count
  FROM date_of_analysis_formation;

  CREATE MATERIALIZED VIEW groups AS
  WITH
    tb_group_affinity_index AS
      (SELECT DISTINCT pd.customer_id,
                       pd.group_id,
                       pd.group_purchase::NUMERIC / COUNT(*) OVER
                         (PARTITION BY pd.customer_id, pd.group_id) AS group_affinity_index
       FROM periods pd
         INNER JOIN purchase_history ph
           ON pd.customer_id = ph.customer_id
       WHERE ph.transaction_datetime
               BETWEEN pd.first_group_purchase_date
               AND pd.last_group_purchase_date),
    tb_main_calculations AS
      (SELECT p.customer_id,
              p.group_id,
              CASE p.transaction_datetime
                WHEN pd.first_group_purchase_date THEN 0
                ELSE ABS(fnc_numeric_interval(
                             p.transaction_datetime -
                             (LEAD(p.transaction_datetime) OVER
                               (ORDER BY p.customer_id, p.group_id,
                                 p.transaction_datetime DESC)))
                  - pd.group_frequency) / pd.group_frequency
                END                                                 AS stability_index,
              pd.group_purchase                                     AS group_purchase,
              pd.group_min_discount                                 AS group_minimum_discount,
              SUM(CASE
                    WHEN p.group_summ_paid <> p.group_summ
                      THEN p.group_summ_paid END) OVER
                (PARTITION BY p.customer_id, p.group_id) /
              SUM(CASE
                    WHEN p.group_summ_paid <> p.group_summ
                      THEN p.group_summ END) OVER
                (PARTITION BY p.customer_id, p.group_id)            AS average_discount,
              fnc_numeric_interval((SELECT af
                                    FROM tb_parameters)
                - pd.last_group_purchase_date) / pd.group_frequency AS group_churn_rate
       FROM purchase_history p
         NATURAL JOIN periods pd),
    tb_aggregate_info_from_main_calculations AS
      (SELECT DISTINCT mc.customer_id            AS customer_id,
                       mc.group_id               AS group_id,
                       CASE
                           COUNT(mc.stability_index)
                           OVER (PARTITION BY mc.customer_id, mc.group_id)
                         WHEN 1 THEN 1
                         ELSE
                               SUM(mc.stability_index)
                               OVER (PARTITION BY mc.customer_id, mc.group_id) /
                               (COUNT(mc.stability_index)
                                OVER (PARTITION BY mc.customer_id, mc.group_id) -
                                1)
                         END                     AS group_stability_index,
                       mc.group_purchase         AS group_purchase,
                       mc.average_discount       AS average_discount,
                       mc.group_minimum_discount AS group_minimum_discount,
                       mc.group_churn_rate       AS group_churn_rate
       FROM tb_main_calculations mc),

    cte_group_margin AS
      (SELECT ph.customer_id,
              ph.group_id,
              ph.group_summ_paid,
              ph.group_cost,
              ph.transaction_datetime,
              ROW_NUMBER()
              OVER (PARTITION BY ph.customer_id, ph.group_id) AS transactions_count
       FROM purchase_history ph),
    tb_group_margin AS
      (SELECT DISTINCT c.customer_id                                 AS customer_id,
                       c.group_id                                    AS group_id,
                       SUM(c.group_summ_paid - c.group_cost)
                       OVER (PARTITION BY c.customer_id, c.group_id) AS group_margin
       FROM cte_group_margin c
       WHERE ((SELECT method FROM tb_parameters) = 1 AND
              c.transaction_datetime >= (SELECT af FROM tb_parameters)
                - (INTERVAL '1 day') * (SELECT value_count FROM tb_parameters))
          OR ((SELECT method FROM tb_parameters) = 2 AND
              c.transactions_count <= (SELECT value_count FROM tb_parameters))
          OR ((SELECT method FROM tb_parameters) NOT IN (1, 2))),
    tb_number_of_discounted_customer_transactions AS
      (SELECT DISTINCT c.customer_id                                 AS customer_id,
                       s.group_id                                    AS group_id,
                       COUNT(CASE WHEN ch.sku_discount > 0 THEN 1 END)
                       OVER (PARTITION BY c.customer_id, s.group_id) AS nums
       FROM transactions t
         NATURAL INNER JOIN cards c
         NATURAL INNER JOIN checks ch
         NATURAL INNER JOIN sku s
       WHERE t.transaction_datetime < (SELECT af
                                       FROM tb_parameters))
  SELECT main.customer_id                             AS customer_id,
         main.group_id                                AS group_id,
         aff.group_affinity_index                     AS group_affinity_index,
         main.group_churn_rate                        AS group_churn_rate,
         main.group_stability_index                   AS group_stability_index,
         marg.group_margin                            AS group_margin,
         discount.nums / main.group_purchase::NUMERIC AS group_discount_share,
         main.group_minimum_discount                  AS group_minimum_discount,
         main.average_discount                        AS group_average_discount
  FROM tb_aggregate_info_from_main_calculations main
    NATURAL INNER JOIN tb_group_affinity_index aff
    NATURAL INNER JOIN tb_group_margin marg
    NATURAL INNER JOIN tb_number_of_discounted_customer_transactions discount;
END
$$ LANGUAGE plpgsql;
