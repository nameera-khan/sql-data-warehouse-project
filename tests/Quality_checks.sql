-- To identify quality issues -- 
SELECT 
prd_id,
COUNT(*)
FROM silver.crm_prod_info
GROUP BY prd_id 
HAVING COUNT(*) > 1 OR prd_id IS NULL -- because we are interested in values where the count > 1 -- 
-- The result shows that there are IDs that have duplicates-- 

-- Checking one of the cst_id 
SELECT * FROM silver.crm_cust_info
WHERE cst_id = 29466;

SELECT *, 
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last -- Use the date that is the most recent 
FROM silver.crm_cust_info
WHERE cst_id = 29466

-- For the whole crm_cust_info table
DROP TABLE silver.crm_cust_info_temp
SELECT *
INTO silver.crm_cust_info_temp
FROM (
    SELECT *, 
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last -- Use the date that is the most recent 
    FROM silver.crm_cust_info
)t WHERE flag_last = 1 -- Using 1 only generates rows that are unique

DROP TABLE silver.crm_cust_info

EXEC sp_rename 'silver.crm_cust_info_temp', 'crm_cust_info';

-- To identify quality issues -- 
SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1 OR cst_id IS NULL

SELECT COUNT(*) FROM silver.crm_cust_info

-- 
SELECT *
INTO silver.crm_cust_info_temp
FROM (
    SELECT *, 
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last -- Use the date that is the most recent 
    FROM bronze.crm_cust_info
)t WHERE flag_last = 1 

DROP TABLE silver.crm_cust_info 

EXEC sp_rename 'silver.crm_cust_info_temp','crm_cust_info'

SELECT * FROM silver.crm_cust_info

SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS row_num
    FROM silver.crm_cust_info
)t 
-- WHERE flag_last = 1;

-- Expectation: No Results 
SELECT prd_nm
FROM bronze.crm_prod_info
WHERE prd_nm != TRIM(prd_nm) -- There are no transformations needed 

-- Check for NULLS or negative numbers. Expectations: No results
SELECT prd_cost
FROM bronze.crm_prod_info
WHERE prd_cost < 0 OR prd_cost IS NULL 

--Data standardisation & consistency 
SELECT DISTINCT prd_line
FROM silver.crm_prod_info

-- Check for Invalid Data Orders
SELECT * 
FROM silver.crm_prod_info
WHERE prd_end_dt < prd_start_dt --the result shows that the start dates are newer than the end dates. 
-- the transformation should be such that the end date and the start date of a product number must not overlap. 
-- In this case, the start date of the product can be the end date of the previous serial number - 1 
-- Prd_start and end_date
SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt_test
FROM bronze.crm_prod_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509');

--check the transformation with new column in silver.crm_prd_info
SELECT * FROM silver.crm_prod_info


-- Sales table quality check 
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
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info) -- the result is as expected - there are no sls_cust_id that do not exist in customer crm table 

--
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
FROM silver.crm_sales_details

--the dates are in integer form, thus needs to be converted to DATE. check for invalid dates
SELECT 
NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details 
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 OR  sls_order_dt > 20500101 

SELECT 
NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details 
WHERE sls_order_dt > 20500101

SELECT 
NULLIF(sls_ship_dt,0) sls_ship_dt
FROM bronze.crm_sales_details 
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8 
OR  sls_ship_dt > 20500101 
OR sls_ship_dt < 19000101

-- check for invalid sales date orders 
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt

-- Check sales quantity consistency 
-- Business rule: Sales = Quantity * Price
-- Values must not be null, zero, or negative

SELECT DISTINCT
sls_sales, 
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity IS NULL OR sls_price IS NULL
ORDER BY sls_sales,sls_quantity,sls_price 
-- Solution 1: the result has bad data quality in sls_sales and sls_price. This issue can only be resolved by
-- consulting the data production team regarding the source system since the data issue has occurred at its conception

-- Rules for the above: if the sales is neg, 0 or null, it can be derived using quantity and price
-- If price is 0, null, calculate the sales and quantity 
-- If price is neg, convert it to a pos value
SELECT DISTINCT
sls_quantity,
sls_sales,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity IS NULL OR sls_price IS NULL
ORDER BY sls_sales,sls_quantity,sls_price 

-- CHECK FOR INVALID DATES AFTER TRANSFORMATION 
SELECT 
* FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

SELECT * FROM silver.crm_sales_details


-- Identify Out of range dates in erp 
SELECT DISTINCT 
bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()


-- Date standardisation for gender
SELECT DISTINCT
gen
FROM silver.erp_cust_az12

--
SELECT DISTINCT
cntry AS old_cntry,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
     WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
     WHEN TRIM(cntry) = '' or cntry IS NULL THEN 'n/a'
     ELSE TRIM(cntry)
END AS cntry
FROM silver.erp_loc_a101 
ORDER BY cntry

--checking unwant
SELECT 
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2

-- check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat!= TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- data standardisation & consistency 
SELECT DISTINCT 
maintenance FROM silver.erp_px_cat_g1v2

