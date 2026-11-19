
CREATE OR REPLACE VIEW analytics.vw_customer_ml_features AS

WITH customer_base AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT customer_id) AS customer_id_count
    FROM olist.customers
    GROUP BY customer_unique_id
),

customer_location AS (
    SELECT DISTINCT ON (c.customer_unique_id)
        c.customer_unique_id,
        c.customer_city,
        c.customer_state
    FROM olist.customers c
    LEFT JOIN olist.orders o
        ON c.customer_id = o.customer_id
    ORDER BY
        c.customer_unique_id,
        o.order_purchase_timestamp DESC NULLS LAST,
        c.customer_id
),

item_totals AS (
    SELECT
        order_id,
        SUM(price) AS item_revenue,
        SUM(freight_value) AS freight_total,
        COUNT(*) AS item_count
    FROM olist.order_items
    GROUP BY order_id
),

review_totals AS (
    SELECT
        order_id,
        AVG(review_score::numeric) AS average_review_score
    FROM olist.order_reviews
    GROUP BY order_id
),

order_features AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,

        COALESCE(i.item_revenue, 0) AS item_revenue,
        COALESCE(i.freight_total, 0) AS freight_total,
        COALESCE(i.item_count, 0) AS item_count,

        r.average_review_score,

        CASE
            WHEN o.order_status = 'delivered'
            THEN EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400.0
        END AS delivery_days

    FROM olist.orders o
    JOIN olist.customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN item_totals i
        ON o.order_id = i.order_id
    LEFT JOIN review_totals r
        ON o.order_id = r.order_id
),

dataset_reference AS (
    SELECT
        MAX(order_purchase_timestamp)::date + 1 AS reference_date
    FROM olist.orders
),

customer_metrics AS (
    SELECT
        customer_unique_id,

        COUNT(DISTINCT order_id) AS total_orders,

        COUNT(DISTINCT order_id)
            FILTER (WHERE order_status = 'delivered')
            AS delivered_orders,

        COUNT(DISTINCT order_id)
            FILTER (WHERE order_status = 'canceled')
            AS canceled_orders,

        COUNT(DISTINCT order_id)
            FILTER (WHERE order_status = 'unavailable')
            AS unavailable_orders,

        SUM(item_revenue)
            FILTER (WHERE order_status = 'delivered')
            AS delivered_item_revenue,

        SUM(freight_total)
            FILTER (WHERE order_status = 'delivered')
            AS delivered_freight,

        SUM(item_count)
            FILTER (WHERE order_status = 'delivered')
            AS delivered_item_count,

        AVG(item_revenue)
            FILTER (WHERE order_status = 'delivered')
            AS average_delivered_order_value,

        MIN(order_purchase_timestamp) AS first_purchase_date,
        MAX(order_purchase_timestamp) AS last_purchase_date,

        AVG(delivery_days)
            FILTER (WHERE delivery_days IS NOT NULL)
            AS average_delivery_days,

        AVG(average_review_score)
            AS average_review_score,

        COUNT(DISTINCT order_id)
            FILTER (WHERE average_review_score IS NOT NULL)
            AS reviewed_orders

    FROM order_features
    GROUP BY customer_unique_id
)

SELECT
    b.customer_unique_id,
    b.customer_id_count,

    l.customer_city,
    l.customer_state,

    COALESCE(m.total_orders, 0) AS total_orders,
    COALESCE(m.delivered_orders, 0) AS delivered_orders,
    COALESCE(m.canceled_orders, 0) AS canceled_orders,
    COALESCE(m.unavailable_orders, 0) AS unavailable_orders,

    COALESCE(m.delivered_item_revenue, 0)
        AS delivered_item_revenue,

    COALESCE(m.delivered_freight, 0)
        AS delivered_freight,

    COALESCE(m.delivered_item_count, 0)
        AS delivered_item_count,

    m.average_delivered_order_value,

    m.first_purchase_date,
    m.last_purchase_date,

    CASE
        WHEN m.last_purchase_date IS NOT NULL
        THEN (
            d.reference_date - m.last_purchase_date::date
        )
    END AS recency_days,

    m.average_delivery_days,
    m.average_review_score,
    COALESCE(m.reviewed_orders, 0) AS reviewed_orders,

    CASE
        WHEN COALESCE(m.total_orders, 0) > 1 THEN 1
        ELSE 0
    END AS repeat_customer,

    d.reference_date AS feature_reference_date

FROM customer_base b
LEFT JOIN customer_location l
    ON b.customer_unique_id = l.customer_unique_id
LEFT JOIN customer_metrics m
    ON b.customer_unique_id = m.customer_unique_id
CROSS JOIN dataset_reference d;


SELECT
    COUNT(*) AS feature_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM analytics.vw_customer_ml_features;


SELECT *
FROM analytics.vw_customer_ml_features
ORDER BY total_orders DESC
LIMIT 10;


SELECT
    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE total_orders < 0
    ) AS invalid_order_counts,

    COUNT(*) FILTER (
        WHERE delivered_item_revenue < 0
    ) AS negative_revenue,

    COUNT(*) FILTER (
        WHERE recency_days < 0
    ) AS negative_recency,

    COUNT(*) FILTER (
        WHERE average_review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores

FROM analytics.vw_customer_ml_features;



SELECT
    COUNT(*) AS total_customers,
    SUM(total_orders) AS total_orders,
    SUM(delivered_orders) AS delivered_orders,
    ROUND(SUM(delivered_item_revenue), 2) AS delivered_revenue,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    COUNT(*) FILTER (
        WHERE repeat_customer = 1
    ) AS repeat_customers
FROM analytics.vw_customer_ml_features;



SELECT
    ROUND(SUM(delivered_item_revenue), 2)
        AS delivered_product_revenue,

    ROUND(SUM(delivered_freight), 2)
        AS delivered_freight_revenue,

    ROUND(
        SUM(delivered_item_revenue + delivered_freight),
        2
    ) AS delivered_revenue_including_freight

FROM analytics.vw_customer_ml_features;

SELECT
    (SELECT COUNT(*)
     FROM olist.orders) AS source_orders,

    (SELECT SUM(total_orders)
     FROM analytics.vw_customer_ml_features) AS feature_orders,

    (SELECT COUNT(*)
     FROM olist.orders
     WHERE order_status = 'delivered') AS source_delivered_orders,

    (SELECT SUM(delivered_orders)
     FROM analytics.vw_customer_ml_features) AS feature_delivered_orders;


SELECT *
FROM analytics.vw_customer_ml_features
LIMIT 5;

SELECT *
FROM analytics.vw_customer_ml_features;