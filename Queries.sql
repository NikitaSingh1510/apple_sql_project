--Apple Sales Project

SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM stores;
SELECT * FROM sales;
SELECT * FROM warranty;

--EDA

SELECT DISTINCT repair_status FROM warranty;
SELECT COUNT(*) FROM sales;

--Improving the Query Performance

--et: 324 ms
--pt: .205 ms
--et: 99 ms after index
EXPLAIN ANALYZE
SELECT * FROM sales 
WHERE product_id='P-45';

--creating indexes for the sales table column
CREATE INDEX sales_product_id ON sales(product_id);
CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_date ON sales(sale_date);

--et: 248 ms
--pt: 0.205 ms
--et: 71 ms after index
EXPLAIN ANALYZE
SELECT * FROM sales 
WHERE store_id='ST-30';


--Buisness Problem
--1. Find the number of stores in each country

SELECT country,COUNT(store_id) as "No. of stores" 
FROM stores
GROUP BY country
ORDER BY 2 DESC;

--2. Calculate the number of units sold by each store

SELECT sales.store_id,store_name,SUM(quantity) AS "Units_Sold"
FROM stores LEFT JOIN sales
USING (store_id)
GROUP BY 1,2
ORDER BY 3 DESC;

--3. How many sales occured in December 2023

SELECT COUNT(sale_id) AS "SALES" 
FROM sales
WHERE TO_CHAR(sale_date,'MM-YYYY')='12-2023';

--4. Calculate the percentage of warranty claims marked as "Rejected"

SELECT ROUND(COUNT(claim_id)*100.0/
      (SELECT COUNT(claim_id) FROM warranty),2) AS "Rejected_Percentage"
FROM warranty
WHERE repair_status='Rejected';

--5. Identify the store that had the highest total units sold last year

SELECT  sales.store_id,stores.store_name,
       SUM(sales.quantity) AS "Units_Sold"
FROM sales INNER JOIN stores
ON sales.store_id=stores.store_id
WHERE sale_date >=(CURRENT_DATE -INTERVAL '1 year')
GROUP BY 1,2
ORDER BY 3 DESC LIMIT 1;

--6. Average price of product in each category

SELECT products.category_id,category_name,
 AVG(price) as "avg_price"
FROM products INNER JOIN category
ON products.category_id=category.category_id
GROUP BY 1,2
ORDER BY 3 DESC;

--7.For each store, identify the best-selling day based on highest quantity sold?

WITH cte as (SELECT store_id,to_char(sale_date,'Day')as day_name,
sum(quantity) as total_unit_sold,
dense_rank() over (partition by store_id order by sum(quantity) desc) as rnk
FROM sales
GROUP BY 1,2)
SELECT store_id,day_name,total_unit_sold
FROM cte
where rnk=1;

--MEDIUM
--8. Identify the least selling product in each country for each year based on toal units sold.

 WITH cte as (SELECT country,
 product_name,
 sum(quantity) as total_units,
 RANK() OVER (PARTITION BY st.country ORDER BY sum(quantity)) as rnk
 FROM sales s JOIN stores st
 ON s.store_id=st.store_id
 JOIN products as p
 ON s.product_id=p.product_id
 GROUP BY 1,2)
 SELECT country,
 product_name,total_units
 FROM cte
 WHERE rnk=1;

 --9.Calculate how many warranty claims were filled within 180 days of a product sale.

 SELECT COUNT(*) as no_of_claims
 FROM warranty w LEFT JOIN sales s
 ON w.sale_id=s.sale_id
 WHERE  w.claim_date-s.sale_date<=180;
  
--10. Determine how many warranty claims were filled for products launched in the last two years.

SELECT product_name,COUNT(claim_id) as no_claims,
COUNT(s.sale_id) as no_sales
 FROM warranty w RIGHT JOIN sales s
 ON w.sale_id=s.sale_id
 JOIN products p
 ON p.product_id=s.product_id
 WHERE  p.launch_date >=CURRENT_DATE - INTERVAL '2 years'
 GROUP BY 1;

