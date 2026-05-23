/* 
===================================================================================
DATA QUALITY INTEGRITY AUDIT
===================================================================================
Description : Rapid structural audit query across Gold layer tables.
Warning     : Returns records ONLY when data quality violations are present.
              An empty result set means 100% data integrity passed.
===================================================================================
*/

-- 1. Check for missing Customer Keys
SELECT 'dim_customer_info' AS View_Name, 'Missing Surrogate Key' AS Issue_Description, customer_id AS Source_ID
FROM gold.dim_customer_info 
WHERE customer_key IS NULL;


-- 2. Check for missing Product Names or Numbers
SELECT 'dim_product_info' AS View_Name, 'Missing Vital Product Details' AS Issue_Description, product_id AS Source_ID
FROM gold.dim_product_info 
WHERE product_name IS NULL OR product_number IS NULL;


-- 3. Check for Orphaned Customer Sales links
SELECT 'fact_sales' AS View_Name, 'Orphaned Customer Key (Broken Link)' AS Issue_Description, sales_order_number AS Source_ID
FROM gold.fact_sales AS fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_customer_info AS dc WHERE fs.customer_key = dc.customer_key);


-- 4. Check for Orphaned Product Sales links
SELECT 'fact_sales' AS View_Name, 'Orphaned Product Key (Broken Link)' AS Issue_Description, sales_order_number AS Source_ID
FROM gold.fact_sales AS fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_product_info AS dp WHERE fs.product_key = dp.product_key);



-- 5. Check for Out-of-Bounds Metrics
SELECT 'fact_sales' AS View_Name, 'Negative Quantity or Price Metric' AS Issue_Description, sales_order_number AS Source_ID
FROM gold.fact_sales 
WHERE quantity < 0 OR unit_price < 0;
