/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' layer after loading data from 'bronze' layer.
    It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

USE DataWarehouse;

-- ====================================================================
-- 1. Checking 'silver.crm_cust_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT cst_id, COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 
    OR cst_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results

SELECT * 
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT * 
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT * 
FROM silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT * 
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

-- Data Standardization & Consistency
-- Expectation: Expected values should be standardized, for example: Male, Female, n/a

SELECT cst_gndr 
FROM silver.crm_cust_info
GROUP BY cst_gndr;

SELECT cst_marital_status 
FROM silver.crm_cust_info
GROUP BY cst_marital_status;

-- Check for Invalid Dates
-- Expectation: No Results
SELECT *
FROM silver.crm_cust_info
WHERE cst_create_date IS NULL
   OR cst_create_date > GETDATE()
   OR cst_create_date < '1900-01-01';

-- ====================================================================
-- 2. Checking 'silver.crm_prd_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
select prd_id, count(*)
from silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null;

-- Check for Unwanted Spaces. Tips: Use trim() function to remove leading and trailing spaces.
-- Expectation: No Results
select * from silver.crm_prd_info
where prd_nm != trim(prd_nm);

-- Check for Null and negative values in 'prd_cost'
-- Expectation: No Results
select prd_cost from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null;

-- Check Data Standardization & Consistency for abbreviations in 'prd_line'
-- Expectation: 'Mountain', 'Other Sales', 'Road', 'Touring', 'n/a'
select distinct prd_line from silver.crm_prd_info;

-- Check for invalid dates orders in 'prd_start_dt' and 'prd_end_dt'
-- Expectation: No Results
select * from silver.crm_prd_info where prd_start_dt > prd_end_dt;


-- ====================================================================
-- 3. Checking 'silver.crm_sales_details'
-- ====================================================================

-- Check for unwanted spaces in 'sls_ord_num'
-- Expectation: No Results
SELECT sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Check for unwanted spaces in 'sls_prd_key'
-- Expectation: No Results
SELECT sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key);

-- Check if the product key exists in silver.crm_prd_info
-- Expectation: No Results
SELECT sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (
    SELECT prd_key_id
    FROM silver.crm_prd_info
    WHERE prd_key_id IS NOT NULL
);

-- Check if the customer key exists in silver.crm_cust_info
-- Expectation: No Results
SELECT sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
    SELECT cst_id
    FROM silver.crm_cust_info
    WHERE cst_id IS NOT NULL
);

-- Check if order date is later than ship date or due date
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Check data consistency between sales, quantity and price
-- Sales = Quantity * Price
-- Values must not be NULL, zero, or negative.
-- Expectation: No Results
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================
-- Identify Out-of-Range Dates
-- Expectation: Birthdates between 1924-01-01 and Today
select distinct bdate from silver.erp_cust_az12 where bdate < '1924-01-01' and bdate > getdate();

-- Data Standardization & Consistency
select distinct gen from silver.erp_cust_az12;

select * from silver.erp_cust_az12;


-- ====================================================================
-- 5. Checking 'silver.erp_loc_a101'
-- ====================================================================

-- Check the data standardization of 'cid' column compare to 'cid' column in 'silver.crm_cust_info'.
-- Expectation: No results
select cid from silver.erp_loc_a101
where cid not in (select cst_key from silver.crm_cust_info);

-- Check the abbreviations, missing data, and invalid dates in 'cntry' column.
select distinct cntry from silver.erp_loc_a101
order by cntry;


-- ====================================================================
-- 6. Checking 'silver.erp_px_cat_g1v2'
-- ====================================================================

-- Check the data standardization of 'id' column compare to 'id' column in 'silver.crm_prd_info'.
select id from silver.erp_px_cat_g1v2
where id not in (select cat_id from silver.crm_prd_info);

-- Check the abbreviations, missing data, and invalid dates in 'cat' column.
select distinct cat from silver.erp_px_cat_g1v2
order by cat;

select distinct subcat from silver.erp_px_cat_g1v2
order by subcat;

select distinct maintenance from silver.erp_px_cat_g1v2
order by maintenance;

-- Check unwanted spaces.
select * from silver.erp_px_cat_g1v2
where cat != trim(cat) or subcat != trim(subcat) or maintenance != trim(maintenance);
