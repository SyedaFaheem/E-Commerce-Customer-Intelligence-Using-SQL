-- DAY 2: TASK 7
-- Step 7A: Identify missing critical order information

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_id,

    COUNT(*) FILTER (
        WHERE order_status IS NULL
    ) AS missing_order_status,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_timestamp,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval_timestamp,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_timestamp,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_timestamp,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery

FROM olist.orders;

-- DAY 2: TASK 7
-- Step 7B: Identify orders requiring quality flags

SELECT
    COUNT(*) AS total_orders,

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
        WHERE order_status = 'delivered'
          AND (
              order_approved_at IS NULL
              OR order_delivered_carrier_date IS NULL
              OR order_delivered_customer_date IS NULL
          )
    ) AS delivered_orders_with_missing_info

FROM olist.orders;

-- DAY 2: TASK 7
-- Step 7C: Inspect existing clean order view

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'vw_orders_clean'
ORDER BY ordinal_position;

-- DAY 2: TASK 7
-- Step 7D: Retrieve existing view definition

SELECT pg_get_viewdef(
    'analytics.vw_orders_clean'::regclass,
    true
) AS view_definition;

-- DAY 2: TASK 7
-- Step 7F: Add missing order information flags

CREATE OR REPLACE VIEW analytics.vw_orders_flagged AS
SELECT
    o.*,

    (o.order_approved_at IS NULL)
        AS missing_approval_flag,

    (o.order_delivered_carrier_date IS NULL)
        AS missing_carrier_flag,

    (o.order_delivered_customer_date IS NULL)
        AS missing_delivery_flag,

    (
        o.order_status = 'delivered'
        AND (
            o.order_approved_at IS NULL
            OR o.order_delivered_carrier_date IS NULL
            OR o.order_delivered_customer_date IS NULL
        )
    ) AS delivered_missing_info_flag

FROM analytics.vw_orders_clean AS o;

-- Step 7F: Verify missing information flags

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE missing_approval_flag
    ) AS missing_approval,

    COUNT(*) FILTER (
        WHERE missing_carrier_flag
    ) AS missing_carrier,

    COUNT(*) FILTER (
        WHERE missing_delivery_flag
    ) AS missing_delivery,

    COUNT(*) FILTER (
        WHERE delivered_missing_info_flag
    ) AS delivered_missing_info

FROM analytics.vw_orders_flagged;

-- DAY 2: TASK 8
-- Step 8A: Validate customer and order relationships

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE o.customer_id IS NULL
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE c.customer_id IS NULL
    ) AS unmatched_customer_ids,

    COUNT(*) FILTER (
        WHERE c.customer_id IS NOT NULL
    ) AS matched_orders

FROM olist.orders AS o
LEFT JOIN olist.customers AS c
    ON o.customer_id = c.customer_id;

-- DAY 2: TASK 8
-- Step 8B: Validate customer ID uniqueness

SELECT
    COUNT(*) AS total_customer_records,

    COUNT(DISTINCT customer_id) AS unique_customer_ids,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_ids,

    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_or_null_excess

FROM olist.customers;

-- DAY 2: TASK 8
-- Step 8C: Validate customer and order join cardinality

SELECT
    COUNT(*) AS joined_records,

    COUNT(DISTINCT o.order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT o.order_id)
        AS duplicate_order_excess,

    COUNT(DISTINCT o.customer_id)
        AS unique_customers

FROM olist.orders AS o
INNER JOIN olist.customers AS c
    ON o.customer_id = c.customer_id;

-- DAY 2: TASK 9
-- Step 9A: Inspect missing product attributes

SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_category,

    COUNT(*) FILTER (
        WHERE product_name_lenght IS NULL
    ) AS missing_name_length,

    COUNT(*) FILTER (
        WHERE product_description_lenght IS NULL
    ) AS missing_description_length,

    COUNT(*) FILTER (
        WHERE product_photos_qty IS NULL
    ) AS missing_photos,

    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weight,

    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
    ) AS missing_length,

    COUNT(*) FILTER (
        WHERE product_height_cm IS NULL
    ) AS missing_height,

    COUNT(*) FILTER (
        WHERE product_width_cm IS NULL
    ) AS missing_width

FROM olist.products;

-- DAY 2: TASK 9
-- Step 9B: Investigate missing attribute patterns

SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
          AND product_name_lenght IS NULL
          AND product_description_lenght IS NULL
          AND product_photos_qty IS NULL
    ) AS all_four_missing,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
          AND (
              product_name_lenght IS NOT NULL
              OR product_description_lenght IS NOT NULL
              OR product_photos_qty IS NOT NULL
          )
    ) AS category_only_or_partial_missing,

    COUNT(*) FILTER (
        WHERE product_category_name IS NOT NULL
          AND (
              product_name_lenght IS NULL
              OR product_description_lenght IS NULL
              OR product_photos_qty IS NULL
          )
    ) AS other_attribute_missing

FROM olist.products;

-- DAY 2: TASK 9
-- Step 9C: Verify existing product quality flags

SELECT
    category_quality_status,
    dimension_quality_status,
    COUNT(*) AS total_products
FROM analytics.vw_products_clean
GROUP BY
    category_quality_status,
    dimension_quality_status
ORDER BY total_products DESC;

-- DAY 2: TASK 9
-- Step 9D: Validate physical product dimensions

SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
           OR product_length_cm IS NULL
           OR product_height_cm IS NULL
           OR product_width_cm IS NULL
    ) AS missing_dimensions,

    COUNT(*) FILTER (
        WHERE product_weight_g = 0
           OR product_length_cm = 0
           OR product_height_cm = 0
           OR product_width_cm = 0
    ) AS zero_dimensions,

    COUNT(*) FILTER (
        WHERE product_weight_g < 0
           OR product_length_cm < 0
           OR product_height_cm < 0
           OR product_width_cm < 0
    ) AS negative_dimensions

FROM olist.products;

-- DAY 2: TASK 9
-- Step 9E: Inspect products with missing or zero dimensions

SELECT
    p.product_id,
    p.product_category_name,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    v.dimension_quality_status
FROM olist.products AS p
LEFT JOIN analytics.vw_products_clean AS v
    ON p.product_id = v.product_id
WHERE
    p.product_weight_g IS NULL
    OR p.product_length_cm IS NULL
    OR p.product_height_cm IS NULL
    OR p.product_width_cm IS NULL
    OR p.product_weight_g = 0
    OR p.product_length_cm = 0
    OR p.product_height_cm = 0
    OR p.product_width_cm = 0
ORDER BY p.product_id;

-- DAY 2: TASK 9
-- Step 9G: Create additional product quality flags

CREATE OR REPLACE VIEW analytics.vw_products_quality_flags AS

SELECT
    p.product_id,

    (
        p.product_category_name IS NULL
        OR p.product_name_lenght IS NULL
        OR p.product_description_lenght IS NULL
        OR p.product_photos_qty IS NULL
    ) AS missing_metadata_flag,

    (
        p.product_weight_g IS NULL
        OR p.product_length_cm IS NULL
        OR p.product_height_cm IS NULL
        OR p.product_width_cm IS NULL
    ) AS missing_dimensions_flag,

    (
        p.product_weight_g = 0
        OR p.product_length_cm = 0
        OR p.product_height_cm = 0
        OR p.product_width_cm = 0
    ) AS zero_dimensions_flag

FROM olist.products AS p;

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (
        WHERE missing_metadata_flag
    ) AS missing_metadata,
    COUNT(*) FILTER (
        WHERE missing_dimensions_flag
    ) AS missing_dimensions,
    COUNT(*) FILTER (
        WHERE zero_dimensions_flag
    ) AS zero_dimensions
FROM analytics.vw_products_quality_flags;

-- DAY 2: TASK 10
-- Step 10A: Identify missing category translations

SELECT
    p.product_category_name,
    COUNT(*) AS affected_products
FROM olist.products AS p
LEFT JOIN olist.product_category_name_translation AS t
    ON p.product_category_name =
       t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY affected_products DESC;

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_name ILIKE '%translat%'
   OR table_name ILIKE '%categor%'
ORDER BY table_schema, table_name;

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_name ILIKE '%translat%'
   OR table_name ILIKE '%categor%'
ORDER BY table_schema, table_name;

SELECT
    table_schema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'olist'
  AND table_name ILIKE '%translat%'
ORDER BY table_name, ordinal_position;

SELECT
    p.product_category_name,
    COUNT(*) AS affected_products
FROM olist.products AS p
LEFT JOIN olist.product_category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY affected_products DESC;


