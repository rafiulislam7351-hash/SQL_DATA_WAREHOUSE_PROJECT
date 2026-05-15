USE Data_Ware_House;
GO

/*******************************************************************************
Script Name:    bronze.sp_load_bronze_data
Description:    Stored procedure to truncate and bulk load raw data from CSV files
                into the Bronze layer tables with granular logging and full batch metrics.
Author:         Data Warehouse ETL Team
Date:           May 2026

PURPOSE:
    - This procedure acts as the ingestion mechanism for the Data Warehouse.
    - It clears existing data in the Bronze (staging) tables and reloads fresh 
      snapshots from the flat-file sources to ensure a clean source-to-bronze sync.
    - Tracks and outputs precise processing durations per step, as well as the 
      total calculated load time for the entire Bronze layer.

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

    -- Declaring timestamp variables for total batch execution and individual processes
    DECLARE @BatchStart DATETIME2 = SYSDATETIME();
    DECLARE @BatchEnd DATETIME2;
    DECLARE @StepStart DATETIME2;
    DECLARE @StepEnd DATETIME2;

    -- Wrapping the entire execution flow in a TRY block for robust error catching
    BEGIN TRY

        PRINT '=========================================================';
        PRINT 'Starting Bronze Layer Load...';
        PRINT '=========================================================';

        ----------------------------------------------------------------------------
        -- 1. Load CRM Customer Information
        ----------------------------------------------------------------------------
        PRINT '>> Processing Table: bronze.crm_cust_info';
        
        PRINT '   - Truncating existing data...';
        TRUNCATE TABLE bronze.crm_cust_info;
        
        PRINT '   - Bulk inserting fresh snapshot...';
        SET @StepStart = SYSDATETIME();
        BULK INSERT bronze.crm_cust_info
        FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,          -- Skip the header row
            FIELDTERMINATOR = ',',
            TABLOCK                -- Optimizes loading performance
        );
        SET @StepEnd = SYSDATETIME();
        PRINT '   -> Completed crm_cust_info in ' + CAST(DATEDIFF(ms, @StepStart, @StepEnd) AS VARCHAR) + ' ms';
        PRINT '';

        ----------------------------------------------------------------------------
        -- 2. Load CRM Product Information
        ----------------------------------------------------------------------------
        PRINT '>> Processing Table: bronze.crm_prd_info';

        PRINT '   - Truncating existing data...';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '   - Bulk inserting fresh snapshot...';
        SET @StepStart = SYSDATETIME();
        BULK INSERT bronze.crm_prd_info
        FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @StepEnd = SYSDATETIME();
        PRINT '   -> Completed crm_prd_info in ' + CAST(DATEDIFF(ms, @StepStart, @StepEnd) AS VARCHAR) + ' ms';
        PRINT '';

        ----------------------------------------------------------------------------
        -- 3. Load CRM Sales Details
        ----------------------------------------------------------------------------
        PRINT '>> Processing Table: bronze.crm_sales_details';

        PRINT '   - Truncating existing data...';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '   - Bulk inserting fresh snapshot...';
        SET @StepStart = SYSDATETIME();
        BULK INSERT bronze.crm_sales_details
        FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @StepEnd = SYSDATETIME();
        PRINT '   -> Completed crm_sales_details in ' + CAST(DATEDIFF(ms, @StepStart, @StepEnd) AS VARCHAR) + ' ms';
        PRINT '';

        ----------------------------------------------------------------------------
        -- 4. Load ERP Customer AZ12 Data
        ----------------------------------------------------------------------------
        PRINT '>> Processing Table: bronze.erp_cust_az12';

        PRINT '   - Truncating existing data...';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '   - Bulk inserting fresh snapshot...';
        SET @StepStart = SYSDATETIME();
        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @StepEnd = SYSDATETIME();
        PRINT '   -> Completed erp_cust_az12 in ' + CAST(DATEDIFF(ms, @StepStart, @StepEnd) AS VARCHAR) + ' ms';
        PRINT '';

        ----------------------------------------------------------------------------
        -- 5. Load ERP Location A101 Data
        ----------------------------------------------------------------------------
        PRINT '>> Processing Table: bronze.erp_loc_a101';

        PRINT '   - Truncating existing data...';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '   - Bulk inserting fresh snapshot...';
        SET @StepStart = SYSDATETIME();
        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @StepEnd = SYSDATETIME();
        PRINT '   -> Completed erp_loc_a101 in ' + CAST(DATEDIFF(ms, @StepStart, @StepEnd) AS VARCHAR) + ' ms';
        PRINT '';

        ----------------------------------------------------------------------------
        -- 6. Load ERP Product Category G1V1 Data
        ----------------------------------------------------------------------------
        PRINT '>> Processing Table: bronze.erp_px_cat_g1v1';

        PRINT '   - Truncating existing data...';
        TRUNCATE TABLE bronze.erp_px_cat_g1v1;

        PRINT '   - Bulk inserting fresh snapshot...';
        SET @StepStart = SYSDATETIME();
        BULK INSERT bronze.erp_px_cat_g1v1
        FROM 'D:\MS SQL Practise\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @StepEnd = SYSDATETIME();
        PRINT '   -> Completed erp_px_cat_g1v1 in ' + CAST(DATEDIFF(ms, @StepStart, @StepEnd) AS VARCHAR) + ' ms';
        PRINT '';

        -- Capture total load time after successfully processing all tables
        SET @BatchEnd = SYSDATETIME();

        PRINT '=========================================================';
        PRINT 'Bronze Layer Load Completed Successfully!';
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(second, @BatchStart, @BatchEnd) AS VARCHAR) + ' seconds';
        PRINT '=========================================================';

    END TRY
    BEGIN CATCH
        -- Structured error tracking blocks executing if any table load fails
        PRINT '=========================================================';
        PRINT 'ERROR DETECTED during Bronze Layer Load processing!';
        PRINT '=========================================================';
        
        -- Custom error message formatting for quick logging analysis
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE() AS ErrorLine,
            ERROR_MESSAGE() AS ErrorMessage;

        -- Rethrowing the exception details back up to the calling agent/orchestrator
        THROW;
    END CATCH
END;
GO
