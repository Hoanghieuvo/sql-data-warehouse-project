/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        -- ====================================================================
    -- 1. Cleansing bronze.crm_cust_info and Loading silver.crm_cust_info
    -- ====================================================================
    SET @start_time = GETDATE();
    truncate table silver.crm_cust_info;
    insert into silver.crm_cust_info(
                                     cst_id,
                                     cst_key,
                                     cst_firstname,
                                     cst_lastname,
                                     cst_marital_status,
                                     cst_gndr,
                                     cst_create_date)
    select cst_id,
           cst_key,
           trim(cst_firstname) as cst_firstname,
           trim(cst_lastname) as cst_lastname,
           case when upper(trim(cst_marital_status)) = 'M' then 'Married'
                when upper(trim(cst_marital_status))  = 'S' then 'Single'
                else 'n/a'
            end
            as cst_marital_status,

           case when upper(trim(cst_gndr)) = 'M' then 'Male'
                when upper(trim(cst_gndr))  = 'F' then 'Female'
                else 'n/a'
            end
           as cst_gndr,
           cst_create_date
    from
    (select * , row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
    from bronze.crm_cust_info) t
    where flag_last = 1 and cst_id is not null;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

    -- ====================================================================
    -- 2. Cleansing bronze.crm_prd_info and Loading silver.crm_prd_info
    -- ====================================================================
    SET @start_time = GETDATE();
    truncate table silver.crm_prd_info;
    insert into silver.crm_prd_info(
                                     prd_id,
                                     cat_id,
                                     prd_key_id,
                                     prd_nm,
                                     prd_cost,
                                     prd_line,
                                     prd_start_dt,
                                     prd_end_dt
    )
    select prd_id,
           replace(substring(prd_key, 1, 5), '-', '_') as cat_id,
           substring(prd_key, 7, len(prd_key)) as prd_key_id,
           prd_nm,
           isnull(prd_cost,0) as prd_cost,
           case when upper(trim(prd_line)) = 'M' then 'Mountain'
                when upper(trim(prd_line)) = 'R' then 'Road'
                when upper(trim(prd_line)) = 'S' then 'Other Sales'
                when upper(trim(prd_line)) = 'T' then 'Touring'
                else 'n/a'
            end as prd_line, -- Maping product line code (abbreviation) to descriptive text
           prd_start_dt,
           dateadd(
               day,
               -1,
               lead(prd_start_dt) over (partition by prd_key order by prd_start_dt) -- Calculate the end date of the product as the day before the start date
           ) as prd_end_dt
    from bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

    -- ====================================================================
    -- 3. Cleansing bronze.crm_sales_details and Loading silver.crm_sales_details
    -- ====================================================================
    SET @start_time = GETDATE();
    truncate table silver.crm_sales_details;
    insert into silver.crm_sales_details(
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
    select sls_ord_num,
           sls_prd_key,
           sls_cust_id,
           case when sls_order_dt = 0 then Null
               when len(sls_order_dt) != 8 then Null
               else cast(cast(sls_order_dt as varchar(20)) as date)
               end as sls_order_dt,
           case when sls_ship_dt = 0 then Null
                when len(sls_ship_dt) != 8 then Null
                else cast(cast(sls_ship_dt as varchar(20)) as date)
               end as sls_ship_dt,
           case when sls_due_dt = 0 then Null
                when len(sls_due_dt) != 8 then Null
                else cast(cast(sls_due_dt as varchar(20)) as date)
               end as sls_due_dt,
           case when sls_sales <= 0 or sls_sales is null or sls_sales != abs(sls_quantity * sls_price) then abs(sls_quantity * sls_price)
               else sls_sales end as sls_sales,
           sls_quantity,
           case when sls_price <= 0 or sls_price is null then sls_sales / nullif(sls_quantity, 0)
               else sls_price
               end as sls_price
    from bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

    -- ====================================================================
    -- 4. Cleansing bronze.erp_cust_az12 and Loading silver.erp_cust_az12
    -- ====================================================================
    SET @start_time = GETDATE();
    truncate table silver.erp_cust_az12;
    insert into silver.erp_cust_az12(
                                     cid,
                                     bdate,
                                     gen
    )
    select case when cid like 'NAS%' then substring(cid, 4, len(cid))
        else cid end as cid,
        case when bdate > getdate() then null
            else bdate end as bdate,
        case when trim(gen) like '%F%' then 'Female'
             when trim(gen) like '%Female%' then 'Female'
             when trim(gen) like '%M%' then 'Male'
             when trim(gen) like '%Male%' then 'Male'
            else 'n/a'
        end as gen
    from bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

    -- ====================================================================
    -- 5. Cleansing bronze.erp_loc_a101 and Loading silver.erp_loc_a101
    -- ====================================================================
    SET @start_time = GETDATE();
    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid, '-', '') AS cid,
        CASE
            WHEN UPPER(TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry)) = 'DE' THEN 'Germany'
            WHEN UPPER(TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry)) IN ('US', 'USA') THEN 'United States'
            WHEN cntry IS NULL OR TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry) = '' THEN 'n/a'
            ELSE TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry)
            END AS cntry
    FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

    -- ====================================================================
    -- 6. Cleansing bronze.erp_px_cat_g1v2 and Loading silver.erp_px_cat_g1v2
    -- ====================================================================
    SET @start_time = GETDATE();
    truncate table silver.erp_px_cat_g1v2;
    insert into silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
    select id, cat, subcat,
           case when upper(trim(char(10) + char(13) + ' ' from maintenance)) = 'YES' then 'Yes'
               else TRIM(CHAR(13) + CHAR(10) + ' ' FROM maintenance)
            end as maintenance
            from bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '=========================================='
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=========================================='

    END TRY

    BEGIN CATCH
        PRINT '=========================================='
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
        PRINT '=========================================='
    END CATCH

END;

go

EXEC Silver.load_silver;