-- DAY 2: TASK 10
-- Step 10C: Validate translated product view

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_products,

    COUNT(*) FILTER (
        WHERE category_english = 'Unknown'
    ) AS unknown_categories,

    COUNT(*) FILTER (
        WHERE translation_status = 'Manual Translation'
    ) AS manual_translations

FROM analytics.vw_product_categories_translated;

-- DAY 2: TASK 11
-- Step 11A: Inspect geolocation data quality

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes,

    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
    ) AS missing_zip_prefixes,

    COUNT(*) FILTER (
        WHERE geolocation_city IS NULL
    ) AS missing_cities,

    COUNT(*) FILTER (
        WHERE geolocation_state IS NULL
    ) AS missing_states,

    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
           OR geolocation_lng IS NULL
    ) AS missing_coordinates

FROM olist.geolocation;

-- DAY 2: TASK 11
-- Step 11B: Investigate duplicate ZIP prefixes

WITH zip_analysis AS (
    SELECT
        geolocation_zip_code_prefix,
        COUNT(*) AS record_count,
        COUNT(DISTINCT geolocation_city)
            AS unique_cities,
        COUNT(DISTINCT geolocation_state)
            AS unique_states
    FROM olist.geolocation
    GROUP BY geolocation_zip_code_prefix
)

SELECT
    COUNT(*) AS total_zip_prefixes,

    COUNT(*) FILTER (
        WHERE record_count > 1
    ) AS duplicate_zip_prefixes,

    COUNT(*) FILTER (
        WHERE unique_cities > 1
    ) AS multiple_city_prefixes,

    COUNT(*) FILTER (
        WHERE unique_states > 1
    ) AS multiple_state_prefixes,

    MAX(record_count) AS max_records_per_zip

FROM zip_analysis;

-- DAY 2: TASK 11
-- Step 11C: Investigate conflicting state assignments

SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    COUNT(*) AS state_record_count,
    COUNT(DISTINCT geolocation_city) AS unique_cities
FROM olist.geolocation
WHERE geolocation_zip_code_prefix IN (
    SELECT geolocation_zip_code_prefix
    FROM olist.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(DISTINCT geolocation_state) > 1
)
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_state
ORDER BY
    geolocation_zip_code_prefix,
    state_record_count DESC,
    geolocation_state;

-- DAY 2: TASK 11
-- Step 11D: Investigate city name variations

SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    geolocation_city,
    COUNT(*) AS city_record_count

FROM olist.geolocation

WHERE geolocation_zip_code_prefix IN (
    SELECT geolocation_zip_code_prefix
    FROM olist.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(DISTINCT geolocation_city) > 1
)

GROUP BY
    geolocation_zip_code_prefix,
    geolocation_state,
    geolocation_city

ORDER BY
    geolocation_zip_code_prefix,
    city_record_count DESC,
    geolocation_city

LIMIT 50;

-- DAY 2: TASK 11
-- Step 11E: Validate standardized city names

WITH city_standardization AS (
    SELECT
        geolocation_zip_code_prefix,

        COUNT(DISTINCT geolocation_city)
            AS original_city_count,

        COUNT(DISTINCT
            TRANSLATE(
                LOWER(TRIM(geolocation_city)),
                'áàâãäéèêëíìîïóòôõöúùûüç',
                'aaaaaeeeeiiiiooooouuuuc'
            )
        ) AS standardized_city_count

    FROM olist.geolocation
    GROUP BY geolocation_zip_code_prefix
)

SELECT
    COUNT(*) AS total_zip_prefixes,

    COUNT(*) FILTER (
        WHERE original_city_count > 1
    ) AS original_city_conflicts,

    COUNT(*) FILTER (
        WHERE original_city_count > 1
          AND standardized_city_count = 1
    ) AS resolved_by_standardization,

    COUNT(*) FILTER (
        WHERE standardized_city_count > 1
    ) AS remaining_city_conflicts

FROM city_standardization;

-- DAY 2: TASK 11
-- Step 11F: Investigate remaining city conflicts

WITH standardized_geo AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,
        geolocation_city,

        TRANSLATE(
            LOWER(TRIM(geolocation_city)),
            'áàâãäéèêëíìîïóòôõöúùûüç',
            'aaaaaeeeeiiiiooooouuuuc'
        ) AS standardized_city

    FROM olist.geolocation
),

conflicting_zips AS (
    SELECT
        geolocation_zip_code_prefix
    FROM standardized_geo
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(DISTINCT standardized_city) > 1
)