--11.List the months in the last two years where sales exceeded 20000 units in the United States.
 
 SELECT 
 TO_CHAR(sale_date,'MM-YYYY') as month,
 SUM(quantity) as total_units_sold
 FROM sales JOIN stores st
 ON sales.store_id=st.store_id
 WHERE country='United States' AND
   sale_date>=CURRENT_DATE-INTERVAL '2 year'
 GROUP BY 1
 HAVING SUM(quantity)>20000;


 --12.Identify the product category with the most warranty claims filed in the last two years.
 
 SELECT c.category_name,
   COUNT(claim_id) as no_claims
 FROM warranty w LEFT JOIN sales s
 ON w.sale_id=s.sale_id
 JOIN products p
 ON p.product_id=s.product_id
 JOIN category c
 ON c.category_id=p.category_id
 WHERE w.claim_date >=CURRENT_DATE - INTERVAL '2 year'
 GROUP BY c.category_name;

 --HARD
 --13.Determine the percentage chance of receiving warranty claims after each purchase for each country.

 SELECT st.country,
    ROUND((COUNT(w.claim_id)::numeric/count(s.sale_id)::numeric)*100,2) as risk
 FROM sales s JOIN stores st
 ON s.store_id=st.store_id
 LEFT JOIN warranty w
 ON w.sale_id=s.sale_id
 GROUP BY st.country
 ORDER BY 2 DESC;

 --14. Analyze the year by year growth ratio for each store.

 WITH cte as (SELECT s.store_id,st.store_name,
 EXTRACT (YEAR FROM sale_date) as year,
 SUM(p.price*s.quantity) as current_year_sales
 FROM sales s JOIN products p
 ON s.product_id=p.product_id
 JOIN stores st
 ON s.store_id=st.store_id
 GROUP BY 1,2,3
 ORDER BY 2,3),
 growth_ratio as (
 SELECT *,
 LAG(current_year_sales,1)OVER (PARTITION BY store_name ORDER BY year) previous_year_sales
 FROM cte)
 SELECT *,
 ROUND((current_year_sales-previous_year_sales)::numeric/previous_year_sales::numeric*100.0,3) as growth_ratio
 FROM growth_ratio
 WHERE previous_year_sales is not null 
 AND year<>EXTRACT (YEAR FROM CURRENT_DATE);


 --15. Calculate the correlation between price and warranty claims for
 --products sold in the last four years,segmented by price range.


SELECT
(CASE
WHEN p.price<500 THEN 'Less Expensive'
WHEN P.price BETWEEN 500 AND 1000 THEN 'Mid-range'
ELSE 'Expensive'
END) as price_segment,
COUNT(w.claim_id) total_claim
FROM warranty w LEFT JOIN sales s 
ON w.sale_id=s.sale_id
JOIN products p
ON p.product_id=s.product_id
WHERE w.claim_date>=CURRENT_DATE -INTERVAL '5 year'
GROUP BY 1;

--16.Write a query to calculate the monthly running total
--of sales of each store over the last four years and compare trends during this period.

WITH cte as 
(SELECT store_id,
EXTRACT (YEAR FROM sale_date)as year,
EXTRACT (MONTH FROM sale_date)as month,
SUM(p.price*s.quantity) as total_revenue
FROM sales s JOIN products p
ON s.product_id=p.product_id
GROUP BY 1,2,3
ORDER BY 1,2,3)
SELECT store_id,month,year,total_revenue,
SUM(total_revenue) OVER (PARTITION BY store_id ORDER BY year,month) as running_total
FROM cte;

--17.Analyze the product sales over time,segmented into key periods: from launch to 6 months,
--6-12 months,12-18 months and beyond 18 months.

SELECT p.product_name,
(CASE
WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN '0-6 month'
WHEN s.sale_date BETWEEN p.launch_date+ INTERVAL '6 month' AND p.launch_date +INTERVAL '12 month' THEN '6-12 month'
WHEN s.sale_date BETWEEN p.launch_date+ INTERVAL '12 month' AND p.launch_date +INTERVAL '18 month' THEN '12-18 month'
ELSE '18+' END
) plc,
SUM(s.quantity) as total_quantity
FROM sales s JOIN products p
ON s.product_id=p.product_id
GROUP BY 1,2
ORDER BY 1,3 DESC;
