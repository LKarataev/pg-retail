DROP FUNCTION IF EXISTS fnc_personal_offers_increase_avg_check_plpgsql;
CREATE
OR REPLACE FUNCTION fnc_personal_offers_increase_avg_check_plpgsql(
	calculation_method INTEGER,
	first_date DATE,
	last_date DATE,
	transactions_num INTEGER,
	check_increase_coeff NUMERIC,
	churn_index_max NUMERIC,
	transaction_share NUMERIC,
	margin_share NUMERIC
) RETURNS TABLE (
	customer_id INTEGER,
	required_check_measure MONEY,
	group_name VARCHAR,
	offer_discount_depth NUMERIC
) AS 
$BODY$
DECLARE
	period_begin DATE;
	period_end DATE;
	r_required_check RECORD;
	r_groups RECORD;
	v_avg_margin NUMERIC;
	v_min_discount NUMERIC;
BEGIN
DROP TABLE IF EXISTS tb_init; -- TODO
CREATE TEMP TABLE tb_init AS
SELECT ROW_NUMBER() OVER (
			PARTITION BY personal_data.customer_id 
			ORDER BY transactions.transaction_datetime DESC
		), personal_data.customer_id,
       transactions.transaction_summ,
       transactions.transaction_datetime
FROM personal_data
    NATURAL LEFT JOIN cards
    NATURAL LEFT JOIN transactions
ORDER BY personal_data.customer_id;

SELECT MIN(transaction_datetime)
INTO period_begin
FROM tb_init;

SELECT MAX(transaction_datetime)
INTO period_end
FROM tb_init;

IF first_date < last_date THEN
	IF first_date > period_begin THEN 
		period_begin := first_date; 
	END IF;
	IF last_date < period_end THEN 
		period_end := last_date; 
	END IF;
END IF;

IF calculation_method = 1 THEN
	DROP TABLE IF EXISTS tb_selected;
	CREATE TEMP TABLE tb_selected AS
	SELECT *
	FROM tb_init
	WHERE transaction_datetime >= period_begin AND transaction_datetime <= period_end;
ELSE
	DROP TABLE IF EXISTS tb_selected;
	CREATE TEMP TABLE tb_selected AS
	SELECT *
	FROM tb_init
	WHERE row_number <= transactions_num;
END IF;

DROP TABLE IF EXISTS tb_required_check;
CREATE TEMP TABLE tb_required_check AS
SELECT 
	tb_selected.customer_id,
    COALESCE(AVG(tb_selected.transaction_summ) * check_increase_coeff, 0) AS required_check_measure
FROM tb_selected
GROUP BY tb_selected.customer_id
ORDER BY tb_selected.customer_id;

DROP TABLE IF EXISTS tb_avg_margin;
CREATE TEMP TABLE tb_avg_margin AS
SELECT DISTINCT
	purchase_history.customer_id,
	purchase_history.group_id,
	AVG((purchase_history.group_summ_paid - purchase_history.group_cost) / purchase_history.group_summ_paid) AS group_average_margin
FROM purchase_history
GROUP BY purchase_history.customer_id, purchase_history.group_id;

FOR r_required_check IN 
	(SELECT * FROM tb_required_check) 
LOOP
	FOR r_groups IN
		(SELECT * FROM groups 
		WHERE groups.customer_id = r_required_check.customer_id 
			AND groups.group_churn_rate <= churn_index_max 
			AND groups.group_discount_share <= transaction_share / 100
		ORDER BY groups.group_affinity_index DESC) 
	LOOP
		SELECT 
			group_average_margin 
		INTO v_avg_margin 
		FROM tb_avg_margin 
		WHERE r_required_check.customer_id = tb_avg_margin.customer_id 
			AND r_groups.group_id = tb_avg_margin.group_id;
		
		v_min_discount := CEIL(20 * r_groups.group_minimum_discount) / 20;
		
		RAISE NOTICE 'customer_id: %',  r_required_check.customer_id; -- TODO	
		RAISE NOTICE 'group_id: %',  r_groups.group_id; -- TODO
		RAISE NOTICE 'group_name: %',  (SELECT groups_sku.group_name FROM groups_sku WHERE groups_sku.group_id = r_groups.group_id); -- TODO
		RAISE NOTICE 'required_check_measure: %',  r_required_check.required_check_measure; -- TODO
		RAISE NOTICE 'margin share: %',  margin_share / 100 * v_avg_margin; -- TODO
		RAISE NOTICE 'v_min_discount: %',  v_min_discount; -- TODO
		RAISE NOTICE 'minimum discount (raw): %',  r_groups.group_minimum_discount; -- TODO
		RAISE NOTICE 'group_affinity_index: %',  r_groups.group_affinity_index; -- TODO
		RAISE NOTICE '-----------------------------------------------------------'; -- TODO

		IF v_min_discount > 0 AND margin_share / 100 * v_avg_margin > v_min_discount THEN
			customer_id := r_required_check.customer_id;
			required_check_measure := r_required_check.required_check_measure;
			group_name := (SELECT groups_sku.group_name FROM groups_sku WHERE group_id = r_groups.group_id);
			offer_discount_depth := v_min_discount * 100;
			RETURN NEXT;
			EXIT;
		END IF;
	END LOOP;	
END LOOP;

END; 
$BODY$ LANGUAGE PLPGSQL;
