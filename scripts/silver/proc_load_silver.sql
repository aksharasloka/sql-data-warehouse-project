/*
===============================================================
Stored Procedure: Load Silver Layer
===============================================================
Script Purpose:
    This procedure performs data cleansing and transformation
    on the bronze layer tables and loads the results into the
    silver layer. Transformations include:
        - Removing duplicates and null records
        - Standardizing categorical values (gender, marital status,
          country, product line)
        - Deriving and validating sales, price, and quantity fields
        - Casting date integers to proper DATE types
        - Extracting category and product keys from composite fields

    Run this procedure after loading the bronze layer.

    Usage: CALL silver.load_silver();
===============================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE start_time TIMESTAMP;
		end_time TIMESTAMP;
		batch_start_time TIMESTAMP;
		batch_end_time TIMESTAMP;

BEGIN
	BEGIN
		batch_start_time:=clock_timestamp();

		RAISE NOTICE '============================================';
		RAISE NOTICE 'LOADING Silver LAYER';
		RAISE NOTICE '============================================';

		RAISE NOTICE '---------------------------------------------';
		RAISE NOTICE 'LOADING CRM TABLES';
		RAISE NOTICE '---------------------------------------------';

		start_time:= clock_timestamp();

		TRUNCATE TABLE silver.crm_cust_info;
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		
		SELECT cst_id,
			   cst_key,
			   TRIM(cst_firstname) as cst_firstname,
			   TRIM(cst_lastname) as cst_lastname,
			   CASE WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
			   		WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
					ELSE 'n/a'
			   END cst_marital_status,
			   CASE WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
					WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
					ELSE 'n/a'
				END cst_gndr,
			   cst_create_date
		FROM(
			SELECT *,
			   ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
		FROM bronze.crm_cust_info 
			WHERE cst_id IS NOT NULL
		)t 
		WHERE flag_last=1 ;

		end_time:=clock_timestamp();

		RAISE NOTICE '>> Load Duration: % seconds',EXTRACT(EPOCH FROM(end_time-start_time));
		
		-- ===============================================================================
		-- Inserting into silver.crm_prd_info table after cleaning & data transformations
		-- ===============================================================================

		start_time:=clock_timestamp();
		
		Truncate Table silver.crm_prd_info;
		INSERT INTO silver.crm_prd_info(
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
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, -- extract category id
			SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key, --extract product id
			prd_nm,
			CASE WHEN prd_cost IS NULL THEN 0 ELSE prd_cost END prd_cost,
			CASE WHEN UPPER(TRIM(prd_line))='R' THEN 'Road'
				 WHEN UPPER(TRIM(prd_line))='M' THEN 'Mountain'
				 WHEN UPPER(TRIM(prd_line))='S' THEN 'Other Sales'
				 WHEN UPPER(TRIM(prd_line))='T' THEN 'Touring'
				 ELSE 'n/a'
			END AS prd_line,
			prd_start_dt,
			CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info;

		end_time:=clock_timestamp(); 

		RAISE NOTICE '>> Load Duration: % seconds',EXTRACT(EPOCH FROM(end_time-start_time));
		-- ===================================================================================
		-- Inserting into silver.crm_sales_details table after cleaning & data transformations
		-- ===================================================================================

		start_time:=clock_timestamp();
		TRUNCATE TABLE silver.crm_sales_details;
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cst_id,
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
			sls_cst_id,
			CASE WHEN sls_order_dt<0 OR LENGTH(CAST(sls_order_dt AS VARCHAR))!=8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,
			CASE WHEN sls_ship_dt<0 OR LENGTH(CAST(sls_ship_dt AS VARCHAR))!=8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,
			CASE WHEN sls_due_dt<0 OR LENGTH(CAST(sls_due_dt AS VARCHAR))!=8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,
			CASE WHEN sls_sales<=0 OR sls_sales IS NULL OR sls_sales!= ABS(sls_price)* sls_quantity 
				 THEN ABS(sls_price)*sls_quantity
				 ELSE sls_sales --deriving sales from price and quantity if inconsistent
			END AS sls_sales,
			sls_quantity,
			CASE WHEN sls_price<=0 OR sls_price IS NULL THEN sls_sales/NULLIF(sls_quantity,0)
				 ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details;

		end_time:=clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds',EXTRACT(EPOCH FROM(end_time-start_time));
		
		-- ===================================================================================
		-- Inserting into silver.erp_cust_az12 table after cleaning & data transformations
		-- ===================================================================================
		start_time:=clock_timestamp();
		
		TRUNCATE TABLE silver.erp_cust_az12;
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
			        ELSE cid
			   END AS cid,
			   CASE WHEN bdate>Current_Date THEN NULL
			   	    ELSE bdate
			   END AS bdate,
			   CASE WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
			   		WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
					ELSE 'n/a'
			   END AS gen
		FROM bronze.erp_cust_az12;
		
		end_time:=clock_timestamp();

		RAISE NOTICE '>> Load Duration: % seconds',EXTRACT(EPOCH FROM(end_time-start_time));
		-- ===================================================================================
		-- Inserting into silver.erp_loc_a101 table after cleaning & data transformations
		-- ===================================================================================

		start_time:=clock_timestamp();

		TRUNCATE TABLE silver.erp_loc_a101;
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT REPLACE(cid,'-','') AS cid,
			   CASE WHEN UPPER(TRIM(cntry))= 'DE' THEN 'Germany'
			   	    WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
					WHEN UPPER(TRIM(cntry))='' OR cntry IS NULL THEN 'n/a'
					ELSE TRIM(cntry)
			   END AS cntry
		FROM bronze.erp_loc_a101;

		end_time:=clock_timestamp();

		RAISE NOTICE '>> Load Duration: % seconds',EXTRACT(EPOCH FROM(end_time-start_time));
		
		-- ===================================================================================
		-- Inserting into silver.erp_px_cat_g1v2 table after cleaning & data transformations
		-- ===================================================================================

		start_time:=clock_timestamp();
		
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintainance
		)
		SELECT id,
			   cat,
			   subcat,
			   maintainance 
		FROM bronze.erp_px_cat_g1v2;

		end_time:=clock_timestamp();

		RAISE NOTICE '>> Load Duration: % seconds',EXTRACT(EPOCH FROM(end_time-start_time));

		batch_end_time:=clock_timestamp();

		RAISE NOTICE 'Total Load Duration : % seconds', EXTRACT(EPOCH FROM (batch_end_time-batch_start_time));
		

	EXCEPTION 
		WHEN OTHERS THEN 
			RAISE NOTICE 'Error Occured while loading silver layer: %',SQLERRM;
	END;
END;
$$;

