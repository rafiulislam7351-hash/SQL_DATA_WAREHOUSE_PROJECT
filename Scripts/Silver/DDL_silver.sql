/*
--===================================
Script Purpose & Overview
--===================================
This script initializes or resets the Silver Layer (the cleansed, standardized, and conformed data layer) inside your Data_Ware_House database.
It extracts raw data from two primary upstream sources:
CRM (Customer Relationship Management): Captures core profiles, product details, and sales transaction history.
ERP (Enterprise Resource Planning): Supplements the CRM data with additional customer demographics, geographic locations, and product hierarchies.
Every table includes a system-generated metadata column (dwh_load_dt) to track exactly when the record entered the data warehouse.
--===================================
⚠️ Critical Warning: Data Loss Risk
--===================================
This script uses DROP TABLE IF EXISTS logic (DROP TABLE silver...).
Running this script on a production database will instantly and permanently delete all existing data in these tables.
Always ensure you have a backup or are running this strictly in a Development/Testing environment before execution!
*/

USE Data_Ware_House;
GO

PRINT '========================================================================';
PRINT ' Starting Silver Layer Reconstitution: Let''s build something great! 🚀';
PRINT '========================================================================';
GO

-- =============================================================================
-- 1. CRM Tables (Customer Relationship Management)
-- =============================================================================

PRINT '--- Processing CRM Tables ---';

-- Recreating crm_cust_info: Stores core customer profile data
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
BEGIN
    DROP TABLE silver.crm_cust_info;
    PRINT '🧹 Old [silver.crm_cust_info] dropped successfully.';
END
GO

CREATE TABLE silver.crm_cust_info (
    cust_id             INT,             -- Unique internal identifier for the customer
    cust_key            NVARCHAR(50),    -- Business key used by the source CRM system
    cust_first_name     NVARCHAR(50),    -- Customer's first name
    cust_last_name      NVARCHAR(50),    -- Customer's last name
    cust_marital_status NVARCHAR(50),    -- Current marital status (e.g., Single, Married)
    cust_gender         NVARCHAR(50),    -- Gender identification
    cust_create_date    DATE,            -- Date the account was created in the CRM
    dwh_load_dt         DATETIME2 DEFAULT GETDATE() -- Timestamp tracking when DWH loaded this row
);
PRINT '✨ Table [silver.crm_cust_info] created! Core customer profiles are ready to load.';
GO


-- Recreating crm_prd_info: Stores product catalog and pricing
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
BEGIN
    DROP TABLE silver.crm_prd_info;
    PRINT '🧹 Old [silver.crm_prd_info] dropped successfully.';
END
GO

CREATE TABLE silver.crm_prd_info (
    prd_id       INT,             -- Unique internal identifier for the product
    prd_key      NVARCHAR(50),    -- Business key/SKU used by the source system
    cat_id       NVARCHAR(50),    -- Foreign key pointing to the ERP product category
    prd_nm       NVARCHAR(50),    -- Name of the product
    prd_cost     INT,             -- Base manufacturing/acquisition cost
    prd_line     NVARCHAR(50),    -- Product segment or line classification
    prd_start_dt DATE,            -- Validity start date for this product version
    prd_end_dt   DATE,            -- Validity end date (useful for tracking historical changes)
    dwh_load_dt  DATETIME2 DEFAULT GETDATE() -- Timestamp tracking when DWH loaded this row
);
PRINT '✨ Table [silver.crm_prd_info] created! Product catalog setup complete.';
GO


-- Recreating crm_sales_details: Stores transaction and order history
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
BEGIN
    DROP TABLE silver.crm_sales_details;
    PRINT '🧹 Old [silver.crm_sales_details] dropped successfully.';
END
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num   NVARCHAR(50),    -- Unique transaction invoice or order number
    sls_prd_key   NVARCHAR(50),    -- Foreign key mapping back to the product info
    sls_cust_id   INT,             -- Foreign key mapping back to the customer info
    sls_order_dt  DATE,            -- Date the order was placed
    sls_ship_dt   DATE,            -- Date the order left the warehouse
    sls_due_dt    DATE,            -- Date the customer payment or delivery is expected
    sls_sales     INT,             -- Total gross sales revenue amount
    sls_quantity  INT,             -- Number of units purchased
    sls_price     INT,             -- Unit price applied at checkout
    dwh_load_dt   DATETIME2 DEFAULT GETDATE() -- Timestamp tracking when DWH loaded this row
);
PRINT '✨ Table [silver.crm_sales_details] created! Transaction ledger is set up and waiting.';
GO


-- =============================================================================
-- 2. ERP Tables (Enterprise Resource Planning)
-- =============================================================================

PRINT '--- Processing ERP Tables ---';

-- Recreating erp_cust_az12: Supplemental customer data (Birth Date/Gender)
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
BEGIN
    DROP TABLE silver.erp_cust_az12;
    PRINT '🧹 Old [silver.erp_cust_az12] dropped successfully.';
END
GO

CREATE TABLE silver.erp_cust_az12 (
    cid         NVARCHAR(50),    -- Customer ID mapped from the ERP side
    bdate       DATE,            -- Customer birthdate (crucial for age demographic analysis)
    gen         NVARCHAR(10),    -- ERP-recorded gender code
    dwh_load_dt DATETIME2 DEFAULT GETDATE() -- Timestamp tracking when DWH loaded this row
);
PRINT '✨ Table [silver.erp_cust_az12] created! Demographics extension table is live.';
GO


-- Recreating erp_loc_a101: Customer location and regional mapping
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
BEGIN
    DROP TABLE silver.erp_loc_a101;
    PRINT '🧹 Old [silver.erp_loc_a101] dropped successfully.';
END
GO

CREATE TABLE silver.erp_loc_a101 (
    cid         NVARCHAR(50),    -- Customer ID mapping link
    cntry       NVARCHAR(30),    -- Country of residence for geographical slicing
    dwh_load_dt DATETIME2 DEFAULT GETDATE() -- Timestamp tracking when DWH loaded this row
);
PRINT '✨ Table [silver.erp_loc_a101] created! Geographic localization definitions are active.';
GO


-- Recreating erp_px_cat_g1v1: Product category and sub-category hierarchy
IF OBJECT_ID('silver.erp_px_cat_g1v1', 'U') IS NOT NULL
BEGIN
    DROP TABLE silver.erp_px_cat_g1v1;
    PRINT '🧹 Old [silver.erp_px_cat_g1v1] dropped successfully.';
END
GO

CREATE TABLE silver.erp_px_cat_g1v1 (
    id          NVARCHAR(30),    -- Category/Sub-category lookup key
    cat         NVARCHAR(50),    -- Top-level macro product category
    subcat      NVARCHAR(30),    -- Secondary micro product sub-category
    maintenance NVARCHAR(30),    -- Operational notes or service levels for the group
    dwh_load_dt DATETIME2 DEFAULT GETDATE() -- Timestamp tracking when DWH loaded this row
);
PRINT '✨ Table [silver.erp_px_cat_g1v1] created! Product hierarchy schema established.';
GO

PRINT '========================================================================';
PRINT ' 🎉 Success! All Silver Layer tables have been perfectly recreated. ';
PRINT '========================================================================';
GO
