
SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_ids,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE order_status IS NULL
    ) AS missing_status,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_dates

FROM olist.orders;
SELECT
    order_status,
    COUNT(*) AS missing_delivery_count
FROM olist.orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY missing_delivery_count DESC;

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM olist.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL
ORDER BY order_purchase_timestamp;

SELECT
    COUNT(*) AS affected_orders,

    COUNT(order_approved_at)
        AS orders_with_approval,

    COUNT(order_delivered_carrier_date)
        AS orders_with_carrier_date,

    COUNT(order_estimated_delivery_date)
        AS orders_with_estimated_date

FROM olist.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

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

Table: products

Total products: 32,951
Unique product IDs: 32,951
Missing product IDs: 0

Missing categories: 610
Missing weights: 2

Missing both category and weight: 1
Missing category only: 609
Missing weight only: 1

Total distinct products affected: 611

Conclusion:

All product IDs are unique and nonnull.

Some products have missing category or
weight information.

Preserve original product records.

For category analysis, handle missing
categories explicitly rather than
silently excluding these products.

For weight analysis, account for
missing weight values.

No data modification performed.


Table: sellers

Total sellers: 3,095
Unique seller IDs: 3,095

Missing seller IDs: 0
Missing seller cities: 0
Missing seller states: 0
Missing seller ZIP codes: 0

Conclusion:

All seller IDs are unique.

No NULL values were detected in
the seller location fields tested.

Seller records passed the initial
uniqueness and completeness checks.

No data modification performed.

/*
STEP 22: GEOLOCATION DATA QUALITY SUMMARY

Table: olist.geolocation

Total records: 1,000,163
Missing values in tested columns: 0

Unique full-record combinations: 738,332
Additional exact duplicate records: 261,831

Geolocation ZIP code prefixes are not unique.
A single prefix can contain multiple coordinates
and city assignments.

Eight ZIP code prefixes have conflicting states.

Each conflicting prefix has one minority-state
record and a dominant state assignment.

Coordinate investigation:
6 minority records have coordinates close to
the dominant ZIP prefix group.
2 records show substantial coordinate differences.

Data quality decisions:

1. Preserve all original source records.
2. Do not automatically correct state assignments.
3. Flag conflicting geographic records for review.
4. Do not join raw geolocation directly to
   customers or sellers using ZIP prefixes.
5. Create a validated geographic lookup table
   before geographic reporting.
6. Document any future correction rules.

Conclusion:

Geolocation data requires preparation before
reliable geographic analysis.
*/

/*
STEP 23: PRODUCT CATEGORY TRANSLATION VALIDATION

Table: olist.product_category_translation

Validation results:

Total records: 71
Unique Portuguese categories: 71
Missing category names: 0
Missing English translations: 0

Findings:

1. All 71 Portuguese category names are unique.
2. No missing Portuguese category names.
3. No missing English translations.
4. No duplicate Portuguese category names detected.

Conclusion:

The product category translation table passed
the uniqueness and NULL validation checks.

The table is suitable for category translation
lookups, subject to relationship validation
with the products table.
*/


/*
STEP 24: PRODUCT CATEGORY RELATIONSHIP VALIDATION

Product categories used: 73
Categories with English translations: 71
Categories without English translations: 2

Missing translations:

1. portateis_cozinha_e_preparadores_de_alimentos
   Affected products: 10

2. pc_gamer
   Affected products: 3

Total affected products: 13

Data quality findings:

1. The translation table contains 71 unique
   Portuguese category names.

2. All 71 translation records have English values.

3. Two categories used in the products table
   have no matching English translation.

4. The missing translations affect 13 products.

Decision:

Preserve all original records.

Do not delete products with missing translations.

Use a documented fallback category label
or a validated translation mapping during analysis.

Conclusion:

Product category validation is complete.
Two missing translation mappings require
handling during downstream analysis.
*/

