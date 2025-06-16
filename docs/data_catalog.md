# Data Catalog for Gold Layer 

## Overview 

The Gold Layer exhibits the business level view of the data after preprocessing. It consists of dimension tables and fact tables. 
---------------------------------------
## 1. gold.dim_customers 
- **Purpose**: Stores customer details enriched with demographics and geographic data
- **Columns**:

| Column Name       | Data Type |                   Description                            |
| :----------       | :-------: | ------------------------------------------------:        |
| customer_key      | INT       | Surrogate key that identifies each customer in dimensions|
|customer_id        | INT       | Unique numerical identifier assigned to each customer| 
| first_name        | NVARCHAR  | Alphanumeric identifier representing the customer, used for tracking and referencing |
|last_name          | NVARCHAR  | The customer's last name as recorded         |
|country            | NVARCHAR  | The country of residence of the customer |
|marital_status     | NVARCHAR | The marital status of the customer  |
|gender         | NVARCHAR | The gender of the customer |
|birthdate |DATE | The date of birth of the customer, formatted as YYYY-MM-DD |
|create_date | DATE | The date and time when the customer record was created in the system |

## 2. gold.dim_products
• **Purpose**: Provides information about products and their attributes 
• Columns: 
| Column_Name | Data Type | Description |
|:------------|:---------:|------------:|
|product_key | INT | Surrogate key uniquely identifying each product in the dimension table |
|product_id | INT | Uniqur identifier of the product for internal tracking|
|product_number| NVARCHAR | Structured alphanumeric representation of the product, used for catogorisation in inventory|
|product_name| NVARCHAR | Descriptive name of th product |
|category_id |NVARCHAR| Unique product category identification |
|category | NVARCHAR | Broader classification of the product |
|subcategory | NVARCHAR | More detailed classification of product within the category such as product type |
|maintenance_required | NVARCHAR | Indicates if the product requires maintenance |
|cost | INT | Base price of the product |
|product_line| NVARCHAR |The specific product line or series to which the product belongs |
|start_date | DATE | The date when the product was made available to use |



