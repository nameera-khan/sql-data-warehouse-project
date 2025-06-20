--EXEC silver.load_silver
/*
Script Purpose: LOAD SILVER LAYER WITH TRANSFORMATIONS INTO THE DATABASE
Notes: Run this file after loading the bronze layer.
- In MacOS using azure data studio, you must download an extension and upload the dataset into the server manually. 
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
BEGIN TRANSACTION; 

SELECT 
cst_id,
cst_key,
cst_firstname,
cst_lastname,
CASE WHEN UPPER(LTRIM(RTRIM(cst_marital_status))) = 'S' THEN 'Single'
     WHEN UPPER(LTRIM(RTRIM(cst_marital_status))) = 'M' THEN 'Married'
     ELSE 'n/a'
END AS cst_marital_status,
CASE WHEN UPPER(LTRIM(RTRIM(cst_gndr))) = 'F' THEN 'Female'
     WHEN UPPER(LTRIM(RTRIM(cst_gndr))) = 'M' THEN 'Male'
     ELSE 'n/a'
END AS cst_gndr,
cst_create_date
INTO silver.temp_transformed_cust
FROM (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
-- flag_last denotes the most recent value in the duplicates partitioned by cst_id
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
)t WHERE flag_last = 1;

PRINT '>>TRUNCATING TABLE silver.crm_cust_info'
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>>INSERTING DATA INTO silver.crm_cust_info'
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT 
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
FROM silver.temp_transformed_cust
DROP TABLE silver.temp_transformed_cust;

COMMIT TRANSACTION;
-- insert the above into silver table 
IF OBJECT_ID('silver.crm_prod_info','U') IS NOT NULL
    DROP TABLE silver.crm_prod_info
CREATE TABLE [silver].[crm_prod_info] (
    [prd_id]          SMALLINT      NULL,
    [cat_id]          NVARCHAR (50) NULL,
    [prd_key]         NVARCHAR (50) NULL,
    [prd_nm]          NVARCHAR (50) NULL,
    [prd_cost]        SMALLINT      NULL,
    [prd_line]        NVARCHAR (50) NULL,
    [prd_start_dt]    DATE          NULL,
    [prd_end_dt]      DATE          NULL,
    [dwh_create_date] DATETIME2 (7) CONSTRAINT [DF_crm_prod_info_dwh_create_date] DEFAULT (CONVERT([datetime2],getdate())) NOT NULL
);
BEGIN TRANSACTION;

-- Step 1: Create transformed data in temp table
SELECT 
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-','_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    prd_start_dt,
    DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
INTO silver.temp_transformed_prod
FROM bronze.crm_prod_info;

PRINT '>>TRUNCATING TABLE silver.crm_prod_info'
TRUNCATE TABLE silver.crm_prod_info;
PRINT '>>INSERTING DATA INTO silver.crm_prod_info'
-- Step 2: Clear target table

-- Step 3: Insert transformed data
INSERT INTO silver.crm_prod_info(
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT 
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM silver.temp_transformed_prod
WHERE prd_end_dt IS NOT NULL OR 
      prd_id IN (
          SELECT prd_id 
          FROM silver.temp_transformed_prod t1
          WHERE prd_end_dt IS NULL AND
                NOT EXISTS (
                    SELECT 1 
                    FROM silver.temp_transformed_prod t2
                    WHERE t2.prd_key = t1.prd_key AND
                          t2.prd_start_dt > t1.prd_start_dt
                )
      );

-- Step 4: Clean up
DROP TABLE silver.temp_transformed_prod;

COMMIT TRANSACTION;

--try to delete the silver table and create a new one with new data type for the dates 
IF OBJECT_ID('silver.crm_sales_details','U') IS NOT NULL
    DROP TABLE silver.crm_sales_details
CREATE TABLE [silver].[crm_sales_details] (
    [sls_ord_num]     NVARCHAR (50) NULL,
    [sls_prd_key]     NVARCHAR (50) NULL,
    [sls_cust_id]     INT           NULL,
    [sls_order_dt]    DATE          NULL,
    [sls_ship_dt]     DATE          NULL,
    [sls_due_dt]      DATE          NULL,
    [sls_sales]       INT           NULL,
    [sls_quantity]    INT           NULL,
    [sls_price]       INT           NULL,
    [dwh_create_date] DATETIME2 (7) CONSTRAINT [DF_crm_sales_details_dwh_create_date] DEFAULT (CONVERT([datetime2],getdate())) NOT NULL
);
-- Sales table transformation 
BEGIN TRANSACTION;

-- Transform and clean data into temporary table
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
         ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE) 
    END AS sls_order_dt,
    CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
         ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE) 
    END AS sls_ship_dt,
    CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
         ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE) 
    END AS sls_due_dt,
    CASE WHEN sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
         ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
         ELSE sls_price
    END AS sls_price
INTO silver.temp_transformed_sales
FROM bronze.crm_sales_details;

PRINT '>> TRUNCATING TABLE silver.crm_sales_details'
TRUNCATE TABLE silver.crm_sales_details;
PRINT '>>INSERTING INTO silver.crm_sales_details'


-- Insert transformed data into target table
INSERT INTO silver.crm_sales_details (
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
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity, 
    sls_price
FROM silver.temp_transformed_sales;
DROP TABLE silver.temp_transformed_sales;

COMMIT TRANSACTION;

-- Transform ERP tables 
BEGIN TRANSACTION; 


SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- position 4 and dynamic length 
    ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
     WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
     ELSE 'n/a'
END AS gen
INTO silver.temp_erp_az12
FROM bronze.erp_cust_az12;

PRINT '>>TRUNCATING TABLE silver.erp_cust_az12'
TRUNCATE TABLE silver.erp_cust_az12;
PRINT '>>INSERTING INTO TABLE silver.erp_cust_az12'
INSERT INTO silver.erp_cust_az12 
(
    cid,
    bdate,
    gen
)
SELECT

cid,
bdate,
gen
FROM silver.temp_erp_az12

DROP TABLE silver.temp_erp_az12;

COMMIT TRANSACTION;



--transforming location
BEGIN TRANSACTION;

SELECT 
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
     WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
     WHEN TRIM(cntry) = '' or cntry IS NULL THEN 'n/a'
     ELSE TRIM(cntry)
END AS cntry
INTO silver.temp_loc_a101
FROM bronze.erp_loc_a101 

PRINT '>> TRUNCATING TABLE silver.erp_loc_a101'
TRUNCATE TABLE silver.erp_loc_a101
PRINT '>>inserting TABLE silver.erp_loc_a101'

INSERT INTO silver.erp_loc_a101
(
cid,
cntry
)
SELECT 
cid,
cntry

FROM silver.temp_loc_a101
DROP TABLE silver.temp_loc_a101;

COMMIT TRANSACTION;


-- 

BEGIN TRANSACTION;
PRINT '>>TRUNCATING TABLE silver.erp_px_cat_g1v2'
TRUNCATE TABLE silver.erp_px_cat_g1v2
PRINT '>>INSERTING INTO TABLE silver.erp_px_cat_g1v2'

INSERT INTO silver.erp_px_cat_g1v2
(
    id,
    cat,
    subcat,
    maintenance
)
SELECT 

    id,  
    cat,
    subcat,
    maintenance

FROM  bronze.erp_px_cat_g1v2

COMMIT TRANSACTION;

END
