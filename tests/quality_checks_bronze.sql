/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'bronze' layer, before cleansing, and after that loading. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.
===============================================================================
*/

-- ====================================================================
-- 1. Checking 'bronze.crm_cust_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
use datawarehouse

select cst_id, count(*) from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;

select * from bronze.crm_cust_info
where cst_id = 29466; -- Look closer at this duplicate record (customer).

-- Check for Unwanted Spaces. Tips: Use trim() function to remove leading and trailing spaces.

select * from bronze.crm_cust_info
where cst_firstname != trim(cst_firstname); -- Spaces in 'cst_firstname'

select * from bronze.crm_cust_info
where cst_lastname != trim(cst_lastname); -- Spaces in 'cst_lastname'

select * from bronze.crm_cust_info
where cst_marital_status != trim(cst_marital_status);

select * from bronze.crm_cust_info
where cst_gndr != trim(cst_gndr);

-- Data Standardization & Consistency. In DWH we aim to use clear and meaningful data instead of abbreviations.
-- For example, 'M' for 'Male'. Tips: Use CASE WHEN statements to replace abbreviations.
select cst_gndr from bronze.crm_cust_info
group by cst_gndr;

select cst_marital_status from bronze.crm_cust_info
group by cst_marital_status;

-- Check for Invalid Dates
SELECT *
FROM bronze.crm_cust_info
WHERE cst_create_date IS NULL
   OR cst_create_date > GETDATE()
   OR cst_create_date < '1900-01-01';


-- ====================================================================
-- 2. Checking 'bronze.crm_prd_info'
-- ====================================================================

select * from bronze.crm_prd_info
select * from bronze.crm_prd_info
select * from bronze.crm_sales_details

-- Check for NULLs or Duplicates in Primary Key
select prd_id, count(*)
from bronze.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null;

-- Check prd_key. We have problems hier. For example: AC-BR-RA-H123 and AC_BR nicht uebereinstimmen.
-- Sothat we need to break the long prd_key into smaller parts, and replace the - with _

-- Check for Unwanted Spaces. Tips: Use trim() function to remove leading and trailing spaces.
select * from bronze.crm_prd_info
where prd_nm != trim(prd_nm);


-- Check for Null and negative values in 'prd_cost'
select prd_cost from bronze.crm_prd_info
where prd_cost < 0 or prd_cost is null;

-- Check for abbreviations in 'prd_line'
select distinct prd_line from bronze.crm_prd_info;

-- Check for invalid dates orders in 'prd_start_dt' and 'prd_end_dt'
select * from bronze.crm_prd_info
where prd_start_dt > prd_end_dt;


-- ====================================================================
-- 3. Checking 'bronze.crm_sales_details'
-- ====================================================================

select * from bronze.crm_sales_details

-- Check for unwanted spaces in 'sls_ord_num'
select sls_ord_num from bronze.crm_sales_details
where sls_ord_num != trim(sls_ord_num);

-- Check for unwanted spaces in 'sls_prd_key'
select sls_prd_key from bronze.crm_sales_details
where sls_prd_key != trim(sls_prd_key);

-- Check if the 2 keys connecting 2 tables have the same format
select sls_prd_key from bronze.crm_sales_details
where sls_prd_key not in (select prd_key_id from silver.crm_prd_info);

-- Check if the 2 keys connecting 2 tables have the same format
select sls_cust_id from bronze.crm_sales_details
where sls_cust_id not in (select cst_id from bronze.crm_cust_info);

-- Check for invalid dates orders in 'sls_order_dt'
select nullif(sls_order_dt, 0) as sls_order_dt from bronze.crm_sales_details
where
sls_order_dt <= 0
or len(crm_sales_details.sls_order_dt) != 8
or sls_order_dt > 20500101 or sls_order_dt < 19000101;

-- Check for invalid dates orders in 'sls_ship_dt'
select nullif(sls_ship_dt, 0) as sls_ship_dt from bronze.crm_sales_details
where
sls_ship_dt <= 0
or len(crm_sales_details.sls_ship_dt) != 8
or sls_ship_dt > 20500101 or sls_ship_dt < 19000101;

-- Check for invalid dates orders in 'sls_due_dt'
select nullif(sls_due_dt, 0) as sls_due_dt from bronze.crm_sales_details
where
sls_due_dt <= 0
or len(crm_sales_details.sls_due_dt) != 8
or sls_due_dt > 20500101 or sls_due_dt < 19000101;

-- Check if order date bigger than ship date and due date
select sls_order_dt from bronze.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt;

-- Check data consistency between sales, quantity and price
-- Sales = Quantity * Price
-- Values must not be Null, Zero, or Negative.
select distinct sls_sales, sls_quantity, sls_price from bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
order by sls_sales, sls_quantity, sls_price;


-- ====================================================================
-- 4. Checking 'bronze.erp_cust_az12'
-- ====================================================================

-- Identify invalid dates in 'bdate' column.
SELECT *
FROM bronze.erp_cust_az12
WHERE bdate IS NULL
   OR bdate > GETDATE()
   OR bdate < '1900-01-01';

-- Data Standardization & Consistency. In DWH we aim to use clear and meaningful data instead of abbreviations.
-- For example, 'M' for 'Male'. Tips: Use CASE WHEN statements to replace abbreviations.
select distinct gen from bronze.erp_cust_az12;


-- ====================================================================
-- 5. Checking 'bronze.erp_loc_a101'
-- ====================================================================

-- Check the data standardization of 'cid' column compare to 'cid' column in 'silver.crm_cust_info'.
select cid from bronze.erp_loc_a101
where cid not in (select cst_key from silver.crm_cust_info);

-- Check the abbreviations, missing data, and invalid dates in 'cntry' column.
select distinct cntry from bronze.erp_loc_a101
order by cntry;


-- ====================================================================
-- 6. Checking 'bronze.erp_px_cat_g1v2'
-- ====================================================================

-- Check the data standardization of 'id' column compare to 'id' column in 'silver.crm_prd_info'.
select id from bronze.erp_px_cat_g1v2
where id not in (select cat_id from silver.crm_prd_info);

-- Check the abbreviations, missing data, and invalid dates in 'cat' column.
select distinct cat from bronze.erp_px_cat_g1v2
order by cat;

select distinct subcat from bronze.erp_px_cat_g1v2
order by subcat;

select distinct maintenance from bronze.erp_px_cat_g1v2
order by maintenance;

-- Check unwanted spaces.
select * from bronze.erp_px_cat_g1v2
where cat != trim(cat) or subcat != trim(subcat) or maintenance != trim(maintenance);


