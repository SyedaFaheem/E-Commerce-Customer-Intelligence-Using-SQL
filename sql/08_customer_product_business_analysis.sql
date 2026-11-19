
-- DAY 3: TASK 8
-- Step 8A: Top 20 High-Value Customers

SELECT
    customer_unique_id,

    customer_type,

    total_orders,

    delivered_orders,

    delivered_product_spending,

    delivered_total_spending,

    avg_delivered_order_value,

    RANK() OVER (
        ORDER BY delivered_total_spending DESC
    ) AS spending_rank

FROM analytics.vw_customer_purchase_behavior

WHERE delivered_orders > 0

ORDER BY
    delivered_total_spending DESC,
    customer_unique_id

LIMIT 20;

-- DAY 3: TASK 8
-- Step 8B: Customer Spending Segmentation

WITH customer_segments AS (
    SELECT
        customer_unique_id,

        delivered_orders,

        delivered_total_spending,

        CASE
            WHEN delivered_total_spending < 100
                THEN 'Low Value'

            WHEN delivered_total_spending < 300
                THEN 'Medium Value'

            WHEN delivered_total_spending < 1000
                THEN 'High Value'

            ELSE 'VIP Customer'
        END AS spending_segment

    FROM analytics.vw_customer_purchase_behavior

    WHERE delivered_orders > 0
)

SELECT
    spending_segment,

    COUNT(*) AS customer_count,

    SUM(delivered_orders) AS delivered_orders,

    ROUND(
        SUM(delivered_total_spending), 2
    ) AS total_spending,

    ROUND(
        AVG(delivered_total_spending), 2
    ) AS avg_spending_per_customer,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(
        100.0 * SUM(delivered_total_spending)
        / SUM(SUM(delivered_total_spending)) OVER (),
        2
    ) AS revenue_share_pct

FROM customer_segments

GROUP BY spending_segment

ORDER BY
    CASE spending_segment
        WHEN 'VIP Customer' THEN 1
        WHEN 'High Value' THEN 2
        WHEN 'Medium Value' THEN 3
        WHEN 'Low Value' THEN 4
    END;


-- DAY 3: TASK 8
-- Step 8C: Customer Revenue Concentration
-- CORRECTED VERSION

WITH ranked_customers AS (
    SELECT
        customer_unique_id,
        delivered_total_spending,

        ROW_NUMBER() OVER (
            ORDER BY
                delivered_total_spending DESC,
                customer_unique_id
        ) AS customer_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(delivered_total_spending) OVER ()
            AS overall_spending

    FROM analytics.vw_customer_purchase_behavior

    WHERE delivered_orders > 0
),

customer_percentiles AS (
    SELECT
        *,

        100.0 * customer_rank
        / NULLIF(total_customers, 0)
            AS customer_rank_pct

    FROM ranked_customers
),

customer_groups AS (
    SELECT
        *,

        CASE
            WHEN customer_rank_pct <= 1
                THEN 'Top 1%'

            WHEN customer_rank_pct <= 5
                THEN 'Top 5%'

            WHEN customer_rank_pct <= 10
                THEN 'Top 10%'

            WHEN customer_rank_pct <= 20
                THEN 'Top 20%'

            ELSE 'Remaining 80%'
        END AS customer_group

    FROM customer_percentiles
)

SELECT
    customer_group,

    COUNT(*) AS customer_count,

    ROUND(
        SUM(delivered_total_spending), 2
    ) AS total_spending,

    ROUND(
        100.0 * SUM(delivered_total_spending)
        / NULLIF(MAX(overall_spending), 0),
        2
    ) AS revenue_share_pct

FROM customer_groups

GROUP BY customer_group

ORDER BY
    CASE customer_group
        WHEN 'Top 1%' THEN 1
        WHEN 'Top 5%' THEN 2
        WHEN 'Top 10%' THEN 3
        WHEN 'Top 20%' THEN 4
        ELSE 5
    END;

-- DAY 3: TASK 8
-- Step 8D: Repeat Customer Rate by Spending Segment

WITH customer_segments AS (
    SELECT
        customer_unique_id,
        customer_type,
        delivered_orders,
        delivered_total_spending,

        CASE
            WHEN delivered_total_spending < 100
                THEN 'Low Value'
            WHEN delivered_total_spending < 300
                THEN 'Medium Value'
            WHEN delivered_total_spending < 1000
                THEN 'High Value'
            ELSE 'VIP Customer'
        END AS spending_segment

    FROM analytics.vw_customer_purchase_behavior

    WHERE delivered_orders > 0
)

SELECT
    spending_segment,

    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE customer_type = 'One-Time Customer'
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE customer_type = 'Repeat Customer'
    ) AS repeat_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE customer_type = 'Repeat Customer'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate_pct,

    ROUND(
        AVG(delivered_total_spending), 2
    ) AS avg_customer_spending,

    ROUND(
        AVG(delivered_orders), 2
    ) AS avg_delivered_orders

FROM customer_segments

GROUP BY spending_segment

ORDER BY
    CASE spending_segment
        WHEN 'VIP Customer' THEN 1
        WHEN 'High Value' THEN 2
        WHEN 'Medium Value' THEN 3
        ELSE 4
    END;

-- DAY 3: TASK 8
-- Step 8E: Create High-Value Customer View

CREATE OR REPLACE VIEW
analytics.vw_high_value_customers AS

WITH customer_segments AS (
    SELECT
        customer_unique_id,
        customer_type,
        total_orders,
        delivered_orders,
        delivered_product_spending,
        delivered_total_spending,
        avg_delivered_order_value,
        first_order_date,
        last_order_date,

        CASE
            WHEN delivered_total_spending < 100
                THEN 'Low Value'

            WHEN delivered_total_spending < 300
                THEN 'Medium Value'

            WHEN delivered_total_spending < 1000
                THEN 'High Value'

            ELSE 'VIP Customer'
        END AS spending_segment

    FROM analytics.vw_customer_purchase_behavior

    WHERE delivered_orders > 0
)

SELECT
    customer_unique_id,
    customer_type,
    spending_segment,

    total_orders,
    delivered_orders,

    delivered_product_spending,
    delivered_total_spending,
    avg_delivered_order_value,

    first_order_date,
    last_order_date,

    ROW_NUMBER() OVER (
        ORDER BY
            delivered_total_spending DESC,
            customer_unique_id
    ) AS spending_rank,

    ROUND(
        100.0 * ROW_NUMBER() OVER (
            ORDER BY
                delivered_total_spending DESC,
                customer_unique_id
        )
        / NULLIF(COUNT(*) OVER (), 0),
        2
    ) AS spending_rank_pct

FROM customer_segments;

-- DAY 3: TASK 8
-- Step 8F: Final High-Value Customer Validation

SELECT
    COUNT(*) AS total_customers,

    COUNT(DISTINCT customer_unique_id)
        AS unique_customers,

    COUNT(*) - COUNT(DISTINCT customer_unique_id)
        AS duplicate_customers,

    COUNT(*) FILTER (
        WHERE spending_segment = 'VIP Customer'
    ) AS vip_customers,

    COUNT(*) FILTER (
        WHERE spending_segment = 'High Value'
    ) AS high_value_customers,

    COUNT(*) FILTER (
        WHERE spending_segment = 'Medium Value'
    ) AS medium_value_customers,

    COUNT(*) FILTER (
        WHERE spending_segment = 'Low Value'
    ) AS low_value_customers,

    SUM(delivered_orders)
        AS total_delivered_orders,

    ROUND(
        SUM(delivered_product_spending), 2
    ) AS total_product_spending,

    ROUND(
        SUM(delivered_total_spending), 2
    ) AS total_item_spending,

    COUNT(DISTINCT spending_rank)
        AS unique_spending_ranks,

    COUNT(*) FILTER (
        WHERE delivered_orders <= 0
           OR delivered_total_spending < 0
           OR spending_rank < 1
           OR spending_rank_pct < 0
           OR spending_rank_pct > 100
           OR spending_segment IS NULL
    ) AS invalid_customer_records

FROM analytics.vw_high_value_customers;

-- DAY 3: TASK 9
-- Step 9A: Validate Product-Level Sales Data

