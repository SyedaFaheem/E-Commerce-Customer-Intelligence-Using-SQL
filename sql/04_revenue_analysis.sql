
--  TASK 1
-- Step 1A: Overall Business KPIs

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT customer_id)
        AS unique_customer_ids,

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
    ) AS total_product_sales,

    ROUND(
        SUM(total_freight_value), 2
    ) AS total_freight_value,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_order_item_value,

    ROUND(
        SUM(total_payment_value), 2
    ) AS total_payment_value,

    ROUND(
        AVG(total_payment_value), 2
    ) AS avg_payment_per_order,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS delivery_rate_pct

FROM analytics.vw_order_summary;


-- Step 1B: Delivered Order Business KPIs

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(DISTINCT customer_id)
        AS unique_customer_ids,

    SUM(total_items) AS total_items_sold,

    ROUND(
        SUM(total_product_value), 2
    ) AS delivered_product_sales,

    ROUND(
        SUM(total_freight_value), 2
    ) AS delivered_freight_value,

    ROUND(
        SUM(total_item_value), 2
    ) AS delivered_item_value,

    ROUND(
        SUM(total_payment_value), 2
    ) AS delivered_payment_value,

    ROUND(
        AVG(total_item_value), 2
    ) AS avg_item_value_per_order,

    ROUND(
        AVG(total_payment_value), 2
    ) AS avg_payment_per_order,

    ROUND(
        AVG(total_items), 2
    ) AS avg_items_per_order,

    COUNT(*) FILTER (
        WHERE missing_payment_flag = TRUE
    ) AS delivered_orders_missing_payment

FROM analytics.vw_order_summary

WHERE order_status = 'delivered';


-- Step 1C: Order Status Distribution

SELECT
    order_status,

    COUNT(*) AS total_orders,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    ROUND(
        SUM(total_payment_value), 2
    ) AS total_payment_value

FROM analytics.vw_order_summary

GROUP BY order_status

ORDER BY total_orders DESC;


-- Step 1D: Create overall business KPI view

CREATE OR REPLACE VIEW analytics.vw_business_kpis AS

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT customer_id)
        AS unique_customer_ids,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'canceled'
    ) AS canceled_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'unavailable'
    ) AS unavailable_orders,

    SUM(total_items) AS total_items,

    ROUND(
        SUM(total_product_value), 2
    ) AS total_product_sales,

    ROUND(
        SUM(total_freight_value), 2
    ) AS total_freight_value,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    ROUND(
        SUM(total_payment_value), 2
    ) AS total_payment_value,

    ROUND(
        AVG(total_payment_value), 2
    ) AS avg_payment_per_order,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS delivery_rate_pct

FROM analytics.vw_order_summary;

-- DAY 3: TASK 1
-- Step 1E: Validate overall business KPI view

SELECT
    total_orders,
    unique_customer_ids,
    delivered_orders,
    canceled_orders,
    unavailable_orders,
    total_items,
    total_product_sales,
    total_freight_value,
    total_item_value,
    total_payment_value,
    avg_payment_per_order,
    delivery_rate_pct

FROM analytics.vw_business_kpis;

-- DAY 3: TASK 2
-- Step 2A: Monthly Delivered Sales Analysis

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date AS order_month,

    COUNT(*) AS delivered_orders,

    SUM(total_items) AS items_sold,

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
        AVG(total_item_value), 2
    ) AS avg_order_value

FROM analytics.vw_order_summary

WHERE order_status = 'delivered'

GROUP BY
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date

ORDER BY order_month;

-- TASK 2
-- Step 2A: Monthly Delivered Sales Analysis

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date AS order_month,

    COUNT(*) AS delivered_orders,

    SUM(total_items) AS items_sold,

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
        AVG(total_item_value), 2
    ) AS avg_order_value

FROM analytics.vw_order_summary

WHERE order_status = 'delivered'

GROUP BY
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date

ORDER BY order_month;

