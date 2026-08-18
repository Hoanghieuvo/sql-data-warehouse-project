/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None.
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

use DataWarehouse

go

create or alter procedure bronze.load_bronze as
begin
    declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
    begin try
        set @batch_start_time = getdate();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        set @start_time = getdate();
        PRINT '>> Truncating Table: bronze.crm_cust_info';
        truncate table bronze.crm_cust_info
        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        bulk insert bronze.crm_cust_info from '/var/opt/mssql/datasets/source_crm/cust_info.csv'
            with (firstrow = 2, fieldterminator = ',', tablock)
        set @end_time = getdate();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        set @start_time = getdate();
        PRINT '>> Truncating Table: bronze.crm_prd_info';
        truncate table bronze.crm_prd_info
        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        bulk insert bronze.crm_prd_info from '/var/opt/mssql/datasets/source_crm/prd_info.csv'
            with (firstrow = 2, fieldterminator = ',', tablock)
        set @end_time = getdate();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        set @start_time = getdate();
        PRINT '>> Truncating Table: bronze.crm_sales_details';
        truncate table bronze.crm_sales_details
        PRINT '>> Inserting Data Into: bronze.crm_sales_details';
        bulk insert bronze.crm_sales_details from '/var/opt/mssql/datasets/source_crm/sales_details.csv'
            with (firstrow = 2, fieldterminator = ',', tablock)
        set @end_time = getdate();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';

        set @start_time = getdate();
        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        truncate table bronze.erp_loc_a101
        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
        bulk insert bronze.erp_loc_a101 from '/var/opt/mssql/datasets/source_erp/loc_a101.csv'
            with (firstrow = 2, fieldterminator = ',', tablock)
        set @end_time = getdate();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        set @start_time = getdate();
        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        truncate table bronze.erp_cust_az12
        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
        bulk insert bronze.erp_cust_az12 from '/var/opt/mssql/datasets/source_erp/cust_az12.csv'
            with (firstrow = 2, fieldterminator = ',', tablock)
        set @end_time = getdate();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        set @start_time = getdate();
        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        truncate table bronze.erp_px_cat_g1v2
        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        bulk insert bronze.erp_px_cat_g1v2 from '/var/opt/mssql/datasets/source_erp/px_cat_g1v2.csv'
            with (firstrow = 2, fieldterminator = ',', tablock)
        set @end_time = getdate();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        set @batch_end_time = getdate();
        PRINT '=========================================='
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=========================================='

    end try
    begin catch
        PRINT '=========================================='
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST (ERROR_NUMBER() AS VARCHAR(50));
        PRINT 'Error Message' + CAST (ERROR_STATE() AS VARCHAR(50));
        PRINT '=========================================='
    end catch;

end;

go

exec bronze.load_bronze;

