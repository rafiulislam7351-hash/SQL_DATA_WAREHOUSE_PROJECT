## 🌟 Gold Layer Overview

The **Gold Layer** represents the final, presentation-ready tier of your data warehouse. In this layer, cleansed staging data from the Silver layer is transformed into an optimized **Star Schema** dimensional model.

By separating data into descriptive descriptive columns (**Dimensions**) and numeric transaction files (**Facts**), this layout provides clean, high-performance reporting. Every object is created as an idempotent view (`CREATE OR ALTER`), integrating automated performance metrics and centralized runtime exception logs.

---

## 👥 1. View: `gold.dim_customer_info`

### Purpose

This dimension view centralizes all customer-related records. It consolidates foundational data from CRM systems with regional and demographic details from ERP systems to create a unified profile of each customer.

| Column Name | Data Type | Description |
| --- | --- | --- |
| **customer_key** | `BIGINT` | **Surrogate Key:** A system-generated sequential integer used as the unique primary key for the Gold layer. <br>
<br>*Example: `1, 2, 3*` |
| **customer_id** | `INT` | **Natural Key:** The primary identifier inherited directly from the operational CRM system. <br>
<br>*Example: `10042*` |
| **customer_number** | `VARCHAR` | The unique cross-system string or business ID used to track the customer. <br>
<br>*Example: `CUST-AZ-992*` |
| **first_name** | `VARCHAR` | The customer's legal first name. <br>
<br>*Example: `"Rafiul"*` |
| **last_name** | `VARCHAR` | The customer's legal family or last name. <br>
<br>*Example: `"Islam"*` |
| **customer_country** | `VARCHAR` | The geographical country of residency retrieved from ERP infrastructure. <br>
<br>*Example: `"Bangladesh"*` |
| **customer_gender** | `VARCHAR` | Cleansed gender attribute. It utilizes CRM data first, falling back to ERP records if missing or marked "Unknown". <br>
<br>*Example: `"Male"*` |
| **marital_status** | `VARCHAR` | The current recorded relationship status of the customer. <br>
<br>*Example: `"Married"*` |
| **customer_birthdate** | `DATE` | The birth date of the customer compiled from auxiliary ERP files. <br>
<br>*Example: `2002-06-15*` |
| **customer_create_date** | `DATE` | The historical timestamp recording when the customer profile was first created. <br>
<br>*Example: `2025-01-10*` |

---

## 📦 2. View: `gold.dim_product_info`

### Purpose

This dimension view flattens operational product tables and nested category structures into a clean catalog dataset. It isolates current business offerings by actively filtering out legacy or deprecated items.

| Column Name | Data Type | Description |
| --- | --- | --- |
| **product_key** | `BIGINT` | **Surrogate Key:** A system-generated sequential integer sorted chronologically by the product introduction timeline. <br>

<br>*Example: `54, 55, 56*` |
| **product_id** | `INT` | The core internal identifier assigned to the item within source database inventories. <br>

<br>*Example: `301*` |
| **product_number** | `VARCHAR` | The distinct alphanumeric business code or SKU identifying the product. <br>

<br>*Example: `"PRD-BK-001"*` |
| **product_name** | `VARCHAR` | The commercial public name of the product line. <br>

<br>*Example: `"Gaming Laptop Pro"*` |
| **category_id** | `VARCHAR` | The operational grouping identifier linked to product taxonomies. <br>

<br>*Example: `"CAT-102"*` |
| **category_name** | `VARCHAR` | High-level division classification for business cataloging. <br>

<br>*Example: `"Electronics"*` |
| **subcategory_name** | `VARCHAR` | Granular sub-grouping detailing specific item families. <br>

<br>*Example: `"Computers & Laptops"*` |
| **category_maintenance** | `VARCHAR` | Strategic classification tag outlining service or maintenance tiers. <br>

<br>*Example: `"Standard-Support"*` |
| **product_cost** | `NUMERIC` | The internal manufacturing or procurement cost baseline for business tracking. <br>

<br>*Example: `850.00*` |
| **product_line** | `VARCHAR` | The broader brand division or targeted manufacturing category. <br>

<br>*Example: `"Premium-Hardware"*` |
| **product_start_date** | `DATE` | The active date when this item was introduced to the market catalog. <br>

<br>*Example: `2026-02-01*` |

---

## 💰 3. View: `gold.fact_sales`

### Purpose

The central transactional hub of the star schema. This view stores business metrics, quantitative measurements, and transactional dates, mapping them back to the dimensional views using our newly established surrogate keys.

| Column Name | Data Type | Description |
| --- | --- | --- |
| **sales_order_number** | `VARCHAR` | The operational invoice or receipt code mapping the row to an actual transaction event. <br>

<br>*Example: `"SO-77419"*` |
| **product_key** | `BIGINT` | **Foreign Key:** References `gold.dim_product_info.product_key` to identify what was sold. <br>

<br>*Example: `55*` |
| **customer_key** | `BIGINT` | **Foreign Key:** References `gold.dim_customer_info.customer_key` to pinpoint who purchased the item. <br>

<br>*Example: `2*` |
| **order_date** | `DATE` | The calendar date when the transaction was completed by the client. <br>

<br>*Example: `2026-05-20*` |
| **ship_date** | `DATE` | The recorded calendar date when inventory left logistics warehouses. <br>

<br>*Example: `2026-05-22*` |
| **due_date** | `DATE` | The target deadline date when customer invoice payments are officially expected. <br>

<br>*Example: `2026-06-20*` |
| **sales_amount** | `NUMERIC` | The final total gross currency value generated by this sales item row. <br>

<br>*Example: `1200.50*` |
| **quantity** | `INT` | The total count of item units purchased within this transaction line. <br>

<br>*Example: `2*` |
| **unit_price** | `NUMERIC` | The standard market sales price listed for a single unit of the product. <br>

<br>*Example: `600.25*` |
