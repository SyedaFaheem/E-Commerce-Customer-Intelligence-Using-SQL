
SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'vw_product_categories_translated'
ORDER BY ordinal_position;

-- DAY 2: TASK 16
-- Step 16D.3: Correct existing category view

CREATE OR REPLACE VIEW analytics.vw_product_categories_translated AS

SELECT
    p.product_id,
    p.product_category_name,

    CASE
        WHEN p.product_category_name IS NULL
            THEN 'Unknown Category'

        WHEN t.product_category_name_english IS NOT NULL
            THEN t.product_category_name_english

        WHEN p.product_category_name = 'pc_gamer'
            THEN 'Gaming PC'

        WHEN p.product_category_name =
            'portateis_cozinha_e_preparadores_de_alimentos'
            THEN 'Portable Kitchen and Food Preparation Appliances'

        ELSE 'Untranslated Category'
    END AS category_english,

    CASE
        WHEN p.product_category_name IS NULL
            THEN 'Missing Category'

        WHEN t.product_category_name_english IS NOT NULL
            THEN 'Translated'

        WHEN p.product_category_name IN (
            'pc_gamer',
            'portateis_cozinha_e_preparadores_de_alimentos'
        )
            THEN 'Manual Translation'

        ELSE 'Untranslated'
    END AS translation_status

FROM olist.products AS p

LEFT JOIN olist.product_category_translation AS t
    ON p.product_category_name = t.product_category_name;

-- DAY 2: TASK 16
-- Step 16E: Final category validation

SELECT
    COUNT(*) AS total_products,

    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(*) FILTER (
        WHERE translation_status = 'Translated'
    ) AS translated_products,

    COUNT(*) FILTER (
        WHERE translation_status = 'Manual Translation'
    ) AS manually_translated_products,

    COUNT(*) FILTER (
        WHERE translation_status = 'Missing Category'
    ) AS missing_category_products,

    COUNT(*) FILTER (
        WHERE translation_status = 'Untranslated'
    ) AS untranslated_products,

    COUNT(*) FILTER (
        WHERE category_english IS NULL
    ) AS missing_english_labels

FROM analytics.vw_product_categories_translated;

-- DAY 2: TASK 17
-- Step 17A: Inspect existing analytical views

SELECT
    table_schema,
    table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'analytics'
ORDER BY table_name;

-- DAY 2: TASK 17
-- Step 17B: Inspect analytical view structures

SELECT
    table_name AS view_name,
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name IN (
      'vw_orders_clean',
      'vw_order_items_clean',
      'vw_order_payments_clean',
      'vw_products_clean',
      'vw_product_categories_translated'
  )
ORDER BY table_name, ordinal_position;

-- DAY 2: TASK 17
-- Step 17C: Inspect product view columns

SELECT
    table_name AS view_name,
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name IN (
      'vw_products_clean',
      'vw_product_categories_translated'
  )
ORDER BY table_name, ordinal_position;

-- DAY 2: TASK 17
-- Step 17D: Validate product join keys

SELECT
    'vw_products_clean' AS view_name,
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_records,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_ids
FROM analytics.vw_products_clean

UNION ALL

SELECT
    'vw_product_categories_translated',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id),
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    )
FROM analytics.vw_product_categories_translated;

-- DAY 2: TASK 17
-- Step 17E: Validate order relationships

SELECT
    'Orders' AS dataset,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id)
        AS additional_records,
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_ids
FROM analytics.vw_orders_clean

UNION ALL

SELECT
    'Order Items',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id),
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    )
FROM analytics.vw_order_items_clean

UNION ALL

SELECT
    'Order Payments',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id),
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    )
FROM analytics.vw_order_payments_clean;

-- DAY 2: TASK 17
-- Step 17F: Validate order coverage

WITH item_orders AS (
    SELECT DISTINCT order_id
    FROM analytics.vw_order_items_clean
),
payment_orders AS (
    SELECT DISTINCT order_id
    FROM analytics.vw_order_payments_clean
)
SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE i.order_id IS NOT NULL
    ) AS orders_with_items,

    COUNT(*) FILTER (
        WHERE i.order_id IS NULL
    ) AS orders_without_items,

    COUNT(*) FILTER (
        WHERE p.order_id IS NOT NULL
    ) AS orders_with_payments,

    COUNT(*) FILTER (
        WHERE p.order_id IS NULL
    ) AS orders_without_payments

