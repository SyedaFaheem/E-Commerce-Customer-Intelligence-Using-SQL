
SELECT 'customers' AS table_name, COUNT(*) AS total_rows
FROM olist.customers
UNION ALL
SELECT 'orders', COUNT(*) FROM olist.orders
UNION ALL
SELECT 'products', COUNT(*) FROM olist.products
UNION ALL
SELECT 'product_category_translation', COUNT(*)
FROM olist.product_category_translation
UNION ALL
SELECT 'sellers', COUNT(*) FROM olist.sellers
UNION ALL
SELECT 'order_items', COUNT(*) FROM olist.order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM olist.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM olist.order_reviews
UNION ALL
SELECT 'geolocation', COUNT(*) FROM olist.geolocation
ORDER BY table_name;
