
/*
 DATA CLEANING AND ANALYTICAL PREPARATION

PROJECT: Olist Ecommerce SQL Analytics
DATABASE: olist_ecommerce
SCHEMA: olist

FINDINGS:

1. REVIEWS
   789 repeated review IDs.
   814 additional review records.
   Preserve original review records.

2. PRODUCTS
   610 missing product categories.
   2 missing product weights.

3. CATEGORY TRANSLATIONS
   73 categories used in products.
   71 categories have translations.
   2 categories lack translations.
   13 products affected.

4. GEOLOCATION
   1,000,163 source records.
   261,831 excess exact duplicate records.
   8 ZIP prefixes linked to multiple states.

5. SELLERS
   3,095 unique seller IDs.
   No missing values in checked fields.

CLEANING PRINCIPLES:

1. Preserve original source tables.
2. Do not delete records automatically.
3. Document all cleaning decisions.
4. Use separate analytical views.
5. Validate joins before aggregation.
6. Preserve the correct record grain.


Database: olist_ecommerce

Source schema: olist
Analytics schema: analytics

1. Preserve all original source tables.

2. Do not delete repeated review IDs.
   Review IDs may reference multiple orders.

3. Preserve missing product attributes.
   Do not invent categories or weights.

4. Deduplicate geolocation records only
   when required by analytical logic.

5. Flag conflicting geographic assignments.
   Do not automatically correct states.

6. Preserve untranslated product categories.
   Use original names as a fallback
   when building analytical views.

7. Create cleaned analytical views
   in the analytics schema.

8. Validate row counts and uniqueness
   after each transformation.



View: analytics.vw_products_clean

Purpose:
Prepare product data for analytical reporting
without modifying original Olist records.

Validation results:
Total products: 32951
Unique products: 32951
Duplicate products: 0

Category quality:
Complete categories: 32328
Missing categories: 610
Missing translations: 13

Dimension quality:
Incomplete dimension records: 2

Cleaning decisions:
1. Preserve all original product records.
2. Retain missing values as NULL.
3. Add English category translations.
4. Flag missing categories and translations.
5. Flag incomplete product dimensions.
6. Do not delete or modify source records.

Conclusion:
The cleaned product view passed row count
and product ID uniqueness validation.
Known missing values remain documented.

/*
DAY 2 | TASK 4C.4
ORDER TIMESTAMP DATA QUALITY FINDINGS

Source table: olist.orders
Total orders: 99,441

VALIDATION RESULTS

1. Delivered without delivery date: 8
2. Delivery before purchase: 0
3. Approval before purchase: 0
4. Carrier before purchase: 166
5. Delivery before carrier: 23
6. Late deliveries: 7,827

CARRIER TIMESTAMP INVESTIGATION

Delivered orders affected: 165
Shipped orders affected: 1

Discrepancy classification:

Under 1 hour: 121
1 to 24 hours: 43
24 hours or more: 2

DATA CLEANING DECISIONS

1. Preserve all 99,441 original orders.

2. Do not modify original timestamps.

3. Flag orders where the carrier timestamp
   occurs before the purchase timestamp.

4. Flag orders where delivery occurs
   before the carrier timestamp.

5. Flag delivered orders without
   a delivery timestamp.

6. Identify late deliveries separately
   as a business performance metric.

7. Preserve NULL values when the
   order lifecycle explains their absence.

8. Create cleaned analytical views
   inside the analytics schema.

9. Keep all original tables in the
   olist schema unchanged.

NEXT ACTION

Create analytics.vw_orders_clean
with explicit data quality flags.


/*


View: analytics.vw_orders_clean
Source: olist.orders

VALIDATION RESULTS

1. Source orders: 99,441
2. Cleaned orders: 99,441
3. Duplicate order IDs: 0
4. Missing order IDs: 0
5. Extra order IDs: 0

DATA QUALITY FINDINGS

1. Carrier timestamps before purchase: 166
2. Late deliveries: 7,826
3. Negative delivery durations: 0
4. Delivered orders without duration: 8
5. Incorrect late delivery flags: 0

BUSINESS RULES

1. Preserve all original orders.
2. Do not modify source records.
3. Flag timestamp inconsistencies.
4. Calculate delivery duration for delivered orders.
5. Classify late deliveries only for
   orders with status 'delivered'.
6. Preserve missing timestamps as NULL.

CONCLUSION

The cleaned orders view passed record preservation
and late delivery classification checks.

Known data quality issues remain documented
without modifying the original source data.
*/


-- ==========================================
-- TASK 5: FINAL DATA QUALITY VALIDATION
-- ==========================================

-- 5A: Verify analytical views
-- 5B: Validate record counts and uniqueness
-- 5C: Validate quality classifications
-- 5D: Final data quality summary



