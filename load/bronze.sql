DROP PROCEDURE IF EXISTS load_bronze();
CREATE PROCEDURE load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
	v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_rows_loaded INT;
BEGIN
	v_start_time := LOCALTIMESTAMP;
	-- Loading bronze layer
	RAISE NOTICE 'Starting bronze layer loading at %',v_start_time;
	
	-- Loading customer data from CRM source
	RAISE NOTICE 'Loading customer info data..';
	TRUNCATE TABLE bronze.crm_cust_info RESTART IDENTITY;
	COPY bronze.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
	)
	FROM 'C:/tmp/data/source_crm/cust_info.csv'
	With(
		FORMAT CSV,
		HEADER TRUE,
		DELIMITER ','
	);
	RAISE NOTICE 'FINISHED LOADING RAW CUSTOMER DATA';
	Select Count(*) into v_rows_loaded from bronze.crm_cust_info;
	RAISE NOTICE 'Total rows loaded: %',v_rows_loaded;

	-- Loading product data from CRM source
	RAISE NOTICE 'Loading product info data..';
	TRUNCATE TABLE bronze.crm_prd_info RESTART IDENTITY;
	COPY bronze.crm_prd_info(
		prd_id,
		prd_key ,
		prd_nm ,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	FROM 'C:/tmp/data/source_crm/prd_info.csv'
	With(
		FORMAT CSV,
		HEADER TRUE,
		DELIMITER ','
	);
	RAISE NOTICE 'FINISHED LOADING RAW PRODUCT DATA';
	Select Count(*) into v_rows_loaded from bronze.crm_prd_info;
	RAISE NOTICE 'Total rows loaded: %',v_rows_loaded;
	
	-- Loading sales data from CRM source
	RAISE NOTICE 'Loading sales data..';
	TRUNCATE TABLE bronze.crm_sales_details RESTART IDENTITY;
	COPY bronze.crm_sales_details(
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
	FROM 'C:/tmp/data/source_crm/sales_details.csv'
	With(
		FORMAT CSV,
		HEADER TRUE,
		DELIMITER ','
	);
	RAISE NOTICE 'FINISHED LOADING RAW SALES DATA';
	Select Count(*) into v_rows_loaded from bronze.crm_sales_details;
	RAISE NOTICE 'Total rows loaded: %',v_rows_loaded;

	-- Loading ERP customer data
	RAISE NOTICE 'Loading ERP Customer Data..';
	TRUNCATE TABLE bronze.erp_CUST_AZ12 RESTART IDENTITY;
	COPY bronze.erp_CUST_AZ12(
		CID,
		BDATE,
		GEN 
	)
	FROM 'C:\tmp\data\source_erp\CUST_AZ12.csv'
	With(
		FORMAT CSV,
		HEADER TRUE,
		DELIMITER ','
	);
	RAISE NOTICE 'FINISHED LOADING ERP Customer Data';
	Select Count(*) into v_rows_loaded from bronze.erp_CUST_AZ12;
	RAISE NOTICE 'Total rows loaded: % ',v_rows_loaded;


	-- Loading ERP location data
	RAISE NOTICE 'Loading ERP Location Data..';
	TRUNCATE TABLE bronze.erp_LOC_A101 RESTART IDENTITY;
	COPY bronze.erp_LOC_A101(
		CID,
		CNTRY
	)
	FROM 'C:\tmp\data\source_erp\LOC_A101.csv'
	With(
		FORMAT CSV,
		HEADER TRUE,
		DELIMITER ','
	);
	RAISE NOTICE 'FINISHED LOADING ERP Location Data';
	Select Count(*) into v_rows_loaded from bronze.erp_LOC_A101;
	RAISE NOTICE 'Total rows loaded: % ',v_rows_loaded;

	-- Loading ERP Category data
	RAISE NOTICE 'Loading ERP Category Data..';
	TRUNCATE TABLE bronze.erp_PX_CAT_G1V2 RESTART IDENTITY;
	COPY bronze.erp_PX_CAT_G1V2(
			ID,
			CAT,
			SUBCAT,
			MAINTENANCE
	)
	FROM 'C:\tmp\data\source_erp\PX_CAT_G1V2.csv'
	With(
		FORMAT CSV,
		HEADER TRUE,
		DELIMITER ','
	);
	RAISE NOTICE 'FINISHED LOADING ERP Category Data';
	Select Count(*) into v_rows_loaded from bronze.erp_PX_CAT_G1V2;
	RAISE NOTICE 'Total rows loaded: % ',v_rows_loaded;


	v_end_time := LOCALTIMESTAMP;
	RAISE NOTICE 'Raw data loaded in %',(v_start_time-v_end_time);
END;
$$;


