DROP FUNCTION IF EXISTS fnc_personal_offers_focused_on_cross_selling;
CREATE FUNCTION fnc_personal_offers_focused_on_cross_selling (
  groups_count INTEGER,
  max_churn_index NUMERIC,
  max_consumption_stability_index NUMERIC,
  max_sku_share NUMERIC,
  allowable_margin_share NUMERIC
) RETURNS TABLE (
  customer_id INTEGER,
  sku_name VARCHAR,
  max_discount_depth NUMERIC
) AS $$ 
WITH target_groups AS(
  SELECT
    customer_id,
    group_id,
    group_affinity_index
  FROM (
        SELECT
          g1.customer_id,
          group_id,
          group_affinity_index,
          RANK() OVER(PARTITION BY g1.customer_id ORDER BY group_id) AS num
        FROM
          groups g1
        JOIN (
              SELECT
                customer_id,
                MAX(group_affinity_index) AS max_group_affinity_index
              FROM
                groups
              WHERE
                group_churn_rate <= max_churn_index
                AND group_stability_index < max_consumption_stability_index
              GROUP BY
                customer_id
             ) AS g2 
          ON g1.customer_id = g2.customer_id
          AND g1.group_affinity_index = g2.max_group_affinity_index
       ) AS suitable_groups
  WHERE num <= groups_count
),
max_margin_sku AS(
  SELECT
    t1.customer_id,
    t1.group_id,
    sku_id AS max_margin_sku_id,
    sku_purchase_price,
    sku_retail_price,
    margin,
    customer_primary_store
  FROM (
        SELECT 
          target_groups.customer_id,
          target_groups.group_id,
          sku.sku_id,
          sku_purchase_price,
          sku_retail_price,
          sku_retail_price - sku_purchase_price AS margin,
          customer_primary_store
        FROM 
          target_groups
        INNER JOIN customers
          ON target_groups.customer_id = customers.customer_id
        INNER JOIN sku
          ON target_groups.group_id = sku.group_id
        INNER JOIN stores
          ON customer_primary_store = stores.transaction_store_id
          AND sku.sku_id = stores.sku_id 
       ) AS t1
  INNER JOIN (
        SELECT
          target_groups.customer_id,
          target_groups.group_id,
          MAX(sku_retail_price - sku_purchase_price) max_margin
        FROM 
          target_groups
        INNER JOIN customers
          ON target_groups.customer_id = customers.customer_id
        INNER JOIN sku
          ON target_groups.group_id = sku.group_id
        INNER JOIN stores
          ON customer_primary_store = stores.transaction_store_id
          AND sku.sku_id = stores.sku_id
        GROUP BY target_groups.customer_id, target_groups.group_id
       ) AS t2
    ON t1.customer_id = t2.customer_id
    AND t1.group_id = t2.group_id
    AND t1.margin = t2.max_margin
),
sku_share_in_group AS(
  SELECT 
    max_margin_sku.*
  FROM max_margin_sku
  INNER JOIN (
              SELECT 
                max_margin_sku.customer_id,
                max_margin_sku.group_id,
                COUNT(*) AS group_transactions_count
              FROM max_margin_sku
              INNER JOIN cards
                ON max_margin_sku.customer_id = cards.customer_id
              INNER JOIN transactions
                ON cards.customer_card_id = transactions.customer_card_id
              GROUP BY max_margin_sku.customer_id, max_margin_sku.group_id
             ) AS group_transactions
    ON max_margin_sku.customer_id = group_transactions.customer_id 
    AND max_margin_sku.group_id = group_transactions.group_id
  INNER JOIN (
              SELECT 
                max_margin_sku.customer_id,
                max_margin_sku.group_id,
                COUNT(*) AS sku_transactions_count
              FROM max_margin_sku
              INNER JOIN cards
                ON max_margin_sku.customer_id = cards.customer_id
              INNER JOIN transactions
                ON cards.customer_card_id = transactions.customer_card_id
              INNER JOIN checks
                ON transactions.transaction_id = checks.transaction_id
                AND max_margin_sku.max_margin_sku_id = checks.sku_id
              GROUP BY max_margin_sku.customer_id, max_margin_sku.group_id
             ) AS sku_transactions
    ON max_margin_sku.customer_id = sku_transactions.customer_id 
    AND max_margin_sku.group_id = sku_transactions.group_id
    AND sku_transactions_count * 100.0 / group_transactions_count <= max_sku_share
),
offered_discounts AS(
  SELECT 
    sku_share_in_group.*,
    sku.sku_name,
    CEIL(20.0 * groups.group_minimum_discount) / 20 * 100 AS minimum_discount
  FROM sku_share_in_group
  INNER JOIN sku
    ON sku_share_in_group.max_margin_sku_id = sku.sku_id
  INNER JOIN groups
    ON sku_share_in_group.customer_id = groups.customer_id
    AND sku_share_in_group.group_id = groups.group_id
)
SELECT 
  customer_id,
  sku_name,
  minimum_discount AS max_discount_depth
FROM offered_discounts
WHERE
  allowable_margin_share * margin / sku_retail_price >= minimum_discount
$$ LANGUAGE SQL;
