
-- TASK 13
-- Step 13A: Validate Delivery Timestamp Data
-- Delivered orders only

SELECT
    COUNT(*) AS total_delivered_orders,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NOT NULL
    ) AS orders_with_purchase_date,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NOT NULL
    ) AS orders_with_approval_date,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NOT NULL
    ) AS orders_with_carrier_date,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NOT NULL
    ) AS orders_with_delivery_date,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NOT NULL
    ) AS orders_with_estimated_date,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              < order_purchase_timestamp
    ) AS delivery_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date
              < order_purchase_timestamp
    ) AS carrier_before_purchase,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date
              < order_purchase_timestamp
    ) AS estimated_before_purchase

FROM analytics.vw_orders_clean

WHERE order_status = 'delivered';

-- DAY 3: TASK 13
-- Step 13B: Average Delivery Time Analysis
-- Delivered orders only

WITH delivery_times AS (
    SELECT
        order_id,

        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )
        ) / 86400.0 AS delivery_days

    FROM analytics.vw_orders_clean

    WHERE order_status = 'delivered'
      AND order_purchase_timestamp IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL
      AND order_delivered_customer_date
          >= order_purchase_timestamp
)

SELECT
    COUNT(*) AS valid_delivered_orders,

    ROUND(AVG(delivery_days), 2)
        AS avg_delivery_days,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY delivery_days)::numeric,
        2
    ) AS median_delivery_days,

    ROUND(MIN(delivery_days), 2)
        AS min_delivery_days,

    ROUND(MAX(delivery_days), 2)
        AS max_delivery_days,

    ROUND(STDDEV_SAMP(delivery_days), 2)
        AS delivery_days_stddev,

    COUNT(*) FILTER (
        WHERE delivery_days <= 7
    ) AS delivered_within_7_days,

    COUNT(*) FILTER (
        WHERE delivery_days > 30
    ) AS delivered_after_30_days

FROM delivery_times;

-- DAY 3: TASK 13
-- Step 13C: Delivery Speed Distribution
-- Delivered orders only

WITH delivery_times AS (
    SELECT
        order_id,

        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )
        ) / 86400.0 AS delivery_days

    FROM analytics.vw_orders_clean

    WHERE order_status = 'delivered'
      AND order_purchase_timestamp IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL
      AND order_delivered_customer_date
          >= order_purchase_timestamp
),

delivery_groups AS (
    SELECT
        order_id,
        delivery_days,

        CASE
            WHEN delivery_days <= 3
                THEN '0-3 Days'

            WHEN delivery_days <= 7
                THEN '3-7 Days'

            WHEN delivery_days <= 14
                THEN '7-14 Days'

            WHEN delivery_days <= 21
                THEN '14-21 Days'

            WHEN delivery_days <= 30
                THEN '21-30 Days'

            ELSE 'Over 30 Days'
        END AS delivery_speed_group

    FROM delivery_times
)

SELECT
    delivery_speed_group,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(delivery_days), 2
    ) AS avg_delivery_days,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (), 2
    ) AS order_share_pct

FROM delivery_groups

GROUP BY delivery_speed_group

ORDER BY
    CASE delivery_speed_group
        WHEN '0-3 Days' THEN 1
        WHEN '3-7 Days' THEN 2
        WHEN '7-14 Days' THEN 3
        WHEN '14-21 Days' THEN 4
        WHEN '21-30 Days' THEN 5
        ELSE 6
    END;

-- DAY 3: TASK 13
-- Step 13D: Actual vs Estimated Delivery Time
-- Delivered orders only

WITH delivery_comparison AS (
    SELECT
        order_id,

        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_estimated_delivery_date
            )
        ) / 86400.0 AS delivery_difference_days

    FROM analytics.vw_orders_clean

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
      AND order_delivered_customer_date
          >= order_purchase_timestamp
)

SELECT
    COUNT(*) AS valid_delivered_orders,

    COUNT(*) FILTER (
        WHERE delivery_difference_days <= 0
    ) AS on_time_or_early_orders,

    COUNT(*) FILTER (
        WHERE delivery_difference_days > 0
    ) AS late_orders,

    ROUND(
        AVG(delivery_difference_days), 2
    ) AS avg_delivery_difference_days,

    ROUND(
        AVG(delivery_difference_days) FILTER (
            WHERE delivery_difference_days > 0
        ), 2
    ) AS avg_late_days,

    ROUND(
        AVG(ABS(delivery_difference_days)) FILTER (
            WHERE delivery_difference_days < 0
        ), 2
    ) AS avg_early_days,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_difference_days <= 0
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_or_early_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_difference_days > 0
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_pct

