--data inspection
select * from dbo.sales_data;



--checking unique values
SELECT DISTINCT status FROM dbo.sales_data;
SELECT DISTINCT year_id FROM dbo.sales_data;
SELECT DISTINCT Productline FROM dbo.sales_data;
SELECT DISTINCT COUNTRY from dbo.sales_data;
SELECT DISTINCT TERRITORY from dbo.sales_data;
SELECT DISTINCT DEALSIZE from dbo.sales_data;


--ANALYSIS
-- 1. Total sales per year and Percentage increase in the sales compared to previous year
--   by grouping sales by year id


WITH Sales_y as 
	(SELECT  
		YEAR_ID AS 'YEAR',  SUM(SALES) AS 'TOTAL_SALES' 
		FROM dbo.sales_data
		group by YEAR_ID

)
select 
	s2.year as 'YEAR', 
	concat(round(100*(s2.total_sales-s1.total_sales)/s1.total_sales, 2), '%') as 'PERCENT_INC_IN_SALES',
	S1.YEAR AS 'PREVIOUS YEAR'
	from sales_y s1, sales_y s2 
	where s2.year>s1.year and s2.year-s1.year=1 
	order by year asc;

-- 2. Total sales per ProductLine
--   By grouping sales BY PRODUCTLINE

SELECT  
	PRODUCTLINE,  
	SUM(SALES) AS 'TOTAL_SALES' 
	FROM dbo.sales_data
	group by PRODUCTLINE
	ORDER BY TOTAL_SALES DESC ;


-- 3. Total sales GROUP BY DEALSIZE
--   By grouping sales by DEALSIZE

SELECT  DEALSIZE,  SUM(SALES) AS 'TOTAL_SALES' 
	FROM dbo.sales_data
	group by DEALSIZE
	ORDER BY TOTAL_SALES DESC;


--DEALSIZE WITH MAX SALES

SELECT TOP 1 DEALSIZE,  SUM(SALES) AS 'TOTAL_SALES' 
	FROM dbo.sales_data
	group by DEALSIZE
	ORDER BY TOTAL_SALES DESC;


-- 4. What was the best month for sale in a specific year? and how much was earned that month

select 
	month_id, 
	sum(sales) as total_sales, 
	count(ordernumber) as frequency
	from sales_data 
	where year_id = 2003	--	change year
	group by month_id, year_id
	order by total_sales desc;

-- 5. What is the total number of sales and what product they sold in november?

select month_id, 
	productline, 
	sum(sales)as total_sales,
	count(ordernumber) as frequency
	from sales_data
	where year_id =2004 and month_id = 11
	group by month_id, productline
	order by total_sales desc

--  6. who is the best customer ?
--  RFM ( RECENCY, FREQUENCY, MONETRY) ANALYSIS

drop table if exists rfm_sales;
WITH rfm as
	 (select 
		 customername,
		 round(sum(sales), 2) as Monetry_value,
		 count(ordernumber) as 'FREQUENCY',
		 cast(max(orderdate) as date) as last_order_date,
		 (select cast(max(orderdate) as date) from sales_data) as max_order_date,
		 datediff(DD, max(orderdate), (select max(orderdate) from sales_data)) as 'RECENCY'
		 from sales_data
		 group by customername
), 

 rfm_calc as
	 (select r.* ,
		 NTILE(4) OVER(order by r.recency desc) as rfm_recency,
		 NTILE(4) OVER(order by r.frequency) as rfm_frequency,
		 NTILE(4) OVER(order by r.Monetry_value) as rfm_monetry_value
		 from rfm r
		 
		 )
		 
-- sum and concat of the rfm is generated for better analysis and the data is added to a new table for further use

select rc.*,
	rfm_recency+rfm_frequency+rfm_monetry_value as Sum_rfm,
	concat(cast(rfm_recency as varchar), cast(rfm_frequency as varchar), cast(rfm_monetry_value as varchar)) as rfm_concat
	into RFM_SALES -- inserted all the data into the new table
	from rfm_calc rc;

select * from RFM_sales --verify the data of newly created table

select distinct (sum_rfm) from rfm_sales -- look at the distinct sum_rfm of the table fro better analysis

-- CUSTOMER SEGMENTATION ON RFM ANALYSIS
drop table if exists customer_type
select 
	 *, 
	(case when sum_rfm in (select sum_rfm from rfm_sales where sum_rfm>10 and rfm_recency>3 and rfm_frequency>=3 and rfm_monetry_value>=3 ) then 'Loyal' 
	  when rfm_concat in (select rfm_concat from rfm_sales where rfm_recency>=3 and rfm_monetry_value>=2 and sum_rfm between 8 and 11 ) then 'Active_buyers'
	  when rfm_concat in (select rfm_concat from rfm_sales where rfm_recency=1 and rfm_frequency<=3 and rfm_monetry_value<=4 ) then 'Lost_Customer' 
	  when rfm_concat in (select rfm_concat from rfm_sales where rfm_recency=2 and rfm_frequency>=2 and rfm_monetry_value>=2 and sum_rfm between 5 and 9 ) then 'Slipping_away_Customer'
	  when rfm_concat in (select rfm_concat from rfm_sales where rfm_recency>=3 and rfm_frequency<2 and rfm_monetry_value<=2) then 'New_Customer'
	  when rfm_concat in (select rfm_concat from rfm_sales where rfm_recency>3 and rfm_frequency>=3 and rfm_monetry_value<3) then 'Potential_buyers'

	end) as Customer_Type 
	into customer_seg
	from rfm_sales;

select * from customer_seg

-- 8. Most sold pair of product ?

--select ordernumber, STRING_AGG(productline,',')  from sales_data group by ordernumber -- all the products grouped by ordernumber

drop table if exists PairOfProducts;
WITH sb AS
(select 
	ordernumber,
	string_agg(productcode,',' ) within group(order by productcode asc) as 'Product_Codes'
	from sales_data 
	where ordernumber in 
	 
	(
		select 
		ordernumber from
		(
			select 
				ordernumber, 
				count(*) as rk
				from sales_data
				where status='Shipped'
				group by ordernumber
		) n
		where rk=2
	) group by ordernumber
) 

SELECT 
	
	distinct product_codes,
	ordernumber
	--into pairofproducts
	from sb 
	order by product_codes;
	
select * from pairofproducts -- query to get the pair of the products 

	
	
	























 
