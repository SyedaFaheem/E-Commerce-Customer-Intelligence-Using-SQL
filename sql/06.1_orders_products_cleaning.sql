
CREATE SCHEMA IF NOT EXISTS analytics;

SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN ('olist', 'analytics')
ORDER BY schema_name;

SELECT
    table_schema,
    COUNT(*) AS base_table_count
FROM information_schema.tables
WHERE table_schema IN ('olist', 'analytics')
  AND table_type = 'BASE TABLE'
GROUP BY table_schema
ORDER BY table_schema;

SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN ('olist', 'analytics')
ORDER BY schema_name;

SELECT *
FROM olist.products
LIMIT 10;

SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'olist'
  AND table_name = 'products'
ORDER BY ordinal_position;

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_categories,

    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weights,

    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
    ) AS missing_lengths,

    COUNT(*) FILTER (
        WHERE product_height_cm IS NULL
    ) AS missing_heights,

    COUNT(*) FILTER (
        WHERE product_width_cm IS NULL
    ) AS missing_widths

FROM olist.products;

CREATE OR REPLACE VIEW analytics.vw_products_clean AS
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,

    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,

    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    CASE
        WHEN p.product_category_name IS NULL
        THEN 'Missing Category'
        WHEN t.product_category_name_english IS NULL
        THEN 'Missing Translation'
        ELSE 'Complete'
    END AS category_quality_status,

    CASE
        WHEN p.product_weight_g IS NULL
          OR p.product_length_cm IS NULL
          OR p.product_height_cm IS NULL
          OR p.product_width_cm IS NULL
        THEN 'Incomplete'
        ELSE 'Complete'
    END AS dimension_quality_status

FROM olist.products p
LEFT JOIN olist.product_category_translation t
    ON p.product_category_name =
       t.product_category_name;

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_products,

    COUNT(*) FILTER (
        WHERE category_quality_status = 'Complete'
    ) AS complete_categories,

    COUNT(*) FILTER (
        WHERE category_quality_status = 'Missing Category'
    ) AS missing_categories,

    COUNT(*) FILTER (
        WHERE category_quality_status = 'Missing Translation'
    ) AS missing_translations,

    COUNT(*) FILTER (
        WHERE dimension_quality_status = 'Incomplete'
    ) AS incomplete_dimensions

FROM analytics.vw_products_clean;

SELECT *
FROM olist.orders
LIMIT 10;

SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'olist'
  AND table_name = 'orders'
ORDER BY ordinal_position;

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_orders,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE order_status IS NULL
    ) AS missing_statuses,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_dates,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_dates,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_dates

FROM olist.orders;

SELECT
    order_status,
    COUNT(*) AS total_orders,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_dates

FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NULL
    ) AS delivered_without_delivery_date,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              < order_purchase_timestamp
    ) AS delivery_before_purchase,

    COUNT(*) FILTER (
        WHERE order_approved_at
              < order_purchase_timestamp
    ) AS approval_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date
              < order_purchase_timestamp
    ) AS carrier_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              < order_delivered_carrier_date
    ) AS delivery_before_carrier,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_deliveries

FROM olist.orders;

SELECT
    order_status,
    COUNT(*) AS affected_orders
FROM olist.orders
WHERE order_delivered_carrier_date
      < order_purchase_timestamp
GROUP BY order_status
ORDER BY affected_orders DESC;

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date,

    ROUND(
        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp
                - order_delivered_carrier_date
            )
        ) / 3600.0,
        2
    ) AS hours_before_purchase

FROM olist.orders

WHERE order_delivered_carrier_date
      < order_purchase_timestamp

ORDER BY hours_before_purchase DESC

LIMIT 20;

WITH timestamp_issues AS (
    SELECT
        order_id,
        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp
                - order_delivered_carrier_date
            )
        ) / 3600.0 AS hours_difference
    FROM olist.orders
    WHERE order_delivered_carrier_date
          < order_purchase_timestamp
)

SELECT
    COUNT(*) AS total_affected_orders,

    COUNT(*) FILTER (
        WHERE hours_difference < 1
    ) AS under_1_hour,

    COUNT(*) FILTER (
        WHERE hours_difference >= 1
          AND hours_difference < 24
    ) AS between_1_and_24_hours,

    COUNT(*) FILTER (
        WHERE hours_difference >= 24
    ) AS over_24_hours

FROM timestamp_issues;

