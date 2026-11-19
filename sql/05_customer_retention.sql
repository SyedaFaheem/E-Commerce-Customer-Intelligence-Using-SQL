


-- TASK 5
-- Step 5A: Customer Identity Validation

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT o.order_id)
        AS unique_orders,

    COUNT(DISTINCT o.customer_id)
        AS unique_customer_records,

    COUNT(DISTINCT c.customer_unique_id)
        AS unique_customers,

    COUNT(*) FILTER (
        WHERE c.customer_id IS NULL
    ) AS orders_without_customer_match,

    COUNT(*) FILTER (
        WHERE c.customer_unique_id IS NULL
    ) AS orders_missing_unique_customer_id,

    COUNT(*) - COUNT(DISTINCT o.order_id)
        AS duplicate_order_rows

FROM analytics.vw_order_summary AS o

LEFT JOIN olist.customers AS c
    ON o.customer_id = c.customer_id;

-- DAY 3: TASK 5
-- Step 5B: Repeat Customer Analysis

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS total_orders

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE total_orders = 1
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE total_orders > 1
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate_pct,

    MAX(total_orders)
        AS maximum_orders_per_customer,

    ROUND(
        AVG(total_orders), 2
    ) AS avg_orders_per_customer

FROM customer_orders;


-- DAY 3: TASK 5
-- Step 5C: Customer Purchase Frequency Distribution

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS total_orders

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
)

SELECT
    total_orders AS orders_per_customer,

    COUNT(*) AS customer_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    SUM(COUNT(*)) OVER (
        ORDER BY total_orders
    ) AS cumulative_customers

FROM customer_orders

GROUP BY total_orders

ORDER BY total_orders;

-- DAY 3: TASK 5
-- Step 5D: One-Time vs Repeat Customer Spending

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS lifetime_orders_in_dataset

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
),

customer_spending AS (
    SELECT
        c.customer_unique_id,

        co.lifetime_orders_in_dataset,

        COUNT(*) AS delivered_orders,

        SUM(o.total_product_value)
            AS product_spending,

        SUM(o.total_item_value)
            AS total_spending

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id

    INNER JOIN customer_orders AS co
        ON c.customer_unique_id = co.customer_unique_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id,
        co.lifetime_orders_in_dataset
)

SELECT
    CASE
        WHEN lifetime_orders_in_dataset = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customers_with_delivered_orders,

    SUM(delivered_orders) AS delivered_orders,

    ROUND(
        SUM(product_spending), 2
    ) AS total_product_spending,

    ROUND(
        SUM(total_spending), 2
    ) AS total_item_spending,

    ROUND(
        AVG(total_spending), 2
    ) AS avg_spending_per_customer,

    ROUND(
        SUM(total_spending)
        / NULLIF(SUM(delivered_orders), 0),
        2
    ) AS avg_spending_per_order

FROM customer_spending

GROUP BY
    CASE
        WHEN lifetime_orders_in_dataset = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END

ORDER BY customer_type;

-- DAY 3: TASK 5
-- Step 5E: Create Customer Purchase Behavior View

CREATE OR REPLACE VIEW
analytics.vw_customer_purchase_behavior AS