SELECT
    COUNT(*) AS total_order_items,

    COUNT(DISTINCT order_id)
        AS orders_with_items,

    COUNT(DISTINCT product_id)
        AS unique_products_sold,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_ids,

    COUNT(*) FILTER (
        WHERE price IS NULL OR price < 0
    ) AS invalid_prices,

    COUNT(*) FILTER (
        WHERE freight_value IS NULL
           OR freight_value < 0
    ) AS invalid_freight_values,

    ROUND(SUM(price), 2)
        AS total_product_sales,

    ROUND(SUM(freight_value), 2)
        AS total_freight_value

FROM analytics.vw_order_items_clean;

-- DAY 3: TASK 9
-- Step 9B: Top 20 Products by Sales Revenue
-- Delivered orders only

SELECT
    oi.product_id,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id)
        AS delivered_orders,

    ROUND(SUM(oi.price), 2)
        AS product_revenue,

    ROUND(SUM(oi.freight_value), 2)
        AS freight_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value), 2
    ) AS total_item_value,

    ROUND(AVG(oi.price), 2)
        AS avg_selling_price

FROM analytics.vw_order_items_clean AS oi

INNER JOIN analytics.vw_orders_clean AS o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY oi.product_id

ORDER BY
    product_revenue DESC,
    oi.product_id

LIMIT 20;

-- DAY 3: TASK 9
-- Step 9C: Top 20 Products by Units Sold
-- Delivered orders only

SELECT
    oi.product_id,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id)
        AS delivered_orders,

    ROUND(SUM(oi.price), 2)
        AS product_revenue,

    ROUND(AVG(oi.price), 2)
        AS avg_selling_price,

    ROUND(SUM(oi.freight_value), 2)
        AS freight_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value), 2
    ) AS total_item_value

FROM analytics.vw_order_items_clean AS oi

INNER JOIN analytics.vw_orders_clean AS o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY oi.product_id

ORDER BY
    units_sold DESC,
    oi.product_id

LIMIT 20;


-- DAY 3: TASK 9
-- Step 9D: Product Revenue Concentration
-- Delivered orders only

WITH product_sales AS (
    SELECT
        oi.product_id,

        COUNT(*) AS units_sold,

        SUM(oi.price) AS product_revenue

    FROM analytics.vw_order_items_clean AS oi

    INNER JOIN analytics.vw_orders_clean AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.product_id
),

ranked_products AS (
    SELECT
        product_id,
        units_sold,
        product_revenue,

        ROW_NUMBER() OVER (
            ORDER BY product_revenue DESC, product_id
        ) AS revenue_rank,

        SUM(product_revenue) OVER ()
            AS overall_product_revenue

    FROM product_sales
)

SELECT
    COUNT(*) AS total_products,

    ROUND(
        MAX(overall_product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 10
        ), 2
    ) AS top_10_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 20
        ), 2
    ) AS top_20_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 50
        ), 2
    ) AS top_50_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 100
        ), 2
    ) AS top_100_revenue,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 10
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_10_revenue_share_pct,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 20
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_20_revenue_share_pct,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 50
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_50_revenue_share_pct,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 100
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_100_revenue_share_pct

FROM ranked_products;

-- DAY 3: TASK 9
-- Step 9E: Create Product Sales Performance View

CREATE OR REPLACE VIEW
analytics.vw_product_sales_performance AS

WITH product_sales AS (
    SELECT
        oi.product_id,

        COUNT(*) AS units_sold,

        COUNT(DISTINCT oi.order_id)
            AS delivered_orders,

        SUM(oi.price)
            AS product_revenue,

        SUM(oi.freight_value)
            AS freight_revenue,

        SUM(oi.price + oi.freight_value)
            AS total_item_value,

        AVG(oi.price)
            AS avg_selling_price

    FROM analytics.vw_order_items_clean AS oi

    INNER JOIN analytics.vw_orders_clean AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.product_id
),

ranked_products AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY product_revenue DESC, product_id
        ) AS revenue_rank,

        ROW_NUMBER() OVER (
            ORDER BY units_sold DESC, product_id
        ) AS volume_rank,

        SUM(product_revenue) OVER ()
            AS overall_product_revenue

    FROM product_sales
)

SELECT
    product_id,
    units_sold,
    delivered_orders,

    ROUND(product_revenue, 2)
        AS product_revenue,

    ROUND(freight_revenue, 2)
        AS freight_revenue,

    ROUND(total_item_value, 2)
        AS total_item_value,

    ROUND(avg_selling_price, 2)
        AS avg_selling_price,

    revenue_rank,
    volume_rank,

    ROUND(
        100.0 * product_revenue
        / NULLIF(overall_product_revenue, 0),
        4
    ) AS product_revenue_share_pct

FROM ranked_products;

-- DAY 3: TASK 9
-- Step 9F: Final Product Performance Validation

SELECT
    COUNT(*) AS total_products,

    COUNT(DISTINCT product_id)
        AS unique_products,

    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_products,

    SUM(units_sold)
        AS total_units_sold,

    SUM(delivered_orders)
        AS total_product_order_occurrences,

    ROUND(
        SUM(product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        SUM(freight_revenue), 2
    ) AS total_freight_revenue,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    COUNT(DISTINCT revenue_rank)
        AS unique_revenue_ranks,

    COUNT(DISTINCT volume_rank)
        AS unique_volume_ranks,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
           OR units_sold <= 0
           OR product_revenue < 0
           OR freight_revenue < 0
           OR revenue_rank < 1
           OR volume_rank < 1
           OR product_revenue_share_pct IS NULL
    ) AS invalid_product_records

FROM analytics.vw_product_sales_performance;

-- DAY 3: TASK 10
-- Step 10A: Validate Product Category Data

SELECT
    COUNT(*) AS total_products,

    COUNT(DISTINCT product_id)
        AS unique_products,

    COUNT(DISTINCT product_category_name)
        AS unique_categories,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_categories

FROM analytics.vw_products_clean;


-- DAY 3: TASK 10
-- Step 10B.1: Inspect Category Translation View

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'vw_product_categories_translated'
ORDER BY ordinal_position;

-- DAY 3: TASK 10
-- Step 10B.2: Validate Category Translations
-- Corrected for existing view structure

SELECT
    COUNT(*) AS total_product_records,

    COUNT(DISTINCT product_id)
        AS unique_products,

    COUNT(DISTINCT product_category_name)
        AS unique_portuguese_categories,

    COUNT(DISTINCT category_english)
        AS unique_english_categories,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_portuguese_categories,

    COUNT(*) FILTER (
        WHERE category_english IS NULL
           OR TRIM(category_english) = ''
    ) AS missing_english_categories,

    COUNT(*) FILTER (
        WHERE translation_status IS NULL
    ) AS missing_translation_status,

    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_product_records

FROM analytics.vw_product_categories_translated;

-- DAY 3: TASK 10
-- Step 10C: Inspect Category Translation Status

SELECT
    translation_status,

    category_english,

    COUNT(*) AS product_count

FROM analytics.vw_product_categories_translated

WHERE product_category_name IS NULL
   OR translation_status IS DISTINCT FROM 'Translated'

GROUP BY
    translation_status,
    category_english

ORDER BY
    product_count DESC,
    translation_status,
    category_english;

-- DAY 3: TASK 10
-- Step 10D: Top 20 Categories by Revenue
-- Delivered orders only

SELECT
    p.category_english AS product_category,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id)
        AS delivered_orders,

    COUNT(DISTINCT oi.product_id)
        AS unique_products_sold,

    ROUND(SUM(oi.price), 2)
        AS product_revenue,

    ROUND(SUM(oi.freight_value), 2)
        AS freight_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value), 2
    ) AS total_item_value,

    ROUND(AVG(oi.price), 2)
        AS avg_selling_price

FROM analytics.vw_order_items_clean AS oi

INNER JOIN analytics.vw_orders_clean AS o
    ON oi.order_id = o.order_id

LEFT JOIN analytics.vw_product_categories_translated AS p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'

GROUP BY
    p.category_english

ORDER BY
    product_revenue DESC,
    product_category

LIMIT 20;

