USE Data_Ware_House;
GO

/*******************************************************************************
Script Name:    bronze.sp_load_bronze_data
Description:    Stored procedure to truncate and bulk load raw data from CSV files
                into the Bronze layer tables.
Author:         Rafiul islam Rafi
Date:           May 2026

PURPOSE:
    - This procedure acts as the ingestion mechanism for the Data Warehouse.
    - It clears existing data in the Bronze (staging) tables and reloads fresh 
      snapshots from the flat-file sources to ensure a clean source-to-bronze sync.

WARNINGS / PRE-REQUISITES:
    1. DESTRUCTIVE ACTION: The TRUNCATE TABLE command permanently deletes all data 
       currently in the Bronze layer before reloading.
    2. FILE PATH DEPENDENCY: The `BULK INSERT` paths are hardcoded to local drive `D:\`.
       Ensure that SQL Server has read permissions to this directory, or update 
       these paths if migrating environments (e.g., to Dev, QA, or Production).
    3. EXCLUSIVE LOCKS: The `TABLOCK` hint takes a table-level lock, minimizing 
       transaction log overhead but preventing concurrent reads/writes during execution.
*******************************************************************************/

CREATE OR ALTER PROCEDURE bronze.sp_load_bronze_data
AS
BEGIN
    -- Settling environment settings for optimal ETL performance
    SET NOCOUNT ON;

    PRINT '=========================================================';
    PRINT 'Starting Bronze Layer Load...';
    PRINT '=========================================================';

    ----------------------------------------------------------------------------
    -- 1. Load CRM Customer Information
    ----------------------------------------------------------------------------
    PRINT '>> Loading CRM Customer Info...';
    
    TRUNCATE TABLE bronze.crm_cust_info;
	
    BULK INSERT bronze.crm_cust_info
    FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,          -- Skip the header row
        FIELDTERMINATOR = ',',
        TABLOCK                -- Optimizes loading performance
    );

    ----------------------------------------------------------------------------
    -- 2. Load CRM Product Information
    ----------------------------------------------------------------------------
    PRINT '>> Loading CRM Product Info...';

    TRUNCATE TABLE bronze.crm_prd_info;

    BULK INSERT bronze.crm_prd_info
    FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    ----------------------------------------------------------------------------
    -- 3. Load CRM Sales Details
    ----------------------------------------------------------------------------
    PRINT '>> Loading CRM Sales Details...';

    TRUNCATE TABLE bronze.crm_sales_details;

    BULK INSERT bronze.crm_sales_details
    FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    ----------------------------------------------------------------------------
    -- 4. Load ERP Customer AZ12 Data
    ----------------------------------------------------------------------------
    PRINT '>> Loading ERP Customer AZ12...';

    TRUNCATE TABLE bronze.erp_cust_az12;

    BULK INSERT bronze.erp_cust_az12
    FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    ----------------------------------------------------------------------------
    -- 5. Load ERP Location A101 Data
    ----------------------------------------------------------------------------
    PRINT '>> Loading ERP Location A101...';

    TRUNCATE TABLE bronze.erp_loc_a101;

    BULK INSERT bronze.erp_loc_a101
    FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    ----------------------------------------------------------------------------
    -- 6. Load ERP Product Category G1V1 Data
    ----------------------------------------------------------------------------
    PRINT '>> Loading ERP Product Category G1V1...';

    TRUNCATE TABLE bronze.erp_px_cat_g1v1;

    BULK INSERT bronze.erp_px_cat_g1v1
    FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    PRINT '=========================================================';
    PRINT 'Bronze Layer Load Completed Successfully!';
    PRINT '=========================================================';
END;
GO
