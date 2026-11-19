
-- DAY 2: TASK 6
-- Step 6A: Examine order status distribution

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- DAY 2: TASK 6
-- Step 6B: Validate order status formatting

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status IS NULL
    ) AS null_statuses,

    COUNT(*) FILTER (
        WHERE order_status IS NOT NULL
          AND order_status <> LOWER(TRIM(order_status))
    ) AS inconsistent_formatting,

    COUNT(*) FILTER (
        WHERE order_status IS NOT NULL
          AND LOWER(TRIM(order_status)) NOT IN (
              'delivered',
              'shipped',
              'canceled',
              'unavailable',
              'invoiced',
              'processing',
              'created',
              'approved'
          )
    ) AS unexpected_statuses

FROM olist.orders;

-- DAY 2: TASK 6
-- Step 6C: Validate order timestamps

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery

FROM olist.orders;

-- DAY 2: TASK 6
-- Step 6D: Validate timestamp chronology

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_approved_at <
              order_purchase_timestamp
    ) AS approval_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date <
              order_purchase_timestamp
    ) AS carrier_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date <
              order_delivered_carrier_date
    ) AS delivery_before_carrier,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date <
              order_purchase_timestamp
    ) AS delivery_before_purchase

FROM olist.orders;

-- DAY 2: TASK 6
-- Step 6E: Missing timestamps by order status

SELECT
    order_status,
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery

FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- DAY 2: TASK 6
-- Step 6F: Final timestamp quality summary

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_approved_at IS NULL
    ) AS delivered_missing_approval,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_carrier_date IS NULL
    ) AS delivered_missing_carrier,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NULL
    ) AS delivered_missing_delivery,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date <
              order_purchase_timestamp
    ) AS carrier_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date <
              order_delivered_carrier_date
    ) AS delivery_before_carrier,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery

FROM olist.orders;
