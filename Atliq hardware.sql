
use gdb023;
1) Provide the list of markets in which customer "Atliq Exclusive" operates its
   business in the APAC region.

SELECT market FROM
dim_customer WHERE customer = 'Atliq Exclusive' 
AND region = 'APAC';
    
----------------------------------------------------------------------------------------------------------------------------------------------------------------

2) What is the percentage of unique product increase in 2021 vs. 2020?

WITH CTE1 AS
(SELECT COUNT(DISTINCT product_code) 
AS Unique_Products_2020 
FROM fact_sales_monthly WHERE fiscal_year = 2020),
CTE2 AS
(SELECT COUNT(DISTINCT product_code)
AS Unique_Products_2021 
FROM fact_sales_monthly WHERE fiscal_year = 2021) 
SELECT *, round((Unique_Products_2021 - Unique_Products_2020) * 100 / Unique_Products_2020,2) AS Percentage_chng
FROM CTE1
CROSS JOIN
CTE2;

--------------------------------------------------------------------------------------------------------------------------------------------------------------

3)Provide a report with all the unique product counts for each segment and
  sort them in descending order of product counts.

SELECT  * FROM dim_product;
SELECT segment,COUNT(DISTINCT product_code) AS Product_Count
FROM dim_product 
GROUP BY segment ORDER BY Product_Count DESC;

--------------------------------------------------------------------------------------------------------------------------------------------------------------

4)  Which segment had the most increase in unique products in 2021 vs 2020?

SELECT * FROM fact_sales_monthly;

 WITH year_2020 AS (
 SELECT segment, COUNT(DISTINCT p.product_code) AS product_count_2020
 FROM dim_product p JOIN
 fact_sales_monthly m USING(product_code)
 WHERE fiscal_year = 2020
 GROUP BY segment),
 year_2021 AS (
 SELECT segment, COUNT(DISTINCT p.product_code) AS product_count_2021
 FROM dim_product p JOIN
 fact_sales_monthly m USING(product_code)
 WHERE fiscal_year = 2021
 GROUP BY segment)
 SELECT year_2020.segment,product_count_2020,product_count_2021,
 (product_count_2021 - product_count_2020) As Difference
 from year_2020
 JOIN year_2021 USING(segment)
 ORDER BY difference DESC;

 --------------------------------------------------------------------------------------------------------------------------------------------------------------
 
5) Get the products that have the highest and lowest manufacturing costs.

SELECT dp.product_code,product,manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product dp ON dp.product_code = m.product_code
WHERE manufacturing_cost IN (
SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost union
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

--------------------------------------------------------------------------------------------------------------------------------------------------------------

 6) Generate a report which contains the top 5 customers who received an 
    average high pre_invoice_discount_pct for the fiscal year 2021 and in the
    Indian market.

SELECT c.customer_code, c.customer,
ROUND(AVG(pre_invoice_discount_pct) * 100,2) AS average_discount_percentage
FROM dim_customer c JOIN
fact_pre_invoice_deductions AS f
USING(customer_code)
WHERE market = 'India' AND fiscal_year = 2021
GROUP BY c.customer_code,c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

--------------------------------------------------------------------------------------------------------------------------------------------------------------

 7) Get the complete report of the Gross sales amount for the customer “Atliq
    Exclusive” for each month. This analysis helps to get an idea of low and
    high-performing months and take strategic decisions.

SELECT 
   DATE_FORMAT(date, '%M %Y') AS month,
   fcm.fiscal_year AS Year,
   CONCAT(ROUND(SUM(sold_quantity * gross_price)/1000000,2),'M') AS gross_sales_amount
FROM
	fact_sales_monthly AS fcm
JOIN 
    dim_customer
    USING(customer_code)
JOIN
	fact_gross_price
    USING (product_code)
WHERE 
	 customer = 'Atliq Exclusive'
GROUP BY month, year  
ORDER BY Year; 

--------------------------------------------------------------------------------------------------------------------------------------------------------------

 8) In which quarter of 2020, got the maximum total_sold_quantity? 


WITH quarter as
(SELECT *,
CASE
	WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
    WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
    WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
    ELSE 'Q4'
    END AS Quarter FROM fact_sales_monthly
    WHERE fiscal_year = 2020)
    SELECT Quarter, CONCAT(ROUND(SUM(sold_quantity) / 1000000,2),'M') AS Total_sold_quantity
    FROM quarter GROUP BY Quarter 
    ORDER BY Total_sold_quantity DESC;

--------------------------------------------------------------------------------------------------------------------------------------------------------------
    
9) Which channel helped to bring more gross sales in the fiscal year 2021
   and the percentage of contribution?

WITH CTE AS
(SELECT c.channel, SUM(f.gross_price * m.sold_quantity) AS total_sales
FROM fact_sales_monthly m
JOIN fact_gross_price f USING(product_code)
JOIN dim_customer c USING(customer_code)
WHERE m.fiscal_year = 2021
GROUP BY c.channel
ORDER BY total_sales DESC)
SELECT channel,CONCAT(ROUND(total_sales / 1000000,2),'M') AS gross_sales_mln,
CONCAT(ROUND(total_sales / (SUM(total_sales) OVER() ) * 100,2),'%')
AS percentage FROM CTE;

--------------------------------------------------------------------------------------------------------------------------------------------------------------

10) Get the Top 3 products in each division that have a high
      total_sold_quantity in the fiscal_year 2021? 
      
WITH CTE1 AS
(SELECT c.division AS division, 
f.product_code AS product_code
, c.product AS product,
SUM(f.sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly f
JOIN dim_product c USING(product_code)
WHERE f.fiscal_year = 2021
GROUP BY c.division,f.product_code,c.product
ORDER BY total_sold_quantity DESC),
CTE2 AS
(SELECT division, product_code, product, total_sold_quantity,
DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
FROM CTE1)
SELECT * FROM CTE2
WHERE rank_order <=3;




