
/*
===============================================================================
SCRIPT PURPOSE:
    This script initializes the 'Bronze' layer of the Data Warehouse. 
    It defines the raw schema for landing data from multiple sources 
    (CRM and ERP systems).

WARNING:
    EXTREME CAUTION: This script uses 'DROP TABLE' statements. 
    Running this will PERMANENTLY DELETE all existing data within the 
    bronze schema tables. Ensure you have a backup or that this is 
    intended for a fresh data load or schema reset.
===============================================================================
*/

USE Data_Ware_House;
GO

-- =============================================================================
-- 1. CRM Tables (Customer Relationship Management)
-- =============================================================================

-- Recreating crm_cust_info: Stores core customer profile data
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO
CREATE TABLE bronze.crm_cust_info (
	cust_id INT,
	cust_key NVARCHAR(50),
	cust_email VARCHAR(255),
	cust_first_name NVARCHAR(50),
	cust_last_name NVARCHAR(50),
	cust_material_status NVARCHAR(50),
	cust_gender NVARCHAR(50),
	cust_create_date DATE
);

-- Recreating crm_prd_info: Stores product catalog and pricing
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO
CREATE TABLE bronze.crm_prd_info (
	prd_id INT,
	prd_key NVARCHAR(50),
	prd_nm  NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(10),
	prd_start_dt DATE,
	prd_end_dt DATE
);

-- Recreating crm_sales_details: Stores transaction and order history
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO
CREATE TABLE bronze.crm_sales_details (
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT
);

-- =============================================================================
-- 2. ERP Tables (Enterprise Resource Planning)
-- =============================================================================

-- Recreating erp_cust_az12: Supplemental customer data (Birth Date/Gender)
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO
CREATE TABLE bronze.erp_cust_az12(
	CID NVARCHAR(50),
	BDATE DATE,
	GEN NVARCHAR(10)
);

-- Recreating erp_loc_a101: Customer location and regional mapping
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO
CREATE TABLE bronze.erp_loc_a101(
	CID NVARCHAR(50),
	CNTRY NVARCHAR(30)
);

-- Recreating erp_px_cat_g1v1: Product category and sub-category hierarchy
IF OBJECT_ID('bronze.erp_px_cat_g1v1', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v1;
GO
CREATE TABLE bronze.erp_px_cat_g1v1(
	ID NVARCHAR(30),
	CAT NVARCHAR(50),
	SUBCAT NVARCHAR(30),
	MAINTENANCE NVARCHAR(30)
);

PRINT 'Successfully recreated all Bronze Layer tables.';
GO
