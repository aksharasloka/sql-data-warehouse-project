-- ===========================================
-- Quality checks for crm_cust_info table
-- ===========================================

SELECT * FROM bronze.crm_cust_info;

-- check for nulls or duplicate values in primary key
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*)>1 OR cst_id IS NULL; --yes

-- check for unwanted spaces for strings
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname!=TRIM(cst_firstname); --yes

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname!=TRIM(cst_lastname); --yes

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr!=TRIM(cst_gndr); --no

-- Data Standardization & Consistency (check for data quality in low cardinality columns)
-- aim to use clear and meaningful values instead of abbreviated terms
-- default n/a for missing values

SELECT DISTINCT cst_gndr 
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

-- Date is in the correct datatype so no changes

-- ===========================================
-- Quality checks for crm_prd_info table
-- ===========================================

SELECT * FROM bronze.crm_prd_info;

-- check for null and duplicate values in primary key
SELECT prd_id,COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*)>1 OR prd_id IS NULL; -- none

-- unwanted spaces 
SELECT * 
FROM bronze.crm_prd_info 
WHERE prd_nm!=TRIM(prd_nm); -- none

-- Data Standardisation & Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

--check for null or negative costs 
SELECT * 
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0; -- can make null as 0

-- Date Inconsistencies 
SELECT * 
FROM bronze.crm_prd_info 
WHERE prd_start_dt > prd_end_dt; --cast next start date as prev end date 

-- ===========================================
-- Quality checks for crm_sales_details table
-- ===========================================

SELECT * FROM bronze.crm_sales_details;

-- check for unwanted spaces in string
SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num!=TRIM(sls_ord_num); --none

-- check if keys align with the joining table keys
SELECT *
FROM bronze.crm_sales_details 
WHERE sls_prd_key NOT IN (
	SELECT prd_key
	FROM silver.crm_prd_info
); --none

SELECT * 
FROM bronze.crm_sales_details
WHERE sls_cst_id NOT IN (
	SELECT cst_id
	FROM silver.crm_cust_info
); --none 

-- Date inconsistencies
SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_order_dt<0 OR LENGTH(CAST(sls_order_dt AS VARCHAR))!=8;

SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_ship_dt<0 OR LENGTH(CAST(sls_ship_dt AS VARCHAR))!=8; --none

SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_due_dt<0 OR LENGTH(CAST(sls_due_dt AS VARCHAR))!=8; --none

--checking if the dates are in the right order
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt> sls_ship_dt OR sls_order_dt > sls_due_dt --none

--checking for null or negative values
--sales=price*quantity
-- if sales is negative or null or zero, derive from price and quantity
-- if price is zero or null, derive from sales and quantity
-- if price is negative, make it positive 

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- ==============================================
-- Quality checks for erp_cust_az12 table
--===============================================

SELECT * FROM bronze.erp_cust_az12;

-- check for unwanted spaces in cid and if it aligns with joining table
SELECT cid
FROM bronze.erp_cust_az12
WHERE cid!=TRIM(cid);

SELECT cid
FROM bronze.erp_cust_az12
WHERE cid NOT IN (
	SELECT cst_key FROM silver.crm_cust_info
); -- Should remove NAS from start to match

-- Date Standardisation
SELECT *
FROM bronze.erp_cust_az12
WHERE bdate>Current_Date;

-- Data Standardization & Consistency for low cardinality columns 
SELECT Distinct gen
FROM bronze.erp_cust_az12; 

-- =============================================
-- Quality checks for bronze.erp_loc_a101
-- =============================================

SELECT * FROM bronze.erp_loc_a101;

--check if cid aligns with joining table
SELECT cid 
FROM bronze.erp_loc_a101
WHERE cid NOT IN (
	SELECT cst_key FROM silver.crm_cust_info
); --should remove "-" to match

--Data Consistency & Standardization
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

-- =============================================
-- Quality checks for bronze.erp_px_cat_g1v2
-- =============================================

SELECT * FROM bronze.erp_px_cat_g1v2;

-- Unwanted spaces
SELECT * 
FROM bronze.erp_px_cat_g1v2
WHERE cat!=TRIM(cat);

SELECT * 
FROM bronze.erp_px_cat_g1v2
WHERE subcat!=TRIM(subcat);

SELECT * 
FROM bronze.erp_px_cat_g1v2
WHERE maintainance!=TRIM(maintainance);

--Data Standardization & Consistency
SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT Maintainance
FROM bronze.erp_px_cat_g1v2;