FROM delivery_comparison;

-- DAY 3: TASK 13
-- Step 13E: Create Delivery Time Reporting View
-- Delivered orders only

CREATE OR REPLACE VIEW
analytics.vw_delivery_time_analysis AS

WITH delivery_base AS (
    SELECT
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,

        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )
        ) / 86400.0 AS delivery_days,

        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_estimated_delivery_date
            )
        ) / 86400.0 AS delivery_difference_days

    FROM analytics.vw_orders_clean

    WHERE order_status = 'delivered'
)

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    ROUND(delivery_days, 2)
        AS delivery_days,

    ROUND(delivery_difference_days, 2)
        AS delivery_difference_days,

    CASE
        WHEN delivery_days IS NULL
            THEN 'Missing Delivery Date'

        WHEN delivery_days < 0
            THEN 'Invalid Delivery Time'

        WHEN delivery_days <= 3
            THEN '0-3 Days'

        WHEN delivery_days <= 7
            THEN '3-7 Days'

        WHEN delivery_days <= 14
            THEN '7-14 Days'

        WHEN delivery_days <= 21
            THEN '14-21 Days'

        WHEN delivery_days <= 30
            THEN '21-30 Days'

        ELSE 'Over 30 Days'
    END AS delivery_speed_group,

    CASE
        WHEN delivery_difference_days IS NULL
            THEN 'Missing Delivery Date'

        WHEN delivery_days < 0
            THEN 'Invalid Delivery Time'

        WHEN delivery_difference_days <= 0
            THEN 'On Time or Early'

        ELSE 'Late'
    END AS delivery_timestamp_status,

    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN 0

        WHEN order_purchase_timestamp IS NULL
            THEN 0

        WHEN order_delivered_customer_date
             < order_purchase_timestamp
            THEN 0

        ELSE 1
    END AS valid_delivery_flag

FROM delivery_base;

-- DAY 3: TASK 13
-- Step 13F: Final Delivery Time Validation

SELECT
    COUNT(*) AS total_delivered_orders,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_orders,

    COUNT(*) FILTER (
        WHERE valid_delivery_flag = 1
    ) AS valid_delivery_orders,

    COUNT(*) FILTER (
        WHERE valid_delivery_flag = 0
    ) AS invalid_or_missing_orders,

    COUNT(*) FILTER (
        WHERE delivery_speed_group = '0-3 Days'
    ) AS delivered_0_3_days,

    COUNT(*) FILTER (
        WHERE delivery_speed_group = '3-7 Days'
    ) AS delivered_3_7_days,

    COUNT(*) FILTER (
        WHERE delivery_speed_group = '7-14 Days'
    ) AS delivered_7_14_days,

    COUNT(*) FILTER (
        WHERE delivery_speed_group = '14-21 Days'
    ) AS delivered_14_21_days,

    COUNT(*) FILTER (
        WHERE delivery_speed_group = '21-30 Days'
    ) AS delivered_21_30_days,

    COUNT(*) FILTER (
        WHERE delivery_speed_group = 'Over 30 Days'
    ) AS delivered_over_30_days,

    COUNT(*) FILTER (
        WHERE delivery_timestamp_status = 'On Time or Early'
    ) AS on_time_or_early_orders,

    COUNT(*) FILTER (
        WHERE delivery_timestamp_status = 'Late'
    ) AS late_orders,

    ROUND(
        AVG(delivery_days) FILTER (
            WHERE valid_delivery_flag = 1
        ), 2
    ) AS avg_delivery_days,

    COUNT(*) FILTER (
        WHERE delivery_speed_group = 'Missing Delivery Date'
    ) AS missing_delivery_group,

    COUNT(*) FILTER (
        WHERE valid_delivery_flag = 1
          AND (
              delivery_days IS NULL
              OR delivery_days < 0
          )
    ) AS invalid_flagged_records

FROM analytics.vw_delivery_time_analysis;

-- DAY 3: TASK 14
-- Step 14A: Calendar-Date On-Time Delivery Rate

