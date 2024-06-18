-- Переводит интервал в численное значение

CREATE OR REPLACE FUNCTION fnc_numeric_interval(p_interval INTERVAL)
  RETURNS NUMERIC AS
$$
SELECT (EXTRACT(DAYS FROM p_interval) +
       EXTRACT(HOURS FROM p_interval) / 24::NUMERIC +
       EXTRACT(MINUTES FROM p_interval) / 1440::NUMERIC +
       EXTRACT(SECONDS FROM p_interval) / 86400::NUMERIC)::NUMERIC;
$$ LANGUAGE sql;