-- Step 2B: Rank monthly delivered sales

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month,

        COUNT(*) AS delivered_orders,

        ROUND(
            SUM(total_product_value), 2
        ) AS product_sales,

        ROUND(
            SUM(total_item_value), 2
        ) AS total_item_value,

        ROUND(
            AVG(total_item_value), 2
        ) AS avg_order_value

    FROM analytics.vw_order_summary

    WHERE order_status = 'delivered'

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date
)

SELECT
    order_month,
    delivered_orders,
    product_sales,
    total_item_value,
    avg_order_value,

    RANK() OVER (
        ORDER BY product_sales DESC
    ) AS sales_rank,

    RANK() OVER (
        ORDER BY product_sales ASC
    ) AS lowest_sales_rank

FROM monthly_sales

WHERE delivered_orders >= 100

ORDER BY sales_rank;


-- Step 2C: Month-over-Month Sales Growth

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month,

        COUNT(*) AS delivered_orders,

        ROUND(
            SUM(total_product_value), 2
        ) AS product_sales

    FROM analytics.vw_order_summary

    WHERE order_status = 'delivered'

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date
),

monthly_growth AS (
    SELECT
        order_month,
        delivered_orders,
        product_sales,

        LAG(order_month) OVER (
            ORDER BY order_month
        ) AS previous_month,

        LAG(product_sales) OVER (
            ORDER BY order_month
        ) AS previous_month_sales

    FROM monthly_sales

    WHERE delivered_orders >= 100
)

SELECT
    order_month,
    delivered_orders,
    product_sales,
    previous_month_sales,

    CASE
        WHEN previous_month =
             (order_month - INTERVAL '1 month')::date
         AND previous_month_sales > 0
        THEN ROUND(
            100.0 * (
                product_sales - previous_month_sales
            ) / previous_month_sales,
            2
        )
        ELSE NULL
    END AS mom_growth_pct

FROM monthly_growth

ORDER BY order_month;


-- Step 2D: Create monthly delivered sales trend view

CREATE OR REPLACE VIEW analytics.vw_monthly_sales_trends AS

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month,

        COUNT(*) AS delivered_orders,

        SUM(total_items) AS items_sold,

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
            AVG(total_item_value), 2
        ) AS avg_order_value

    FROM analytics.vw_order_summary

    WHERE order_status = 'delivered'

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date
),

monthly_growth AS (
    SELECT
        *,

        LAG(order_month) OVER (
            ORDER BY order_month
        ) AS previous_month,

        LAG(product_sales) OVER (
            ORDER BY order_month
        ) AS previous_month_sales

    FROM monthly_sales

    WHERE delivered_orders >= 100
)

SELECT
    order_month,
    delivered_orders,
    items_sold,
    product_sales,
    freight_value,
    total_item_value,
    total_payment_value,
    avg_order_value,

    CASE
        WHEN previous_month =
             (order_month - INTERVAL '1 month')::date
         AND previous_month_sales > 0
        THEN ROUND(
            100.0 * (
                product_sales - previous_month_sales
            ) / previous_month_sales,
            2
        )
        ELSE NULL
    END AS mom_growth_pct

FROM monthly_growth;



-- Step 2E: Validate monthly sales trends

SELECT
    COUNT(*) AS total_months,

    COUNT(DISTINCT order_month)
        AS unique_months,

    COUNT(*) - COUNT(DISTINCT order_month)
        AS duplicate_months,

    MIN(order_month) AS first_month,

    MAX(order_month) AS last_month,

    SUM(delivered_orders)
        AS total_delivered_orders,

    ROUND(
        SUM(product_sales), 2
    ) AS total_product_sales,

    COUNT(*) FILTER (
        WHERE mom_growth_pct > 0
    ) AS growth_months,

    COUNT(*) FILTER (
        WHERE mom_growth_pct < 0
    ) AS decline_months,

    COUNT(*) FILTER (
        WHERE mom_growth_pct IS NULL
    ) AS months_without_comparison,

    MAX(mom_growth_pct)
        AS highest_growth_pct,

    MIN(mom_growth_pct)
        AS largest_decline_pct