FROM analytics.vw_orders_clean AS o

LEFT JOIN item_orders AS i
    ON o.order_id = i.order_id

LEFT JOIN payment_orders AS p
    ON o.order_id = p.order_id;

-- DAY 2: TASK 17
-- Step 17G: Investigate missing relationships

WITH item_orders AS (
    SELECT DISTINCT order_id
    FROM analytics.vw_order_items_clean
),
payment_orders AS (
    SELECT DISTINCT order_id
    FROM analytics.vw_order_payments_clean
)
SELECT
    o.order_status,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE i.order_id IS NULL
    ) AS orders_without_items,

    COUNT(*) FILTER (
        WHERE p.order_id IS NULL
    ) AS orders_without_payments,

    COUNT(*) FILTER (
        WHERE i.order_id IS NULL
          AND p.order_id IS NULL
    ) AS orders_missing_both

FROM analytics.vw_orders_clean AS o

LEFT JOIN item_orders AS i
    ON o.order_id = i.order_id

LEFT JOIN payment_orders AS p
    ON o.order_id = p.order_id

GROUP BY o.order_status
ORDER BY orders_without_items DESC;

-- DAY 2: TASK 17
-- Step 17H: Check orphaned records

SELECT
    'Order Items' AS dataset,
    COUNT(*) AS orphaned_records,
    COUNT(DISTINCT i.order_id) AS affected_orders
FROM analytics.vw_order_items_clean AS i
LEFT JOIN analytics.vw_orders_clean AS o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'Order Payments' AS dataset,
    COUNT(*) AS orphaned_records,
    COUNT(DISTINCT p.order_id) AS affected_orders
FROM analytics.vw_order_payments_clean AS p
LEFT JOIN analytics.vw_orders_clean AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- DAY 2: TASK 17
-- Step 17I: Create order level analytical view

CREATE OR REPLACE VIEW analytics.vw_order_summary AS

WITH item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS total_items,
        COUNT(DISTINCT product_id) AS unique_products,
        ROUND(SUM(price)::numeric, 2)
            AS total_product_value,
        ROUND(SUM(freight_value)::numeric, 2)
            AS total_freight_value,
        ROUND(SUM(total_item_value)::numeric, 2)
            AS total_item_value
    FROM analytics.vw_order_items_clean
    GROUP BY order_id
),

payment_summary AS (
    SELECT
        order_id,
        COUNT(*) AS total_payment_records,
        COUNT(DISTINCT payment_type)
            AS payment_methods_used,
        ROUND(SUM(payment_value)::numeric, 2)
            AS total_payment_value
    FROM analytics.vw_order_payments_clean
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.is_late_delivery,

    COALESCE(i.total_items, 0)
        AS total_items,

    COALESCE(i.unique_products, 0)
        AS unique_products,

    COALESCE(i.total_product_value, 0)
        AS total_product_value,

    COALESCE(i.total_freight_value, 0)
        AS total_freight_value,

    COALESCE(i.total_item_value, 0)
        AS total_item_value,

    COALESCE(p.total_payment_records, 0)
        AS total_payment_records,

    COALESCE(p.payment_methods_used, 0)
        AS payment_methods_used,

    COALESCE(p.total_payment_value, 0)
        AS total_payment_value,

    CASE
        WHEN i.order_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_items_flag,

    CASE
        WHEN p.order_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_payment_flag

FROM analytics.vw_orders_clean AS o

LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id

LEFT JOIN payment_summary AS p
    ON o.order_id = p.order_id;

-- DAY 2: TASK 17
-- Step 17J: Validate consolidated order summary

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_orders,

    COUNT(*) FILTER (
        WHERE missing_items_flag = TRUE
    ) AS orders_without_items,

    COUNT(*) FILTER (
        WHERE missing_payment_flag = TRUE
    ) AS orders_without_payments,

    SUM(total_items) AS total_items,

    SUM(total_payment_records)
        AS total_payment_records,

    ROUND(SUM(total_product_value), 2)
        AS total_product_value,

    ROUND(SUM(total_freight_value), 2)
        AS total_freight_value,

    ROUND(SUM(total_payment_value), 2)
        AS total_payment_value

FROM analytics.vw_order_summary;

-- DAY 2: TASK 18
-- Step 18A: Investigate payment differences

WITH reconciliation AS (
    SELECT
        order_id,
        order_status,
        total_item_value,
        total_payment_value,
        ROUND(
            total_payment_value - total_item_value,
            2
        ) AS payment_difference
    FROM analytics.vw_order_summary
)

SELECT
    order_status,
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE payment_difference = 0
    ) AS matching_orders,

    COUNT(*) FILTER (
        WHERE payment_difference > 0
    ) AS payments_higher,

    COUNT(*) FILTER (
        WHERE payment_difference < 0
    ) AS payments_lower,

    ROUND(SUM(payment_difference), 2)
        AS total_difference

