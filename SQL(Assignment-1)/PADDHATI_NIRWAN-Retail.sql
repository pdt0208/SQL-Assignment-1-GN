SELECT event_id, store_id, product_code, base_price, promo_type
FROM fact_events
WHERE base_price > 1000;

SELECT event_id, product_code, promo_type, `quantity_sold(before_promo)`, `quantity_sold(after_promo)`
FROM fact_events
WHERE `quantity_sold(after_promo)` > 100
ORDER BY `quantity_sold(after_promo)` DESC;

SELECT DISTINCT promo_type
FROM fact_events;

SELECT COUNT(event_id) AS Total_number_of_events, SUM(`quantity_sold(before_promo)`) AS Total_quantity_sold_before_promotion,
SUM(`quantity_sold(after_promo)`) AS Total_quantity_sold_after_promotion, AVG(base_price) AS Average_base_price,
MAX(base_price) AS Maximum_base_price, MIN(base_price) AS Minimum_base_price
FROM fact_events;

SELECT promo_type, COUNT(event_id) AS Number_of_events, SUM(`quantity_sold(before_promo)`) AS Total_quantity_before,
SUM(`quantity_sold(after_promo)`) AS Total_quantity_after
FROM fact_events
GROUP BY promo_type
ORDER BY Total_quantity_after DESC;

SELECT promo_type, SUM(`quantity_sold(before_promo)`) AS total_before,
SUM(`quantity_sold(after_promo)`) AS total_after, SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events
GROUP BY promo_type
ORDER BY quantity_change DESC;

SELECT SUM(f.`quantity_sold(after_promo)`) , SUM(f.`quantity_sold(before_promo)`) , 
SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS quantity_change , p.category , COUNT(f.event_id)
FROM fact_events f
INNER JOIN dim_products p ON f.product_code = p.product_code
GROUP BY p.category
ORDER BY SUM(f.`quantity_sold(after_promo)`) DESC;

SELECT s.city , COUNT(f.event_id) AS Number_of_promotional_events , SUM(f.`quantity_sold(before_promo)`) AS Total_quantity_before_promotion , SUM(f.`quantity_sold(after_promo)`) AS Total_quantity_after_promotion
FROM fact_events f
INNER JOIN dim_stores s ON s.store_id = f.store_id 
GROUP BY s.city 
ORDER BY SUM(f.`quantity_sold(after_promo)`)DESC;

SELECT c.campaign_name , c.start_date , c.end_date, COUNT(f.event_id) AS Number_of_promotional_events , SUM(f.`quantity_sold(before_promo)`) AS Total_quantity_before_promotion , SUM(f.`quantity_sold(after_promo)`) AS Total_quantity_after_promotion
FROM fact_events f
INNER JOIN dim_campaigns c ON c.campaign_id = f.campaign_id
GROUP BY c.campaign_name , c.start_date , c.end_date
ORDER BY SUM(f.`quantity_sold(after_promo)`)DESC;

SELECT AVG(f.base_price) AS Average_Base_Price, SUM(f.`quantity_sold(after_promo)`) AS Total_quantity_after_promotion , p.category AS Category
FROM fact_events f
INNER JOIN dim_products p ON p.product_code = f.product_code
GROUP BY p.category
HAVING SUM(f.`quantity_sold(after_promo)`) > 1000
ORDER BY SUM(f.`quantity_sold(after_promo)`) DESC;

SELECT s.city , p.category , SUM(f.`quantity_sold(after_promo)`) AS Total_quantity_after_promotion
FROM fact_events f
INNER JOIN dim_stores s ON s.store_id = f.store_id
INNER JOIN dim_products p ON p.product_code = f.product_code
GROUP BY s.city , p.category 
ORDER BY  s.city , SUM(f.`quantity_sold(after_promo)`) DESC ;

SELECT p.category, p.product_name, SUM(f.`quantity_sold(after_promo)`) AS Total_quantity_after_promotion,
SUM(f.`quantity_sold(before_promo)`) AS Total_quantity_before_promotion, SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS quantity_change,
( ( SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) ) / NULLIF(SUM(f.`quantity_sold(before_promo)`), 0) ) * 100 AS Percentage_change
FROM fact_events f 
INNER JOIN dim_products p ON f.product_code = p.product_code
GROUP BY p.category, p.product_name
ORDER BY Percentage_change DESC;

SELECT SUM(f.`quantity_sold(after_promo)`) AS Total_quantity_after_promotion , SUM(f.`quantity_sold(before_promo)`) AS Total_quantity_before_promotion,
COUNT(f.event_id) AS Number_of_events , SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS quantity_change , f.promo_type , 
c.campaign_name
FROM fact_events f
INNER JOIN dim_campaigns c ON f.campaign_id = c.campaign_id 
GROUP BY f.promo_type , c.campaign_name
ORDER BY  c.campaign_name , quantity_change DESC;