FROM analytics.vw_monthly_sales_trends;

--  TASK 3
-- Step 3A: Monthly Sales Growth Analysis

WITH monthly_sales AS (
    SELECT
        order_month,
        delivered_orders,
        product_sales,
        mom_growth_pct,

        LAG(product_sales) OVER (
            ORDER BY order_month
        ) AS previous_month_sales

    FROM analytics.vw_monthly_sales_trends
)

SELECT
    order_month,
    delivered_orders,
    product_sales,
    previous_month_sales,

    CASE
        WHEN mom_growth_pct IS NOT NULL
        THEN ROUND(
            product_sales - previous_month_sales,
            2
        )
        ELSE NULL
    END AS sales_change_value,

    mom_growth_pct,

    CASE
        WHEN mom_growth_pct > 0 THEN 'Growth'
        WHEN mom_growth_pct < 0 THEN 'Decline'
        ELSE 'No Comparison'
    END AS growth_status

FROM monthly_sales

ORDER BY order_month;


-- Step 3B: Rank Monthly Sales Growth

WITH monthly_changes AS (
    SELECT
        order_month,
        delivered_orders,
        product_sales,
        mom_growth_pct,

        LAG(product_sales) OVER (
            ORDER BY order_month
        ) AS previous_month_sales

    FROM analytics.vw_monthly_sales_trends
),

valid_changes AS (
    SELECT
        order_month,
        delivered_orders,
        product_sales,
        mom_growth_pct,

        ROUND(
            product_sales - previous_month_sales,
            2
        ) AS sales_change_value

    FROM monthly_changes

    WHERE mom_growth_pct IS NOT NULL
)

SELECT
    order_month,
    delivered_orders,
    product_sales,
    sales_change_value,
    mom_growth_pct,

    RANK() OVER (
        ORDER BY mom_growth_pct DESC
    ) AS growth_pct_rank,

    RANK() OVER (
        ORDER BY sales_change_value DESC
    ) AS sales_change_rank

FROM valid_changes

ORDER BY growth_pct_rank;


-- Step 3C: Monthly Sales Growth Consistency

SELECT
    COUNT(*) AS total_months,

    COUNT(mom_growth_pct)
        AS comparable_months,

    COUNT(*) FILTER (
        WHERE mom_growth_pct > 0
    ) AS growth_months,

    COUNT(*) FILTER (
        WHERE mom_growth_pct < 0
    ) AS decline_months,

    ROUND(
        AVG(mom_growth_pct), 2
    ) AS avg_mom_growth_pct,

    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY mom_growth_pct
        )::numeric, 2
    ) AS median_mom_growth_pct,

    ROUND(
        STDDEV_SAMP(mom_growth_pct), 2
    ) AS growth_volatility_pct,

    MAX(mom_growth_pct)
        AS highest_growth_pct,

    MIN(mom_growth_pct)
        AS lowest_growth_pct

FROM analytics.vw_monthly_sales_trends;


-- Step 3D: Create monthly growth performance view

CREATE OR REPLACE VIEW
analytics.vw_monthly_growth_performance AS

WITH monthly_changes AS (
    SELECT
        order_month,
        delivered_orders,
        product_sales,
        avg_order_value,
        mom_growth_pct,

        LAG(product_sales) OVER (
            ORDER BY order_month
        ) AS previous_month_sales

    FROM analytics.vw_monthly_sales_trends
)

SELECT
    order_month,
    delivered_orders,
    product_sales,
    avg_order_value,
    previous_month_sales,

    CASE
        WHEN mom_growth_pct IS NOT NULL
        THEN ROUND(
            product_sales - previous_month_sales,
            2
        )
        ELSE NULL
    END AS sales_change_value,

    mom_growth_pct,

    CASE
        WHEN mom_growth_pct IS NULL
            THEN 'No Comparison'

        WHEN mom_growth_pct >= 20
            THEN 'High Growth'

        WHEN mom_growth_pct > 0
            THEN 'Moderate Growth'

        WHEN mom_growth_pct = 0
            THEN 'Stable'

        WHEN mom_growth_pct >= -10
            THEN 'Moderate Decline'

        ELSE 'High Decline'
    END AS growth_performance_status