/*
DAY 2: TASK 6
STANDARDIZE ORDER STATUSES AND TIMESTAMPS

SOURCE: olist.orders
TOTAL ORDERS: 99,441

STATUS VALIDATION
1. Eight recognized order statuses.
2. Missing statuses: 0
3. Inconsistent formatting: 0
4. Unexpected statuses: 0

TIMESTAMP VALIDATION
1. Missing purchase timestamps: 0
2. Missing approval timestamps: 160
3. Missing carrier timestamps: 1,783
4. Missing delivery timestamps: 2,965

CHRONOLOGY FINDINGS
1. Approval before purchase: 0
2. Carrier before purchase: 166
3. Delivery before carrier: 23
4. Delivery before purchase: 0

DELIVERED ORDER QUALITY
1. Delivered orders: 96,478
2. Missing approval: 14
3. Missing carrier date: 2
4. Missing delivery date: 8

CLEANING DECISIONS
1. Preserve original source records.
2. Retain missing timestamps as NULL.
3. Flag chronological inconsistencies.
4. Do not automatically correct timestamps.
5. Maintain all eight recognized statuses.

CONCLUSION
Order status formatting validation passed.
Timestamp anomalies were identified and
documented for further investigation.
*/


/*
DAY 2: TASK 7
FLAG MISSING ORDER INFORMATION

VALIDATION RESULTS

Total orders: 99,441
Missing approval timestamps: 160
Missing carrier timestamps: 1,783
Missing delivery timestamps: 2,965

Delivered orders with missing information: 23

CLEANING DECISIONS

1. Preserve all original order records.
2. Retain missing timestamps as NULL.
3. Create analytics.vw_orders_flagged.
4. Add four Boolean missing information flags.
5. Preserve the existing 12 columns.
6. Count each affected delivered order once.
7. Do not automatically replace missing dates.

CONCLUSION

Missing order information has been identified
and flagged without modifying source records.

All 99,441 orders are preserved.
Validation results match previous quality checks.
*/




/*
DAY 2: TASK 8
VALIDATE CUSTOMER AND ORDER RELATIONSHIPS

VALIDATION RESULTS

Total orders: 99,441
Total customer records: 99,441
Unique customer IDs: 99,441
Missing customer IDs: 0
Unmatched customer IDs: 0

JOIN VALIDATION

Joined records: 99,441
Unique orders after join: 99,441
Duplicate order excess: 0

CLEANING DECISIONS

1. Preserve all customer and order records.
2. Use customer_id as the relationship key.
3. No customer ID corrections are required.
4. Customer and order joins preserve record counts.
5. Maintain order_id as the unique order identifier.

CONCLUSION

Customer and order relationships passed validation.
No missing or unmatched customer IDs were found.
The join introduced no duplicate order records.
*/


/*
DAY 2: TASK 9
HANDLE MISSING PRODUCT ATTRIBUTES

TOTAL PRODUCTS: 32,951

PRODUCT METADATA FINDINGS
1. Missing product categories: 610
2. Missing product name lengths: 610
3. Missing description lengths: 610
4. Missing photo quantities: 610
5. All four attributes are missing for the
   same 610 products.
6. No partial missing patterns were detected
   across these four attributes.

PHYSICAL DIMENSION FINDINGS
1. Missing physical measurements: 2 products
2. Zero product weight: 4 products
3. Negative physical measurements: 0 products

EXISTING ANALYTICAL VIEW
analytics.vw_products_clean

1. Missing measurements are classified
   as Incomplete.
2. Zero weight products are currently
   classified as Complete.
3. Existing dimension classification
   requires enhancement.

CLEANING DECISIONS
1. Preserve all 32,951 product records.
2. Keep original missing values as NULL.
3. Do not replace zero weights with
   estimated values.
4. Flag missing product metadata.
5. Flag zero weight separately.
6. Preserve the original source tables.

CONCLUSION
Product attribute issues have been identified.
Additional analytical quality flags are needed
for zero weight and missing metadata.
*/

/*
DAY 2: TASK 10
Product Category Translation Cleaning

Total products: 32,951
Official translations: 32,328
Manual translations: 13
Missing original categories: 610

VALIDATION RESULTS
Total records: 32,951
Unique products: 32,951
Duplicate products: 0
Unknown categories: 610

CLEANING DECISIONS
1. Preserved original product records.
2. Created a separate analytical translation view.
3. Added manual translations for two categories.
4. Assigned 'Unknown' to missing categories.
5. Preserved translation status for auditing.
6. Confirmed no duplicate or lost products.

View:
analytics.vw_product_categories_translated

Conclusion:
Product translation cleaning and validation passed.
The exact calculated combined value is R$15,842,553.24. The final combined value column is cut off in your screenshot, so its displayed value has not yet been independently confirmed.
*/
