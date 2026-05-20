USE Data_Ware_House;
GO

/*******************************************************************************
OBJECTIVE:
    Orchestrate the complete Extract, Transform, Load (ETL) lifecycle from the 
    Bronze staging tier into the conformed Silver Layer. Handles schema data-cleansing, 
    value standardization, deduplication, and pipeline performance telemetry.

WARNINGS:
    - This procedure uses TRUNCATE statements. Running this completely flushes 
      the target Silver tables before processing structural ingestion.
    - An error midway will cause the execution to abort via XACT_ABORT, 
      potentially leaving analytical layers empty until a successful rerun.
*******************************************************************************/

CREATE OR ALTER PROCEDURE silver.load_silver_layer
AS
BEGIN
    -- Disable row count messages to optimize network performance
    SET NOCOUNT ON;
    -- Automatically roll back transactions if a runtime error occurs
    SET XACT_ABORT ON;

    -- =========================================================================
    -- TIME TRACKING & MONITORING INITIALIZATION
    -- =========================================================================
    DECLARE @GlobalStartTime DATETIME2 = SYSDATETIME();
    DECLARE @StepStartTime DATETIME2;
    DECLARE @StepEndTime DATETIME2;
    DECLARE @DurationMs INT;
    DECLARE @Message NVARCHAR(500);

    PRINT '=========================================================================';
    PRINT ' 🌟 STARTING SILVER LAYER ETL PIPELINE ENGINE';
    PRINT ' 🕒 Initialization Timestamp: ' + CONVERT(NVARCHAR, @GlobalStartTime, 121);
    PRINT '=========================================================================';

    BEGIN TRY
        -- =========================================================================
        -- PHASE 1: TRUNCATE TARGET TABLES
        -- Deletes existing records and resets identity counters across all Silver tables.
        -- Executed in reverse dependency order (Sales details truncated first).
        -- =========================================================================
        SET @StepStartTime = SYSDATETIME();
        PRINT '--- 🧹 Step 1: Commencing Target Storage Purge (Truncations) ---';

        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '   >> [silver.crm_sales_details] flushed successfully.';

        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '   >> [silver.crm_cust_info] flushed successfully.';

        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '   >> [silver.crm_prd_info] flushed successfully.';

        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '   >> [silver.erp_cust_az12] flushed successfully.';

        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '   >> [silver.erp_loc_a101] flushed successfully.';

        TRUNCATE TABLE silver.erp_px_cat_g1v1;
        PRINT '   >> [silver.erp_px_cat_g1v1] flushed successfully.';

        SET @StepEndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF(MILLISECOND, @StepStartTime, @StepEndTime);
        SET @Message = '✨ SUCCESS: Storage purge finished. Tables ready for fresh data. Time taken: ' + CAST(@DurationMs AS NVARCHAR) + ' ms.' + CHAR(10);
        RAISERROR(@Message, 0, 1) WITH NOWAIT;


        -- =========================================================================
        -- PHASE 2: DATA TRANSFORMATION AND INGESTION
        -- =========================================================================
        PRINT '--- 🚀 Step 2: Commencing Data Transformation and Ingestion ---';

        -- -------------------------------------------------------------------------
        -- Table 1: silver.crm_cust_info
        -- -------------------------------------------------------------------------
        SET @StepStartTime = SYSDATETIME();
        PRINT '📥 Processing: silver.crm_cust_info (Standardizing profiles & deduplicating)...';

        -- CTE to find and extract the most recent snapshot per distinct customer ID
        WITH RankedCustomers AS (
            SELECT
                TRY_CAST(cust_id AS INT) AS cust_id,                        -- Enforce strict data type casting
                TRY_CAST(cust_key AS INT) AS cust_key,                      -- Cast customer business key to internal format
                COALESCE(TRIM(cust_first_name), 'Unknown') AS cust_first_name, -- Clean structural whitespace strings
                COALESCE(TRIM(cust_last_name), 'Unknown') AS cust_last_name,  
                CASE 
                    WHEN UPPER(TRIM(cust_material_status)) = 'S' THEN 'Single'
                    WHEN UPPER(TRIM(cust_material_status)) = 'M' THEN 'Married'
                    ELSE 'Unknown' 
                END AS cust_marital_status,                                 -- Transform short-codes to clear descriptions
                CASE 
                    WHEN UPPER(TRIM(cust_gender)) = 'M' THEN 'Male'
                    WHEN UPPER(TRIM(cust_gender)) = 'F' THEN 'Female'
                    ELSE 'Unknown'
                END AS cust_gender,
                TRY_CAST(cust_create_date AS DATE) AS cust_create_date,
                ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY cust_create_date DESC) AS flag -- Track duplicate profiles
            FROM bronze.crm_cust_info
            WHERE cust_id IS NOT NULL
        )
        INSERT INTO silver.crm_cust_info (
            cust_id,
            cust_key, 
            cust_first_name,
            cust_last_name, 
            cust_marital_status,
            cust_gender,
            cust_create_date
        )
        SELECT 
            cust_id,
            cust_key,
            cust_first_name,
            cust_last_name,
            cust_marital_status,
            cust_gender,
            cust_create_date
        FROM RankedCustomers
        WHERE flag = 1; -- Filter down to only ingest unique, fresh entries

        SET @StepEndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF(MILLISECOND, @StepStartTime, @StepEndTime);
        SET @Message = '✔️ SUCCESS: Loaded [silver.crm_cust_info]. Time taken: ' + CAST(@DurationMs AS NVARCHAR) + ' ms.' + CHAR(10);
        RAISERROR(@Message, 0, 1) WITH NOWAIT;


        -- -------------------------------------------------------------------------
        -- Table 2: silver.crm_prd_info
        -- -------------------------------------------------------------------------
        SET @StepStartTime = SYSDATETIME();
        PRINT '📥 Processing: silver.crm_prd_info (Extracting SKUs & building historical timelines)...';

        -- CTE to trim and cleanly extract embedded category components from product keys
        WITH CleanedBronze AS (
            SELECT
                prd_id,
                SUBSTRING(UPPER(TRIM(prd_key)), 7, LEN(prd_key)) AS prd_key,      -- Isolate the raw key code
                REPLACE(SUBSTRING(UPPER(TRIM(prd_key)), 1, 5), '-', '_') AS cat_id, -- Isolate and refactor prefix as category ID
                prd_nm,
                ISNULL(prd_cost, 0) AS prd_cost,                                  -- Default missing financial metrics to zero
                CASE
                    WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                    WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                    WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Tour'
                    WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                    ELSE 'Unknown'
                END AS prd_line,
                TRY_CAST(prd_start_dt AS DATE) AS prd_start_dt
            FROM bronze.crm_prd_info
        ),
        -- CTE using LEAD window function to calculate dimensional expiration dates automatically
        FinalTimeline AS (
            SELECT
                prd_id,
                prd_key,
                cat_id,
                prd_nm,
                prd_cost,
                prd_line,
                prd_start_dt,
                COALESCE(
                    DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_id ORDER BY prd_start_dt)), 
                    CAST('9999-12-31' AS DATE)
                ) AS prd_end_dt, -- Set missing end dates to the high data-warehouse default threshold
                ROW_NUMBER() OVER (PARTITION BY prd_id, prd_start_dt ORDER BY prd_cost DESC) AS rn
            FROM CleanedBronze
        )
        INSERT INTO silver.crm_prd_info (
            prd_id,
            prd_key,
            cat_id,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT 
            prd_id,
            prd_key,
            cat_id,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        FROM FinalTimeline
        WHERE rn = 1;

        SET @StepEndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF(MILLISECOND, @StepStartTime, @StepEndTime);
        SET @Message = '✔️ SUCCESS: Loaded [silver.crm_prd_info]. Time taken: ' + CAST(@DurationMs AS NVARCHAR) + ' ms.' + CHAR(10);
        RAISERROR(@Message, 0, 1) WITH NOWAIT;


        -- -------------------------------------------------------------------------
        -- Table 3: silver.crm_sales_details
        -- -------------------------------------------------------------------------
        SET @StepStartTime = SYSDATETIME();
        PRINT '📥 Processing: silver.crm_sales_details (Parsing composite dates & auditing pricing equations)...';

        INSERT INTO silver.crm_sales_details(
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            TRIM(sls_prd_key) AS sls_prd_key,
            CAST(sls_cust_id AS INT) AS sls_cust_id,
            -- Convert string/integer raw formatted dates safely over into standard SQL format (YYYYMMDD)
            TRY_CONVERT(DATE, 
                CASE 
                    WHEN sls_order_dt IS NULL THEN NULL
                    WHEN TRIM(CAST(sls_order_dt AS NVARCHAR(20))) = '0' THEN NULL
                    WHEN LEN(TRIM(CAST(sls_order_dt AS NVARCHAR(20)))) != 8 THEN NULL
                    ELSE CAST(sls_order_dt AS NVARCHAR(8))
                END, 112
            ) AS sls_order_dt,
            TRY_CONVERT(DATE, 
                CASE 
                    WHEN sls_ship_dt IS NULL THEN NULL
                    WHEN TRIM(CAST(sls_ship_dt AS NVARCHAR(20))) = '0' THEN NULL
                    WHEN LEN(TRIM(CAST(sls_ship_dt AS NVARCHAR(20)))) != 8 THEN NULL
                    ELSE CAST(sls_ship_dt AS NVARCHAR(8))
                END, 112
            ) AS sls_ship_dt,
            TRY_CONVERT(DATE, 
                CASE 
                    WHEN sls_due_dt IS NULL THEN NULL
                    WHEN TRIM(CAST(sls_due_dt AS NVARCHAR(20))) = '0' THEN NULL
                    WHEN LEN(TRIM(CAST(sls_due_dt AS NVARCHAR(20)))) != 8 THEN NULL
                    ELSE CAST(sls_due_dt AS NVARCHAR(8))
                END, 112
            ) AS sls_due_dt,
            -- Data Quality Audit: Recalculate sales amount if fields match unexpected or empty entries
            CASE 
                WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_price != sls_quantity * ABS(sls_price) 
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            TRY_CAST(sls_quantity AS INT) AS sls_quantity,
            -- Data Quality Audit: Reverse engineer unit price when numbers do not balance mathematically
            CASE
                WHEN sls_price <= 0 OR sls_price IS NULL OR sls_price != sls_sales / NULLIF(sls_quantity, 0) 
                    THEN NULLIF(sls_sales, 0) / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @StepEndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF(MILLISECOND, @StepStartTime, @StepEndTime);
        SET @Message = '✔️ SUCCESS: Loaded [silver.crm_sales_details]. Time taken: ' + CAST(@DurationMs AS NVARCHAR) + ' ms.' + CHAR(10);
        RAISERROR(@Message, 0, 1) WITH NOWAIT;


        -- -------------------------------------------------------------------------
        -- Table 4: silver.erp_cust_az12
        -- -------------------------------------------------------------------------
        SET @StepStartTime = SYSDATETIME();
        PRINT '📥 Processing: silver.erp_cust_az12 (Filtering outlier demographic records)...';

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT 
            -- Strips away source prefixes like 'NAS' if present within raw entries
            CASE
                WHEN cid LIKE '%NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,
            -- Eradicate impossible age ranges or future dates to prevent calculation errors
            CASE 
                WHEN bdate > GETDATE() OR bdate < '1920-01-01' THEN NULL
                ELSE bdate
            END AS bdate,
            CASE
                WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
                WHEN gen IS NULL THEN 'Unknown'
                WHEN LEN(TRIM(gen)) = 0 THEN 'Unknown'
                ELSE gen
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @StepEndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF(MILLISECOND, @StepStartTime, @StepEndTime);
        SET @Message = '✔️ SUCCESS: Loaded [silver.erp_cust_az12]. Time taken: ' + CAST(@DurationMs AS NVARCHAR) + ' ms.' + CHAR(10);
        RAISERROR(@Message, 0, 1) WITH NOWAIT;


        -- -------------------------------------------------------------------------
        -- Table 5: silver.erp_loc_a101
        -- -------------------------------------------------------------------------
        SET @StepStartTime = SYSDATETIME();
        PRINT '📥 Processing: silver.erp_loc_a101 (Conforming geographical names)...';

        INSERT INTO silver.erp_loc_a101 (
            cid, 
            cntry
        )
        SELECT
            REPLACE(TRIM(CID), '-', '') AS cid, -- Standardize relational keys by stripping out hyphens
            CASE
                WHEN TRIM(CNTRY) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
                WHEN TRIM(CNTRY) IS NULL OR TRIM(CNTRY) = '' THEN 'Unknown'
                WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
                ELSE TRIM(CNTRY)
            END AS cntry -- Map regional variations cleanly over into singular names
        FROM bronze.erp_loc_a101;

        SET @StepEndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF(MILLISECOND, @StepStartTime, @StepEndTime);
        SET @Message = '✔️ SUCCESS: Loaded [silver.erp_loc_a101]. Time taken: ' + CAST(@DurationMs AS NVARCHAR) + ' ms.' + CHAR(10);
        RAISERROR(@Message, 0, 1) WITH NOWAIT;


        -- -------------------------------------------------------------------------
        -- Table 6: silver.erp_px_cat_g1v1
        -- -------------------------------------------------------------------------
        SET @StepStartTime = SYSDATETIME();
        PRINT '📥 Processing: silver.erp_px_cat_g1v1 (Extracting baseline product mapping hierarchy)...';

        INSERT INTO silver.erp_px_cat_g1v1 (id, cat, subcat, maintenance)
        SELECT id, cat, subcat, maintenance FROM bronze.erp_px_cat_g1v1;

        SET @StepEndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF(MILLISECOND, @StepStartTime, @StepEndTime);
        SET @Message = '✔️ SUCCESS: Loaded [silver.erp_px_cat_g1v1]. Time taken: ' + CAST(@DurationMs AS NVARCHAR) + ' ms.' + CHAR(10);
        RAISERROR(@Message, 0, 1) WITH NOWAIT;


        -- =========================================================================
        -- GLOBAL METRICS SUMMARY REPORT
        -- =========================================================================
        DECLARE @GlobalEndTime DATETIME2 = SYSDATETIME();
        DECLARE @TotalDurationMs INT = DATEDIFF(MILLISECOND, @GlobalStartTime, @GlobalEndTime);

        PRINT '=========================================================================';
        PRINT ' 🎉 SILVER LAYER REFRESH SUCCESSFUL!';
        PRINT ' 🏁 End Time:    ' + CONVERT(NVARCHAR, @GlobalEndTime, 121);
        PRINT ' ⏱️ Total Time:  ' + CAST(@TotalDurationMs AS NVARCHAR) + ' ms (' + CAST(CAST(@TotalDurationMs / 1000.0 AS DECIMAL(10,2)) AS NVARCHAR) + ' seconds)';
        PRINT '=========================================================================';

    END TRY
    BEGIN CATCH
        -- Structured Error Capture Block
        PRINT '=========================================================================';
        PRINT ' ❌ EXECUTION FAILURE DETECTED INSIDE PIPELINE PROCESS!';
        PRINT ' 🚨 Error Number:    ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT ' 🚨 Error Severity:  ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
        PRINT ' 🚨 Error State:     ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT ' 🚨 Error Procedure: ' + COALESCE(ERROR_PROCEDURE(), 'Ad-Hoc Script');
        PRINT ' 🚨 Error Line:      ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT ' 🚨 Error Message:   ' + ERROR_MESSAGE();
        PRINT '=========================================================================';
        
        -- Escalate the exception up to the executing application or orchestrator
        THROW;
    END CATCH
END;
GO