-- DAY 3: TASK 10
-- Step 10E: Validate Overall Category Revenue
-- Delivered orders only

WITH category_sales AS (
    SELECT
        COALESCE(
            p.category_english,
            'Unknown Category'
        ) AS product_category,

        COUNT(*) AS units_sold,

        SUM(oi.price) AS product_revenue,

        SUM(oi.freight_value) AS freight_revenue

    FROM analytics.vw_order_items_clean AS oi

    INNER JOIN analytics.vw_orders_clean AS o
        ON oi.order_id = o.order_id

    LEFT JOIN analytics.vw_product_categories_translated AS p
        ON oi.product_id = p.product_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            p.category_english,
            'Unknown Category'
        )
)

SELECT
    COUNT(*) AS total_categories,

    SUM(units_sold) AS total_units_sold,

    ROUND(SUM(product_revenue), 2)
        AS total_product_revenue,

    ROUND(SUM(freight_revenue), 2)
        AS total_freight_revenue,

    ROUND(
        SUM(product_revenue + freight_revenue), 2
    ) AS total_item_value,

    COUNT(*) FILTER (
        WHERE product_category = 'Unknown Category'
    ) AS unknown_category_groups,

    COALESCE(
        SUM(units_sold) FILTER (
            WHERE product_category = 'Unknown Category'
        ), 0
    ) AS unknown_category_units,

    ROUND(
        COALESCE(
            SUM(product_revenue) FILTER (
                WHERE product_category = 'Unknown Category'
            ), 0
        ), 2
    ) AS unknown_category_revenue

FROM category_sales;

-- DAY 3: TASK 10
-- Step 10F: Create Product Category Revenue View

CREATE OR REPLACE VIEW
analytics.vw_category_sales_performance AS

WITH category_sales AS (
    SELECT
        COALESCE(
            p.category_english,
            'Unknown Category'
        ) AS product_category,

        COUNT(*) AS units_sold,

        COUNT(DISTINCT oi.order_id)
            AS delivered_orders,

        COUNT(DISTINCT oi.product_id)
            AS unique_products_sold,

        SUM(oi.price)
            AS product_revenue,

        SUM(oi.freight_value)
            AS freight_revenue,

        SUM(oi.price + oi.freight_value)
            AS total_item_value,

        AVG(oi.price)
            AS avg_selling_price

    FROM analytics.vw_order_items_clean AS oi

    INNER JOIN analytics.vw_orders_clean AS o
        ON oi.order_id = o.order_id

    LEFT JOIN analytics.vw_product_categories_translated AS p
        ON oi.product_id = p.product_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            p.category_english,
            'Unknown Category'
        )
),

ranked_categories AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY product_revenue DESC,
                     product_category
        ) AS revenue_rank,

        ROW_NUMBER() OVER (
            ORDER BY units_sold DESC,
                     product_category
        ) AS volume_rank,

        SUM(product_revenue) OVER ()
            AS overall_product_revenue

    FROM category_sales
)

SELECT
    product_category,
    units_sold,
    delivered_orders,
    unique_products_sold,

    ROUND(product_revenue, 2)
        AS product_revenue,

    ROUND(freight_revenue, 2)
        AS freight_revenue,

    ROUND(total_item_value, 2)
        AS total_item_value,

    ROUND(avg_selling_price, 2)
        AS avg_selling_price,

    revenue_rank,
    volume_rank,

    ROUND(
        100.0 * product_revenue
        / NULLIF(overall_product_revenue, 0),
        4
    ) AS revenue_share_pct

FROM ranked_categories;

-- DAY 3: TASK 10
-- Step 10G: Final Category Revenue Validation

SELECT
    COUNT(*) AS total_categories,

    COUNT(DISTINCT product_category)
        AS unique_categories,

    COUNT(*) - COUNT(DISTINCT product_category)
        AS duplicate_categories,

    SUM(units_sold)
        AS total_units_sold,

    ROUND(
        SUM(product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        SUM(freight_revenue), 2
    ) AS total_freight_revenue,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    COUNT(DISTINCT revenue_rank)
        AS unique_revenue_ranks,

    COUNT(DISTINCT volume_rank)
        AS unique_volume_ranks,

    COUNT(*) FILTER (
        WHERE product_category = 'Unknown Category'
    ) AS unknown_category_groups,

    COUNT(*) FILTER (
        WHERE product_category IS NULL
           OR units_sold <= 0
           OR product_revenue < 0
           OR freight_revenue < 0
           OR revenue_rank < 1
           OR volume_rank < 1
           OR revenue_share_pct IS NULL
    ) AS invalid_category_records

FROM analytics.vw_category_sales_performance;

-- DAY 3: TASK 11
-- Step 11A: Validate Seller-Level Sales Data
-- Delivered orders only

SELECT
    COUNT(*) AS total_seller_item_records,

    COUNT(DISTINCT oi.seller_id)
        AS active_sellers,

    COUNT(DISTINCT oi.order_id)
        AS delivered_orders,

    COUNT(DISTINCT oi.product_id)
        AS unique_products_sold,

    COUNT(*) FILTER (
        WHERE oi.seller_id IS NULL
    ) AS missing_seller_ids,

    ROUND(
        SUM(oi.price), 2
    ) AS total_product_revenue,

    ROUND(
        SUM(oi.freight_value), 2
    ) AS total_freight_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value), 2
    ) AS total_item_value

FROM analytics.vw_order_items_clean AS oi

INNER JOIN analytics.vw_orders_clean AS o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered';

-- DAY 3: TASK 11
-- Step 11B: Top 20 Sellers by Revenue
-- Delivered orders only

SELECT
    oi.seller_id,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id)
        AS delivered_orders,

    COUNT(DISTINCT oi.product_id)
        AS unique_products_sold,

    ROUND(
        SUM(oi.price), 2
    ) AS product_revenue,

    ROUND(
        SUM(oi.freight_value), 2
    ) AS freight_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value), 2
    ) AS total_item_value,

    ROUND(
        AVG(oi.price), 2
    ) AS avg_selling_price

FROM analytics.vw_order_items_clean AS oi

INNER JOIN analytics.vw_orders_clean AS o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY oi.seller_id

ORDER BY
    product_revenue DESC,
    oi.seller_id

LIMIT 20;

-- DAY 3: TASK 11
-- Step 11C: Top 20 Sellers by Units Sold
-- Delivered orders only

SELECT
    oi.seller_id,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id)
        AS delivered_orders,

    COUNT(DISTINCT oi.product_id)
        AS unique_products_sold,

    ROUND(
        SUM(oi.price), 2
    ) AS product_revenue,

    ROUND(
        AVG(oi.price), 2
    ) AS avg_selling_price,

    ROUND(
        SUM(oi.freight_value), 2
    ) AS freight_revenue,

    ROUND(
        SUM(oi.price + oi.freight_value), 2
    ) AS total_item_value

FROM analytics.vw_order_items_clean AS oi

INNER JOIN analytics.vw_orders_clean AS o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY oi.seller_id

ORDER BY
    units_sold DESC,
    oi.seller_id

LIMIT 20;

-- DAY 3: TASK 11
-- Step 11D: Seller Revenue Concentration
-- Delivered orders only

WITH seller_sales AS (
    SELECT
        oi.seller_id,
        COUNT(*) AS units_sold,
        SUM(oi.price) AS product_revenue

    FROM analytics.vw_order_items_clean AS oi

    INNER JOIN analytics.vw_orders_clean AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        units_sold,
        product_revenue,

        ROW_NUMBER() OVER (
            ORDER BY product_revenue DESC, seller_id
        ) AS revenue_rank,

        SUM(product_revenue) OVER ()
            AS overall_product_revenue

    FROM seller_sales
)

SELECT
    COUNT(*) AS total_sellers,

    ROUND(
        MAX(overall_product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 10
        ), 2
    ) AS top_10_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 20
        ), 2
    ) AS top_20_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 50
        ), 2
    ) AS top_50_revenue,

    ROUND(
        SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 100
        ), 2
    ) AS top_100_revenue,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 10
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_10_revenue_share_pct,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 20
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_20_revenue_share_pct,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 50
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_50_revenue_share_pct,

    ROUND(
        100.0 * SUM(product_revenue) FILTER (
            WHERE revenue_rank <= 100
        ) / NULLIF(MAX(overall_product_revenue), 0),
        2
    ) AS top_100_revenue_share_pct

