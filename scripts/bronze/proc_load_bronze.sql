/*
===============================================================
Stored Procedure: Load Bronze Layer
===============================================================
Script Purpose:
    This procedure truncates and reloads all bronze tables
    from source CSV files. Run this to refresh the bronze layer
    with the latest source data.

    Usage: CALL bronze.load_bronze();
===============================================================
*/
CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
	batch_start_time TIMESTAMP;
	batch_end_time TIMESTAMP;
BEGIN
	BEGIN

		batch_start_time:= clock_timestamp();
		
		RAISE NOTICE '============================================';
		RAISE NOTICE 'LOADING BRONZE LAYER';
		RAISE NOTICE '============================================';

		RAISE NOTICE '---------------------------------------------';
		RAISE NOTICE 'LOADING CRM TABLES';
		RAISE NOTICE '---------------------------------------------';

		start_time:= clock_timestamp();

		RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		RAISE NOTICE '>>Inserting Data into: bronze.crm_cust_info';
		COPY bronze.crm_cust_info 
		FROM '/tmp/datasets/source_crm/cust_info.csv'
		WITH(
			FORMAT csv,
			HEADER true,
			DELIMITER ','
		);

		end_time:= clock_timestamp();

		RAISE NOTICE '>> Load Duration: % seconds',EXTRACT(EPOCH FROM(end_time-start_time));

		start_time:= clock_timestamp();

		RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		RAISE NOTICE '>>Inserting Data into: bronze.crm_prd_info';
		COPY bronze.crm_prd_info
		FROM '/tmp/datasets/source_crm/prd_info.csv'
		WITH(
			FORMAT CSV,
			HEADER true,
			DELIMITER ','
		);

		end_time:= clock_timestamp();

		RAISE NOTICE 'Load Duration: % seconds',EXTRACT(EPOCH FROM (end_time-start_time));

		start_time:=clock_timestamp();
		RAISE NOTICE 'Truncating table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		RAISE NOTICE 'Inserting Data into: bronze.crm_sales_details';
		COPY bronze.crm_sales_details
		FROM '/tmp/datasets/source_crm/sales_details.csv'
		WITH(
			FORMAT CSV,
			HEADER true,
			DELIMITER ','
		);

		end_time:=clock_timestamp();

		RAISE NOTICE 'Load Duration: % seconds',EXTRACT(EPOCH FROM (end_time-start_time));

		start_time:= clock_timestamp();
		
		RAISE NOTICE 'Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		RAISE NOTICE 'Inserting Data into: bronze.erp_cust_az12';
		COPY bronze.erp_cust_az12
		FROM '/tmp/datasets/source_erp/cust_az12.csv'
		WITH(
			FORMAT CSV,
			HEADER true,
			DELIMITER ','
		);

		end_time:= clock_timestamp();

		RAISE NOTICE 'Load Duration: % seconds',EXTRACT(EPOCH FROM (end_time-start_time));

		start_time:=clock_timestamp();

		RAISE NOTICE 'Truncating table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		RAISE NOTICE 'Inserting Data into: bronze.erp_loc_a101';
		COPY bronze.erp_loc_a101
		FROM '/tmp/datasets/source_erp/loc_a101.csv'
		WITH(
			FORMAT CSV,
			HEADER TRUE,
			DELIMITER ','
		);

		end_time:=clock_timestamp();

		RAISE NOTICE 'Load Duration: % seconds',EXTRACT(EPOCH FROM (end_time-start_time));

		start_time:=clock_timestamp();

		RAISE NOTICE 'Truncating table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		RAISE NOTICE 'Inserting Data into: bronze.erp_px_cat_g1v2';
		COPY bronze.erp_px_cat_g1v2
		FROM '/tmp/datasets/source_erp/px_cat_g1v2.csv'
		WITH( FORMAT CSV, HEADER true, DELIMITER ',');

		end_time:=clock_timestamp();

		RAISE NOTICE 'Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time-start_time));

		batch_end_time:=clock_timestamp();

		RAISE NOTICE 'Total Load Duration : % seconds', EXTRACT(EPOCH FROM (batch_end_time-batch_start_time));

	EXCEPTION
		WHEN OTHERS THEN 
			RAISE NOTICE 'Error Occured while loading bronze layer: %',SQLERRM;

	END;
END;
$$;
		