WITH delivery_status AS (
    SELECT
        order_id,

        CASE
            WHEN order_delivered_customer_date::date
                 <= order_estimated_delivery_date::date
                THEN 'On Time'

            ELSE 'Late'
        END AS delivery_status

    FROM analytics.vw_delivery_time_analysis

    WHERE valid_delivery_flag = 1
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    COUNT(*) AS total_valid_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'On Time'
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_status = 'On Time'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_status = 'Late'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_pct

FROM delivery_status;

-- DAY 3: TASK 14
-- Step 14B: Late Delivery Severity Analysis
-- Calendar-date comparison

WITH late_deliveries AS (
    SELECT
        order_id,

        (
            order_delivered_customer_date::date
            - order_estimated_delivery_date::date
        ) AS days_late

    FROM analytics.vw_delivery_time_analysis

    WHERE valid_delivery_flag = 1
      AND order_estimated_delivery_date IS NOT NULL
      AND order_delivered_customer_date::date
          > order_estimated_delivery_date::date
),

delay_groups AS (
    SELECT
        order_id,
        days_late,

        CASE
            WHEN days_late BETWEEN 1 AND 3
                THEN '1-3 Days Late'

            WHEN days_late BETWEEN 4 AND 7
                THEN '4-7 Days Late'

            WHEN days_late BETWEEN 8 AND 14
                THEN '8-14 Days Late'

            WHEN days_late BETWEEN 15 AND 30
                THEN '15-30 Days Late'

            ELSE 'Over 30 Days Late'
        END AS delay_group

    FROM late_deliveries
)

SELECT
    delay_group,

    COUNT(*) AS late_orders,

    ROUND(
        AVG(days_late), 2
    ) AS avg_days_late,

    MAX(days_late) AS max_days_late,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS late_order_share_pct

FROM delay_groups

GROUP BY delay_group

ORDER BY
    CASE delay_group
        WHEN '1-3 Days Late' THEN 1
        WHEN '4-7 Days Late' THEN 2
        WHEN '8-14 Days Late' THEN 3
        WHEN '15-30 Days Late' THEN 4
        ELSE 5
    END;

-- DAY 3: TASK 14
-- Step 14C: Monthly On-Time Delivery Performance
-- Grouped by purchase month

WITH monthly_delivery AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS purchase_month,

        order_id,

        CASE
            WHEN order_delivered_customer_date::date
                 <= order_estimated_delivery_date::date
                THEN 1
            ELSE 0
        END AS on_time_flag

    FROM analytics.vw_delivery_time_analysis

    WHERE valid_delivery_flag = 1
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    purchase_month,

    COUNT(*) AS delivered_orders,

    SUM(on_time_flag) AS on_time_orders,

    COUNT(*) - SUM(on_time_flag)
        AS late_orders,

    ROUND(
        100.0 * SUM(on_time_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_pct,

    ROUND(
        100.0 * (
            COUNT(*) - SUM(on_time_flag)
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_pct

FROM monthly_delivery

GROUP BY purchase_month

ORDER BY purchase_month;

-- DAY 3: TASK 14
-- Step 14D: Validate Monthly Delivery Totals

WITH monthly_delivery AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS purchase_month,

        COUNT(*) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE order_delivered_customer_date::date
                  <= order_estimated_delivery_date::date
        ) AS on_time_orders,

        COUNT(*) FILTER (
            WHERE order_delivered_customer_date::date
                  > order_estimated_delivery_date::date
        ) AS late_orders

    FROM analytics.vw_delivery_time_analysis

    WHERE valid_delivery_flag = 1
      AND order_estimated_delivery_date IS NOT NULL

    GROUP BY 1
)

SELECT
    COUNT(*) AS total_months,

    SUM(delivered_orders) AS total_delivered_orders,

    SUM(on_time_orders) AS total_on_time_orders,

    SUM(late_orders) AS total_late_orders,

    SUM(delivered_orders)
      - SUM(on_time_orders)
      - SUM(late_orders)
        AS unclassified_orders,

    ROUND(
        100.0 * SUM(on_time_orders)
        / NULLIF(SUM(delivered_orders), 0),
        2
    ) AS overall_on_time_pct

FROM monthly_delivery;

-- DAY 3: TASK 14
-- Step 14E: Create On-Time Delivery Reporting View

CREATE OR REPLACE VIEW
analytics.vw_on_time_delivery_analysis AS

WITH delivery_base AS (
    SELECT
        order_id,
        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        delivery_days,
        valid_delivery_flag,

        (
            order_delivered_customer_date::date
            - order_estimated_delivery_date::date
        ) AS delivery_difference_calendar_days

    FROM analytics.vw_delivery_time_analysis
),

delivery_classification AS (
    SELECT
        *,

        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS purchase_month,

        CASE
            WHEN valid_delivery_flag = 0
                 OR order_estimated_delivery_date IS NULL
                THEN 'Missing or Invalid'

            WHEN delivery_difference_calendar_days <= 0
                THEN 'On Time'

            ELSE 'Late'
        END AS delivery_status,

        CASE
            WHEN valid_delivery_flag = 1
                 AND order_estimated_delivery_date IS NOT NULL
                 AND delivery_difference_calendar_days <= 0
                THEN 1
            ELSE 0
        END AS on_time_flag,

        CASE
            WHEN valid_delivery_flag = 1
                 AND delivery_difference_calendar_days > 0
                THEN 1
            ELSE 0
        END AS late_flag

    FROM delivery_base
)

SELECT
    order_id,
    purchase_month,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    delivery_days,
    delivery_difference_calendar_days,
    delivery_status,
    on_time_flag,
    late_flag,
    valid_delivery_flag,

    CASE
        WHEN delivery_status = 'Missing or Invalid'
            THEN 'Missing or Invalid'

        WHEN delivery_status = 'On Time'
            THEN 'On Time'

        WHEN delivery_difference_calendar_days BETWEEN 1 AND 3
            THEN '1-3 Days Late'

        WHEN delivery_difference_calendar_days BETWEEN 4 AND 7
            THEN '4-7 Days Late'

        WHEN delivery_difference_calendar_days BETWEEN 8 AND 14
            THEN '8-14 Days Late'

        WHEN delivery_difference_calendar_days BETWEEN 15 AND 30
            THEN '15-30 Days Late'

        ELSE 'Over 30 Days Late'
    END AS delay_severity_group

FROM delivery_classification;

-- DAY 3: TASK 14
-- Step 14F: Final On-Time Delivery Validation

SELECT
    COUNT(*) AS total_delivered_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_orders,

    COUNT(*) FILTER (
        WHERE valid_delivery_flag = 1
    ) AS valid_delivery_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'On Time'
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Missing or Invalid'
    ) AS missing_or_invalid_orders,

    SUM(on_time_flag) AS total_on_time_flags,

    SUM(late_flag) AS total_late_flags,

    ROUND(
        100.0 * SUM(on_time_flag)
        / NULLIF(
            COUNT(*) FILTER (
                WHERE valid_delivery_flag = 1
            ), 0
        ),
        2
    ) AS on_time_delivery_pct,

    COUNT(*) FILTER (
        WHERE delay_severity_group = '1-3 Days Late'
    ) AS late_1_3_days,

    COUNT(*) FILTER (
        WHERE delay_severity_group = '4-7 Days Late'
    ) AS late_4_7_days,

    COUNT(*) FILTER (
        WHERE delay_severity_group = '8-14 Days Late'
    ) AS late_8_14_days,

    COUNT(*) FILTER (
        WHERE delay_severity_group = '15-30 Days Late'
    ) AS late_15_30_days,

    COUNT(*) FILTER (
        WHERE delay_severity_group = 'Over 30 Days Late'
    ) AS late_over_30_days,

    COUNT(*) FILTER (
        WHERE
            (delivery_status = 'On Time'
                AND (on_time_flag <> 1 OR late_flag <> 0))
            OR
            (delivery_status = 'Late'
                AND (late_flag <> 1 OR on_time_flag <> 0))
            OR
            (delivery_status = 'Missing or Invalid'
                AND (on_time_flag <> 0 OR late_flag <> 0))
            OR delivery_status IS NULL
            OR on_time_flag IS NULL
            OR late_flag IS NULL
    ) AS invalid_classification_records

FROM analytics.vw_on_time_delivery_analysis;

-- DAY 3: TASK 15
-- Step 15A: Validate Payment Data

SELECT
    COUNT(*) AS total_payment_records,

    COUNT(DISTINCT order_id)
        AS orders_with_payments,

    COUNT(DISTINCT payment_type)
        AS payment_method_count,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_ids,

    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS missing_payment_methods,

    COUNT(*) FILTER (
        WHERE payment_installments IS NULL
    ) AS missing_installment_values,

    COUNT(*) FILTER (
        WHERE payment_value IS NULL
    ) AS missing_payment_values,

    COUNT(*) FILTER (
        WHERE payment_value < 0
    ) AS negative_payment_values,

    COUNT(*) FILTER (
        WHERE payment_installments < 0
    ) AS negative_installment_values,

    ROUND(
        SUM(payment_value), 2
    ) AS total_payment_value

FROM olist.order_payments;


-- DAY 3: TASK 15
-- Step 15B: Payment Method Distribution
-- All order statuses

SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(
        SUM(payment_value), 2
    ) AS total_payment_value,

    ROUND(
        AVG(payment_value), 2
    ) AS avg_payment_value,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS payment_record_share_pct,

    ROUND(
        100.0 * SUM(payment_value)
        / SUM(SUM(payment_value)) OVER (),
        2
    ) AS payment_value_share_pct

FROM olist.order_payments

GROUP BY payment_type

ORDER BY total_payment_value DESC;

-- DAY 3: TASK 15
-- Step 15C: Payment Installment Analysis
-- All order statuses

WITH installment_groups AS (
    SELECT
        order_id,
        payment_type,
        payment_installments,
        payment_value,

        CASE
            WHEN payment_installments = 0
                THEN '0 Installments'

            WHEN payment_installments = 1
                THEN '1 Installment'

            WHEN payment_installments BETWEEN 2 AND 3
                THEN '2-3 Installments'

            WHEN payment_installments BETWEEN 4 AND 6
                THEN '4-6 Installments'

            WHEN payment_installments BETWEEN 7 AND 10
                THEN '7-10 Installments'

            ELSE '11+ Installments'
        END AS installment_group

    FROM olist.order_payments
)

SELECT
    installment_group,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(
        SUM(payment_value), 2
    ) AS total_payment_value,

    ROUND(
        AVG(payment_value), 2
    ) AS avg_payment_value,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS payment_record_share_pct,

    ROUND(
        100.0 * SUM(payment_value)
        / NULLIF(
            SUM(SUM(payment_value)) OVER (), 0
        ),
        2
    ) AS payment_value_share_pct

FROM installment_groups

GROUP BY installment_group

ORDER BY
    CASE installment_group
        WHEN '0 Installments' THEN 1
        WHEN '1 Installment' THEN 2
        WHEN '2-3 Installments' THEN 3
        WHEN '4-6 Installments' THEN 4
        WHEN '7-10 Installments' THEN 5
        ELSE 6
    END;

-- DAY 3: TASK 15
-- Step 15D: Payment Methods vs Installments
-- All order statuses

SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(*) FILTER (
        WHERE payment_installments = 0
    ) AS zero_installment_records,

    COUNT(*) FILTER (
        WHERE payment_installments = 1
    ) AS single_installment_records,

    COUNT(*) FILTER (
        WHERE payment_installments >= 2
    ) AS multiple_installment_records,

    ROUND(
        AVG(payment_installments), 2
    ) AS avg_installments,

    MAX(payment_installments)
        AS max_installments,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE payment_installments >= 2
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS multiple_installment_pct,

    ROUND(
        SUM(payment_value), 2
    ) AS total_payment_value

FROM olist.order_payments

GROUP BY payment_type

ORDER BY payment_records DESC;

-- DAY 3: TASK 15
-- Step 15E: Create Payment Analysis Reporting View

CREATE OR REPLACE VIEW
analytics.vw_payment_analysis AS

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,

    CASE
        WHEN payment_installments = 0
            THEN '0 Installments'

        WHEN payment_installments = 1
            THEN '1 Installment'

        WHEN payment_installments BETWEEN 2 AND 3
            THEN '2-3 Installments'

        WHEN payment_installments BETWEEN 4 AND 6
            THEN '4-6 Installments'

        WHEN payment_installments BETWEEN 7 AND 10
            THEN '7-10 Installments'

        ELSE '11+ Installments'
    END AS installment_group,

    CASE
        WHEN payment_installments >= 2
            THEN 1
        ELSE 0
    END AS multiple_installment_flag,

    CASE
        WHEN payment_installments = 0
            THEN 1
        ELSE 0
    END AS zero_installment_flag,

    CASE
        WHEN payment_type = 'not_defined'
            THEN 1
        ELSE 0
    END AS undefined_payment_flag,

    CASE
        WHEN payment_type = 'credit_card'
            THEN 'Credit Card'

        WHEN payment_type = 'boleto'
            THEN 'Boleto'

        WHEN payment_type = 'voucher'
            THEN 'Voucher'

        WHEN payment_type = 'debit_card'
            THEN 'Debit Card'

        ELSE 'Not Defined'
    END AS payment_method_label

FROM olist.order_payments;

-- DAY 3: TASK 15
-- Step 15F: Final Payment Analysis Validation

SELECT
    COUNT(*) AS total_payment_records,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    COUNT(DISTINCT payment_type)
        AS payment_method_count,

    COUNT(*) FILTER (
        WHERE multiple_installment_flag = 1
    ) AS multiple_installment_records,

    COUNT(*) FILTER (
        WHERE zero_installment_flag = 1
    ) AS zero_installment_records,

    COUNT(*) FILTER (
        WHERE undefined_payment_flag = 1
    ) AS undefined_payment_records,

    COUNT(*) FILTER (
        WHERE payment_type = 'credit_card'
    ) AS credit_card_records,

    COUNT(*) FILTER (
        WHERE payment_type = 'boleto'
    ) AS boleto_records,

    COUNT(*) FILTER (
        WHERE payment_type = 'voucher'
    ) AS voucher_records,

    COUNT(*) FILTER (
        WHERE payment_type = 'debit_card'
    ) AS debit_card_records,

    ROUND(
        SUM(payment_value), 2
    ) AS total_payment_value,

    COUNT(*) FILTER (
        WHERE payment_value IS NULL
           OR payment_value < 0
           OR payment_installments IS NULL
           OR payment_installments < 0
           OR installment_group IS NULL
           OR payment_method_label IS NULL
           OR multiple_installment_flag IS NULL
           OR zero_installment_flag IS NULL
           OR undefined_payment_flag IS NULL
           OR multiple_installment_flag
              <> CASE
                    WHEN payment_installments >= 2 THEN 1
                    ELSE 0
                 END
           OR zero_installment_flag
              <> CASE
                    WHEN payment_installments = 0 THEN 1
                    ELSE 0
                 END
           OR undefined_payment_flag
              <> CASE
                    WHEN payment_type = 'not_defined' THEN 1
                    ELSE 0
                 END
    ) AS invalid_payment_records

FROM analytics.vw_payment_analysis;

-- DAY 3: TASK 16
-- Step 16A: Validate Customer Review Data

SELECT
    COUNT(*) AS total_review_records,

    COUNT(DISTINCT review_id)
        AS unique_review_ids,

    COUNT(DISTINCT order_id)
        AS orders_with_reviews,

    COUNT(*) - COUNT(DISTINCT review_id)
        AS duplicate_review_ids,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS additional_reviews_per_order,

    COUNT(*) FILTER (
        WHERE review_id IS NULL
    ) AS missing_review_ids,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_ids,

    COUNT(*) FILTER (
        WHERE review_score IS NULL
    ) AS missing_review_scores,

    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores,

    ROUND(
        AVG(review_score), 2
    ) AS avg_review_score,

    MIN(review_score)
        AS min_review_score,

    MAX(review_score)
        AS max_review_score

FROM olist.order_reviews;

-- DAY 3: TASK 16
-- Step 16B: Customer Review Score Distribution
-- Review-record level

SELECT
    review_score,

    COUNT(*) AS review_records,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS review_share_pct,

    CASE
        WHEN review_score IN (4, 5)
            THEN 'Positive'

        WHEN review_score = 3
            THEN 'Neutral'

        ELSE 'Negative'
    END AS satisfaction_group

FROM olist.order_reviews

GROUP BY review_score

ORDER BY review_score DESC;

-- DAY 3: TASK 16
-- Step 16C: Investigate Duplicate Review IDs

WITH review_id_analysis AS (
    SELECT
        review_id,

        COUNT(*) AS record_count,

        COUNT(DISTINCT order_id)
            AS distinct_orders,

        COUNT(DISTINCT review_score)
            AS distinct_scores

    FROM olist.order_reviews

    GROUP BY review_id
),

duplicate_reviews AS (
    SELECT *
    FROM review_id_analysis
    WHERE record_count > 1
)

SELECT
    COUNT(*) AS duplicated_review_ids,

    COALESCE(
        SUM(record_count), 0
    ) AS records_with_duplicated_ids,

    COALESCE(
        SUM(record_count - 1), 0
    ) AS additional_review_id_occurrences,

    COUNT(*) FILTER (
        WHERE distinct_orders > 1
    ) AS review_ids_with_multiple_orders,

    COUNT(*) FILTER (
        WHERE distinct_scores > 1
    ) AS review_ids_with_multiple_scores,

    MAX(record_count)
        AS max_records_per_review_id

FROM duplicate_reviews;


-- DAY 3: TASK 16
-- Step 16D: Investigate Multiple Reviews per Order

WITH order_review_analysis AS (
    SELECT
        order_id,

        COUNT(*) AS review_records,

        COUNT(DISTINCT review_id)
            AS distinct_review_ids,

        COUNT(DISTINCT review_score)
            AS distinct_review_scores,

        MIN(review_score) AS min_review_score,

        MAX(review_score) AS max_review_score

    FROM olist.order_reviews

    GROUP BY order_id
),

multiple_review_orders AS (
    SELECT *
    FROM order_review_analysis
    WHERE review_records > 1
)

SELECT
    COUNT(*) AS orders_with_multiple_reviews,

    COALESCE(
        SUM(review_records), 0
    ) AS records_in_multiple_review_orders,

    COALESCE(
        SUM(review_records - 1), 0
    ) AS additional_review_records,

    COUNT(*) FILTER (
        WHERE distinct_review_ids > 1
    ) AS orders_with_different_review_ids,

    COUNT(*) FILTER (
        WHERE distinct_review_scores > 1
    ) AS orders_with_conflicting_scores,

    COUNT(*) FILTER (
        WHERE distinct_review_scores = 1
    ) AS orders_with_consistent_scores,

    MAX(review_records)
        AS max_reviews_per_order

FROM multiple_review_orders;


-- DAY 3: TASK 16
-- Step 16E: Validate Review Timestamps

SELECT
    COUNT(*) AS total_review_records,

    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS missing_creation_dates,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS missing_answer_timestamps,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp
              < review_creation_date
    ) AS answer_before_creation,

    MIN(review_creation_date)
        AS earliest_review_creation,

    MAX(review_creation_date)
        AS latest_review_creation,

    MIN(review_answer_timestamp)
        AS earliest_review_answer,

    MAX(review_answer_timestamp)
        AS latest_review_answer,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NOT NULL
          AND review_creation_date IS NOT NULL
          AND review_answer_timestamp >= review_creation_date
    ) AS valid_review_timestamps

