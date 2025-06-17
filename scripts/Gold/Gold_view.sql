
--Data integration for 2 gender columns 
SELECT 
    
    ci.cst_gndr,
    ca.gen,
   CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is master for gender info
        ELSE COALESCE(ca.gen, 'n/a')
   END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca 
ON          ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la 
ON          ci.cst_key = la.cid
ORDER BY 1,2
--if THERE ARE NULLS IN THIS VIEW, IT IS DUE TO JOINING 2 TABLES WHERE THE INFORMATION MAY NOT BE PRESENT IN EITHER 
/*If there is a mismatch in data, for example ; if the column from crm table has a female and the column from erp has male, we must ask the source system experts to clarify what is the master table. 
Since most customer information is stored in crm, the data on the crm column is much more accurate*/

SELECT prd_key, COUNT(*) FROM ( -- THIS SELECT STATEMENT IS TO CHECK FOR DUPLICATES 
SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt,
pc.cat,
pc.subcat,
pc.maintenance 
FROM silver.crm_prod_info pn -- Choose only current data and not history
LEFT JOIN silver.erp_px_cat_g1v2 pc -- Join with erp_px_cat 
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL -- Filters out all historical data 
)t GROUP BY prd_key
HAVING COUNT(*) > 1

CREATE VIEW gold.dim_products AS
SELECT 
ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pn.prd_cost AS product_cost,
pn.prd_line AS product_line,
pn.cat_id AS category_id,
pc.cat AS category,
pc.subcat AS sub_category,
pc.maintenance AS maintenance,
pn.prd_start_dt AS start_date,
pn.prd_end_dt AS end_date
FROM silver.crm_prod_info pn -- Choose only current data and not history
LEFT JOIN silver.erp_px_cat_g1v2 pc -- Join with erp_px_cat 
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL

CREATE VIEW gold.fact_sales AS
--  Sales Fact table
SELECT 
sd.sls_ord_num AS order_number,
pr.product_number,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS sales_quantity,
sd.sls_price AS sales_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr 
ON sd.sls_prd_key = pr.product_number 
LEFT JOIN gold.dim_customers cu 
ON sd.sls_cust_id = cu.customer_id

