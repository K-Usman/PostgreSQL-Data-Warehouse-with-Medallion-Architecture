/*
===================================================================
CREATING SILVER LAYER TABLES
===================================================================
Purpose: This script create silver layer tables and contains cleaned and standardized data. 
We don't do modelling and joining in this layer.

Note: This schema is created after analyzing source data and is based on the requirements of our modelling in the gold
layer for example: silver.products has two attributes product_category and product_sales_key that is the split of 
prd_key in bronze.crm_prd_info. These two attributes will be used in the join to get category and sales information.
*/

-- Customers schema
DROP TABLE IF EXISTS silver.customer;
CREATE TABLE silver.customer(
	customer_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	customer_id INT NOT NULL,
	customer_key varchar(30) NOT NULL,
	first_name TEXT,
	last_name TEXT,
	marital_status TEXT,
	gender TEXT,
	valid_from DATE NOT NULL,
	valid_to DATE NOT NULL DEFAULT '9999-12-31',
	is_current BOOLEAN NOT NULL DEFAULT TRUE,
	source_load_date DATE NOT NULL
);

-- This index enforces uniqueness of customer ids on rows that are active, ensure's only one customer id remains active.
CREATE UNIQUE INDEX idx_customer_current
ON silver.customer(customer_id)
where is_current is TRUE;


-- Product Schema
DROP TABLE IF EXISTS silver.products;
CREATE TABLE silver.products(
	products_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	product_id INT NOT NULL,
	product_number varchar(30), -- prd_key
	product_category TEXT, -- prd_key first part
	product_sales_key varchar(30), -- prd_key second part
	product_name TEXT,
	product_cost NUMERIC,
	product_line TEXT, -- prd_line M=Mountain,R=Road,S=Sports,T=Touring
	source_load_date DATE NOT NULL
);

-- Sales schema
DROP TABLE IF EXISTS silver.sales;
CREATE TABLE silver.sales(
	sale_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	sales_id varchar(30),
	product_key varchar(30),
	customer_id INT,
	order_date DATE,
	ship_date DATE,
	due_date DATE,
	sales_amount NUMERIC,
	quantity INT,
	price NUMERIC,
	source_load_date DATE NOT NULL
);

-- Customer details schema
DROP TABLE IF EXISTS silver.customer_details;
CREATE TABLE silver.customer_details(
	customer_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	customer_id INT NOT NULL, 
	birth_date DATE,
	gender TEXT,
	source_load_date DATE NOT NULL
);

-- Customer location schema
DROP TABLE IF EXISTS silver.customer_location;
CREATE TABLE silver.customer_location(
	customer_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	customer_id INT NOT NULL,
	country TEXT,
	valid_from DATE NOT NULL,
	valid_to DATE NOT NULL DEFAULT '9999-12-31',
	is_current BOOLEAN NOT NULL DEFAULT TRUE,
	source_load_date DATE NOT NULL
);

-- Category schema
DROP TABLE IF EXISTS silver.category;
CREATE TABLE silver.category(
	category_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	category_id varchar(30),
	category_name TEXT,
	sub_category TEXT,
	maintenance_required TEXT,
	source_load_date DATE NOT NULL
);







