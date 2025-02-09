-- base query that joins tables (orders,orders_items,products)
WITH base AS (
SELECT	
		oi.order_id,
		oi.id as item_id,
		oi.product_id,
		pr.product_name,
		pr.category,
		oi.quantity,
		oi.price_at_purchase,
		CAST((oi.price_at_purchase * oi.quantity) AS numeric) AS pq,
		o.total_price,
		o.order_date,
		EXTRACT(DAY FROM o.order_date) AS day,
    	EXTRACT(MONTH FROM o.order_date) AS month,
    	EXTRACT(YEAR FROM o.order_date) AS year,
    	TO_CHAR(o.order_date, 'Day') AS day_of_week,
    	EXTRACT(WEEK FROM o.order_date) AS week_of_year
FROM orders_items AS oi
LEFT JOIN products AS pr
ON pr.id = oi.product_id
LEFT JOIN orders AS o
ON o.id = oi.order_id
)
-- In order to analyze products and categories performance in a Dashboard,
-- We only summarize Quantity and Sales (pq) grouped by year
-- Let's focus on 2024 first 10 months
, base2 AS (
SELECT  product_name,
		category,
		year,
		month,
		SUM(quantity) as q_total,
		SUM(pq) as pq_total
FROM base AS b
WHERE year = 2024 AND month BETWEEN 1 AND 10
GROUP BY product_name, category, year,month
)
--final output table
SELECT	product_name,
		category,
		year,month,
		q_total,
		pq_total,
		COALESCE(q_total - LAG(q_total,1) OVER(PARTITION BY product_name ORDER BY product_name,year,month),0) AS grow_q,
		COALESCE(pq_total - LAG(pq_total,1) OVER(PARTITION BY product_name ORDER BY product_name,year,month),0) AS grow_pq
FROM base2
ORDER BY product_name,year,month