FROM olist.order_reviews;

-- DAY 3: TASK 16
-- Step 16F: Create Order-Level Satisfaction View

CREATE OR REPLACE VIEW
analytics.vw_customer_satisfaction AS

WITH ranked_reviews AS (

    SELECT
        review_id,
        order_id,
        review_score,
        review_creation_date,
        review_answer_timestamp,

        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS review_records_per_order,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                review_answer_timestamp DESC,
                review_creation_date DESC,
                review_id DESC
        ) AS review_rank

    FROM olist.order_reviews
)

SELECT
    order_id,
    review_id,
    review_score,
    review_creation_date,
    review_answer_timestamp,
    review_records_per_order,

    CASE
        WHEN review_score >= 4
            THEN 'Positive'
        WHEN review_score = 3
            THEN 'Neutral'
        ELSE 'Negative'
    END AS satisfaction_group,

    CASE
        WHEN review_score >= 4 THEN 1
        ELSE 0
    END AS positive_review_flag,

    CASE
        WHEN review_score <= 2 THEN 1
        ELSE 0
    END AS negative_review_flag,

    CASE
        WHEN review_records_per_order > 1 THEN 1
        ELSE 0
    END AS multiple_reviews_flag

FROM ranked_reviews

WHERE review_rank = 1;

-- DAY 3: TASK 16
-- Step 16G: Validate Customer Satisfaction View