SELECT
    g.geolocation_zip_code_prefix,
    g.geolocation_state,
    g.standardized_city,
    COUNT(*) AS record_count

FROM standardized_geo AS g

INNER JOIN conflicting_zips AS c
    ON g.geolocation_zip_code_prefix =
       c.geolocation_zip_code_prefix

GROUP BY
    g.geolocation_zip_code_prefix,
    g.geolocation_state,
    g.standardized_city

ORDER BY
    g.geolocation_zip_code_prefix,
    record_count DESC,
    g.standardized_city

LIMIT 50;

-- DAY 2: TASK 11
-- Step 11G: Create clean geographic lookup

CREATE OR REPLACE VIEW analytics.vw_geolocation_clean AS

WITH standardized_geo AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,

        TRANSLATE(
            LOWER(TRIM(geolocation_city)),
            'áàâãäéèêëíìîïóòôõöúùûüç',
            'aaaaaeeeeiiiiooooouuuuc'
        ) AS standardized_city,

        geolocation_lat,
        geolocation_lng

    FROM olist.geolocation
),

city_frequency AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,
        standardized_city,
        COUNT(*) AS location_count,

        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY geolocation_lat)
            AS latitude,

        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY geolocation_lng)
            AS longitude

    FROM standardized_geo

    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_state,
        standardized_city
),

ranked_locations AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY
                location_count DESC,
                geolocation_state,
                standardized_city
        ) AS location_rank

    FROM city_frequency
)

SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    standardized_city AS geolocation_city,
    latitude AS geolocation_lat,
    longitude AS geolocation_lng,
    location_count AS supporting_records

FROM ranked_locations
WHERE location_rank = 1;

-- DAY 2: TASK 11
-- Step 11H: Validate clean geographic lookup

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes,

    COUNT(*) -
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS duplicate_zip_prefixes,

    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
    ) AS missing_zip_prefixes,

    COUNT(*) FILTER (
        WHERE geolocation_city IS NULL
           OR geolocation_state IS NULL
    ) AS missing_locations,

    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
           OR geolocation_lng IS NULL
    ) AS missing_coordinates

FROM analytics.vw_geolocation_clean;

-- DAY 2: TASK 11
-- Step 11I: Final coordinate validation

SELECT
    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
           OR geolocation_lng IS NULL
    ) AS missing_coordinates
FROM analytics.vw_geolocation_clean;

-- DAY 2: TASK 12
-- Step 12A: Identify ZIP and state conflicts

SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    COUNT(*) AS state_record_count

FROM olist.geolocation

WHERE geolocation_zip_code_prefix IN (
    SELECT geolocation_zip_code_prefix
    FROM olist.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(DISTINCT geolocation_state) > 1
)

GROUP BY
    geolocation_zip_code_prefix,
    geolocation_state

ORDER BY
    geolocation_zip_code_prefix,
    state_record_count DESC;

-- DAY 2: TASK 12
-- Step 12B: Flag ZIP and state inconsistencies

CREATE OR REPLACE VIEW
analytics.vw_geolocation_state_flags AS

WITH state_counts AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,
        COUNT(*) AS state_record_count

    FROM olist.geolocation

    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_state
),

ranked_states AS (
    SELECT
        *,
        SUM(state_record_count) OVER (
            PARTITION BY geolocation_zip_code_prefix
        ) AS total_zip_records,

        COUNT(*) OVER (
            PARTITION BY geolocation_zip_code_prefix
        ) AS state_count,

        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY
                state_record_count DESC,
                geolocation_state
        ) AS state_rank

    FROM state_counts
)

SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    state_record_count,
    total_zip_records,

    CASE
        WHEN state_count = 1
            THEN 'Consistent'

        WHEN state_rank = 1
            THEN 'Majority State'

        ELSE 'Minority State Conflict'
    END AS state_quality_status

FROM ranked_states;

-- DAY 2: TASK 12
-- Step 12C: Validate ZIP and state quality flags

SELECT
    state_quality_status,
    COUNT(*) AS total_combinations,
    SUM(state_record_count) AS total_source_records,
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes

FROM analytics.vw_geolocation_state_flags

GROUP BY state_quality_status

ORDER BY state_quality_status;

-- DAY 2: TASK 12
-- Step 12C: Validate ZIP and state quality flags

