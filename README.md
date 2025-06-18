
# sql-data-warehouse-project

![DWH](https://github.com/user-attachments/assets/9caf7920-a4b0-4fe9-9f3e-d59fe1a1c01f)


A modern data warehouse with SQL server which includes ETL processes, data modelling and analytics

This is a repository for the **Data Warehouse and Analytics Project** !
This project's objective is to demonstrate data warehousing and analytical solutions; includes building a data warehouse to generating actionable insights. This is a portfolio project for data engineering endeavours and analysis of the data stored in the warehouse. 

The requirements for the project are as listed below: 

### Objective 
To develop a data warehouse using SQL server to combine sales data, consequently enabling analytical ad-hoc reporting and informed decision making. 

### Specification 
- **Data Sources** : Import the data from the source system that are available as CSV files 
- **Data Quality** : Cleanse and transform the data suitable for business analysis
- **Integration** : Combine the 2 source files into a single, user-friendly data model designed for analytical queries. 
- **Scope** : Focus on the latest dataset only and not include historisation in the warehouse.
- **Documentation** : Provide clear documentation of the data model to support business stakeholders and technical teams.

---
### BI Analytics & Reporting 
Develop SQL based analytics to create ad-hoc reports for the following:
- Customer behaviour
- Product Performance
- Sales Trends

These insights are helpful in empowering stakeholders with key business metrics. 
---
### Star Schema 
![Sales schema](https://github.com/user-attachments/assets/27ed84aa-e3ff-48d8-b6be-c77460da43e4)

## Repository structure 

```plaintext
data-warehouse-project/
├── datasets/                # Raw CRM and ERP datasets
├── docs/                    # Project documentation
│   ├── IntegrationModel.svg # Draw.io diagram
│   └── data_catalog.md      # Dataset catalog
├── scripts/                 # SQL ETL scripts
│   ├── bronze/              # Raw data extraction
│   ├── silver/              # Data cleaning
│   └── gold/                # Analytical models
├── tests/                   # Test scripts
├── README.md                # Project overview
├── LICENSE                  # MIT License
└── .gitignore              # Git ignore rules
''' 

## License 
This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution. 

