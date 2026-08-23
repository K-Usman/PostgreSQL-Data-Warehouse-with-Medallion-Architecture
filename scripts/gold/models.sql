
-- CREATE customer dimension by joining customer, customer_detail and customer_location tables
CREATE OR REPLACE VIEW gold.dim_customer AS
SELECT c.customer_sk,
	   c.customer_id,
	   c.first_name,
	   c.last_name,
	   c.marital_status,
	   COALESCE(c.gender,cd.gender) as gender,
	   cd.birth_date,
	   loc.country,
	   c.valid_from,
       c.valid_to,
       c.is_current
FROM silver.customer c
LEFT JOIN silver.customer_location loc
	ON c.customer_id=loc.customer_id
	AND loc.valid_from <= c.valid_from
    AND (loc.valid_to > c.valid_from OR loc.valid_to IS NULL)
LEFT JOIN silver.customer_details cd
	ON c.customer_id=cd.customer_id;

-- CREATE product dimension by joining products and category tables
CREATE OR REPLACE VIEW gold.dim_product AS
Select p.products_sk,
	   p.product_number,
	   p.product_category,
	   p.product_sales_key,
	   p.product_name,
	   p.product_cost,
	   p.product_line,
	   c.category_name,
	   c.sub_category,
	   c.maintenance_required
FROM silver.products p
JOIN silver.category c
	ON p.product_category=c.category_id;

-- CREATE fact sales view
DROP VIEW gold.fact_sales
CREATE VIEW gold.fact_sales AS
SELECT
    s.sales_id as order_number,
    s.product_key,
    s.customer_id,
    s.order_date,
    s.ship_date,
	s.due_date,
	(s.quantity * s.price) as sales_amount,
	s.quantity,
	s.price
FROM silver.sales s
JOIN silver.customer c 
    ON s.customer_id = c.customer_id
    AND c.is_current = TRUE
JOIN silver.products p 
    ON s.product_key = p.product_sales_key;