SELECT
    state_quality_status,
    COUNT(*) AS total_combinations,
    SUM(state_record_count) AS total_source_records,
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes

FROM analytics.vw_geolocation_state_flags

GROUP BY state_quality_status

ORDER BY state_quality_status;

-- DAY 2: TASK 13
-- Step 13A: Inspect order item data quality

SELECT
    COUNT(*) AS total_order_items,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(DISTINCT seller_id) AS unique_sellers,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR product_id IS NULL
           OR seller_id IS NULL
           OR order_item_id IS NULL
    ) AS missing_identifiers,

    COUNT(*) FILTER (
        WHERE price IS NULL
           OR freight_value IS NULL
    ) AS missing_financial_values,

    COUNT(*) FILTER (
        WHERE price < 0
           OR freight_value < 0
    ) AS negative_financial_values

FROM olist.order_items;

-- DAY 2: TASK 13
-- Step 13B: Validate order item uniqueness

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT (order_id, order_item_id))
        AS unique_order_items,

    COUNT(*) -
    COUNT(DISTINCT (order_id, order_item_id))
        AS duplicate_order_items,

    COUNT(*) FILTER (
        WHERE order_item_id < 1
    ) AS invalid_item_numbers,

    MIN(order_item_id) AS min_item_number,

    MAX(order_item_id) AS max_item_number

FROM olist.order_items;

-- DAY 2: TASK 13
-- Step 13C: Validate relationships

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

FROM olist.order_items AS oi

LEFT JOIN olist.orders AS o
    ON oi.order_id = o.order_id

LEFT JOIN olist.products AS p
    ON oi.product_id = p.product_id

LEFT JOIN olist.sellers AS s
    ON oi.seller_id = s.seller_id;

-- DAY 2: TASK 13
-- Step 13D: Create clean order items view

CREATE OR REPLACE VIEW analytics.vw_order_items_clean AS

SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.shipping_limit_date,

    oi.price,
    oi.freight_value,

    (oi.price + oi.freight_value)
        AS total_item_value,

    CASE
        WHEN oi.price IS NULL
          OR oi.freight_value IS NULL
            THEN 'Missing Financial Data'

        WHEN oi.price < 0
          OR oi.freight_value < 0
            THEN 'Invalid Financial Data'

        ELSE 'Valid'
    END AS financial_quality_status

FROM olist.order_items AS oi;

-- DAY 2: TASK 13
-- Step 13E: Final order items validation

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT (order_id, order_item_id))
        AS unique_order_items,

    COUNT(*) -
    COUNT(DISTINCT (order_id, order_item_id))
        AS duplicate_order_items,

    COUNT(*) FILTER (
        WHERE financial_quality_status = 'Valid'
    ) AS valid_financial_records,

    COUNT(*) FILTER (
        WHERE financial_quality_status <> 'Valid'
    ) AS invalid_financial_records,

    COUNT(*) FILTER (
        WHERE total_item_value IS NULL
    ) AS missing_total_values,

    ROUND(SUM(price)::numeric, 2)
        AS total_product_value,

    ROUND(SUM(freight_value)::numeric, 2)
        AS total_freight_value,

    ROUND(SUM(total_item_value)::numeric, 2)
        AS total_combined_value

FROM analytics.vw_order_items_clean;

-- DAY 2: TASK 14
-- Step 14A: Payment data quality assessment

SELECT
    COUNT(*) AS total_payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR payment_sequential IS NULL
    ) AS missing_identifiers,

    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS missing_payment_types,

    COUNT(*) FILTER (
        WHERE payment_value IS NULL
    ) AS missing_payment_values,

    COUNT(*) FILTER (
        WHERE payment_value < 0
    ) AS negative_payment_values,

    COUNT(*) FILTER (
        WHERE payment_value = 0
    ) AS zero_payment_values,

    ROUND(SUM(payment_value)::numeric, 2)
        AS total_payment_value

FROM olist.order_payments;

-- DAY 2: TASK 14
-- Step 14A: Payment data quality assessment

SELECT
    COUNT(*) AS total_payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR payment_sequential IS NULL
    ) AS missing_identifiers,

    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS missing_payment_types,

    COUNT(*) FILTER (
        WHERE payment_value IS NULL
    ) AS missing_payment_values,

    COUNT(*) FILTER (
        WHERE payment_value < 0
    ) AS negative_payment_values,

    COUNT(*) FILTER (
        WHERE payment_value = 0
    ) AS zero_payment_values,

    ROUND(SUM(payment_value)::numeric, 2)
        AS total_payment_value

