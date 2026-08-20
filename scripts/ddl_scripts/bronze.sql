DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info(
	cst_id INT,
	cst_key varchar(50),
	cst_firstname varchar(50),
	cst_lastname varchar(50),
	cst_marital_status varchar(50),
	cst_gndr varchar(50),
	cst_create_date DATE,
	_load_date DATE DEFAULT CURRENT_DATE
);


DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info(
	prd_id INT,
	prd_key varchar(50),
	prd_nm varchar(50),
	prd_cost NUMERIC,
	prd_line varchar(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	_load_date DATE DEFAULT CURRENT_DATE
);

DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details(
	sls_ord_num varchar(50),
	sls_prd_key varchar(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price NUMERIC,
	_load_date DATE DEFAULT CURRENT_DATE
);

DROP TABLE IF EXISTS bronze.erp_CUST_AZ12;
CREATE TABLE bronze.erp_CUST_AZ12(
	CID varchar(50),
	BDATE DATE,
	GEN varchar(50),
	_load_date DATE DEFAULT CURRENT_DATE
);

DROP TABLE IF EXISTS bronze.erp_LOC_A101;
CREATE TABLE bronze.erp_LOC_A101(
	CID varchar(50),
	CNTRY varchar(50),
	_load_date DATE DEFAULT CURRENT_DATE
);


DROP TABLE IF EXISTS bronze.erp_PX_CAT_G1V2;
CREATE TABLE bronze.erp_PX_CAT_G1V2(
	ID varchar(50),
	CAT varchar(50),
	SUBCAT varchar(50),
	MAINTENANCE varchar(50),
	_load_date DATE DEFAULT CURRENT_DATE
);














