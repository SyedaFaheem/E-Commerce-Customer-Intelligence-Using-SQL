"vw_tableau_fact_orders"	"CREATE OR REPLACE VIEW analytics.vw_tableau_fact_orders AS
 SELECT order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    date_trunc('month'::text, order_purchase_timestamp)::date AS order_month,
    EXTRACT(year FROM order_purchase_timestamp)::integer AS order_year,
    EXTRACT(month FROM order_purchase_timestamp)::integer AS order_month_number,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    is_late_delivery,
    total_items,
    unique_products,
    COALESCE(total_product_value, 0::numeric) AS product_revenue,
    COALESCE(total_freight_value, 0::numeric) AS freight_revenue,
    COALESCE(total_item_value, 0::numeric) AS total_revenue,
    COALESCE(total_payment_value, 0::numeric) AS total_payment_value,
    total_payment_records,
    payment_methods_used,
    missing_items_flag,
    missing_payment_flag,
        CASE
            WHEN order_status::text = 'delivered'::text THEN 1
            ELSE 0
        END AS delivered_order_flag,
        CASE
            WHEN order_status::text = 'delivered'::text THEN COALESCE(total_item_value, 0::numeric)
            ELSE 0::numeric
        END AS delivered_revenue
   FROM analytics.vw_order_summary;
;"
"vw_tableau_dim_customers"	"CREATE OR REPLACE VIEW analytics.vw_tableau_dim_customers AS
 SELECT customer_unique_id,
    total_orders,
    delivered_orders,
    COALESCE(delivered_product_spending, 0::numeric) AS product_spending,
    COALESCE(delivered_total_spending, 0::numeric) AS total_spending,
    COALESCE(avg_delivered_order_value, 0::numeric) AS avg_order_value,
    first_order_date,
    last_order_date,
    customer_type,
        CASE
            WHEN delivered_orders >= 2 THEN 1
            ELSE 0
        END AS repeat_customer_flag,
        CASE
            WHEN delivered_orders >= 2 THEN 'Repeat Customer'::text
            WHEN delivered_orders = 1 THEN 'One-Time Customer'::text
            ELSE 'No Delivered Orders'::text
        END AS delivered_customer_segment
   FROM analytics.vw_customer_purchase_behavior;
;"
"vw_tableau_dim_products"	"CREATE OR REPLACE VIEW analytics.vw_tableau_dim_products AS
 SELECT p.product_id,
    COALESCE(p.category_english, p.product_category_name, 'Unknown'::text) AS product_category,
    p.product_category_name AS original_category,
    p.translation_status,
    COALESCE(s.units_sold, 0::bigint) AS units_sold,
    COALESCE(s.delivered_orders, 0::bigint) AS delivered_orders,
    COALESCE(s.product_revenue, 0::numeric) AS product_revenue,
    COALESCE(s.freight_revenue, 0::numeric) AS freight_revenue,
    COALESCE(s.total_item_value, 0::numeric) AS total_item_value,
    s.avg_selling_price,
    s.revenue_rank,
    s.volume_rank,
    s.product_revenue_share_pct
   FROM analytics.vw_product_categories_translated p
     LEFT JOIN analytics.vw_product_sales_performance s ON p.product_id::text = s.product_id::text;
;"
"vw_tableau_monthly_sales"	"CREATE OR REPLACE VIEW analytics.vw_tableau_monthly_sales AS
 SELECT order_month,
    EXTRACT(year FROM order_month)::integer AS order_year,
    EXTRACT(month FROM order_month)::integer AS order_month_number,
    count(*) AS total_orders,
    sum(delivered_order_flag) AS delivered_orders,
    round(sum(delivered_revenue), 2) AS delivered_revenue,
    round(sum(product_revenue) FILTER (WHERE order_status::text = 'delivered'::text), 2) AS delivered_product_revenue,
    round(sum(freight_revenue) FILTER (WHERE order_status::text = 'delivered'::text), 2) AS delivered_freight_revenue,
    round(sum(delivered_revenue) / NULLIF(sum(delivered_order_flag), 0)::numeric, 2) AS delivered_aov,
    count(*) FILTER (WHERE order_status::text = 'delivered'::text AND is_late_delivery = true) AS late_deliveries
   FROM analytics.vw_tableau_fact_orders
  GROUP BY order_month;