FROM reconciliation
GROUP BY order_status
ORDER BY ABS(SUM(payment_difference)) DESC;

-- DAY 2: TASK 18
-- Step 18B: Investigate delivered order mismatches

WITH delivered_reconciliation AS (
    SELECT
        order_id,
        total_items,
        total_payment_records,
        total_item_value,
        total_payment_value,
        ROUND(
            total_payment_value - total_item_value,
            2
        ) AS payment_difference

    FROM analytics.vw_order_summary

    WHERE order_status = 'delivered'
)

SELECT
    COUNT(*) AS total_delivered_orders,

    COUNT(*) FILTER (
        WHERE payment_difference = 0
    ) AS matching_orders,

    COUNT(*) FILTER (
        WHERE payment_difference <> 0
    ) AS mismatched_orders,

    COUNT(*) FILTER (
        WHERE payment_difference > 0
    ) AS payments_higher,

    COUNT(*) FILTER (
        WHERE payment_difference < 0
    ) AS payments_lower,

    ROUND(
        SUM(ABS(payment_difference)), 2
    ) AS absolute_difference,

    ROUND(
        SUM(payment_difference), 2
    ) AS net_difference,

    ROUND(
        MAX(ABS(payment_difference)), 2
    ) AS largest_order_difference

FROM delivered_reconciliation;

-- DAY 2: TASK 18
-- Step 18C: Classify delivered payment differences

WITH payment_differences AS (
    SELECT
        order_id,
        total_item_value,
        total_payment_value,
        ROUND(
            total_payment_value - total_item_value,
            2
        ) AS payment_difference
    FROM analytics.vw_order_summary
    WHERE order_status = 'delivered'
),

classified_orders AS (
    SELECT
        *,
        CASE
            WHEN payment_difference = 0
                THEN 'Exact Match'

            WHEN ABS(payment_difference) <= 1
                THEN 'Small Difference (<= R$1)'

            WHEN ABS(payment_difference) <= 10
                THEN 'Moderate Difference (R$1 to R$10)'

            WHEN ABS(payment_difference) <= 100
                THEN 'Large Difference (R$10 to R$100)'

            ELSE 'Critical Difference (> R$100)'
        END AS difference_category
    FROM payment_differences
)

SELECT
    difference_category,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE payment_difference > 0
    ) AS payments_higher,

    COUNT(*) FILTER (
        WHERE payment_difference < 0
    ) AS payments_lower,

    ROUND(
        SUM(ABS(payment_difference)), 2
    ) AS absolute_difference,

    ROUND(
        SUM(payment_difference), 2
    ) AS net_difference

FROM classified_orders

GROUP BY difference_category

ORDER BY
    CASE difference_category
        WHEN 'Exact Match' THEN 1
        WHEN 'Small Difference (<= R$1)' THEN 2
        WHEN 'Moderate Difference (R$1 to R$10)' THEN 3
        WHEN 'Large Difference (R$10 to R$100)' THEN 4
        ELSE 5
    END;

-- DAY 2: TASK 18
-- Step 18D: Investigate critical payment discrepancies

SELECT
    order_id,
    order_status,
    total_items,
    total_payment_records,
    total_product_value,
    total_freight_value,
    total_item_value,
    total_payment_value,

    ROUND(
        total_payment_value - total_item_value,
        2
    ) AS payment_difference,

    missing_items_flag,
    missing_payment_flag

FROM analytics.vw_order_summary

WHERE order_status = 'delivered'
  AND ABS(
      total_payment_value - total_item_value
  ) > 100

ORDER BY
    ABS(
        total_payment_value - total_item_value
    ) DESC;

