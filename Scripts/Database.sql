/********************************************************************************
-- PROJECT: Data Warehouse Infrastructure (Medallion Architecture)
-- CREATED: May 2026
-- OBJECTIVE: 
    This script initializes the 'Data_Ware_House' database using a 
    Medallion Architecture (Bronze, Silver, Gold). 
-- ARCHITECTURE OVERVIEW:
    - BRONZE: Raw data ingestion. Minimal transformation.
    - SILVER: Cleansed, filtered, and augmented data.
    - GOLD: Business-level aggregates and reporting-ready tables.
********************************************************************************/

USE master;
GO

-- Check if the database already exists. 
-- If it does, drop it to ensure a clean slate for development.
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'Data_Ware_House')
BEGIN
    ALTER DATABASE Data_Ware_House SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Data_Ware_House;
END
GO

-- Initialize the core database container
CREATE DATABASE Data_Ware_House;
GO

USE Data_Ware_House;
GO

/* 
   SCHEMAS CONFIGURATION 
   We use schemas to logically separate the data processing layers.
*/

-- 1. Bronze Layer: Used for landing raw data directly from source systems.
CREATE SCHEMA bronze;
GO

-- 2. Silver Layer: Used for validated, deduplicated, and standardized data.
CREATE SCHEMA silver;
GO

-- 3. Gold Layer: Highly refined data optimized for analytics and BI dashboards.
CREATE SCHEMA gold;
GO
