-- DAY 3: TASK 7
-- Step 7A: Validate Customer Geographic Data

SELECT
    COUNT(*) AS total_customer_records,

    COUNT(DISTINCT customer_unique_id)
        AS unique_customers,

    COUNT(DISTINCT customer_state)
        AS total_states,

    COUNT(DISTINCT customer_city)
        AS total_cities,

    COUNT(*) FILTER (
        WHERE customer_state IS NULL
           OR TRIM(customer_state) = ''
    ) AS missing_state_records,

    COUNT(*) FILTER (
        WHERE customer_city IS NULL
           OR TRIM(customer_city) = ''
    ) AS missing_city_records,

    COUNT(*) FILTER (
        WHERE customer_zip_code_prefix IS NULL
    ) AS missing_zip_records,

    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
    ) AS missing_unique_customer_ids

FROM olist.customers;

-- DAY 3: TASK 7
-- Step 7B: Customer Distribution by State

SELECT
    c.customer_state AS state,

    COUNT(DISTINCT c.customer_unique_id)
        AS unique_customers,

    COUNT(DISTINCT o.order_id)
        AS total_orders,

    ROUND(
        100.0 * COUNT(DISTINCT o.order_id)
        / SUM(COUNT(DISTINCT o.order_id)) OVER (),
        2
    ) AS order_share_pct,

    RANK() OVER (
        ORDER BY COUNT(DISTINCT o.order_id) DESC
    ) AS state_rank

FROM analytics.vw_order_summary AS o

INNER JOIN olist.customers AS c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_state

ORDER BY total_orders DESC;

-- DAY 3: TASK 7
-- Step 7C: State-Level Revenue Analysis

SELECT
    c.customer_state AS state,

    COUNT(DISTINCT o.order_id)
        AS delivered_orders,

    ROUND(
        SUM(o.total_product_value), 2
    ) AS product_sales,

    ROUND(
        SUM(o.total_freight_value), 2
    ) AS freight_value,

    ROUND(
        SUM(o.total_item_value), 2
    ) AS total_item_value,

    ROUND(
        SUM(o.total_item_value)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS avg_order_value,

    ROUND(
        100.0 * SUM(o.total_item_value)
        / SUM(SUM(o.total_item_value)) OVER (),
        2
    ) AS revenue_share_pct,

    RANK() OVER (
        ORDER BY SUM(o.total_item_value) DESC
    ) AS revenue_rank

FROM analytics.vw_order_summary AS o

INNER JOIN olist.customers AS c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_state

ORDER BY total_item_value DESC;


-- Step 7D: Validate State-Level Revenue

WITH state_revenue AS (
    SELECT
        c.customer_state AS state,

        COUNT(*) AS delivered_orders,

        SUM(o.total_product_value) AS product_sales,

        SUM(o.total_freight_value) AS freight_value,

        SUM(o.total_item_value) AS total_item_value

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_state
)

SELECT
    COUNT(*) AS total_states,

    SUM(delivered_orders) AS total_delivered_orders,

    ROUND(SUM(product_sales), 2)
        AS total_product_sales,

    ROUND(SUM(freight_value), 2)
        AS total_freight_value,

    ROUND(SUM(total_item_value), 2)
        AS total_item_value,

    COUNT(*) FILTER (
        WHERE delivered_orders <= 0
           OR total_item_value < 0
    ) AS invalid_states

FROM state_revenue;

-- DAY 3: TASK 7
-- Step 7E: Create Customer Geography View

CREATE OR REPLACE VIEW
analytics.vw_customer_geography AS

WITH state_summary AS (
    SELECT
        c.customer_state AS state,

        COUNT(DISTINCT c.customer_unique_id)
            AS unique_customers,

        COUNT(DISTINCT o.order_id)
            AS total_orders,

        COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
        ) AS delivered_orders,

        COALESCE(
            SUM(o.total_product_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ) AS product_sales,

        COALESCE(
            SUM(o.total_freight_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ) AS freight_value,

        COALESCE(
            SUM(o.total_item_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ) AS total_item_value

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_state
)

SELECT
    state,

    unique_customers,

    total_orders,

    delivered_orders,

    ROUND(product_sales, 2)
        AS product_sales,

    ROUND(freight_value, 2)
        AS freight_value,

    ROUND(total_item_value, 2)
        AS total_item_value,

    ROUND(
        total_item_value
        / NULLIF(delivered_orders, 0),
        2
    ) AS avg_order_value,

    ROUND(
        100.0 * total_orders
        / NULLIF(SUM(total_orders) OVER (), 0),
        2
    ) AS order_share_pct,

    ROUND(
        100.0 * total_item_value
        / NULLIF(SUM(total_item_value) OVER (), 0),
        2
    ) AS revenue_share_pct,

    RANK() OVER (
        ORDER BY total_item_value DESC
    ) AS revenue_rank

FROM state_summary;

-- DAY 3: TASK 7
-- Step 7F: Final Customer Geography Validation

SELECT
    COUNT(*) AS total_states,

    COUNT(DISTINCT state) AS unique_states,

    COUNT(*) - COUNT(DISTINCT state)
        AS duplicate_states,

    SUM(total_orders) AS total_orders,

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

    COUNT(*) FILTER (
        WHERE total_orders < delivered_orders
           OR delivered_orders < 0
           OR total_item_value < 0
           OR revenue_share_pct < 0
           OR revenue_share_pct > 100
           OR order_share_pct < 0
           OR order_share_pct > 100
    ) AS invalid_states,

    ROUND(
        SUM(order_share_pct), 2
    ) AS total_order_share_pct,

    ROUND(
        SUM(revenue_share_pct), 2
    ) AS total_revenue_share_pct

FROM analytics.vw_customer_geography;
