DROP VIEW IF EXISTS customers;
CREATE VIEW customers AS
WITH
  rates
    AS (SELECT c.customer_id                               AS customer_id,
               RANK() OVER (ORDER BY
                 fnc_customer_average(c.customer_id) DESC) AS rate1,
               RANK() OVER (ORDER BY
                 fnc_customer_frequency(c.customer_id))    AS rate2,
               (fnc_customer_inactive_period(c.customer_id))
                 / fnc_customer_frequency(c.customer_id)   AS rate3
        FROM transactions t
          INNER JOIN cards c
            ON t.customer_card_id = c.customer_card_id
        GROUP BY c.customer_id),
  new_nums
    AS (SELECT 1 AS value
        UNION
        SELECT 2
        UNION
        SELECT 3),
  segment_nums
    AS (SELECT average_check.value AS average_check,
               frequency.value     AS frequency,
               churn.value         AS churn
        FROM new_nums AS average_check
          CROSS JOIN new_nums AS frequency
          CROSS JOIN new_nums AS churn
        ORDER BY average_check, frequency, churn),
  segment_ref
    AS (SELECT ROW_NUMBER() OVER () AS nums,
               CASE segment_nums.average_check
                 WHEN 1 THEN 'Low'
                 WHEN 2 THEN 'Medium'
                 ELSE 'High'
                 END                AS average_check,
               CASE segment_nums.frequency
                 WHEN 1 THEN 'Rarely'
                 WHEN 2 THEN 'Occasionally'
                 ELSE 'Often'
                 END                AS frequency,
               CASE segment_nums.churn
                 WHEN 1 THEN 'Low'
                 WHEN 2 THEN 'Medium'
                 ELSE 'High'
                 END                AS churn
        FROM segment_nums),
  calculates
    AS (SELECT pd.customer_id                               AS customer_id,
               fnc_customer_average(pd.customer_id)         AS customer_average_check,
               CASE
                 WHEN r.rate1 <= ROUND((SELECT COUNT(*)
                                        FROM rates) * 0.10) THEN 'High'
                 WHEN r.rate1 <= ROUND((SELECT COUNT(*)
                                        FROM rates) * 0.35) THEN 'Medium'
                 ELSE 'Low'
                 END                                        AS customer_average_check_segment,
               fnc_customer_frequency(pd.customer_id)       AS customer_frequency,
               CASE
                 WHEN r.rate2 <= ROUND((SELECT COUNT(*)
                                        FROM rates) * 0.10) THEN 'Often'
                 WHEN r.rate2 <= ROUND((SELECT COUNT(*)
                                        FROM rates) * 0.35) THEN 'Occasionally'
                 ELSE 'Rarely'
                 END                                        AS customer_frequency_segment,
               fnc_customer_inactive_period(pd.customer_id) AS customer_inactive_period,
               r.rate3                                      AS customer_churn_rate,
               CASE
                 WHEN r.rate3 BETWEEN 0 AND 2 THEN 'Low'
                 WHEN r.rate3 BETWEEN 2 AND 5 THEN 'Medium'
                 WHEN r.rate3 > 5 THEN 'High'
                 END                                        AS customer_churn_segment
        FROM personal_data pd
          INNER JOIN rates r
            ON r.customer_id = pd.customer_id)
SELECT c.*,
       sr.nums                                   AS customer_segment,
       fnc_customer_primary_store(c.customer_id) AS customer_primary_store
FROM calculates c
  LEFT JOIN segment_ref sr
    ON c.customer_average_check_segment = sr.average_check
    AND c.customer_churn_segment = sr.churn
    AND c.customer_frequency_segment = sr.frequency
ORDER BY c.customer_id;