FROM ranked_sellers;

-- DAY 3: TASK 11
-- Step 11E: Create Seller Sales Performance View

CREATE OR REPLACE VIEW
analytics.vw_seller_sales_performance AS

WITH seller_sales AS (
    SELECT
        oi.seller_id,

        COUNT(*) AS units_sold,

        COUNT(DISTINCT oi.order_id)
            AS delivered_orders,

        COUNT(DISTINCT oi.product_id)
            AS unique_products_sold,

        SUM(oi.price)
            AS product_revenue,

        SUM(oi.freight_value)
            AS freight_revenue,

        SUM(oi.price + oi.freight_value)
            AS total_item_value,

        AVG(oi.price)
            AS avg_selling_price

    FROM analytics.vw_order_items_clean AS oi

    INNER JOIN analytics.vw_orders_clean AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id
),

ranked_sellers AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY product_revenue DESC, seller_id
        ) AS revenue_rank,

        ROW_NUMBER() OVER (
            ORDER BY units_sold DESC, seller_id
        ) AS volume_rank,

        SUM(product_revenue) OVER ()
            AS overall_product_revenue

    FROM seller_sales
)

SELECT
    seller_id,
    units_sold,
    delivered_orders,
    unique_products_sold,

    ROUND(product_revenue, 2)
        AS product_revenue,

    ROUND(freight_revenue, 2)
        AS freight_revenue,

    ROUND(total_item_value, 2)
        AS total_item_value,

    ROUND(avg_selling_price, 2)
        AS avg_selling_price,

    revenue_rank,
    volume_rank,

    ROUND(
        100.0 * product_revenue
        / NULLIF(overall_product_revenue, 0),
        4
    ) AS revenue_share_pct

FROM ranked_sellers;

-- DAY 3: TASK 11
-- Step 11F: Final Seller Performance Validation