SELECT p.product_name, p.category, SUM( f.base_price * f.`quantity_sold(before_promo)`) AS revenue_before,
SUM( f.base_price * f.`quantity_sold(after_promo)`) AS revenue_after, 
SUM(f.base_price * f.`quantity_sold(after_promo)`) - SUM(f.base_price * f.`quantity_sold(before_promo)`) AS revenue_difference
FROM fact_events f
INNER JOIN dim_products p ON f.product_code = p.product_code
GROUP BY p.product_name, p.category
ORDER BY revenue_difference DESC;

SELECT SUM(`quantity_sold(before_promo)`) AS Total_quantity_before_promotion , 
SUM(`quantity_sold(after_promo)`) AS Total_quantity_after_promotion ,
((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) ) / NULLIF(SUM(`quantity_sold(before_promo)`), 0) ) * 100 AS Percentage_change ,
CASE 
   WHEN ((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) ) / NULLIF(SUM(`quantity_sold(before_promo)`), 0) ) * 100  >= 50 THEN 'High Impact'
   WHEN ((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) ) / NULLIF(SUM(`quantity_sold(before_promo)`), 0) ) * 100 >= 20 THEN 'Medium Impact'
   ELSE 'Low Impact' 
END AS performance_category 
FROM fact_events 
GROUP BY promo_type
ORDER BY Percentage_change DESC;

WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(f.`quantity_sold(after_promo)`) AS total_quantity_after
    FROM fact_events f
    JOIN dim_products p
        ON f.product_code = p.product_code
    GROUP BY p.category, p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_name,
        total_quantity_after,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY total_quantity_after DESC
        ) AS category_rank
    FROM product_sales
)
SELECT
    category,
    product_name,
    total_quantity_after,
    category_rank
FROM ranked_products
WHERE category_rank <= 2
ORDER BY category, category_rank;

WITH sales_each_store AS (
    SELECT s.city, s.store_id, SUM(f.`quantity_sold(after_promo)`) AS total_quantity_after
    FROM fact_events f
    INNER JOIN dim_stores s ON f.store_id = s.store_id
    GROUP BY s.city, s.store_id
),

ranked_stores AS (
    SELECT city, store_id, total_quantity_after,
	   DENSE_RANK() OVER (
            PARTITION BY city
            ORDER BY total_quantity_after DESC
        ) AS city_rank
    FROM sales_each_store
)

SELECT city, store_id, total_quantity_after, city_rank
FROM ranked_stores
WHERE city_rank <= 2
ORDER BY city, city_rank;

WITH campaign_product_sales AS (
    SELECT c.campaign_name, p.product_name, SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after,
	SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS quantity_change,
    (
            (
                SUM(f.`quantity_sold(after_promo)`)
                - SUM(f.`quantity_sold(before_promo)`)
            )
            / NULLIF(
                SUM(f.`quantity_sold(before_promo)`), 0
            )
        ) * 100 AS percentage_change

    FROM fact_events f

    INNER JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
	INNER JOIN dim_products p ON f.product_code = p.product_code
    GROUP BY c.campaign_name, p.product_name
),

ranked_products AS (
    SELECT campaign_name, product_name, total_before, total_after, quantity_change, percentage_change,
            DENSE_RANK() OVER (
            PARTITION BY campaign_name
            ORDER BY percentage_change DESC
        ) AS campaign_rank

    FROM campaign_product_sales
)

SELECT campaign_name, product_name, total_before, total_after, quantity_change, percentage_change, campaign_rank
FROM ranked_products
WHERE campaign_rank <= 3
ORDER BY campaign_name, campaign_rank;

WITH product_analysis AS (
    SELECT p.product_name, p.category, COUNT(f.event_id) AS event_count,
           SUM(f.`quantity_sold(before_promo)`) AS total_before , SUM(f.`quantity_sold(after_promo)`) AS total_after,
           SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS quantity_change,
           ( ( SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) ) / NULLIF( SUM(f.`quantity_sold(before_promo)`), 0))* 100 AS percentage_change,
           SUM( f.base_price * f.`quantity_sold(before_promo)` ) AS revenue_before,
           SUM( f.base_price * f.`quantity_sold(after_promo)` ) AS revenue_after,
           SUM( f.base_price * f.`quantity_sold(after_promo)`) - SUM( f.base_price * f.`quantity_sold(before_promo)` ) AS revenue_change, 
           AVG(f.base_price) AS average_base_price

    FROM fact_events f
    INNER JOIN dim_products p ON f.product_code = p.product_code
    GROUP BY p.product_name , p.category ),

ranked_products AS (
    SELECT product_name, category, event_count, total_before, total_after, quantity_change, percentage_change, revenue_before, revenue_after,
        revenue_change, average_base_price,
    DENSE_RANK() OVER ( PARTITION BY category
	ORDER BY revenue_change DESC ) AS product_rank
    FROM product_analysis )

SELECT product_name, category, event_count, total_before, total_after, quantity_change, percentage_change, revenue_before,
    revenue_after, revenue_change, average_base_price, product_rank

FROM ranked_products
WHERE product_rank <= 2
ORDER BY category, product_rank;