-- DAY 2: TASK 18
-- Step 18E: Create financial reconciliation view

CREATE OR REPLACE VIEW analytics.vw_order_financial_quality AS

WITH financial_checks AS (
    SELECT
        *,
        ROUND(
            total_payment_value - total_item_value,
            2
        ) AS payment_difference
    FROM analytics.vw_order_summary
)

SELECT
    order_id,
    order_status,
    total_items,
    total_payment_records,
    total_item_value,
    total_payment_value,
    payment_difference,
    missing_items_flag,
    missing_payment_flag,

    CASE
        WHEN missing_items_flag
            THEN 'Missing Items'

        WHEN missing_payment_flag
            THEN 'Missing Payment'

        WHEN payment_difference = 0
            THEN 'Exact Match'

        WHEN ABS(payment_difference) <= 1
            THEN 'Small Difference'

        WHEN ABS(payment_difference) <= 10
            THEN 'Moderate Difference'

        WHEN ABS(payment_difference) <= 100
            THEN 'Large Difference'

        ELSE 'Critical Difference'
    END AS financial_quality_status

FROM financial_checks;

-- DAY 2: TASK 18
-- Step 18F: Validate financial quality classifications

SELECT
    financial_quality_status,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status <> 'delivered'
    ) AS other_orders,

    ROUND(
        SUM(ABS(payment_difference)), 2
    ) AS absolute_difference,

    ROUND(
        SUM(payment_difference), 2
    ) AS net_difference

FROM analytics.vw_order_financial_quality

GROUP BY financial_quality_status

ORDER BY
    CASE financial_quality_status
        WHEN 'Exact Match' THEN 1
        WHEN 'Small Difference' THEN 2
        WHEN 'Moderate Difference' THEN 3
        WHEN 'Large Difference' THEN 4
        WHEN 'Critical Difference' THEN 5
        WHEN 'Missing Items' THEN 6
        WHEN 'Missing Payment' THEN 7
        ELSE 8
    END;

-- DAY 2: TASK 19
-- Step 19A: Validate reporting readiness

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_dates,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE order_status IS NULL
    ) AS missing_order_status,

    COUNT(*) FILTER (
        WHERE total_item_value < 0
    ) AS negative_item_values,

    COUNT(*) FILTER (
        WHERE total_payment_value < 0
    ) AS negative_payment_values,

    COUNT(*) FILTER (
        WHERE total_items = 0
    ) AS orders_without_items,

    COUNT(*) FILTER (
        WHERE total_payment_records = 0
    ) AS orders_without_payments

FROM analytics.vw_order_summary;

-- DAY 2: TASK 19
-- Step 19B: Validate monthly sales KPIs

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date AS order_month,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    ROUND(
        SUM(total_product_value), 2
    ) AS product_sales,

    ROUND(
        SUM(total_freight_value), 2
    ) AS freight_value,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    ROUND(
        SUM(total_payment_value), 2
    ) AS total_payment_value

FROM analytics.vw_order_summary

GROUP BY
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date

ORDER BY order_month;

-- DAY 2: TASK 19
-- Step 19C: Create monthly sales KPI view

CREATE OR REPLACE VIEW analytics.vw_monthly_sales_kpis AS

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date AS order_month,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'canceled'
    ) AS canceled_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'unavailable'
    ) AS unavailable_orders,

    ROUND(
        SUM(total_product_value), 2
    ) AS product_sales,

    ROUND(
        SUM(total_freight_value), 2
    ) AS freight_value,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    ROUND(
        SUM(total_payment_value), 2
    ) AS total_payment_value,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS delivery_rate_pct,

    ROUND(
        SUM(total_payment_value)
        / NULLIF(COUNT(*), 0), 2
    ) AS avg_payment_per_order,

    CASE
        WHEN DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date >= DATE '2018-09-01'
            THEN 'Review Coverage'
        ELSE 'Historical Period'
    END AS reporting_period_status

FROM analytics.vw_order_summary

GROUP BY
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date

ORDER BY order_month;

-- DAY 2: TASK 19
-- Step 19D: Validate monthly KPI view

