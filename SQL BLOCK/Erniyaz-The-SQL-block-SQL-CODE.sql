CREATE TABLE customer_info (
    id_client SERIAL PRIMARY KEY,
    total_amount DECIMAL,
    gender VARCHAR(1),
    age INTEGER,
    count_city INTEGER,
    response_communication INTEGER,
    communication_3month INTEGER,
    tenure INTEGER
);

CREATE TABLE transactions_info (
    date_new DATE,
    id_check INTEGER,
    id_client INTEGER REFERENCES customer_info(id_client),
    count_products DECIMAL,
    sum_payment DECIMAL
);

-- 10 строк из таблицы информации о клиентах
SELECT * FROM customer_info
LIMIT 10;

-- 10 строк из таблицы информации о транзакциях
SELECT * FROM transactions_info
LIMIT 10;


----------------------------------------------------------------------------------------------

-- 1. Список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков 
-- за указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за
-- месяц, количество всех операций по клиенту за период;

-- Шаг 1: Идентифицируем клиентов, совершивших транзакции в каждом месяце указанного периода (с 01.06.2015 по 01.06.2016).
WITH monthly_transactions AS (
    SELECT 
        id_client,
        DATE_TRUNC('month', date_new) AS month,
        COUNT(*) AS monthly_count
    FROM 
        transactions_info
    WHERE 
        date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        id_client, DATE_TRUNC('month', date_new)
),
continuous_customers AS (
    SELECT 
        id_client
    FROM 
        monthly_transactions
    GROUP BY 
        id_client
    HAVING 
        COUNT(DISTINCT month) = 12
)

-- Шаг 2: Рассчитываем средний чек, среднемесячную сумму покупки и общее количество транзакций.
SELECT 
    c.id_client,
    c.gender,
    AVG(t.sum_payment) AS avg_check,
    SUM(t.sum_payment) / 12 AS avg_monthly_purchase,
    COUNT(t.id_check) AS total_operations
FROM 
    customer_info AS c
JOIN 
    transactions_info AS t ON c.id_client = t.id_client
JOIN 
    continuous_customers AS cc ON c.id_client = cc.id_client
WHERE 
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    c.id_client, c.gender;

-----------------------------------------------------------------------------------------------------------


-- 2.	информацию в разрезе месяцев:

-- a.	средняя сумма чека в месяц;
SELECT 
    DATE_TRUNC('month', t.date_new) AS month,
    AVG(t.sum_payment) AS avg_check
FROM 
    transactions_info AS t
WHERE 
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    DATE_TRUNC('month', t.date_new)
ORDER BY 
    month;


-- b.	среднее количество операций в месяц;
SELECT 
    DATE_TRUNC('month', t.date_new) AS month,
    COUNT(t.id_check) / 12 AS avg_operations_per_month
FROM 
    transactions_info AS t
WHERE 
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    DATE_TRUNC('month', t.date_new)
ORDER BY 
    month;


-- c.	среднее количество клиентов, которые совершали операции;
SELECT 
    DATE_TRUNC('month', t.date_new) AS month,
    COUNT(DISTINCT t.id_client) AS total_clients
FROM 
    transactions_info AS t
WHERE 
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    DATE_TRUNC('month', t.date_new)
ORDER BY 
    month;


-- d.	долю от общего количества операций за год и долю в месяц от общей суммы операций;
WITH yearly_totals AS (
    SELECT 
        COUNT(t.id_check) AS total_operations
    FROM 
        transactions_info AS t
    WHERE 
        t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
)
SELECT 
    DATE_TRUNC('month', t.date_new) AS month,
    COUNT(t.id_check) AS operations_in_month,
    ROUND((COUNT(t.id_check)::decimal / yt.total_operations) * 100, 2) AS operations_share
FROM 
    transactions_info AS t,
    yearly_totals AS yt
WHERE 
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    DATE_TRUNC('month', t.date_new), yt.total_operations
ORDER BY 
    month;



-- e.	вывести % соотношение M/F/NA в каждом месяце с их долей затрат;
SELECT 
    DATE_TRUNC('month', t.date_new) AS month,
    ROUND((SUM(CASE WHEN c.gender = 'M' THEN t.sum_payment ELSE 0 END)::decimal / SUM(t.sum_payment)) * 100, 2) AS male_share,
    ROUND((SUM(CASE WHEN c.gender = 'F' THEN t.sum_payment ELSE 0 END)::decimal / SUM(t.sum_payment)) * 100, 2) AS female_share,
    ROUND((SUM(CASE WHEN c.gender IS NULL OR c.gender = 'NA' THEN t.sum_payment ELSE 0 END)::decimal / SUM(t.sum_payment)) * 100, 2) AS na_share
FROM 
    transactions_info AS t
JOIN 
    customer_info AS c ON t.id_client = c.id_client
WHERE 
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    DATE_TRUNC('month', t.date_new)
ORDER BY 
    month;


-------------------------------------------------------------------------------------------------------------

-- 3.	возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
-- с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.


-- a. Сумма и количество операций за весь период для возрастных групп с шагом 10 лет и клиентов 
-- без информации о возрасте:

SELECT
    CASE 
        WHEN c.age IS NULL THEN 'No age info'
        WHEN c.age BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.age >= 70 THEN '70+'
    END AS age_group,
    SUM(t.sum_payment) AS total_sum,
    COUNT(t.id_check) AS total_operations
FROM
    customer_info AS c
JOIN
    transactions_info AS t ON c.id_client = t.id_client
WHERE
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY
    age_group
ORDER BY
    age_group;


-- b. Средние показатели поквартально для каждой возрастной группы:
SELECT
    CASE 
        WHEN c.age IS NULL THEN 'No age info'
        WHEN c.age BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.age >= 70 THEN '70+'
    END AS age_group,
    DATE_TRUNC('quarter', t.date_new) AS quarter,
    AVG(t.sum_payment) AS avg_sum_per_quarter,
    COUNT(t.id_check) AS total_operations,
    ROUND((COUNT(t.id_check)::decimal / (SELECT COUNT(*) FROM transactions_info WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01')) * 100, 2) AS operations_share
FROM
    customer_info AS c
JOIN
    transactions_info AS t ON c.id_client = t.id_client
WHERE
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY
    age_group, DATE_TRUNC('quarter', t.date_new)
ORDER BY
    age_group, quarter;


