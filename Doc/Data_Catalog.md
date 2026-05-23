## 🌟 Gold Layer Overview

The **Gold Layer** represents the final, presentation-ready tier of your data warehouse. In this layer, cleansed staging data from the Silver layer is transformed into an optimized **Star Schema** dimensional model.

By separating data into descriptive columns (**Dimensions**) and numeric transaction files (**Facts**), this layout provides clean, high-performance reporting. Every object is created as an idempotent view (`CREATE OR ALTER`), integrating automated performance metrics and centralized runtime exception logs.

---

## 👥 1. View: `gold.dim_customer_info`

### Purpose
This dimension view centralizes all customer-related records. It consolidates foundational data from CRM systems with regional and demographic details from ERP systems to create a unified profile of each customer.

### Schema Definition

| Column Name | Data Type | Key Type / Constraints | Description & Examples |
| :--- | :--- | :--- | :--- |
| **customer_key** | `BIGINT` | **Surrogate Key** | Dynamically generated sequential integer used as the unique primary key for the Gold layer. Generated using `ROW_NUMBER() OVER (ORDER BY cust_info.cust_id)`. |
| **customer_id** | `INT` | **Natural Key** | The primary identifier inherited directly from the operational CRM system (`cust_info.cust_id`). |
| **customer_number** | `VARCHAR` | Unique | The unique cross-system string or business ID used to track the customer (`cust_info.cust_key`). |
| **first_name** | `VARCHAR` | Nullable | The customer's legal first name. |
| **last_name** | `VARCHAR` | Nullable | The customer's legal family or last name. |
| **customer_country** | `VARCHAR` | Nullable | The geographical country of residency retrieved from ERP infrastructure (`cust_loc.cntry`). |
| **customer_gender** | `VARCHAR` | Cleansed | Cleansed gender attribute. Utilizes CRM master data first; if missing or marked 'Unknown', it falls back to ERP records (`ex_info.gen`). |
| **marital_status** | `VARCHAR` | Nullable | The current recorded relationship status of the customer. |
| **customer_birthdate** | `DATE` | Temporal | The customer's date of birth sourced from ERP data extensions (`ex_info.bdate`). |
| **customer_create_date**| `DATE` | Temporal | The initial profile record creation timestamp recorded in the CRM source system. |

---

## 📦 2. View: `gold.dim_product_info`

### Purpose
This dimension view provides a unified registry of active inventory items, catalog items, and parts. It filters out retired items and joins product categories with operational maintenance tiers for clear business intelligence reporting.

### Schema Definition

| Column Name | Data Type | Key Type / Constraints | Description & Examples |
| :--- | :--- | :--- | :--- |
| **product_key** | `BIGINT` | **Surrogate Key** | Unique system-generated surrogate key for the product dimension. Generated using `ROW_NUMBER() OVER (ORDER BY product_info.prd_start_dt, product_info.prd_key)`. |
| **product_id** | `INT` | **Natural Key** | Operational item ID sourced from production CRM inventory modules (`product_info.prd_id`). |
| **product_number** | `VARCHAR` | Unique | The distinct alphanumeric business code or SKU identifying the product (`product_info.prd_key`). |
| **product_name** | `VARCHAR` | Not Null | The official market label or commercial name of the product line. |
| **category_id** | `VARCHAR` | Foreign Key | The operational grouping identifier linked to product taxonomies (`product_info.cat_id`). |
| **category_name** | `VARCHAR` | Nullable | High-level division classification for business cataloging (`category_info.cat`). |
| **subcategory_name** | `VARCHAR` | Nullable | Granular sub-grouping detailing specific item families (`category_info.subcat`). |
| **category_maintenance**| `VARCHAR` | Nullable | Strategic classification tag outlining service or maintenance tiers (`category_info.maintenance`). |
| **product_cost** | `NUMERIC` | Metric | The internal manufacturing or procurement cost baseline for business tracking. |
| **product_line** | `VARCHAR` | Nullable | The broader brand division or targeted manufacturing category. |
| **product_start_date** | `DATE` | Temporal | The active date when this item was introduced to the market catalog. Filtered to include active records only (`WHERE prd_end_dt IS NULL`). |

---

## 💰 3. View: `gold.fact_sales`

### Purpose
The central transactional hub of the star schema. This view stores business metrics, quantitative measurements, and transactional dates, mapping them back to the dimensional views using our newly established surrogate keys.

### Schema Definition

| Column Name | Data Type | Key Type / Constraints | Description & Examples |
| :--- | :--- | :--- | :--- |
| **sales_order_number** | `VARCHAR` | Origin Token | The operational invoice or receipt code mapping the row to an actual transaction event (`sd.sls_ord_num`). |
| **product_key** | `BIGINT` | **Foreign Key** | References `gold.dim_product_info.product_key` to identify what item was sold. Joined via product business codes. |
| **customer_key** | `BIGINT` | **Foreign Key** | References `gold.dim_customer_info.customer_key` to pinpoint who purchased the item. Joined via operational customer IDs. |
| **order_date** | `DATE` | Temporal | The calendar date when the transaction was completed by the client (`sd.sls_order_dt`). |
| **ship_date** | `DATE` | Temporal | The recorded calendar date when inventory left logistics warehouses (`sd.sls_ship_dt`). |
| **due_date** | `DATE` | Temporal | The target deadline date when customer invoice payments are officially expected (`sd.sls_due_dt`). |
| **sales_amount** | `NUMERIC` | Financial Metric | The final total gross currency value generated by this sales item row (`sd.sls_sales`). |
| **quantity** | `INT` | Quantity Metric | The total count of item units purchased within this transaction line (`sd.sls_quantity`). |
| **unit_price** | `NUMERIC` | Rate Metric | The standard market sales price listed for a single unit of the product (`sd.sls_price`). |