CREATE OR REPLACE VIEW analytics.vw_orders_clean AS

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    CASE
        WHEN order_status = 'delivered'
             AND order_delivered_customer_date IS NULL
        THEN 'Missing Delivery Date'

        WHEN order_delivered_customer_date
             < order_purchase_timestamp
        THEN 'Delivery Before Purchase'

        WHEN order_approved_at
             < order_purchase_timestamp
        THEN 'Approval Before Purchase'

        WHEN order_delivered_carrier_date
             < order_purchase_timestamp
        THEN 'Carrier Before Purchase'

        WHEN order_delivered_customer_date
             < order_delivered_carrier_date
        THEN 'Delivery Before Carrier'

        ELSE 'Valid'
    END AS timestamp_quality_status,

    CASE
        WHEN order_delivered_carrier_date
             < order_purchase_timestamp
        THEN TRUE
        ELSE FALSE
    END AS carrier_timestamp_issue,

    CASE
        WHEN order_status = 'delivered'
             AND order_delivered_customer_date
                 > order_estimated_delivery_date
        THEN TRUE
        ELSE FALSE
    END AS is_late_delivery,

    CASE
        WHEN order_status = 'delivered'
             AND order_delivered_customer_date IS NOT NULL
        THEN EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )
        ) / 86400.0
        ELSE NULL
    END AS delivery_days

FROM olist.orders;

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_orders

FROM analytics.vw_orders_clean;

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE carrier_timestamp_issue = TRUE
    ) AS carrier_timestamp_issues,

    COUNT(*) FILTER (
        WHERE is_late_delivery = TRUE
    ) AS late_deliveries,

    COUNT(*) FILTER (
        WHERE delivery_days < 0
    ) AS negative_delivery_days,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND delivery_days IS NULL
    ) AS delivered_without_duration

FROM analytics.vw_orders_clean;

SELECT
    order_id,
    order_status,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    is_late_delivery
FROM analytics.vw_orders_clean
WHERE order_delivered_customer_date >
      order_estimated_delivery_date
  AND is_late_delivery IS DISTINCT FROM TRUE;

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE is_late_delivery = TRUE
    ) AS late_deliveries,

    COUNT(*) FILTER (
        WHERE is_late_delivery = FALSE
    ) AS not_late_deliveries,

    COUNT(*) FILTER (
        WHERE is_late_delivery IS DISTINCT FROM
            (
                order_delivered_customer_date >
                order_estimated_delivery_date
            )
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
    ) AS incorrect_late_flags

FROM analytics.vw_orders_clean
WHERE order_status = 'delivered';

SELECT
    (SELECT COUNT(*)
     FROM olist.orders) AS source_orders,

    (SELECT COUNT(*)
     FROM analytics.vw_orders_clean) AS cleaned_orders,

    (SELECT COUNT(*)
     FROM (
         SELECT order_id FROM olist.orders
         EXCEPT
         SELECT order_id FROM analytics.vw_orders_clean
     ) AS missing) AS missing_order_ids,

    (SELECT COUNT(*)
     FROM (
         SELECT order_id FROM analytics.vw_orders_clean
         EXCEPT
         SELECT order_id FROM olist.orders
     ) AS extra) AS extra_order_ids;

SELECT
    table_schema,
    table_name,
    view_definition IS NOT NULL AS definition_available
FROM information_schema.views
WHERE table_schema = 'analytics'
ORDER BY table_name;

SELECT
    'Orders' AS dataset,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_ids
FROM analytics.vw_orders_clean

UNION ALL

SELECT
    'Products' AS dataset,
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id) AS unique_ids
FROM analytics.vw_products_clean;

SELECT
    timestamp_quality_status,
    COUNT(*) AS total_orders
FROM analytics.vw_orders_clean
GROUP BY timestamp_quality_status
ORDER BY total_orders DESC;

SELECT
    category_quality_status,
    COUNT(*) AS total_products
FROM analytics.vw_products_clean
GROUP BY category_quality_status
ORDER BY total_products DESC;

SELECT
    dimension_quality_status,
    COUNT(*) AS total_products
FROM analytics.vw_products_clean
GROUP BY dimension_quality_status
ORDER BY total_products DESC;

SELECT
    'Orders' AS dataset,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_records,
    COUNT(*) FILTER (
        WHERE timestamp_quality_status <> 'Valid'
    ) AS flagged_records
FROM analytics.vw_orders_clean

UNION ALL

SELECT
    'Products' AS dataset,
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id) AS unique_records,
    COUNT(*) FILTER (
        WHERE category_quality_status <> 'Complete'
           OR dimension_quality_status <> 'Complete'
    ) AS flagged_records
FROM analytics.vw_products_clean;
