/********************************************************************************
-- SCRIPT PURPOSE: 
    Initializes the 'Data_Ware_House' environment by establishing the 
    Medallion Architecture framework. This sets up the logical layers 
    (Bronze, Silver, Gold) required for a standard Data Engineering pipeline.

-- !!! WARNING - DESTRUCTIVE SCRIPT !!!:
    This script contains a 'DROP DATABASE' command. Running this will 
    PERMANENTLY DELETE all existing data, tables, and schemas within 
    'Data_Ware_House'. Use ONLY in development or when a full 
    environment reset is required.
********************************************************************************/

USE master;
GO

-- 1. DATABASE EXISTENCE CHECK & RESET
-- Logic: If the DB exists, we force-close all active connections and delete it.
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'Data_Ware_House')
BEGIN
    PRINT 'Warning: Data_Ware_House exists. Dropping existing database...';
    ALTER DATABASE Data_Ware_House SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Data_Ware_House;
END
ELSE
BEGIN
    PRINT 'Data_Ware_House does not exist. Proceeding with fresh creation...';
END
GO

-- 2. DATABASE CREATION
CREATE DATABASE Data_Ware_House;
GO

USE Data_Ware_House;
GO

-- 3. SCHEMA ORGANIZATION (Medallion Architecture)

-- BRONZE: The "Raw" zone. Data is kept in its original format. 
-- No transformations are applied here; it serves as a historical record.
CREATE SCHEMA bronze;
GO

-- SILVER: The "Cleaned" zone. Data is filtered, joined, and standardized. 
-- This is where we handle nulls, duplicates, and data type formatting.
CREATE SCHEMA silver;
GO

-- GOLD: The "Curated" zone. Data is modeled for the end-user. 
-- This layer contains aggregated Data Marts and tables ready for Power BI/Tableau.
CREATE SCHEMA gold;
GO

PRINT 'Data Warehouse setup complete. Schemas [bronze], [silver], and [gold] created successfully.';
