
SELECT
    COUNT(*) AS orphan_orders
FROM olist.orders o
LEFT JOIN olist.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    COUNT(*) AS total_order_items,

    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS missing_orders,

    COUNT(*) FILTER (
        WHERE p.product_id IS NULL
    ) AS missing_products,

    COUNT(*) FILTER (
        WHERE s.seller_id IS NULL
    ) AS missing_sellers

FROM olist.order_items oi

LEFT JOIN olist.orders o
    ON oi.order_id = o.order_id

LEFT JOIN olist.products p
    ON oi.product_id = p.product_id

LEFT JOIN olist.sellers s
    ON oi.seller_id = s.seller_id;


SELECT
    COUNT(*) AS total_payments,

    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS missing_order_references,

    COUNT(DISTINCT p.order_id)
        AS unique_orders_with_payments

FROM olist.order_payments p

LEFT JOIN olist.orders o
    ON p.order_id = o.order_id;


SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist.orders o
LEFT JOIN olist.order_payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;


SELECT
    COUNT(*) AS total_reviews,

    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS missing_order_references,

    COUNT(DISTINCT r.order_id)
        AS unique_orders_with_reviews

FROM olist.order_reviews r

LEFT JOIN olist.orders o
    ON r.order_id = o.order_id;

SELECT
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id)
        AS repeated_review_id_records,
    COUNT(DISTINCT order_id)
        AS unique_reviewed_orders
FROM olist.order_reviews;

SELECT
    review_id,
    COUNT(*) AS occurrence_count,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM olist.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
LIMIT 20;

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_creation_date,
    review_answer_timestamp
FROM olist.order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM olist.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id, order_id
LIMIT 30;

SELECT
    review_id,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT review_score) AS distinct_scores,
    COUNT(DISTINCT review_creation_date)
        AS distinct_creation_dates,
    COUNT(DISTINCT review_answer_timestamp)
        AS distinct_answer_dates
FROM olist.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY total_records DESC
LIMIT 20;

WITH repeated_reviews AS (
    SELECT
        review_id,
        COUNT(*) AS total_records,
        COUNT(DISTINCT order_id) AS distinct_orders,
        COUNT(DISTINCT review_score) AS distinct_scores,
        COUNT(DISTINCT review_creation_date)
            AS distinct_creation_dates,
        COUNT(DISTINCT review_answer_timestamp)
            AS distinct_answer_dates
    FROM olist.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS repeated_review_ids,
    SUM(total_records - 1) AS extra_review_records,
    COUNT(*) FILTER (
        WHERE distinct_orders > 1
    ) AS ids_linked_to_multiple_orders,
    COUNT(*) FILTER (
        WHERE distinct_scores > 1
           OR distinct_creation_dates > 1
           OR distinct_answer_dates > 1
    ) AS ids_with_conflicting_details
FROM repeated_reviews;

WITH review_consistency AS (
    SELECT
        review_id,
        COUNT(*) AS total_records,
        COUNT(DISTINCT review_comment_title)
            AS distinct_titles,
        COUNT(DISTINCT review_comment_message)
            AS distinct_messages,
        COUNT(*) FILTER (
            WHERE review_comment_title IS NULL
        ) AS missing_titles,
        COUNT(*) FILTER (
            WHERE review_comment_message IS NULL
        ) AS missing_messages
    FROM olist.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS repeated_review_ids,
    COUNT(*) FILTER (
        WHERE distinct_titles > 1
           OR distinct_messages > 1
    ) AS ids_with_conflicting_comments,
    COUNT(*) FILTER (
        WHERE missing_titles > 0
    ) AS ids_with_missing_titles,
    COUNT(*) FILTER (
        WHERE missing_messages > 0
    ) AS ids_with_missing_messages
FROM review_consistency;

WITH review_null_checks AS (
    SELECT
        review_id,
        COUNT(*) AS total_records,
        COUNT(review_comment_title) AS titles_present,
        COUNT(review_comment_message) AS messages_present,
        COUNT(review_score) AS scores_present,
        COUNT(review_creation_date) AS dates_present,
        COUNT(review_answer_timestamp) AS answers_present
    FROM olist.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS repeated_review_ids,
    COUNT(*) FILTER (
        WHERE titles_present > 0
          AND titles_present < total_records
    ) AS mixed_null_titles,
    COUNT(*) FILTER (
        WHERE messages_present > 0
          AND messages_present < total_records
    ) AS mixed_null_messages,
    COUNT(*) FILTER (
        WHERE scores_present > 0
          AND scores_present < total_records
    ) AS mixed_null_scores,
    COUNT(*) FILTER (
        WHERE dates_present > 0
          AND dates_present < total_records
    ) AS mixed_null_dates,
    COUNT(*) FILTER (
        WHERE answers_present > 0
          AND answers_present < total_records
    ) AS mixed_null_answers
FROM review_null_checks;

/*
OLIST ECOMMERCE DATA QUALITY FINDINGS

Database: olist_ecommerce
Schema: olist
Table: order_reviews

Review validation results:

Total review records: 99,224
Unique review IDs: 98,410
Repeated review IDs: 789
Additional records beyond unique review IDs: 814

All 789 repeated review IDs reference
multiple orders.

No conflicting review scores, timestamps,
or nonnull comments were detected.

No mixed NULL and nonnull values were
detected within repeated review ID groups
for the fields examined.

743 repeated review IDs contain at least
one missing review title.

490 repeated review IDs contain at least
one missing review message.

Conclusion:

Review IDs are not unique in the source data.

Repeated review IDs have consistent
review details across the fields tested.

Preserve original source records.
Do not remove repeated review IDs without
additional business validation.

For analysis, use the appropriate record
grain and avoid assuming review_id alone
uniquely identifies each row.
*/

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_ids,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_categories,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weights
FROM olist.products;

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
          AND product_weight_g IS NULL
    ) AS missing_both,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
          AND product_weight_g IS NOT NULL
    ) AS missing_category_only,
    COUNT(*) FILTER (
        WHERE product_category_name IS NOT NULL
          AND product_weight_g IS NULL
    ) AS missing_weight_only
FROM olist.products;

SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_id) AS unique_sellers,
    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS missing_seller_ids,
    COUNT(*) FILTER (
        WHERE seller_city IS NULL
    ) AS missing_cities,
    COUNT(*) FILTER (
        WHERE seller_state IS NULL
    ) AS missing_states,
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix IS NULL
    ) AS missing_zip_codes