SELECT
    COUNT(*) AS total_sellers,

    COUNT(DISTINCT seller_id)
        AS unique_sellers,

    COUNT(*) - COUNT(DISTINCT seller_id)
        AS duplicate_sellers,

    SUM(units_sold)
        AS total_units_sold,

    SUM(delivered_orders)
        AS total_seller_order_occurrences,

    ROUND(
        SUM(product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        SUM(freight_revenue), 2
    ) AS total_freight_revenue,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    COUNT(DISTINCT revenue_rank)
        AS unique_revenue_ranks,

    COUNT(DISTINCT volume_rank)
        AS unique_volume_ranks,

    COUNT(*) FILTER (
        WHERE seller_id IS NULL
           OR units_sold <= 0
           OR delivered_orders <= 0
           OR unique_products_sold <= 0
           OR product_revenue < 0
           OR freight_revenue < 0
           OR revenue_rank < 1
           OR volume_rank < 1
           OR revenue_share_pct IS NULL
    ) AS invalid_seller_records

FROM analytics.vw_seller_sales_performance;

-- DAY 3: TASK 12
-- Step 12A: Product Sales Frequency Distribution
-- Delivered orders only

WITH product_frequency AS (
    SELECT
        product_id,
        units_sold,
        product_revenue,

        CASE
            WHEN units_sold = 1
                THEN '1 Unit'

            WHEN units_sold = 2
                THEN '2 Units'

            WHEN units_sold BETWEEN 3 AND 5
                THEN '3-5 Units'

            WHEN units_sold BETWEEN 6 AND 10
                THEN '6-10 Units'

            WHEN units_sold BETWEEN 11 AND 20
                THEN '11-20 Units'

            ELSE '21+ Units'
        END AS sales_frequency_group

    FROM analytics.vw_product_sales_performance
)

SELECT
    sales_frequency_group,

    COUNT(*) AS product_count,

    SUM(units_sold) AS total_units_sold,

    ROUND(
        SUM(product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS product_share_pct,

    ROUND(
        100.0 * SUM(product_revenue)
        / SUM(SUM(product_revenue)) OVER (),
        2
    ) AS revenue_share_pct

FROM product_frequency

GROUP BY sales_frequency_group

ORDER BY
    MIN(units_sold);

-- DAY 3: TASK 12
-- Step 12B: Low-Volume Product Revenue Analysis
-- Delivered orders only

WITH product_groups AS (
    SELECT
        product_id,
        units_sold,
        delivered_orders,
        product_revenue,
        avg_selling_price,

        CASE
            WHEN units_sold = 1
                THEN 'Single-Sale Products'

            WHEN units_sold = 2
                THEN 'Two-Sale Products'

            ELSE 'Three or More Sales'
        END AS sales_group

    FROM analytics.vw_product_sales_performance
)

SELECT
    sales_group,

    COUNT(*) AS product_count,

    SUM(units_sold) AS total_units_sold,

    ROUND(
        SUM(product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        AVG(product_revenue), 2
    ) AS avg_revenue_per_product,

    ROUND(
        SUM(product_revenue)
        / NULLIF(SUM(units_sold), 0), 2
    ) AS avg_selling_price,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (), 2
    ) AS product_share_pct,

    ROUND(
        100.0 * SUM(product_revenue)
        / SUM(SUM(product_revenue)) OVER (), 2
    ) AS revenue_share_pct

FROM product_groups

GROUP BY sales_group

ORDER BY
    CASE sales_group
        WHEN 'Single-Sale Products' THEN 1
        WHEN 'Two-Sale Products' THEN 2
        ELSE 3
    END;

-- DAY 3: TASK 12
-- Step 12C: Low-Volume, Low-Revenue Products
-- Delivered orders only

SELECT
    product_id,
    units_sold,
    delivered_orders,
    product_revenue,
    avg_selling_price,
    revenue_rank,
    volume_rank

FROM analytics.vw_product_sales_performance

WHERE units_sold <= 2
  AND product_revenue < 100

ORDER BY
    product_revenue ASC,
    units_sold ASC,
    product_id

LIMIT 20;

-- DAY 3: TASK 12
-- Step 12D: Low-Volume Product Summary
-- Delivered orders only

WITH product_classification AS (
    SELECT
        product_id,
        units_sold,
        product_revenue,

        CASE
            WHEN units_sold <= 2
                 AND product_revenue < 100
                THEN 'Low-Volume Low-Revenue'

            WHEN units_sold <= 2
                THEN 'Low-Volume Higher-Revenue'

            ELSE 'Higher-Volume Products'
        END AS product_group

    FROM analytics.vw_product_sales_performance
)

SELECT
    product_group,

    COUNT(*) AS product_count,

    SUM(units_sold) AS total_units_sold,

    ROUND(
        SUM(product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        AVG(product_revenue), 2
    ) AS avg_revenue_per_product,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (), 2
    ) AS product_share_pct,

    ROUND(
        100.0 * SUM(product_revenue)
        / SUM(SUM(product_revenue)) OVER (), 2
    ) AS revenue_share_pct

FROM product_classification

GROUP BY product_group

ORDER BY
    CASE product_group
        WHEN 'Low-Volume Low-Revenue' THEN 1
        WHEN 'Low-Volume Higher-Revenue' THEN 2
        ELSE 3
    END;

-- DAY 3: TASK 12
-- Step 12E: Create Low-Performing Product View

CREATE OR REPLACE VIEW
analytics.vw_low_performing_products AS

SELECT
    product_id,
    units_sold,
    delivered_orders,
    product_revenue,
    freight_revenue,
    total_item_value,
    avg_selling_price,
    revenue_rank,
    volume_rank,
    product_revenue_share_pct,

    CASE
        WHEN units_sold <= 2
             AND product_revenue < 100
            THEN 'Low-Volume Low-Revenue'

        WHEN units_sold <= 2
            THEN 'Low-Volume Higher-Revenue'

        ELSE 'Higher-Volume Products'
    END AS product_performance_group,

    CASE
        WHEN units_sold <= 2
             AND product_revenue < 100
            THEN 1
        ELSE 0
    END AS low_performance_flag

FROM analytics.vw_product_sales_performance;

-- DAY 3: TASK 12
-- Step 12F: Final Low-Performing Product Validation

SELECT
    COUNT(*) AS total_products,

    COUNT(DISTINCT product_id)
        AS unique_products,

    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_products,

    COUNT(*) FILTER (
        WHERE product_performance_group =
              'Low-Volume Low-Revenue'
    ) AS low_volume_low_revenue_products,

    COUNT(*) FILTER (
        WHERE product_performance_group =
              'Low-Volume Higher-Revenue'
    ) AS low_volume_higher_revenue_products,

    COUNT(*) FILTER (
        WHERE product_performance_group =
              'Higher-Volume Products'
    ) AS higher_volume_products,

    SUM(low_performance_flag)
        AS flagged_products,

    SUM(units_sold)
        AS total_units_sold,

    ROUND(
        SUM(product_revenue), 2
    ) AS total_product_revenue,

    ROUND(
        SUM(freight_revenue), 2
    ) AS total_freight_revenue,

    ROUND(
        SUM(total_item_value), 2
    ) AS total_item_value,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
           OR units_sold <= 0
           OR product_revenue < 0
           OR freight_revenue < 0
           OR product_performance_group IS NULL
           OR low_performance_flag IS NULL
           OR low_performance_flag NOT IN (0, 1)
           OR (
               low_performance_flag = 1
               AND NOT (
                   units_sold <= 2
                   AND product_revenue < 100
               )
           )
           OR (
               low_performance_flag = 0
               AND units_sold <= 2
               AND product_revenue < 100
           )
    ) AS invalid_product_records

FROM analytics.vw_low_performing_products;

-- DAY 3: TASK 18
-- Step 18A: Validate Customer Revenue Distribution

SELECT
    COUNT(*) AS total_customers,

    COUNT(DISTINCT customer_unique_id)
        AS unique_customers,

    COUNT(*) - COUNT(DISTINCT customer_unique_id)
        AS duplicate_customer_records,

    COUNT(*) FILTER (
        WHERE delivered_orders > 0
    ) AS customers_with_delivered_orders,

    COUNT(*) FILTER (
        WHERE delivered_total_spending = 0
    ) AS zero_spending_customers,

    COUNT(*) FILTER (
        WHERE delivered_total_spending < 0
    ) AS negative_spending_customers,

    ROUND(
        SUM(delivered_total_spending), 2
    ) AS total_customer_revenue,

    ROUND(
        AVG(delivered_total_spending), 2
    ) AS avg_customer_revenue,

    ROUND(
        MAX(delivered_total_spending), 2
    ) AS highest_customer_revenue,

    ROUND(
        MIN(delivered_total_spending), 2
    ) AS lowest_customer_revenue

FROM analytics.vw_customer_purchase_behavior

WHERE delivered_orders > 0;

-- DAY 3: TASK 18
-- Step 18B: Rank Customers by Revenue

WITH customer_revenue AS (

    SELECT
        customer_unique_id,
        delivered_orders,
        delivered_total_spending AS customer_revenue

    FROM analytics.vw_customer_purchase_behavior

    WHERE delivered_orders > 0

),

ranked_customers AS (

    SELECT
        customer_unique_id,
        delivered_orders,
        customer_revenue,

        ROW_NUMBER() OVER (
            ORDER BY
                customer_revenue DESC,
                customer_unique_id
        ) AS revenue_rank,

        SUM(customer_revenue) OVER ()
            AS total_revenue,

        SUM(customer_revenue) OVER (
            ORDER BY
                customer_revenue DESC,
                customer_unique_id
            ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
        ) AS cumulative_revenue

    FROM customer_revenue

)

SELECT
    revenue_rank,
    customer_unique_id,
    delivered_orders,

    ROUND(customer_revenue, 2)
        AS customer_revenue,

    ROUND(
        100.0 * customer_revenue
        / NULLIF(total_revenue, 0),
        4
    ) AS revenue_share_pct,

    ROUND(
        100.0 * cumulative_revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS cumulative_revenue_pct

FROM ranked_customers

ORDER BY revenue_rank

LIMIT 20;

-- DAY 3: TASK 18
-- Step 18C: Revenue Concentration Analysis

WITH customer_revenue AS (

    SELECT
        customer_unique_id,
        delivered_total_spending AS customer_revenue

    FROM analytics.vw_customer_purchase_behavior

    WHERE delivered_orders > 0

),

ranked_customers AS (

    SELECT
        customer_unique_id,
        customer_revenue,

        ROW_NUMBER() OVER (
            ORDER BY
                customer_revenue DESC,
                customer_unique_id
        ) AS revenue_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(customer_revenue) OVER ()
            AS total_revenue

    FROM customer_revenue

),

revenue_concentration AS (

    SELECT
        threshold.customer_percentile,

        COUNT(*) FILTER (
            WHERE rc.revenue_rank <= CEIL(
                rc.total_customers
                * threshold.customer_percentile / 100.0
            )
        ) AS customers_in_group,

        MAX(rc.total_customers) AS total_customers,

        ROUND(
            SUM(rc.customer_revenue) FILTER (
                WHERE rc.revenue_rank <= CEIL(
                    rc.total_customers
                    * threshold.customer_percentile / 100.0
                )
            ),
            2
        ) AS group_revenue,

        MAX(rc.total_revenue) AS total_revenue

    FROM ranked_customers rc

    CROSS JOIN (
        VALUES (1), (5), (10), (20)
    ) AS threshold(customer_percentile)

    GROUP BY threshold.customer_percentile

)

SELECT
    customer_percentile
        AS top_customer_pct,

    customers_in_group,

    total_customers,

    group_revenue,

    ROUND(
        100.0 * group_revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS revenue_contribution_pct

FROM revenue_concentration

ORDER BY top_customer_pct;

-- DAY 3: TASK 18
-- Step 18D: Create Revenue Concentration View

CREATE OR REPLACE VIEW
analytics.vw_customer_revenue_concentration AS

WITH customer_revenue AS (

    SELECT
        customer_unique_id,
        delivered_orders,
        delivered_total_spending
            AS customer_revenue

    FROM analytics.vw_customer_purchase_behavior

    WHERE delivered_orders > 0

),

ranked_customers AS (

    SELECT
        customer_unique_id,
        delivered_orders,
        customer_revenue,

        ROW_NUMBER() OVER (
            ORDER BY
                customer_revenue DESC,
                customer_unique_id
        ) AS revenue_rank,

        COUNT(*) OVER ()
            AS total_customers,

        SUM(customer_revenue) OVER ()
            AS total_revenue,

        SUM(customer_revenue) OVER (
            ORDER BY
                customer_revenue DESC,
                customer_unique_id
            ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
        ) AS cumulative_revenue

    FROM customer_revenue

)

SELECT
    customer_unique_id,
    delivered_orders,
    customer_revenue,
    revenue_rank,
    total_customers,

    ROUND(
        100.0 * revenue_rank
        / NULLIF(total_customers, 0),
        2
    ) AS customer_percentile_rank,

    ROUND(
        100.0 * customer_revenue
        / NULLIF(total_revenue, 0),
        4
    ) AS revenue_share_pct,

    ROUND(
        100.0 * cumulative_revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS cumulative_revenue_pct

FROM ranked_customers;

-- DAY 3: TASK 18
-- Step 18E: Final Revenue Concentration Validation

WITH validation AS (

    SELECT
        COUNT(*) AS total_customers,

        COUNT(DISTINCT customer_unique_id)
            AS unique_customers,

        COUNT(*) - COUNT(DISTINCT customer_unique_id)
            AS duplicate_customers,

        ROUND(
            SUM(customer_revenue), 2
        ) AS total_customer_revenue,

        COUNT(*) FILTER (
            WHERE customer_revenue <= 0
               OR customer_revenue IS NULL
        ) AS invalid_revenue_rows,

        COUNT(*) FILTER (
            WHERE revenue_rank < 1
               OR revenue_rank > total_customers
               OR revenue_rank IS NULL
        ) AS invalid_rank_rows,

        COUNT(*) - COUNT(DISTINCT revenue_rank)
            AS duplicate_rank_rows,

        COUNT(*) FILTER (
            WHERE revenue_share_pct < 0
               OR revenue_share_pct > 100
               OR cumulative_revenue_pct < 0
               OR cumulative_revenue_pct > 100
               OR revenue_share_pct IS NULL
               OR cumulative_revenue_pct IS NULL
        ) AS invalid_percentage_rows,

        MAX(cumulative_revenue_pct) FILTER (
            WHERE revenue_rank = total_customers
        ) AS final_cumulative_revenue_pct

    FROM analytics.vw_customer_revenue_concentration

)

SELECT *
FROM validation;

-- DAY 3: TASK 19
-- Step 19A: Inventory Existing Analytics Views

SELECT
    table_schema,
    table_name AS view_name

FROM information_schema.views

WHERE table_schema = 'analytics'

ORDER BY view_name;

-- DAY 3: TASK 19
-- Step 19B: Inspect Power BI Reporting Columns

SELECT
    table_name AS view_name,
    ordinal_position AS column_position,
    column_name,
    data_type

FROM information_schema.columns

WHERE table_schema = 'analytics'

  AND table_name IN (
      'vw_business_kpis',
      'vw_monthly_sales_kpis',
      'vw_monthly_sales_trends',
      'vw_customer_purchase_behavior',
      'vw_customer_geography',
      'vw_customer_cohort_retention_final',
      'vw_customer_revenue_concentration',
      'vw_product_sales_performance',
      'vw_category_sales_performance',
      'vw_seller_sales_performance',
      'vw_on_time_delivery_analysis',
      'vw_payment_analysis',
      'vw_delivery_satisfaction'
  )

ORDER BY
    table_name,
    ordinal_position;

-- DAY 3: TASK 19
-- Step 19C: Power BI Reporting View Row Counts

SELECT
    '01_Business_KPIs' AS reporting_view,
    COUNT(*) AS total_rows
FROM analytics.vw_business_kpis

UNION ALL

SELECT
    '02_Monthly_Sales_KPIs',
    COUNT(*)
FROM analytics.vw_monthly_sales_kpis

UNION ALL

SELECT
    '03_Monthly_Sales_Trends',
    COUNT(*)
FROM analytics.vw_monthly_sales_trends

UNION ALL

SELECT
    '04_Customer_Purchase_Behavior',
    COUNT(*)
FROM analytics.vw_customer_purchase_behavior

UNION ALL

SELECT
    '05_Customer_Geography',
    COUNT(*)
FROM analytics.vw_customer_geography

UNION ALL

SELECT
    '06_Cohort_Retention',
    COUNT(*)
FROM analytics.vw_customer_cohort_retention_final

UNION ALL

SELECT
    '07_Revenue_Concentration',
    COUNT(*)
FROM analytics.vw_customer_revenue_concentration

UNION ALL

SELECT
    '08_Product_Performance',
    COUNT(*)
FROM analytics.vw_product_sales_performance

UNION ALL

SELECT
    '09_Category_Performance',
    COUNT(*)
FROM analytics.vw_category_sales_performance

UNION ALL

SELECT
    '10_Seller_Performance',
    COUNT(*)
FROM analytics.vw_seller_sales_performance

UNION ALL

SELECT
    '11_On_Time_Delivery',
    COUNT(*)
FROM analytics.vw_on_time_delivery_analysis

UNION ALL

SELECT
    '12_Payment_Analysis',
    COUNT(*)
FROM analytics.vw_payment_analysis

UNION ALL

SELECT
    '13_Delivery_Satisfaction',
    COUNT(*)
FROM analytics.vw_delivery_satisfaction

ORDER BY reporting_view;

-- DAY 3: TASK 19
-- Step 19D: Validate Reporting View Granularity

WITH key_checks AS (

    SELECT
        'Monthly Sales KPIs' AS reporting_view,
        COUNT(*) AS total_rows,
        COUNT(DISTINCT order_month) AS unique_keys
    FROM analytics.vw_monthly_sales_kpis

    UNION ALL

    SELECT
        'Monthly Sales Trends',
        COUNT(*),
        COUNT(DISTINCT order_month)
    FROM analytics.vw_monthly_sales_trends

    UNION ALL

    SELECT
        'Customer Purchase Behavior',
        COUNT(*),
        COUNT(DISTINCT customer_unique_id)
    FROM analytics.vw_customer_purchase_behavior

    UNION ALL

    SELECT
        'Customer Revenue Concentration',
        COUNT(*),
        COUNT(DISTINCT customer_unique_id)
    FROM analytics.vw_customer_revenue_concentration

    UNION ALL

    SELECT
        'Customer Geography',
        COUNT(*),
        COUNT(DISTINCT state)
    FROM analytics.vw_customer_geography

    UNION ALL

    SELECT
        'Cohort Retention',
        COUNT(*),
        COUNT(DISTINCT (
            cohort_month,
            cohort_month_number
        ))
    FROM analytics.vw_customer_cohort_retention_final

    UNION ALL

    SELECT
        'Product Performance',
        COUNT(*),
        COUNT(DISTINCT product_id)
    FROM analytics.vw_product_sales_performance

    UNION ALL

    SELECT
        'Category Performance',
        COUNT(*),
        COUNT(DISTINCT product_category)
    FROM analytics.vw_category_sales_performance

    UNION ALL

    SELECT
        'Seller Performance',
        COUNT(*),
        COUNT(DISTINCT seller_id)
    FROM analytics.vw_seller_sales_performance

    UNION ALL

    SELECT
        'On-Time Delivery',
        COUNT(*),
        COUNT(DISTINCT order_id)
    FROM analytics.vw_on_time_delivery_analysis

    UNION ALL

    SELECT
        'Delivery Satisfaction',
        COUNT(*),
        COUNT(DISTINCT order_id)
    FROM analytics.vw_delivery_satisfaction

)

SELECT
    reporting_view,
    total_rows,
    unique_keys,

    total_rows - unique_keys
        AS duplicate_key_rows,

    CASE
        WHEN total_rows = unique_keys
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status

FROM key_checks

ORDER BY reporting_view;


-- DAY 3: TASK 19
-- Step 19E: Validate Payment Reporting Granularity

SELECT
    COUNT(*) AS total_payment_rows,

    COUNT(DISTINCT order_id)
        AS unique_orders_with_payments,

    COUNT(DISTINCT (
        order_id,
        payment_sequential
    )) AS unique_payment_keys,

    COUNT(*) - COUNT(DISTINCT (
        order_id,
        payment_sequential
    )) AS duplicate_payment_keys,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR payment_sequential IS NULL
    ) AS missing_payment_keys,

    COUNT(*) FILTER (
        WHERE payment_value < 0
           OR payment_value IS NULL
    ) AS invalid_payment_values,

    ROUND(
        SUM(payment_value), 2
    ) AS total_payment_value

FROM analytics.vw_payment_analysis;

-- DAY 3: TASK 19
-- Step 19F: Final Reporting Readiness Check

WITH required_views AS (

    SELECT *
    FROM (
        VALUES
            ('vw_business_kpis'),
            ('vw_monthly_sales_kpis'),
            ('vw_monthly_sales_trends'),
            ('vw_customer_purchase_behavior'),
            ('vw_customer_geography'),
            ('vw_customer_cohort_retention_final'),
            ('vw_customer_revenue_concentration'),
            ('vw_product_sales_performance'),
            ('vw_category_sales_performance'),
            ('vw_seller_sales_performance'),
            ('vw_on_time_delivery_analysis'),
            ('vw_payment_analysis'),
            ('vw_delivery_satisfaction')
    ) AS v(view_name)

),

existing_views AS (

    SELECT table_name AS view_name

    FROM information_schema.views

    WHERE table_schema = 'analytics'

)

SELECT
    COUNT(*) AS required_reporting_views,

    COUNT(ev.view_name) AS available_reporting_views,

    COUNT(*) - COUNT(ev.view_name)
        AS missing_reporting_views,

    CASE
        WHEN COUNT(*) = COUNT(ev.view_name)
            THEN 'READY'
        ELSE 'REVIEW REQUIRED'
    END AS reporting_status

FROM required_views rv

LEFT JOIN existing_views ev
    ON rv.view_name = ev.view_name;

-- DAY 3: TASK 20
-- Step 20A: Final Revenue Reconciliation

WITH revenue_sources AS (

    SELECT
        '01_Order_Summary' AS reporting_source,
        SUM(total_item_value) AS total_revenue
    FROM analytics.vw_order_summary
    WHERE order_status = 'delivered'

    UNION ALL

    SELECT
        '02_Product_Performance',
        SUM(total_item_value)
    FROM analytics.vw_product_sales_performance

    UNION ALL

    SELECT
        '03_Category_Performance',
        SUM(total_item_value)
    FROM analytics.vw_category_sales_performance

    UNION ALL

    SELECT
        '04_Seller_Performance',
        SUM(total_item_value)
    FROM analytics.vw_seller_sales_performance

    UNION ALL

    SELECT
        '05_Customer_Revenue_Concentration',
        SUM(customer_revenue)
    FROM analytics.vw_customer_revenue_concentration

)

SELECT
    reporting_source,

    ROUND(total_revenue, 2) AS total_revenue,

    ROUND(
        total_revenue - 15419773.75,
        2
    ) AS difference_from_baseline,

    CASE
        WHEN ABS(total_revenue - 15419773.75) < 0.01
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status

FROM revenue_sources

ORDER BY reporting_source;

-- DAY 3: TASK 20
-- Step 20B: Final Customer Population Reconciliation

WITH customer_summary AS (

    SELECT
        COUNT(*) AS total_customers,

        COUNT(*) FILTER (
            WHERE delivered_orders > 0
        ) AS customers_with_delivered_orders,

        COUNT(*) FILTER (
            WHERE delivered_orders = 0
        ) AS customers_without_delivered_orders,

        COUNT(*) FILTER (
            WHERE delivered_orders IS NULL
               OR delivered_orders < 0
        ) AS invalid_delivered_order_counts

    FROM analytics.vw_customer_purchase_behavior

),

concentration_summary AS (

    SELECT
        COUNT(*) AS concentration_customers
    FROM analytics.vw_customer_revenue_concentration

)

SELECT
    cs.total_customers,
    cs.customers_with_delivered_orders,
    cs.customers_without_delivered_orders,
    cr.concentration_customers,

    cs.customers_with_delivered_orders
        - cr.concentration_customers
        AS delivered_customer_difference,

    cs.total_customers
        - cs.customers_with_delivered_orders
        - cs.customers_without_delivered_orders
        AS customer_classification_difference,

    cs.invalid_delivered_order_counts,

    CASE
        WHEN cs.total_customers = 96096
         AND cs.customers_with_delivered_orders = 93358
         AND cs.customers_without_delivered_orders = 2738
         AND cr.concentration_customers = 93358
         AND cs.invalid_delivered_order_counts = 0
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status

FROM customer_summary cs
CROSS JOIN concentration_summary cr;

-- DAY 3: TASK 20
-- Step 20C: Final Order and Delivery Reconciliation

WITH order_summary AS (

    SELECT
        COUNT(*) AS delivered_orders
    FROM analytics.vw_order_summary
    WHERE order_status = 'delivered'

),

delivery_summary AS (

    SELECT
        COUNT(*) AS delivery_view_orders,

        COUNT(*) FILTER (
            WHERE delivery_status = 'On Time'
        ) AS on_time_orders,

        COUNT(*) FILTER (
            WHERE delivery_status = 'Late'
        ) AS late_orders,

        COUNT(*) FILTER (
            WHERE delivery_status = 'Missing or Invalid'
        ) AS missing_or_invalid_orders

    FROM analytics.vw_on_time_delivery_analysis

),

satisfaction_summary AS (

    SELECT
        COUNT(*) AS reviewed_delivered_orders
    FROM analytics.vw_delivery_satisfaction

)

SELECT
    os.delivered_orders,
    ds.delivery_view_orders,
    ds.on_time_orders,
    ds.late_orders,
    ds.missing_or_invalid_orders,
    ss.reviewed_delivered_orders,

    os.delivered_orders - ss.reviewed_delivered_orders
        AS delivered_orders_without_reviews,

    ROUND(
        100.0 * ss.reviewed_delivered_orders
        / NULLIF(os.delivered_orders, 0),
        2
    ) AS delivered_review_coverage_pct,

    CASE
        WHEN os.delivered_orders = ds.delivery_view_orders
         AND ds.on_time_orders
             + ds.late_orders
             + ds.missing_or_invalid_orders
             = ds.delivery_view_orders
         AND ss.reviewed_delivered_orders
             <= os.delivered_orders
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status

FROM order_summary os
CROSS JOIN delivery_summary ds
CROSS JOIN satisfaction_summary ss;

-- DAY 3: TASK 20
-- Step 20D: Product, Category, Seller Reconciliation

WITH reporting_totals AS (

    SELECT
        '01_Product_Performance' AS reporting_source,
        SUM(units_sold) AS total_units_sold,
        SUM(product_revenue) AS product_revenue,
        SUM(freight_revenue) AS freight_revenue
    FROM analytics.vw_product_sales_performance

    UNION ALL

    SELECT
        '02_Category_Performance',
        SUM(units_sold),
        SUM(product_revenue),
        SUM(freight_revenue)
    FROM analytics.vw_category_sales_performance

    UNION ALL

    SELECT
        '03_Seller_Performance',
        SUM(units_sold),
        SUM(product_revenue),
        SUM(freight_revenue)
    FROM analytics.vw_seller_sales_performance

)

SELECT
    reporting_source,

    total_units_sold,

    ROUND(product_revenue, 2) AS product_revenue,

    ROUND(freight_revenue, 2) AS freight_revenue,

    ROUND(
        product_revenue + freight_revenue,
        2
    ) AS total_item_value,

    CASE
        WHEN total_units_sold = 110197
         AND ABS(product_revenue - 13221498.11) < 0.01
         AND ABS(freight_revenue - 2198275.64) < 0.01
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status

FROM reporting_totals

ORDER BY reporting_source;

-- DAY 3: TASK 20
-- Step 20D: Product, Category, Seller Reconciliation

WITH reporting_totals AS (

    SELECT
        '01_Product_Performance' AS reporting_source,
        SUM(units_sold) AS total_units_sold,
        SUM(product_revenue) AS product_revenue,
        SUM(freight_revenue) AS freight_revenue
    FROM analytics.vw_product_sales_performance

    UNION ALL

    SELECT
        '02_Category_Performance',
        SUM(units_sold),
        SUM(product_revenue),
        SUM(freight_revenue)
    FROM analytics.vw_category_sales_performance

    UNION ALL

    SELECT
        '03_Seller_Performance',
        SUM(units_sold),
        SUM(product_revenue),
        SUM(freight_revenue)
    FROM analytics.vw_seller_sales_performance

)

SELECT
    reporting_source,

    total_units_sold,

    ROUND(product_revenue, 2) AS product_revenue,

    ROUND(freight_revenue, 2) AS freight_revenue,

    ROUND(
        product_revenue + freight_revenue,
        2
    ) AS total_item_value,

    CASE
        WHEN total_units_sold = 110197
         AND ABS(product_revenue - 13221498.11) < 0.01
         AND ABS(freight_revenue - 2198275.64) < 0.01
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status

FROM reporting_totals

ORDER BY reporting_source;

-- DAY 3: TASK 20
-- Step 20E: Top 5 Revenue Categories

SELECT
    product_category,
    units_sold,
    delivered_orders,

    ROUND(product_revenue, 2)
        AS product_revenue,

    ROUND(revenue_share_pct, 2)
        AS revenue_share_pct,

    ROUND(avg_selling_price, 2)
        AS avg_selling_price

FROM analytics.vw_category_sales_performance

ORDER BY
    product_revenue DESC,
    product_category

LIMIT 5;

-- DAY 3: TASK 20
-- Step 20F: Top 5 Seller Performance

SELECT
    seller_id,
    units_sold,
    delivered_orders,
    unique_products_sold,

    ROUND(product_revenue, 2)
        AS product_revenue,

    ROUND(revenue_share_pct, 2)
        AS revenue_share_pct,

    ROUND(avg_selling_price, 2)
        AS avg_selling_price

FROM analytics.vw_seller_sales_performance

ORDER BY
    product_revenue DESC,
    seller_id

LIMIT 5;

-- DAY 3: TASK 20
-- Step 20G: Monthly Revenue Performance

SELECT
    order_month,
    delivered_orders,

    ROUND(product_sales, 2)
        AS product_revenue,

    ROUND(total_item_value, 2)
        AS total_item_value,

    ROUND(avg_order_value, 2)
        AS avg_order_value,

    ROUND(mom_growth_pct, 2)
        AS mom_growth_pct,

    RANK() OVER (
        ORDER BY total_item_value DESC
    ) AS revenue_rank

FROM analytics.vw_monthly_sales_trends

ORDER BY order_month;


-- DAY 3: TASK 20
-- Step 20H: Customer Revenue Concentration

SELECT
    CASE
        WHEN customer_percentile_rank <= 1
            THEN 'Top 1%'
        WHEN customer_percentile_rank <= 5
            THEN 'Top 5%'
        WHEN customer_percentile_rank <= 10
            THEN 'Top 10%'
        WHEN customer_percentile_rank <= 20
            THEN 'Top 20%'
        ELSE 'Other Customers'
    END AS customer_segment,

    COUNT(*) AS customers,

    ROUND(SUM(customer_revenue), 2)
        AS segment_revenue,

    ROUND(
        100.0 * SUM(customer_revenue)
        / NULLIF(
            SUM(SUM(customer_revenue)) OVER (),
            0
        ),
        2
    ) AS revenue_share_pct

FROM analytics.vw_customer_revenue_concentration

GROUP BY 1

ORDER BY
    CASE
        WHEN CASE
            WHEN customer_percentile_rank <= 1 THEN 'Top 1%'
            WHEN customer_percentile_rank <= 5 THEN 'Top 5%'
            WHEN customer_percentile_rank <= 10 THEN 'Top 10%'
            WHEN customer_percentile_rank <= 20 THEN 'Top 20%'
            ELSE 'Other Customers'
        END = 'Top 1%' THEN 1
        WHEN CASE
            WHEN customer_percentile_rank <= 1 THEN 'Top 1%'
            WHEN customer_percentile_rank <= 5 THEN 'Top 5%'
            WHEN customer_percentile_rank <= 10 THEN 'Top 10%'
            WHEN customer_percentile_rank <= 20 THEN 'Top 20%'
            ELSE 'Other Customers'
        END = 'Top 5%' THEN 2
        WHEN CASE
            WHEN customer_percentile_rank <= 1 THEN 'Top 1%'
            WHEN customer_percentile_rank <= 5 THEN 'Top 5%'
            WHEN customer_percentile_rank <= 10 THEN 'Top 10%'
            WHEN customer_percentile_rank <= 20 THEN 'Top 20%'
            ELSE 'Other Customers'
        END = 'Top 10%' THEN 3
        WHEN CASE
            WHEN customer_percentile_rank <= 1 THEN 'Top 1%'
            WHEN customer_percentile_rank <= 5 THEN 'Top 5%'
            WHEN customer_percentile_rank <= 10 THEN 'Top 10%'
            WHEN customer_percentile_rank <= 20 THEN 'Top 20%'
            ELSE 'Other Customers'
        END = 'Top 20%' THEN 4
        ELSE 5
    END;


-- DAY 3: TASK 20
-- Step 20I: Final Executive Business KPI Summary

WITH order_metrics AS (
    SELECT
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) AS delivered_orders
    FROM analytics.vw_order_summary
),

revenue_metrics AS (
    SELECT
        ROUND(SUM(total_item_value), 2)
            AS delivered_revenue
    FROM analytics.vw_order_summary
    WHERE order_status = 'delivered'
),

customer_metrics AS (
    SELECT
        COUNT(*) AS total_customers,
        COUNT(*) FILTER (
            WHERE delivered_orders > 0
        ) AS delivered_customers
    FROM analytics.vw_customer_purchase_behavior
),

delivery_metrics AS (
    SELECT
        COUNT(*) FILTER (
            WHERE delivery_status = 'On Time'
        ) AS on_time_orders,
        COUNT(*) FILTER (
            WHERE delivery_status IN ('On Time', 'Late')
        ) AS valid_delivery_orders
    FROM analytics.vw_on_time_delivery_analysis
),

satisfaction_metrics AS (
    SELECT
        ROUND(AVG(review_score), 2)
            AS avg_review_score,
        COUNT(*) AS reviewed_delivered_orders
    FROM analytics.vw_delivery_satisfaction
)

SELECT
    o.total_orders,
    o.delivered_orders,
    c.total_customers,
    c.delivered_customers,
    r.delivered_revenue,

    ROUND(
        r.delivered_revenue
        / NULLIF(o.delivered_orders, 0),
        2
    ) AS avg_delivered_order_value,

    ROUND(
        100.0 * d.on_time_orders
        / NULLIF(d.valid_delivery_orders, 0),
        2
    ) AS on_time_delivery_pct,

    s.avg_review_score,
    s.reviewed_delivered_orders

FROM order_metrics o
CROSS JOIN revenue_metrics r
CROSS JOIN customer_metrics c
CROSS JOIN delivery_metrics d
CROSS JOIN satisfaction_metrics s;


-- DAY 3: TASK 20
-- Step 20J: Final Overall SQL Validation

WITH checks AS (

    SELECT
        '01_Total_Orders' AS metric,
        COUNT(*)::numeric AS actual_value,
        99441::numeric AS expected_value
    FROM analytics.vw_order_summary

    UNION ALL

    SELECT
        '02_Delivered_Orders',
        COUNT(*)::numeric,
        96478::numeric
    FROM analytics.vw_order_summary
    WHERE order_status = 'delivered'

    UNION ALL

    SELECT
        '03_Delivered_Revenue',
        ROUND(SUM(total_item_value), 2),
        15419773.75::numeric
    FROM analytics.vw_order_summary
    WHERE order_status = 'delivered'

    UNION ALL

    SELECT
        '04_Total_Customers',
        COUNT(*)::numeric,
        96096::numeric
    FROM analytics.vw_customer_purchase_behavior

    UNION ALL

    SELECT
        '05_Delivered_Customers',
        COUNT(*)::numeric,
        93358::numeric
    FROM analytics.vw_customer_revenue_concentration

    UNION ALL

    SELECT
        '06_Products_Sold',
        COUNT(*)::numeric,
        32216::numeric
    FROM analytics.vw_product_sales_performance

    UNION ALL

    SELECT
        '07_Active_Sellers',
        COUNT(*)::numeric,
        2970::numeric
    FROM analytics.vw_seller_sales_performance

    UNION ALL

    SELECT
        '08_Delivery_Records',
        COUNT(*)::numeric,
        96478::numeric
    FROM analytics.vw_on_time_delivery_analysis

    UNION ALL

    SELECT
        '09_Payment_Records',
        COUNT(*)::numeric,
        103886::numeric
    FROM analytics.vw_payment_analysis

    UNION ALL

    SELECT
        '10_Reviewed_Delivered_Orders',
        COUNT(*)::numeric,
        95832::numeric
    FROM analytics.vw_delivery_satisfaction

),

validation AS (

    SELECT
        metric,
        actual_value,
        expected_value,

        CASE
            WHEN actual_value = expected_value
                THEN 'PASS'
            ELSE 'FAIL'
        END AS validation_status

    FROM checks

)

SELECT
    metric,
    actual_value,
    expected_value,
    validation_status

FROM validation

UNION ALL

SELECT
    'FINAL_VALIDATION_SUMMARY',
    COUNT(*) FILTER (
        WHERE validation_status = 'PASS'
    )::numeric,
    COUNT(*)::numeric,

    CASE
        WHEN COUNT(*) FILTER (
            WHERE validation_status = 'PASS'
        ) = COUNT(*)
            THEN 'ALL CHECKS PASSED'
        ELSE 'REVIEW REQUIRED'
    END

FROM validation

ORDER BY metric;
