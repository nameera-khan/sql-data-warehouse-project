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