SELECT
    COUNT(*) AS total_reviewed_orders,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_order_records,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Positive'
    ) AS positive_orders,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Neutral'
    ) AS neutral_orders,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Negative'
    ) AS negative_orders,

    ROUND(
        AVG(review_score), 2
    ) AS avg_review_score,

    COUNT(*) FILTER (
        WHERE multiple_reviews_flag = 1
    ) AS orders_with_multiple_reviews,

    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
           OR review_score IS NULL
           OR satisfaction_group IS NULL
           OR positive_review_flag
              <> CASE
                    WHEN review_score >= 4 THEN 1
                    ELSE 0
                 END
           OR negative_review_flag
              <> CASE
                    WHEN review_score <= 2 THEN 1
                    ELSE 0
                 END
           OR multiple_reviews_flag
              <> CASE
                    WHEN review_records_per_order > 1 THEN 1
                    ELSE 0
                 END
           OR satisfaction_group
              <> CASE
                    WHEN review_score >= 4 THEN 'Positive'
                    WHEN review_score = 3 THEN 'Neutral'
                    ELSE 'Negative'
                 END
    ) AS invalid_records

FROM analytics.vw_customer_satisfaction;

-- DAY 3: TASK 16
-- Step 16H: Delivery Performance vs Satisfaction

WITH delivery_reviews AS (

    SELECT
        d.order_id,
        d.delivery_status,
        s.review_score,
        s.satisfaction_group

    FROM analytics.vw_on_time_delivery_analysis d

    INNER JOIN analytics.vw_customer_satisfaction s
        ON d.order_id = s.order_id

)

