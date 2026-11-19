

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'olist'
ORDER BY table_name;

SELECT 'customers' AS table_name,
       COUNT(*) AS total_rows
FROM olist.customers

UNION ALL

SELECT 'orders' AS table_name,
       COUNT(*) AS total_rows
FROM olist.orders;


-- Check tables in the Olist schema
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'olist'
ORDER BY table_name;

-- Verify customers and orders
SELECT 'customers' AS table_name,
       COUNT(*) AS total_rows
FROM olist.customers

UNION ALL

SELECT 'orders' AS table_name,
       COUNT(*) AS total_rows
FROM olist.orders;

-- Preview customers
SELECT *
FROM olist.customers
LIMIT 5;

-- Preview orders
SELECT *
FROM olist.orders
LIMIT 5;
