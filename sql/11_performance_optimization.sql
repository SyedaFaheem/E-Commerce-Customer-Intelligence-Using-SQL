
-- =====================================================
-- OLIST E-COMMERCE ANALYTICS
-- DAY 4: PERFORMANCE OPTIMIZATION
-- Tasks 9-12, 16-18
-- =====================================================

-- 1. Timestamp index
CREATE INDEX IF NOT EXISTS idx_orders_purchase_timestamp
ON olist.orders (order_purchase_timestamp);


-- 2. Verify index health and usage
SELECT
    s.relname AS table_name,
    s.indexrelname AS index_name,
    s.idx_scan AS index_scans,
    pg_size_pretty(
        pg_relation_size(s.indexrelid)
    ) AS index_size,
    i.indisvalid AS is_valid,
    i.indisready AS is_ready
FROM pg_stat_user_indexes s
JOIN pg_index i
    ON s.indexrelid = i.indexrelid
WHERE s.schemaname = 'olist'
  AND s.indexrelname = 'idx_orders_purchase_timestamp';


-- 3. Check PostgreSQL memory settings
SELECT
    current_setting('work_mem') AS work_mem,
    current_setting('shared_buffers') AS shared_buffers,
    current_setting('effective_cache_size')
        AS effective_cache_size;


-- 4. Benchmark Tableau monthly sales
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM analytics.vw_tableau_monthly_sales;


-- 5. Benchmark customer segments
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM analytics.vw_tableau_customer_segments;


-- 6. Benchmark product categories
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM analytics.vw_tableau_category_performance;


-- 7. Benchmark geographic sales
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM analytics.vw_tableau_geographic_sales;


-- 8. Review saved performance documentation
SELECT *
FROM analytics.performance_documentation
ORDER BY optimization_area, metric_name;