FROM olist.order_payments;





-- DAY 2: TASK 14
-- Step 14A: Payment data quality assessment

SELECT
    COUNT(*) AS total_payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR payment_sequential IS NULL
    ) AS missing_identifiers,

    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS missing_payment_types,

    COUNT(*) FILTER (
        WHERE payment_value IS NULL
    ) AS missing_payment_values,

    COUNT(*) FILTER (
        WHERE payment_value < 0
    ) AS negative_payment_values,

    COUNT(*) FILTER (
        WHERE payment_value = 0
    ) AS zero_payment_values,

    ROUND(SUM(payment_value)::numeric, 2)
        AS total_payment_value

FROM olist.order_payments;

-- DAY 2: TASK 14
-- Step 14B: Investigate zero payment values

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value

FROM olist.order_payments

WHERE payment_value = 0

ORDER BY order_id, payment_sequential;

-- DAY 2: TASK 14
-- Step 14C: Validate payment record uniqueness

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT (order_id, payment_sequential))
        AS unique_payment_records,

    COUNT(*) -
    COUNT(DISTINCT (order_id, payment_sequential))
        AS duplicate_payment_records,

    COUNT(*) FILTER (
        WHERE payment_sequential < 1
    ) AS invalid_payment_sequence,

    MIN(payment_sequential)
        AS min_payment_sequence,

    MAX(payment_sequential)
        AS max_payment_sequence

FROM olist.order_payments;

-- DAY 2: TASK 14
-- Step 14D: Investigate zero value payments

WITH zero_payment_orders AS (
    SELECT DISTINCT order_id
    FROM olist.order_payments
    WHERE payment_value = 0
)

SELECT
    zp.order_id,

    COUNT(*) AS total_payment_records,

    COUNT(*) FILTER (
        WHERE op.payment_value = 0
    ) AS zero_payment_records,

    COUNT(*) FILTER (
        WHERE op.payment_value > 0
    ) AS positive_payment_records,

    ROUND(SUM(op.payment_value)::numeric, 2)
        AS total_order_payment

FROM zero_payment_orders AS zp

JOIN olist.order_payments AS op
    ON zp.order_id = op.order_id

GROUP BY zp.order_id
ORDER BY total_order_payment DESC;

-- DAY 2: TASK 14
-- Step 14E: Create cleaned payment view

CREATE OR REPLACE VIEW analytics.vw_order_payments_clean AS

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
)

SELECT
    op.order_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value,

    ps.total_order_payment,

    CASE
        WHEN op.payment_value IS NULL
            THEN 'Missing Payment Value'

        WHEN op.payment_value < 0
            THEN 'Invalid Payment Value'

        WHEN op.payment_value = 0
             AND ps.total_order_payment > 0
            THEN 'Zero Payment With Positive Order Total'

        WHEN op.payment_value = 0
             AND ps.total_order_payment = 0
            THEN 'Zero Payment Only'

        ELSE 'Valid'
    END AS payment_quality_status

FROM olist.order_payments AS op

LEFT JOIN payment_summary AS ps
    ON op.order_id = ps.order_id;

-- DAY 2: TASK 14
-- Step 14F: Final payment view validation

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT (order_id, payment_sequential))
        AS unique_payment_records,

    COUNT(*) -
    COUNT(DISTINCT (order_id, payment_sequential))
        AS duplicate_payment_records,

    COUNT(*) FILTER (
        WHERE payment_quality_status = 'Valid'
    ) AS valid_payments,

    COUNT(*) FILTER (
        WHERE payment_quality_status =
        'Zero Payment With Positive Order Total'
    ) AS zero_with_positive_total,

    COUNT(*) FILTER (
        WHERE payment_quality_status = 'Zero Payment Only'
    ) AS zero_only_payments,

    COUNT(*) FILTER (
        WHERE payment_quality_status NOT IN (
            'Valid',
            'Zero Payment With Positive Order Total',
            'Zero Payment Only'
        )
        OR payment_quality_status IS NULL
    ) AS other_quality_statuses,

    ROUND(SUM(payment_value)::numeric, 2)
        AS total_payment_value

FROM analytics.vw_order_payments_clean;

-- DAY 2: TASK 15
-- Step 15A: Review data quality assessment