SELECT
    delivery_status,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score), 2
    ) AS avg_review_score,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Positive'
    ) AS positive_orders,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Negative'
    ) AS negative_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE satisfaction_group = 'Positive'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS positive_review_rate_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE satisfaction_group = 'Negative'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS negative_review_rate_pct

FROM delivery_reviews

GROUP BY delivery_status

ORDER BY reviewed_orders DESC;

-- DAY 3: TASK 16
-- Step 16I: Create Delivery Satisfaction View

CREATE OR REPLACE VIEW
analytics.vw_delivery_satisfaction AS

SELECT
    d.order_id,
    d.delivery_status,

    s.review_id,
    s.review_score,
    s.review_creation_date,
    s.review_answer_timestamp,
    s.review_records_per_order,

    s.satisfaction_group,
    s.positive_review_flag,
    s.negative_review_flag,
    s.multiple_reviews_flag,

    CASE
        WHEN d.delivery_status = 'Late'
            AND s.negative_review_flag = 1
            THEN 1
        ELSE 0
    END AS late_negative_review_flag,

    CASE
        WHEN d.delivery_status = 'On Time'
            AND s.positive_review_flag = 1
            THEN 1
        ELSE 0
    END AS on_time_positive_review_flag

FROM analytics.vw_on_time_delivery_analysis d