FROM olist.sellers;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
    ) AS missing_zip_codes,
    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
    ) AS missing_latitudes,
    COUNT(*) FILTER (
        WHERE geolocation_lng IS NULL
    ) AS missing_longitudes,
    COUNT(*) FILTER (
        WHERE geolocation_city IS NULL
    ) AS missing_cities,
    COUNT(*) FILTER (
        WHERE geolocation_state IS NULL
    ) AS missing_states
FROM olist.geolocation;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) AS records_checked,
    COUNT(DISTINCT (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )) AS unique_records,
    COUNT(*) -
    COUNT(DISTINCT (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )) AS exact_duplicate_records
FROM olist.geolocation;

SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS occurrence_count
FROM olist.geolocation
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
LIMIT 20;

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS total_records,
    COUNT(DISTINCT (
        geolocation_lat,
        geolocation_lng
    )) AS unique_coordinates,
    COUNT(DISTINCT geolocation_city)
        AS unique_cities,
    COUNT(DISTINCT geolocation_state)
        AS unique_states
FROM olist.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT (
    geolocation_lat,
    geolocation_lng
)) > 1
ORDER BY unique_coordinates DESC
LIMIT 20;

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS total_records,
    COUNT(DISTINCT geolocation_state)
        AS unique_states,
    STRING_AGG(
        DISTINCT geolocation_state,
        ', '
        ORDER BY geolocation_state
    ) AS states
FROM olist.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_state) > 1
ORDER BY unique_states DESC, total_records DESC
LIMIT 20;

WITH conflicting_zips AS (
    SELECT
        geolocation_zip_code_prefix
    FROM olist.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(DISTINCT geolocation_state) > 1
)
SELECT
    g.geolocation_zip_code_prefix,
    g.geolocation_state,
    g.geolocation_city,
    COUNT(*) AS record_count,
    COUNT(DISTINCT (
        g.geolocation_lat,
        g.geolocation_lng
    )) AS unique_coordinates
FROM olist.geolocation g
JOIN conflicting_zips c
    ON g.geolocation_zip_code_prefix =
       c.geolocation_zip_code_prefix
GROUP BY
    g.geolocation_zip_code_prefix,
    g.geolocation_state,
    g.geolocation_city
ORDER BY
    g.geolocation_zip_code_prefix,
    record_count DESC;

WITH state_counts AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,
        COUNT(*) AS state_count
    FROM olist.geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_state
),
ranked_states AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY state_count DESC,
                     geolocation_state
        ) AS state_rank,
        COUNT(*) OVER (
            PARTITION BY geolocation_zip_code_prefix
        ) AS state_options
    FROM state_counts
),
dominant_locations AS (
    SELECT
        g.geolocation_zip_code_prefix,
        r.geolocation_state AS dominant_state,
        ROUND(AVG(g.geolocation_lat)::numeric, 6)
            AS avg_latitude,
        ROUND(AVG(g.geolocation_lng)::numeric, 6)
            AS avg_longitude
    FROM olist.geolocation g
    JOIN ranked_states r
        ON g.geolocation_zip_code_prefix =
           r.geolocation_zip_code_prefix
       AND g.geolocation_state =
           r.geolocation_state
    WHERE r.state_rank = 1
      AND r.state_options > 1
    GROUP BY
        g.geolocation_zip_code_prefix,
        r.geolocation_state
)
SELECT
    g.geolocation_zip_code_prefix,
    g.geolocation_city,
    g.geolocation_state AS minority_state,
    d.dominant_state,
    g.geolocation_lat AS minority_latitude,
    g.geolocation_lng AS minority_longitude,
    d.avg_latitude,
    d.avg_longitude
FROM olist.geolocation g
JOIN dominant_locations d
    ON g.geolocation_zip_code_prefix =
       d.geolocation_zip_code_prefix
WHERE g.geolocation_state <> d.dominant_state
ORDER BY g.geolocation_zip_code_prefix;

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'olist'
ORDER BY table_name;

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'olist'
  AND table_name LIKE '%translat%';

SELECT
    COUNT(DISTINCT p.product_category_name)
        AS product_categories_used,

    COUNT(DISTINCT t.product_category_name)
        AS matched_categories,

    COUNT(DISTINCT p.product_category_name)
        - COUNT(DISTINCT t.product_category_name)
        AS unmatched_categories

FROM olist.products p

LEFT JOIN olist.product_category_translation t
    ON p.product_category_name =
       t.product_category_name;

SELECT
    p.product_category_name,
    COUNT(*) AS affected_products
FROM olist.products p
LEFT JOIN olist.product_category_translation t
    ON p.product_category_name =
       t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY affected_products DESC;