SELECT
    c.customer_unique_id,

    COUNT(DISTINCT o.order_id)
        AS total_orders,

    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_status = 'delivered'
    ) AS delivered_orders,

    ROUND(
        COALESCE(
            SUM(o.total_product_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ), 2
    ) AS delivered_product_spending,

    ROUND(
        COALESCE(
            SUM(o.total_item_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ), 2
    ) AS delivered_total_spending,

    ROUND(
        COALESCE(
            SUM(o.total_item_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ),
        2
    ) AS avg_delivered_order_value,

    MIN(o.order_purchase_timestamp)
        AS first_order_date,

    MAX(o.order_purchase_timestamp)
        AS last_order_date,

    CASE
        WHEN COUNT(DISTINCT o.order_id) = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type

FROM analytics.vw_order_summary AS o

INNER JOIN olist.customers AS c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_unique_id;

-- DAY 3: TASK 5
-- Step 5F: Final Customer Behavior Validation

SELECT
    COUNT(*) AS total_customers,

    COUNT(DISTINCT customer_unique_id)
        AS unique_customers,

    COUNT(*) - COUNT(DISTINCT customer_unique_id)
        AS duplicate_customers,

    COUNT(*) FILTER (
        WHERE customer_type = 'One-Time Customer'
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE customer_type = 'Repeat Customer'
    ) AS repeat_customers,

    SUM(total_orders) AS total_orders,

    SUM(delivered_orders) AS total_delivered_orders,

    ROUND(
        SUM(delivered_product_spending), 2
    ) AS total_product_spending,

    ROUND(
        SUM(delivered_total_spending), 2
    ) AS total_item_spending,

    COUNT(*) FILTER (
        WHERE delivered_orders = 0
    ) AS customers_without_delivered_orders,

    COUNT(*) FILTER (
        WHERE total_orders < delivered_orders
           OR total_orders < 1
           OR delivered_total_spending < 0
    ) AS invalid_customer_records

FROM analytics.vw_customer_purchase_behavior;

-- DAY 3: TASK 6
-- Step 6A: Identify Customer First Order Month

WITH customer_first_order AS (
    SELECT
        customer_unique_id,

        MIN(first_order_date) AS first_order_date,

        DATE_TRUNC(
            'month',
            MIN(first_order_date)
        )::date AS first_order_month

    FROM analytics.vw_customer_purchase_behavior

    GROUP BY customer_unique_id
)

SELECT
    first_order_month,

    COUNT(*) AS new_customers

FROM customer_first_order

GROUP BY first_order_month

ORDER BY first_order_month;

-- DAY 3: TASK 6
-- Step 6B: Validate First-Order Customer Distribution

WITH monthly_new_customers AS (
    SELECT
        DATE_TRUNC(
            'month', first_order_date
        )::date AS first_order_month,

        COUNT(*) AS new_customers

    FROM analytics.vw_customer_purchase_behavior

    GROUP BY 1
)

SELECT
    COUNT(*) AS total_months,

    MIN(first_order_month) AS first_month,

    MAX(first_order_month) AS last_month,

    SUM(new_customers) AS total_new_customers,

    COUNT(*) FILTER (
        WHERE new_customers < 10
    ) AS months_with_fewer_than_10_customers

FROM monthly_new_customers;

-- DAY 3: TASK 6
-- Step 6C: Monthly New vs Returning Customers

WITH customer_monthly_activity AS (
    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS order_month

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id
),

customer_first_month AS (
    SELECT
        customer_unique_id,

        MIN(order_month) AS first_order_month

    FROM customer_monthly_activity

    GROUP BY customer_unique_id
)

SELECT
    a.order_month,

    COUNT(*) AS active_customers,

    COUNT(*) FILTER (
        WHERE a.order_month = f.first_order_month
    ) AS new_customers,

    COUNT(*) FILTER (
        WHERE a.order_month > f.first_order_month
    ) AS returning_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE a.order_month > f.first_order_month
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS returning_customer_pct

FROM customer_monthly_activity AS a

INNER JOIN customer_first_month AS f
    ON a.customer_unique_id = f.customer_unique_id

GROUP BY a.order_month

ORDER BY a.order_month;

-- DAY 3: TASK 6
-- Step 6D: Validate Monthly Customer Activity

WITH customer_monthly_activity AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS order_month
    FROM analytics.vw_order_summary AS o
    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id
),

customer_first_month AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS first_order_month
    FROM customer_monthly_activity
    GROUP BY customer_unique_id
),

monthly_summary AS (
    SELECT
        a.order_month,
        COUNT(*) AS active_customers,
        COUNT(*) FILTER (
            WHERE a.order_month = f.first_order_month
        ) AS new_customers,
        COUNT(*) FILTER (
            WHERE a.order_month > f.first_order_month
        ) AS returning_customers
    FROM customer_monthly_activity AS a
    INNER JOIN customer_first_month AS f
        ON a.customer_unique_id = f.customer_unique_id
    GROUP BY a.order_month
)

SELECT
    COUNT(*) AS total_months,

    SUM(active_customers)
        AS total_monthly_customer_appearances,

    SUM(new_customers)
        AS total_new_customers,

    SUM(returning_customers)
        AS total_returning_customer_appearances,

    COUNT(*) FILTER (
        WHERE active_customers <>
              new_customers + returning_customers
    ) AS invalid_months,

    COUNT(*) FILTER (
        WHERE returning_customers > active_customers
           OR new_customers > active_customers
    ) AS invalid_customer_counts

FROM monthly_summary;

-- DAY 3: TASK 6
-- Step 6E: Create Monthly New vs Returning Customers View

CREATE OR REPLACE VIEW
analytics.vw_monthly_customer_activity AS

WITH customer_monthly_activity AS (
    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS order_month

    FROM analytics.vw_order_summary AS o

    INNER JOIN olist.customers AS c
        ON o.customer_id = c.customer_id
),

customer_first_month AS (
    SELECT
        customer_unique_id,

        MIN(order_month) AS first_order_month

    FROM customer_monthly_activity

    GROUP BY customer_unique_id
),

monthly_summary AS (
    SELECT
        a.order_month,

        COUNT(*) AS active_customers,

        COUNT(*) FILTER (
            WHERE a.order_month = f.first_order_month
        ) AS new_customers,

        COUNT(*) FILTER (
            WHERE a.order_month > f.first_order_month
        ) AS returning_customers

    FROM customer_monthly_activity AS a

    INNER JOIN customer_first_month AS f
        ON a.customer_unique_id = f.customer_unique_id

    GROUP BY a.order_month
)

SELECT
    order_month,

    EXTRACT(YEAR FROM order_month)::int
        AS order_year,

    EXTRACT(MONTH FROM order_month)::int
        AS month_number,

    TO_CHAR(order_month, 'FMMonth')
        AS month_name,

    active_customers,

    new_customers,

    returning_customers,

    ROUND(
        100.0 * new_customers
        / NULLIF(active_customers, 0),
        2
    ) AS new_customer_pct,

    ROUND(
        100.0 * returning_customers
        / NULLIF(active_customers, 0),
        2
    ) AS returning_customer_pct

FROM monthly_summary;

-- DAY 3: TASK 6
-- Step 6F: Final Monthly Customer Activity Validation

SELECT
    COUNT(*) AS total_months,

    COUNT(DISTINCT order_month)
        AS unique_months,

    COUNT(*) - COUNT(DISTINCT order_month)
        AS duplicate_months,

    MIN(order_month) AS first_month,

    MAX(order_month) AS last_month,

    SUM(active_customers)
        AS total_customer_appearances,

    SUM(new_customers)
        AS total_new_customers,

    SUM(returning_customers)
        AS total_returning_appearances,

    COUNT(*) FILTER (
        WHERE active_customers <>
              new_customers + returning_customers
    ) AS invalid_months,

    COUNT(*) FILTER (
        WHERE new_customer_pct < 0
           OR new_customer_pct > 100
           OR returning_customer_pct < 0
           OR returning_customer_pct > 100
           OR new_customer_pct IS NULL
           OR returning_customer_pct IS NULL
    ) AS invalid_percentage_months

FROM analytics.vw_monthly_customer_activity;


-- DAY 3: TASK 17
-- Step 17A: Validate Customer Purchase History

SELECT
    COUNT(*) AS total_delivered_orders,

    COUNT(DISTINCT o.order_id)
        AS unique_delivered_orders,

    COUNT(DISTINCT c.customer_unique_id)
        AS unique_customers,

    COUNT(DISTINCT DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )) AS purchase_months,

    MIN(o.order_purchase_timestamp)
        AS earliest_purchase,

    MAX(o.order_purchase_timestamp)
        AS latest_purchase,

    COUNT(*) FILTER (
        WHERE c.customer_unique_id IS NULL
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE o.order_purchase_timestamp IS NULL
    ) AS missing_purchase_dates

