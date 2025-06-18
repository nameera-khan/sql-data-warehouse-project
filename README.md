
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
data-warehouse-project/
│
├── datasets/                           # Raw CRM and ERP datasets
│
├── docs/                               # Project documentation and architecture details
│   ├── IntegrationModel.svg                      # Draw.io that shows the integration model between CRM and ERP table and data flow diagram
│   ├── data_catalog.md                 # Catalog of datasets and gold layer variables to view for business insights
│
├── scripts/                            # SQL scripts for ETL and transformations
│   ├── bronze/                         # Scripts for extracting and loading raw data with steps for data upload using Azure Data studio SQL extension
│   ├── silver/                         # Scripts for cleaning and transforming data
│   ├── gold/                           # Scripts for creating analytical models
│
├── tests/                              # Test scripts and quality files
│   |-- Quality_checks/              
├── README.md                           # Project overview and instructions
├── LICENSE                             # License information for the repository
├── .gitignore                          # Files and directories to be ignored by Git
            
## License 
This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution. 