INNER JOIN analytics.vw_customer_satisfaction s
    ON d.order_id = s.order_id;

-- DAY 3: TASK 16
-- Step 16J: Final Delivery Satisfaction Validation

SELECT
    COUNT(*) AS total_reviewed_delivered_orders,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_order_records,

    COUNT(*) FILTER (
        WHERE delivery_status = 'On Time'
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Missing or Invalid'
    ) AS missing_or_invalid_orders,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Positive'
    ) AS positive_orders,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Neutral'
    ) AS neutral_orders,

    COUNT(*) FILTER (
        WHERE satisfaction_group = 'Negative'
    ) AS negative_orders,

    COUNT(*) FILTER (
        WHERE late_negative_review_flag = 1
    ) AS late_negative_reviews,

    COUNT(*) FILTER (
        WHERE on_time_positive_review_flag = 1
    ) AS on_time_positive_reviews,

    ROUND(
        AVG(review_score), 2
    ) AS avg_review_score,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR review_id IS NULL
           OR review_score NOT BETWEEN 1 AND 5
           OR review_score IS NULL
           OR delivery_status IS NULL
           OR satisfaction_group IS NULL
           OR late_negative_review_flag
              <> CASE
                    WHEN delivery_status = 'Late'
                     AND negative_review_flag = 1
                        THEN 1
                    ELSE 0
                 END
           OR on_time_positive_review_flag
              <> CASE
                    WHEN delivery_status = 'On Time'
                     AND positive_review_flag = 1
                        THEN 1
                    ELSE 0
                 END
    ) AS invalid_records

FROM analytics.vw_delivery_satisfaction;
