# 📋 Data Warehouse Naming Conventions & Best Practices

## 1. Overview
This document establishes the official naming conventions and architectural standards for the `Data_Ware_House` platform. Consistent naming structures guarantee that database objects are easily searchable, self-documenting, and seamlessly integrated across our Silver and Gold analytical layers.

---

## 🏛️ 2. Schema Architecture

We enforce a strict physical separation of data tiers using database schemas. Schema names must always be written in **lowercase**.

| Schema Name | Tier / Layer | Purpose | Access Governance |
| :--- | :--- | :--- | :--- |
| `silver` | Cleanse & Standardize | Contains cleaned, deduplicated, and deduplicated tables mirrored from source applications (CRM, ERP, POS). | Read/Write: ETL Service Accounts<br>Read-Only: Data Engineers |
| `gold` | Presentation (Star Schema) | Stores user-facing, optimized dimensional models (Facts and Dimensions) engineered for high-performance BI tool consumption. | Read/Write: ETL Service Accounts<br>Read-Only: Analysts / Power Users |

---

## 📊 3. Database Objects (Tables & Views)

Object names must be **lowercase**, utilize **snake_case** for word separation, and contain descriptive prefixes to clearly signify their architectural purpose.

### 👥 Dimension Views (`gold.dim_*`)
Dimensions describe business entities. They must always begin with the `dim_` prefix and use singular nouns representing the target grains.
* *Good Patterns:* `dim_customer_info`, `dim_product_info`, `dim_store_location`
* *Bad Patterns:* `DimCustomer`, `dim_customers`, `tbl_product`

### 💰 Fact Views (`gold.fact_*`)
Facts represent numerical, transactional events or business measurements. They must always begin with the `fact_` prefix and use plural nouns describing the core event type.
* *Good Patterns:* `fact_sales`, `fact_inventory_snapshots`, `fact_orders`
* *Bad Patterns:* `fact_sale`, `SalesFact`, `fact_crm_data`

---

## 🔑 4. Column & Field Naming Rules

To maintain an intuitive semantic layer for business intelligence tracking, all field names must be strictly written in **lowercase** and utilize **snake_case**.

### 🛠️ Key Identifiers
* **Surrogate Keys (`*_key`):** System-generated sequential integers utilizing the `ROW_NUMBER()` window function in the Gold layer. Must always end in `_key`.
    * *Examples:* `customer_key`, `product_key`
* **Natural / Operational Keys (`*_id`):** The primary production key pulled directly from the source system. Must always end in `_id`.
    * *Examples:* `customer_id`, `product_id`, `category_id`
* **Business Tokens (`*_number`):** Alphanumeric string codes visible to end-users in operational platforms. Must always end in `_number`.
    * *Examples:* `customer_number`, `product_number`, `sales_order_number`

### 📅 Temporal & Date Fields
* **True Dates (`*_date`):** Standard `DATE` types indicating a specific calendar day. Must end in `_date`.
    * *Examples:* `order_date`, `ship_date`, `due_date`, `product_start_date`
* **Timestamps (`*_datetime` / `*_timestamp`):** Continuous historical execution points containing hours, minutes, and seconds.
    * *Examples:* `customer_create_date`, `dw_inserted_timestamp`

### 📈 Metrics & Measurements
Numeric measurement columns must clearly reflect their unit of scale within the label:
* **Currency Amounts:** End in `_amount` (e.g., `sales_amount`, `discount_amount`).
* **Physical Quantities:** Named `quantity` or prefixed with `qty_`.
* **Unit Rates:** End in `_price` or `_cost` (e.g., `unit_price`, `product_cost`).

---

## 💻 5. T-SQL Scripting & Variable Standarization

When writing database scripts, stored procedures, or automation blocks, follow these syntax layouts:

### 🔠 SQL Keywords & Command Structures
All native SQL keywords, control structures, and system definitions must be formatted in **UPPERCASE** to differentiate code logic from schema definitions:
```sql
-- Standardized Query Pattern
CREATE OR ALTER VIEW gold.dim_product_info AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY product_info.prd_start_dt) AS product_key,
    product_info.prd_id AS product_id
FROM silver.crm_prd_info AS product_info
WHERE product_info.prd_end_dt IS NULL;