FROM monthly_changes;


-- Step 3E: Validate growth performance classifications

SELECT
    growth_performance_status,

    COUNT(*) AS total_months,

    ROUND(
        AVG(mom_growth_pct), 2
    ) AS avg_growth_pct,

    MIN(mom_growth_pct) AS lowest_growth_pct,

    MAX(mom_growth_pct) AS highest_growth_pct,

    ROUND(
        SUM(sales_change_value), 2
    ) AS total_sales_change

FROM analytics.vw_monthly_growth_performance

GROUP BY growth_performance_status

ORDER BY
    CASE growth_performance_status
        WHEN 'High Growth' THEN 1
        WHEN 'Moderate Growth' THEN 2
        WHEN 'Stable' THEN 3
        WHEN 'Moderate Decline' THEN 4
        WHEN 'High Decline' THEN 5
        WHEN 'No Comparison' THEN 6
        ELSE 7
    END;

-- TASK 4
-- Step 4A: Monthly Average Order Value Analysis

SELECT
    order_month,

    delivered_orders,

    product_sales,

    total_item_value,

    avg_order_value,

    ROUND(
        product_sales
        / NULLIF(delivered_orders, 0),
        2
    ) AS avg_product_value_per_order,

    ROUND(
        freight_value
        / NULLIF(delivered_orders, 0),
        2
    ) AS avg_freight_per_order,

    ROUND(
        100.0 * freight_value
        / NULLIF(total_item_value, 0),
        2
    ) AS freight_share_pct

FROM analytics.vw_monthly_sales_trends

ORDER BY order_month;


-- Step 4B: Rank Monthly Average Order Value

SELECT
    order_month,

    delivered_orders,

    avg_order_value,

    ROUND(
        product_sales
        / NULLIF(delivered_orders, 0),
        2
    ) AS avg_product_value,

    ROUND(
        freight_value
        / NULLIF(delivered_orders, 0),
        2
    ) AS avg_freight_value,

    ROUND(
        100.0 * freight_value
        / NULLIF(total_item_value, 0),
        2
    ) AS freight_share_pct,

    RANK() OVER (
        ORDER BY avg_order_value DESC
    ) AS highest_aov_rank,

    RANK() OVER (
        ORDER BY avg_order_value ASC
    ) AS lowest_aov_rank

FROM analytics.vw_monthly_sales_trends

ORDER BY highest_aov_rank;


-- Step 4C: Seasonal Sales Analysis

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month,

        EXTRACT(
            MONTH FROM order_purchase_timestamp
        )::int AS month_number,

        COUNT(*) AS delivered_orders,

        SUM(total_product_value)
            AS product_sales,

        SUM(total_item_value)
            AS total_item_value

    FROM analytics.vw_order_summary

    WHERE order_status = 'delivered'

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date,
        EXTRACT(
            MONTH FROM order_purchase_timestamp
        )::int
)

SELECT
    month_number,

    TO_CHAR(
        MAKE_DATE(2024, month_number, 1),
        'FMMonth'
    ) AS month_name,

    COUNT(*) AS years_with_data,

    SUM(delivered_orders) AS total_orders,

    ROUND(
        SUM(product_sales), 2
    ) AS total_product_sales,

    ROUND(
        AVG(product_sales), 2
    ) AS avg_monthly_product_sales,

    ROUND(
        SUM(total_item_value)
        / NULLIF(SUM(delivered_orders), 0),
        2
    ) AS avg_order_value

FROM monthly_sales

GROUP BY month_number

ORDER BY month_number;


-- Step 4D: Year-over-Year Sales Comparison

