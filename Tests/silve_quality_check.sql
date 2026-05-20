USE Data_Ware_House;
/*
=========================================================================
Quality Checks
=========================================================================

Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.

=========================================================================
*/

-- =========================================================================
-- 1. Check for Null or Duplicate Primary Keys
-- =========================================================================
PRINT '🔍 Checking for Null or Duplicate Primary Keys...';

-- Checking Dimension Table: crm_cust_info
SELECT 'crm_cust_info' AS Table_Name, cust_id AS Missing_Or_Duplicate_ID, COUNT(*) AS Total_Occurrences
FROM silver.crm_cust_info
GROUP BY cust_id
HAVING COUNT(*) > 1 OR cust_id IS NULL;

-- Checking Dimension Table: erp_cust_az12
SELECT 'erp_cust_az12' AS Table_Name, cid AS Missing_Or_Duplicate_ID, COUNT(*) AS Total_Occurrences
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;


-- =========================================================================
-- 2. Check for Unwanted Spaces in String Fields
-- =========================================================================
PRINT '🔍 Checking for Unwanted Spaces in String Fields...';

SELECT 'crm_cust_info' AS Table_Name, cust_id AS Record_ID, 'cust_first_name' AS Column_Name, cust_first_name AS Flawed_Value
FROM silver.crm_cust_info
WHERE cust_first_name <> TRIM(cust_first_name)
UNION ALL
SELECT 'erp_loc_a101' AS Table_Name, cid AS Record_ID, 'cntry' AS Column_Name, cntry AS Flawed_Value
FROM silver.erp_loc_a101
WHERE cntry <> TRIM(cntry);


-- =========================================================================
-- 3. Check for Data Standardization and Consistency (Categorical Domain)
-- =========================================================================
PRINT '🔍 Checking for Data Standardization Issues...';

-- Verify Gender mapping conformed cleanly
SELECT 'crm_cust_info' AS Table_Name, cust_id AS Record_ID, 'cust_gender' AS Column_Name, cust_gender AS Non_Standard_Value
FROM silver.crm_cust_info
WHERE cust_gender NOT IN ('Male', 'Female', 'Unknown')
UNION ALL
-- Verify Marital Status mapping conformed cleanly
SELECT 'crm_cust_info' AS Table_Name, cust_id AS Record_ID, 'cust_marital_status' AS Column_Name, cust_marital_status AS Non_Standard_Value
FROM silver.crm_cust_info
WHERE cust_marital_status NOT IN ('Single', 'Married', 'Unknown');


-- =========================================================================
-- 4. Check for Invalid Date Ranges and Orders
-- =========================================================================
PRINT '🔍 Checking for Invalid Date Ranges and Orders...';

-- Product start dates must precede or equal end dates
SELECT 'crm_prd_info' AS Table_Name, prd_key AS Record_ID, 'prd_start_dt > prd_end_dt' AS Logic_Violation, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt
UNION ALL
-- Birthdays must not be in the future or realistically before 1920
SELECT 'erp_cust_az12' AS Table_Name, cid AS Record_ID, 'Out of bounds birthday' AS Logic_Violation, bdate, NULL
FROM silver.erp_cust_az12
WHERE bdate > GETDATE() OR bdate < '1920-01-01';


-- =========================================================================
-- 5. Check for Data Consistency Between Related Fields
-- =========================================================================
PRINT '🔍 Checking Data Consistency Between Related Fields...';

-- Verify Financial Calculations match correctly (Sales = Qty * Price)
SELECT 
    'crm_sales_details' AS Table_Name, 
    sls_ord_num AS Record_ID, 
    CONCAT('Sales (', sls_sales, ') does not equal Qty (', sls_quantity, ') * Price (', sls_price, ')') AS Mismatch_Details
FROM silver.crm_sales_details
WHERE sls_sales <> (sls_quantity * sls_price);

PRINT '✨ Quality check complete. Analyze any output records for troubleshooting!';