FROM olist.orders o

INNER JOIN olist.customers c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered';

-- DAY 3: TASK 17
-- Step 17B: Identify First Purchase Month

WITH customer_first_purchase AS (

    SELECT
        c.customer_unique_id,

        MIN(o.order_purchase_timestamp)
            AS first_purchase_date,

        DATE_TRUNC(
            'month',
            MIN(o.order_purchase_timestamp)
        )::date AS cohort_month,

        COUNT(DISTINCT o.order_id)
            AS total_delivered_orders

    FROM olist.orders o

    INNER JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    cohort_month,

    COUNT(*) AS cohort_customers,

    COUNT(*) FILTER (
        WHERE total_delivered_orders >= 2
    ) AS repeat_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE total_delivered_orders >= 2
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate_pct

FROM customer_first_purchase

GROUP BY cohort_month

ORDER BY cohort_month;

-- DAY 3: TASK 17
-- Step 17C: Monthly Customer Retention Matrix

WITH customer_orders AS (

    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS purchase_month

    FROM olist.orders o

    INNER JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

),

customer_cohorts AS (

    SELECT
        customer_unique_id,
        purchase_month,

        MIN(purchase_month) OVER (
            PARTITION BY customer_unique_id
        ) AS cohort_month

    FROM customer_orders

),

cohort_activity AS (

    SELECT
        cohort_month,

        (
            EXTRACT(YEAR FROM purchase_month)
            - EXTRACT(YEAR FROM cohort_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM purchase_month)
            - EXTRACT(MONTH FROM cohort_month)
        ) AS months_since_first_purchase,

        customer_unique_id

    FROM customer_cohorts

)

SELECT
    cohort_month,

    months_since_first_purchase::int
        AS cohort_month_number,

    COUNT(DISTINCT customer_unique_id)
        AS active_customers,

    MAX(
        COUNT(DISTINCT customer_unique_id)
    ) FILTER (
        WHERE months_since_first_purchase = 0
    ) OVER (
        PARTITION BY cohort_month
    ) AS cohort_size

FROM cohort_activity

GROUP BY
    cohort_month,
    months_since_first_purchase

ORDER BY
    cohort_month,
    cohort_month_number;

-- DAY 3: TASK 17
-- Step 17D: Monthly Cohort Retention Rates

WITH customer_orders AS (

    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS purchase_month

    FROM olist.orders o

    INNER JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

),

customer_cohorts AS (

    SELECT
        customer_unique_id,
        purchase_month,

        MIN(purchase_month) OVER (
            PARTITION BY customer_unique_id
        ) AS cohort_month

    FROM customer_orders

),

cohort_activity AS (

    SELECT
        cohort_month,

        (
            (
                EXTRACT(YEAR FROM purchase_month)
                - EXTRACT(YEAR FROM cohort_month)
            ) * 12
            +
            (
                EXTRACT(MONTH FROM purchase_month)
                - EXTRACT(MONTH FROM cohort_month)
            )
        )::int AS cohort_month_number,

        customer_unique_id

    FROM customer_cohorts

),

monthly_retention AS (

    SELECT
        cohort_month,
        cohort_month_number,

        COUNT(DISTINCT customer_unique_id)
            AS active_customers

    FROM cohort_activity

    GROUP BY
        cohort_month,
        cohort_month_number

),

retention_with_size AS (

    SELECT
        cohort_month,
        cohort_month_number,
        active_customers,

        MAX(active_customers) FILTER (
            WHERE cohort_month_number = 0
        ) OVER (
            PARTITION BY cohort_month
        ) AS cohort_size

    FROM monthly_retention

)

SELECT
    cohort_month,
    cohort_month_number,
    cohort_size,
    active_customers,

    ROUND(
        100.0 * active_customers
        / NULLIF(cohort_size, 0),
        2
    ) AS retention_rate_pct

FROM retention_with_size

ORDER BY
    cohort_month,
    cohort_month_number;

-- DAY 3: TASK 17
-- Step 17E: Create Final Cohort Retention View

CREATE OR REPLACE VIEW
analytics.vw_customer_cohort_retention_final AS

WITH customer_orders AS (

    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS purchase_month

    FROM olist.orders o

    INNER JOIN olist.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

),

customer_cohorts AS (

    SELECT
        customer_unique_id,
        purchase_month,

        MIN(purchase_month) OVER (
            PARTITION BY customer_unique_id
        ) AS cohort_month

    FROM customer_orders

),

cohort_sizes AS (

    SELECT
        cohort_month,

        COUNT(DISTINCT customer_unique_id)
            AS cohort_size

    FROM customer_cohorts

    WHERE purchase_month = cohort_month

    GROUP BY cohort_month

),

monthly_activity AS (

    SELECT
        cohort_month,

        (
            (
                EXTRACT(YEAR FROM purchase_month)
                - EXTRACT(YEAR FROM cohort_month)
            ) * 12
            +
            (
                EXTRACT(MONTH FROM purchase_month)
                - EXTRACT(MONTH FROM cohort_month)
            )
        )::int AS cohort_month_number,

        COUNT(DISTINCT customer_unique_id)
            AS active_customers

    FROM customer_cohorts

    GROUP BY
        cohort_month,
        cohort_month_number

),

observation_end AS (

    SELECT
        MAX(purchase_month) AS last_observed_month

    FROM customer_orders

),

cohort_calendar AS (

    SELECT
        cs.cohort_month,
        cs.cohort_size,
        gs.cohort_month_number,

        (
            cs.cohort_month
            + gs.cohort_month_number
              * INTERVAL '1 month'
        )::date AS activity_month

    FROM cohort_sizes cs

    CROSS JOIN observation_end oe

    CROSS JOIN LATERAL generate_series(
        0,

        (
            (
                EXTRACT(YEAR FROM oe.last_observed_month)
                - EXTRACT(YEAR FROM cs.cohort_month)
            ) * 12
            +
            (
                EXTRACT(MONTH FROM oe.last_observed_month)
                - EXTRACT(MONTH FROM cs.cohort_month)
            )
        )::int

    ) AS gs(cohort_month_number)

)

SELECT
    cc.cohort_month,
    cc.activity_month,
    cc.cohort_month_number,
    cc.cohort_size,

    COALESCE(
        ma.active_customers, 0
    ) AS active_customers,

    ROUND(
        100.0
        * COALESCE(ma.active_customers, 0)
        / NULLIF(cc.cohort_size, 0),
        2
    ) AS retention_rate_pct

FROM cohort_calendar cc

LEFT JOIN monthly_activity ma
    ON cc.cohort_month = ma.cohort_month
   AND cc.cohort_month_number = ma.cohort_month_number;

-- DAY 3: TASK 17
-- Step 17F: Final Cohort Retention Validation

WITH cohort_checks AS (

    SELECT
        cohort_month,

        COUNT(*) AS observed_month_rows,

        MAX(cohort_size) AS cohort_size,

        COUNT(*) FILTER (
            WHERE cohort_month_number = 0
        ) AS month_zero_rows,

        COUNT(*) FILTER (
            WHERE cohort_month_number = 0
              AND retention_rate_pct = 100
              AND active_customers = cohort_size
        ) AS valid_month_zero_rows

    FROM analytics.vw_customer_cohort_retention_final

    GROUP BY cohort_month

),

view_checks AS (

    SELECT
        COUNT(*) AS total_retention_rows,

        COUNT(DISTINCT cohort_month)
            AS total_cohorts,

        COUNT(*) FILTER (
            WHERE cohort_month_number = 0
        ) AS month_zero_rows,

        COUNT(*) FILTER (
            WHERE cohort_month_number > 0
              AND active_customers = 0
        ) AS zero_activity_months,

        COUNT(*) FILTER (
            WHERE retention_rate_pct < 0
               OR retention_rate_pct > 100
               OR cohort_size <= 0
               OR active_customers < 0
               OR active_customers > cohort_size
               OR retention_rate_pct IS NULL
        ) AS invalid_retention_rows,

        COUNT(*) - COUNT(
            DISTINCT (
                cohort_month,
                cohort_month_number
            )
        ) AS duplicate_cohort_month_rows,

        MAX(activity_month)
            AS latest_activity_month

    FROM analytics.vw_customer_cohort_retention_final

)

SELECT
    vc.total_retention_rows,

    vc.total_cohorts,

    (
        SELECT SUM(cohort_size)
        FROM cohort_checks
    ) AS total_cohort_customers,

    vc.month_zero_rows,

    (
        SELECT SUM(valid_month_zero_rows)
        FROM cohort_checks
    ) AS valid_month_zero_rows,

    vc.zero_activity_months,

    vc.invalid_retention_rows,

    vc.duplicate_cohort_month_rows,

    vc.latest_activity_month

FROM view_checks vc;