SELECT
    COUNT(*) AS total_review_records,

    COUNT(DISTINCT review_id)
        AS unique_review_ids,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    COUNT(*) - COUNT(DISTINCT review_id)
        AS repeated_review_id_records,

    COUNT(*) FILTER (
        WHERE review_id IS NULL
           OR order_id IS NULL
    ) AS missing_identifiers,

    COUNT(*) FILTER (
        WHERE review_score IS NULL
    ) AS missing_review_scores,

    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores,

    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS missing_creation_dates,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS missing_answer_timestamps

FROM olist.order_reviews;

-- DAY 2: TASK 15
-- Step 15A: Review data quality assessment

SELECT
    COUNT(*) AS total_review_records,

    COUNT(DISTINCT review_id)
        AS unique_review_ids,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    COUNT(*) - COUNT(DISTINCT review_id)
        AS repeated_review_id_records,

    COUNT(*) FILTER (
        WHERE review_id IS NULL
           OR order_id IS NULL
    ) AS missing_identifiers,

    COUNT(*) FILTER (
        WHERE review_score IS NULL
    ) AS missing_review_scores,

    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores,

    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS missing_creation_dates,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS missing_answer_timestamps

FROM olist.order_reviews;

-- DAY 2: TASK 15
-- Step 15A: Review data quality assessment

SELECT
    COUNT(*) AS total_review_records,

    COUNT(DISTINCT review_id)
        AS unique_review_ids,

    COUNT(DISTINCT order_id)
        AS unique_orders,

    COUNT(*) - COUNT(DISTINCT review_id)
        AS repeated_review_id_records,

    COUNT(*) FILTER (
        WHERE review_id IS NULL
           OR order_id IS NULL
    ) AS missing_identifiers,

    COUNT(*) FILTER (
        WHERE review_score IS NULL
    ) AS missing_review_scores,

    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores,

    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS missing_creation_dates,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS missing_answer_timestamps

FROM olist.order_reviews;

-- DAY 2: TASK 15
-- Step 15B: Investigate repeated review IDs

WITH review_analysis AS (
    SELECT
        review_id,
        COUNT(*) AS record_count,
        COUNT(DISTINCT order_id) AS unique_orders,
        COUNT(DISTINCT review_score) AS unique_scores,
        COUNT(DISTINCT review_creation_date)
            AS unique_creation_dates,
        COUNT(DISTINCT review_answer_timestamp)
            AS unique_answer_timestamps
    FROM olist.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS repeated_review_ids,

    SUM(record_count) AS records_in_repeated_groups,

    SUM(record_count - 1) AS additional_records,

    COUNT(*) FILTER (
        WHERE unique_orders > 1
    ) AS review_ids_multiple_orders,

    COUNT(*) FILTER (
        WHERE unique_scores > 1
    ) AS review_ids_multiple_scores,

    COUNT(*) FILTER (
        WHERE unique_creation_dates > 1
    ) AS review_ids_multiple_creation_dates,

    COUNT(*) FILTER (
        WHERE unique_answer_timestamps > 1
    ) AS review_ids_multiple_answer_timestamps,

    MAX(record_count) AS max_records_per_review_id

FROM review_analysis;

-- DAY 2: TASK 15
-- Step 15C: Validate composite review key

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT (review_id, order_id))
        AS unique_review_order_pairs,

    COUNT(*) -
    COUNT(DISTINCT (review_id, order_id))
        AS duplicate_review_order_pairs,

    COUNT(*) FILTER (
        WHERE review_id IS NULL
           OR order_id IS NULL
    ) AS missing_identifiers,

    COUNT(DISTINCT review_id)
        AS unique_review_ids,

    COUNT(DISTINCT order_id)
        AS unique_orders

FROM olist.order_reviews;

-- DAY 2: TASK 15
-- Step 15D: Create cleaned review view

CREATE OR REPLACE VIEW analytics.vw_order_reviews_clean AS

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,

    CASE
        WHEN review_score >= 4 THEN 'Positive'
        WHEN review_score = 3 THEN 'Neutral'
        WHEN review_score <= 2 THEN 'Negative'
    END AS review_sentiment,

    CASE
        WHEN review_comment_message IS NULL
          OR TRIM(review_comment_message) = ''
        THEN 'No Comment'
        ELSE 'Has Comment'
    END AS comment_status,

    CASE
        WHEN review_answer_timestamp < review_creation_date
        THEN 'Invalid Timestamp'
        ELSE 'Valid'
    END AS review_quality_status