;"
"vw_tableau_customer_segments"	"CREATE OR REPLACE VIEW analytics.vw_tableau_customer_segments AS
 SELECT delivered_customer_segment,
    count(*) AS total_customers,
    count(*) FILTER (WHERE repeat_customer_flag = 1) AS repeat_customers,
    sum(total_orders) AS total_orders,
    sum(delivered_orders) AS delivered_orders,
    round(sum(product_spending), 2) AS product_revenue,
    round(sum(total_spending), 2) AS total_revenue,
    round(avg(total_spending), 2) AS avg_customer_value,
    round(sum(total_spending) / NULLIF(sum(delivered_orders), 0::numeric), 2) AS avg_order_value,
    round(count(*)::numeric * 100.0 / NULLIF(sum(count(*)) OVER (), 0::numeric), 2) AS customer_share_pct
   FROM analytics.vw_tableau_dim_customers
  GROUP BY delivered_customer_segment;
;"
"vw_tableau_category_performance"	"CREATE OR REPLACE VIEW analytics.vw_tableau_category_performance AS
 SELECT product_category,
    count(*) AS total_products,
    count(*) FILTER (WHERE units_sold > 0) AS products_sold,
    sum(units_sold) AS units_sold,
    round(sum(product_revenue), 2) AS product_revenue,
    round(sum(freight_revenue), 2) AS freight_revenue,
    round(sum(total_item_value), 2) AS total_revenue,
    round(sum(product_revenue) / NULLIF(sum(units_sold), 0::numeric), 2) AS avg_revenue_per_unit,
    round(sum(product_revenue) * 100.0 / NULLIF(sum(sum(product_revenue)) OVER (), 0::numeric), 2) AS revenue_share_pct,
    dense_rank() OVER (ORDER BY (sum(product_revenue)) DESC) AS revenue_rank
   FROM analytics.vw_tableau_dim_products
  GROUP BY product_category;
;"
"vw_tableau_geographic_sales"	"CREATE OR REPLACE VIEW analytics.vw_tableau_geographic_sales AS
 SELECT state AS state_code,
    unique_customers,
    total_orders,
    delivered_orders,
    round(COALESCE(product_sales, 0::numeric), 2) AS product_revenue,
    round(COALESCE(freight_value, 0::numeric), 2) AS freight_revenue,
    round(COALESCE(total_item_value, 0::numeric), 2) AS total_revenue,
    round(COALESCE(avg_order_value, 0::numeric), 2) AS avg_order_value,
    order_share_pct,
    revenue_share_pct,
    revenue_rank,
        CASE
            WHEN state::text = 'SP'::text THEN 'São Paulo'::text
            WHEN state::text = 'RJ'::text THEN 'Rio de Janeiro'::text
            WHEN state::text = 'MG'::text THEN 'Minas Gerais'::text
            WHEN state::text = 'RS'::text THEN 'Rio Grande do Sul'::text
            WHEN state::text = 'PR'::text THEN 'Paraná'::text
            WHEN state::text = 'SC'::text THEN 'Santa Catarina'::text
            WHEN state::text = 'BA'::text THEN 'Bahia'::text
            WHEN state::text = 'DF'::text THEN 'Distrito Federal'::text
            WHEN state::text = 'ES'::text THEN 'Espírito Santo'::text
            WHEN state::text = 'GO'::text THEN 'Goiás'::text
            WHEN state::text = 'PE'::text THEN 'Pernambuco'::text
            WHEN state::text = 'CE'::text THEN 'Ceará'::text
            WHEN state::text = 'PA'::text THEN 'Pará'::text
            WHEN state::text = 'MT'::text THEN 'Mato Grosso'::text
            WHEN state::text = 'MA'::text THEN 'Maranhão'::text
            WHEN state::text = 'MS'::text THEN 'Mato Grosso do Sul'::text
            WHEN state::text = 'PB'::text THEN 'Paraíba'::text
            WHEN state::text = 'PI'::text THEN 'Piauí'::text
            WHEN state::text = 'RN'::text THEN 'Rio Grande do Norte'::text
            WHEN state::text = 'AL'::text THEN 'Alagoas'::text
            WHEN state::text = 'SE'::text THEN 'Sergipe'::text
            WHEN state::text = 'TO'::text THEN 'Tocantins'::text
            WHEN state::text = 'RO'::text THEN 'Rondônia'::text
            WHEN state::text = 'AM'::text THEN 'Amazonas'::text
            WHEN state::text = 'AC'::text THEN 'Acre'::text
            WHEN state::text = 'AP'::text THEN 'Amapá'::text
            WHEN state::text = 'RR'::text THEN 'Roraima'::text
            ELSE 'Unknown'::text
        END AS state_name,
    'Brazil'::text AS country
   FROM analytics.vw_customer_geography;
;"