SELECT
    COUNT(*) AS total_months,

    MIN(order_month) AS first_month,

    MAX(order_month) AS last_month,

    SUM(total_orders) AS total_orders,

    SUM(delivered_orders) AS delivered_orders,

    SUM(canceled_orders) AS canceled_orders,

    SUM(unavailable_orders) AS unavailable_orders,

    ROUND(
        SUM(product_sales), 2
    ) AS total_product_sales,

    ROUND(
        SUM(freight_value), 2
    ) AS total_freight,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    ROUND(
        SUM(total_payment_value), 2
    ) AS total_payment_value,

    COUNT(*) FILTER (
        WHERE reporting_period_status = 'Review Coverage'
    ) AS months_requiring_review

FROM analytics.vw_monthly_sales_kpis;

-- DAY 2: TASK 19
-- Step 19E: Verify reporting period flags

SELECT
    reporting_period_status,
    COUNT(*) AS total_months,
    SUM(total_orders) AS total_orders
FROM analytics.vw_monthly_sales_kpis
GROUP BY reporting_period_status
ORDER BY reporting_period_status;

-- DAY 2: TASK 20
-- Step 20A: Audit analytical views

SELECT
    table_schema,
    table_name AS view_name,
    CASE
        WHEN table_name IN (
            'vw_orders_clean',
            'vw_orders_flagged',
            'vw_order_items_clean',
            'vw_order_payments_clean',
            'vw_order_reviews_clean',
            'vw_products_clean',
            'vw_products_quality_flags',
            'vw_product_categories_translated',
            'vw_geolocation_clean',
            'vw_geolocation_state_flags',
            'vw_order_summary',
            'vw_order_financial_quality',
            'vw_monthly_sales_kpis'
        )
        THEN 'Expected View'
        ELSE 'Additional View'
    END AS audit_status

FROM information_schema.views

WHERE table_schema = 'analytics'

ORDER BY view_name;

-- DAY 2: TASK 20
-- Step 20B: Final data quality audit

SELECT
    'Order Summary' AS dataset,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_records,
    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_records
FROM analytics.vw_order_summary

UNION ALL

SELECT
    'Financial Quality',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id)
FROM analytics.vw_order_financial_quality

UNION ALL

SELECT
    'Monthly Sales KPIs',
    COUNT(*),
    COUNT(DISTINCT order_month),
    COUNT(*) - COUNT(DISTINCT order_month)
FROM analytics.vw_monthly_sales_kpis

UNION ALL

SELECT
    'Products',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id)
FROM analytics.vw_products_clean

UNION ALL

SELECT
    'Product Categories',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id)
FROM analytics.vw_product_categories_translated;

-- DAY 2: TASK 20
-- Step 20C: Final financial consistency check

WITH source_totals AS (
    SELECT
        COUNT(*) AS total_orders,
        SUM(total_item_value) AS item_value,
        SUM(total_payment_value) AS payment_value
    FROM analytics.vw_order_summary
),

quality_totals AS (
    SELECT
        COUNT(*) AS total_orders,
        SUM(total_item_value) AS item_value,
        SUM(total_payment_value) AS payment_value
    FROM analytics.vw_order_financial_quality
),

monthly_totals AS (
    SELECT
        SUM(total_orders) AS total_orders,
        SUM(total_item_value) AS item_value,
        SUM(total_payment_value) AS payment_value
    FROM analytics.vw_monthly_sales_kpis
)

SELECT
    s.total_orders AS source_orders,
    q.total_orders AS quality_orders,
    m.total_orders AS monthly_orders,

    ROUND(s.item_value, 2) AS source_item_value,
    ROUND(q.item_value, 2) AS quality_item_value,
    ROUND(m.item_value, 2) AS monthly_item_value,

    ROUND(s.payment_value, 2) AS source_payment_value,
    ROUND(q.payment_value, 2) AS quality_payment_value,
    ROUND(m.payment_value, 2) AS monthly_payment_value,

    CASE
        WHEN s.total_orders = q.total_orders
         AND s.total_orders = m.total_orders
         AND ROUND(s.item_value, 2) = ROUND(q.item_value, 2)
         AND ROUND(s.item_value, 2) = ROUND(m.item_value, 2)
         AND ROUND(s.payment_value, 2) = ROUND(q.payment_value, 2)
         AND ROUND(s.payment_value, 2) = ROUND(m.payment_value, 2)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS final_validation_status

FROM source_totals AS s
CROSS JOIN quality_totals AS q
CROSS JOIN monthly_totals AS m;