FROM olist.order_reviews;

-- DAY 2: TASK 15
-- Step 15E: Validate cleaned reviews view

SELECT
    COUNT(*) AS total_reviews,

    COUNT(DISTINCT (review_id, order_id))
        AS unique_review_order_pairs,

    COUNT(*) -
    COUNT(DISTINCT (review_id, order_id))
        AS duplicate_review_order_pairs,

    COUNT(*) FILTER (
        WHERE review_sentiment = 'Positive'
    ) AS positive_reviews,

    COUNT(*) FILTER (
        WHERE review_sentiment = 'Neutral'
    ) AS neutral_reviews,

    COUNT(*) FILTER (
        WHERE review_sentiment = 'Negative'
    ) AS negative_reviews,

    COUNT(*) FILTER (
        WHERE comment_status = 'Has Comment'
    ) AS reviews_with_comments,

    COUNT(*) FILTER (
        WHERE comment_status = 'No Comment'
    ) AS reviews_without_comments,

    COUNT(*) FILTER (
        WHERE review_quality_status = 'Invalid Timestamp'
    ) AS invalid_timestamps,

    COUNT(*) FILTER (
        WHERE review_sentiment IS NULL
           OR comment_status IS NULL
           OR review_quality_status IS NULL
    ) AS unclassified_reviews

FROM analytics.vw_order_reviews_clean;

-- DAY 2: TASK 15
-- Step 15F: Final quality check

SELECT
    COUNT(*) FILTER (
        WHERE review_quality_status = 'Invalid Timestamp'
    ) AS invalid_timestamps,

    COUNT(*) FILTER (
        WHERE review_sentiment IS NULL
           OR comment_status IS NULL
           OR review_quality_status IS NULL
    ) AS unclassified_reviews

FROM analytics.vw_order_reviews_clean;

-- DAY 2: TASK 15
-- Step 15F: Final quality check

SELECT
    COUNT(*) FILTER (
        WHERE review_quality_status = 'Invalid Timestamp'
    ) AS invalid_timestamps,

    COUNT(*) FILTER (
        WHERE review_sentiment IS NULL
           OR comment_status IS NULL
           OR review_quality_status IS NULL
    ) AS unclassified_reviews

FROM analytics.vw_order_reviews_clean;


SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_name ILIKE '%categor%'
   OR table_name ILIKE '%translat%'
ORDER BY table_schema, table_name;

-- DAY 2: TASK 16
-- Step 16A: Validate category translations

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT product_category_name)
        AS unique_portuguese_categories,

    COUNT(DISTINCT product_category_name_english)
        AS unique_english_categories,

    COUNT(*) - COUNT(DISTINCT product_category_name)
        AS duplicate_portuguese_categories,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
           OR TRIM(product_category_name) = ''
    ) AS missing_portuguese_categories,

    COUNT(*) FILTER (
        WHERE product_category_name_english IS NULL
           OR TRIM(product_category_name_english) = ''
    ) AS missing_english_categories

FROM olist.product_category_translation;

-- DAY 2: TASK 16
-- Step 16B: Validate product category coverage

SELECT
    COUNT(*) AS total_products,

    COUNT(DISTINCT p.product_category_name)
        AS unique_product_categories,

    COUNT(*) FILTER (
        WHERE p.product_category_name IS NULL
    ) AS products_without_category,

    COUNT(*) FILTER (
        WHERE p.product_category_name IS NOT NULL
          AND t.product_category_name IS NULL
    ) AS products_without_translation,

    COUNT(DISTINCT p.product_category_name)
        FILTER (
            WHERE t.product_category_name IS NULL
        ) AS untranslated_categories,

    COUNT(*) FILTER (
        WHERE t.product_category_name_english IS NOT NULL
    ) AS products_with_translation

FROM olist.products AS p

LEFT JOIN olist.product_category_translation AS t
    ON p.product_category_name = t.product_category_name;

-- DAY 2: TASK 16
-- Step 16C: Identify untranslated categories

SELECT
    p.product_category_name,
    COUNT(*) AS affected_products

FROM olist.products AS p

LEFT JOIN olist.product_category_translation AS t
    ON p.product_category_name = t.product_category_name

WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL

GROUP BY p.product_category_name

ORDER BY affected_products DESC;