WITH monthly_sales AS (
    SELECT
        EXTRACT(
            YEAR FROM order_purchase_timestamp
        )::int AS order_year,

        EXTRACT(
            MONTH FROM order_purchase_timestamp
        )::int AS order_month,

        COUNT(*) AS delivered_orders,

        SUM(total_product_value)
            AS product_sales

    FROM analytics.vw_order_summary

    WHERE order_status = 'delivered'

      AND order_purchase_timestamp >= '2017-01-01'

      AND order_purchase_timestamp < '2018-09-01'

    GROUP BY
        EXTRACT(YEAR FROM order_purchase_timestamp),
        EXTRACT(MONTH FROM order_purchase_timestamp)
)

SELECT
    order_month,

    MAX(delivered_orders) FILTER (
        WHERE order_year = 2017
    ) AS orders_2017,

    MAX(delivered_orders) FILTER (
        WHERE order_year = 2018
    ) AS orders_2018,

    ROUND(
        MAX(product_sales) FILTER (
            WHERE order_year = 2017
        ), 2
    ) AS sales_2017,

    ROUND(
        MAX(product_sales) FILTER (
            WHERE order_year = 2018
        ), 2
    ) AS sales_2018,

    ROUND(
        100.0 * (
            MAX(product_sales) FILTER (
                WHERE order_year = 2018
            )
            -
            MAX(product_sales) FILTER (
                WHERE order_year = 2017
            )
        )
        / NULLIF(
            MAX(product_sales) FILTER (
                WHERE order_year = 2017
            ), 0
        ),
        2
    ) AS yoy_sales_growth_pct

FROM monthly_sales

WHERE order_month BETWEEN 1 AND 8

GROUP BY order_month

ORDER BY order_month;


-- Step 4E: Create Seasonal Sales Performance View

CREATE OR REPLACE VIEW
analytics.vw_seasonal_sales_performance AS

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month,

        EXTRACT(
            YEAR FROM order_purchase_timestamp
        )::int AS order_year,

        EXTRACT(
            MONTH FROM order_purchase_timestamp
        )::int AS month_number,

        COUNT(*) AS delivered_orders,

        SUM(total_product_value)
            AS product_sales,

        SUM(total_freight_value)
            AS freight_value,

        SUM(total_item_value)
            AS total_item_value

    FROM analytics.vw_order_summary

    WHERE order_status = 'delivered'

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date,
        EXTRACT(
            YEAR FROM order_purchase_timestamp
        ),
        EXTRACT(
            MONTH FROM order_purchase_timestamp
        )
)

SELECT
    order_month,
    order_year,
    month_number,

    TO_CHAR(
        order_month,
        'FMMonth'
    ) AS month_name,

    delivered_orders,

    ROUND(
        product_sales, 2
    ) AS product_sales,

    ROUND(
        freight_value, 2
    ) AS freight_value,

    ROUND(
        total_item_value, 2
    ) AS total_item_value,

    ROUND(
        total_item_value
        / NULLIF(delivered_orders, 0),
        2
    ) AS avg_order_value,

    ROUND(
        freight_value
        / NULLIF(delivered_orders, 0),
        2
    ) AS avg_freight_per_order,

    ROUND(
        100.0 * freight_value
        / NULLIF(total_item_value, 0),
        2
    ) AS freight_share_pct

FROM monthly_sales;


-- Step 4F: Validate Seasonal Sales Performance View

SELECT
    COUNT(*) AS total_months,

    COUNT(DISTINCT order_month)
        AS unique_months,

    COUNT(*) - COUNT(DISTINCT order_month)
        AS duplicate_months,

    MIN(order_month) AS first_month,

    MAX(order_month) AS last_month,

    SUM(delivered_orders) AS total_delivered_orders,

    ROUND(
        SUM(product_sales), 2
    ) AS total_product_sales,

    ROUND(
        SUM(freight_value), 2
    ) AS total_freight_value,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    COUNT(DISTINCT order_year)
        AS years_represented,

    COUNT(*) FILTER (
        WHERE delivered_orders < 100
    ) AS sparse_months

FROM analytics.vw_seasonal_sales_performance;

