/*
=======================================================================================================
STORED PROCEDURE: LOADING DATA INTO SILVER LAYER
=======================================================================================================
Purpose: This script contains a stored procedure that loads data from bronze layer after standardization and cleaning into silver layer tables.
Transformations include:
	- Implementation of SCD Type 2 on customer and customer location tables.
	- Standardization for country, dates etc columns.
	- Null Handling.
	- Data Enrichment.
*/

DROP PROCEDURE IF EXISTS silver.load_silver;
CREATE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
	v_start_time TIMESTAMP;
	v_end_time TIMESTAMP;
BEGIN
		v_start_time := LOCALTIMESTAMP;
		RAISE NOTICE 'Starting loading into silver layer at: %',v_start_time;
		RAISE NOTICE '========================================================';
		RAISE NOTICE 'Started transforming customer data..';
		-- Transformations on customer data and loading in silver layer.
		CREATE TEMP TABLE stg_customer ON COMMIT DROP AS
		Select DISTINCT ON (cst_id) cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN TRIM(cst_marital_status)='S' THEN 'Single' 
			 WHEN TRIM(cst_marital_status)= 'M' THEN 'Married' 
			 ELSE 'Unknown' END AS cst_marital_status,
		CASE WHEN TRIM(cst_gndr)='F' THEN 'Female'
			 WHEN TRIM(cst_gndr)='M' THEN 'Male'
			 ELSE NULLIF(initcap(TRIM(cst_gndr)),'')
			 END AS cst_gndr,
		_load_date
		FROM bronze.crm_cust_info
		WHERE cst_id is not null
		ORDER BY cst_id,_load_date DESC;
		
		/*
		1. SCD Type 2 logic: Compares source table to the customer data in destination(silver.customer) table, if a dimension i.e first_name,last_name, 
		marital_status for a customer id is changed, it will deactivate that record and insert the updated attribute.
		*/
		UPDATE silver.customer t
		SET valid_to = stg._load_date, is_current = FALSE
		FROM stg_customer stg
		WHERE t.customer_id = stg.cst_id
		  AND t.is_current = TRUE
		  AND (
		    t.first_name     IS DISTINCT FROM stg.cst_firstname OR
		    t.last_name      IS DISTINCT FROM stg.cst_lastname OR
		    t.marital_status IS DISTINCT FROM stg.cst_marital_status
		);
		-- Insert new or update customer record
		RAISE NOTICE 'Inserting transformed customer data into silver layer';
		INSERT INTO silver.customer (
		    customer_id, customer_key, first_name, last_name, 
		    marital_status, gender,source_load_date
		)
		SELECT 
		    stg.cst_id, stg.cst_key, stg.cst_firstname, stg.cst_lastname, 
		    stg.cst_marital_status, stg.cst_gndr,stg._load_date
		FROM stg_customer stg
		LEFT JOIN silver.customer t
		  ON stg.cst_id = t.customer_id
		 AND t.is_current = TRUE
		WHERE t.customer_id IS NULL;
		RAISE NOTICE 'Inserted customer data into silver.customer';
		RAISE NOTICE '========================================================';
		-- Customer transformations ends here
		
		RAISE NOTICE '========================================================';
		RAISE NOTICE 'Started transforming product data..';
		-- Transformations on product data and loading in silver layer.
		CREATE TEMP TABLE stg_product ON COMMIT DROP AS
		SELECT DISTINCT ON (prd_id) prd_id,
		prd_key,
		REPLACE(TRIM(SUBSTRING(prd_key FROM 1 FOR 5)), '-', '_') AS product_category,
		SUBSTRING(prd_key FROM 7) as product_sales_key,
		prd_nm,
		COALESCE(prd_cost,0) as prd_cost,
		CASE WHEN TRIM(prd_line)='R' THEN 'Road'
			 WHEN TRIM(prd_line)='M' THEN 'Mountain'
			 WHEN TRIM(prd_line)='S' THEN 'Sport'
			 WHEN TRIM(prd_line)='T' THEN 'Touring'
			 ELSE 'Unknown product line'
			 END AS product_line,
		_load_date
		FROM bronze.crm_prd_info
		where prd_end_dt is null;
		
		-- Inserting transformed products data into silver layer
		RAISE NOTICE 'Inserting transformed product data into silver layer';
		INSERT INTO silver.products(product_id,
									product_number,
									product_category,
									product_sales_key,
									product_name,
									product_cost,
									product_line,
									source_load_date)
		Select   stg.prd_id,
									stg.prd_key,
									stg.product_category,
									stg.product_sales_key,
									stg.prd_nm,
									stg.prd_cost,
									stg.product_line,
									stg._load_date
		FROM stg_product stg;
		RAISE NOTICE 'Inserted product data into silver.products';
		RAISE NOTICE '========================================================';
		-- Product transformations ends here

		RAISE NOTICE '========================================================';
		RAISE NOTICE 'Started transforming sales data..';
		-- Sales table transformations
		CREATE TEMP TABLE stg_sales ON COMMIT DROP AS
		SELECT DISTINCT on (sls_ord_num) sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE 
			WHEN sls_order_dt::TEXT ~ '^[0-9]{8}$' AND sls_order_dt::TEXT <> '00000000'
			THEN TO_DATE(sls_order_dt::TEXT,'YYYYMMDD')
			ELSE (TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD') - INTERVAL '7 days')::DATE
			END AS sls_order_dt,
		TO_DATE(sls_ship_dt::TEXT,'YYYYMMDD') as sls_ship_dt,
		TO_DATE(sls_due_dt::TEXT,'YYYYMMDD') as sls_due_dt,
		sls_sales,
		sls_quantity,
		COALESCE(sls_price,0) as sls_price,
		_load_date
		FROM bronze.crm_sales_details;
		
		-- Inserting transformed sales data into silver layer
		RAISE NOTICE 'Inserting transformed sales data into silver layer';
		INSERT INTO silver.sales(sales_id,
								product_key,
								customer_id,
								order_date,
								ship_date,
								due_date,
								sales_amount,
								quantity,
								price,
								source_load_date)
		SELECT stg.sls_ord_num,
								stg.sls_prd_key,
								stg.sls_cust_id,
								stg.sls_order_dt,
								stg.sls_ship_dt,
								stg.sls_due_dt,
								stg.sls_sales,
								stg.sls_quantity,
								stg.sls_price,
								stg._load_date
		FROM stg_sales stg;
		RAISE NOTICE 'Inserted sales data into silver.sales';
		RAISE NOTICE '========================================================';
		-- Sales transformations ends here
		
		
		-- ERP customer detail transformations
		RAISE NOTICE '========================================================';
		RAISE NOTICE 'Started transforming customer details data..';
		CREATE TEMP TABLE stg_cust_details ON COMMIT DROP AS
		Select 
		SUBSTRING(cid FROM 9)::INT as cid,
		bdate,
		CASE WHEN TRIM(gen)='F' THEN 'Female'
			 WHEN TRIM(gen)='M' THEN 'Male'
			 ELSE NULLIF(initcap(TRIM(gen)),'')
			 END AS gen, 
		_load_date 
		FROM bronze.erp_CUST_AZ12;

		-- Insert transformed customer details data into silver layer
		RAISE NOTICE 'Inserting transformed customer details data into silver layer';
		INSERT INTO silver.customer_details(customer_id,
											birth_date,
											gender,
											source_load_date)
		SELECT      stg.cid,
											stg.bdate,
											stg.gen,
											stg._load_date
		FROM stg_cust_details stg;
		RAISE NOTICE 'Inserted customer details data into silver.customer_details';
		RAISE NOTICE '========================================================';
		-- Customer details transformations ends here
		
		
		-- ERP customer location transformations
		RAISE NOTICE '========================================================';
		RAISE NOTICE 'Started transforming customer location data..';
		CREATE TEMP TABLE stg_cust_location ON COMMIT DROP AS
		Select DISTINCT ON (cid) SUBSTRING(cid from 7)::INT as cid,
		CASE
		    WHEN UPPER(TRIM(cntry)) IN ('US', 'USA')
		        THEN 'United States'
		    WHEN UPPER(TRIM(cntry))='DE'
		        THEN 'Germany'
		    ELSE NULLIF(initcap(TRIM(cntry)),'')
		END AS cntry,
		_load_date
		from bronze.erp_loc_a101
		WHERE cid IS NOT NULL
		ORDER BY cid, _load_date DESC;

		-- Inserting customer location data with SCD record insertion
		RAISE NOTICE 'Inserting transformed customer location data into silver layer';
		UPDATE silver.customer_location cl
		SET valid_to=stg._load_date, is_current=FALSE
		FROM stg_cust_location stg
		WHERE cl.customer_id=stg.cid and cl.is_current=TRUE
		AND   cl.country IS DISTINCT FROM stg.cntry;
		
		INSERT INTO silver.customer_location (customer_id,country,source_load_date)
		SELECT stg.cid,stg.cntry,stg._load_date
		FROM stg_cust_location stg
		LEFT JOIN silver.customer_location cl
			ON cl.customer_id=stg.cid and cl.is_current=TRUE
		Where cl.customer_id IS NULL;
		RAISE NOTICE 'Inserted customer location data into silver.customer_location';
		RAISE NOTICE '========================================================';
		-- customer location transformations ends here
		
		
		-- ERP category data transformation
		RAISE NOTICE '========================================================';
		RAISE NOTICE 'Started transforming category data..';
		CREATE TEMP TABLE stg_category ON COMMIT DROP AS
		SELECT 
		TRIM(id) as id,
		cat,
		subcat,
		maintenance,
		_load_date
		FROM bronze.erp_px_cat_g1v2;
		
		-- Insert category data into silver layer
		RAISE NOTICE 'Inserting transformed category data into silver layer';
		INSERT INTO silver.category(category_id,
									category_name,
									sub_category,
									maintenance_required,
									source_load_date)
		SELECT      stg.id,
									stg.cat,
									stg.subcat,
									stg.maintenance,
									stg._load_date
		FROM stg_category stg;
		RAISE NOTICE 'Inserted category data into silver.category';
		RAISE NOTICE '========================================================';
		-- category data transformations ends here
		v_end_time := LOCALTIMESTAMP;
		RAISE NOTICE 'Finished loading into silver layer at: %. Time taken: %',v_end_time,(v_start_time-v_end_time);
END;
$$;

