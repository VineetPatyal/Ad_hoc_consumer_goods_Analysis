# Request 1

select
distinct market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

# Request 2 

WITH product_count AS (
select
      fiscal_year,
      count(distinct product_code) as unique_products
from fact_sales_monthly
group by fiscal_year )
    
select 
      pc20.unique_products as unique_products2020 ,
      pc21.unique_products as unique_products2021,
      round(((pc21.unique_products-pc20.unique_products)/pc20.unique_products) * 100,2) as percentage_chg
from product_count pc20
cross join product_count pc21
on pc20.fiscal_year= 2020 and pc21.fiscal_year= 2021;

# Request 3

select
      segment,
      count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

# Request 4

WITH product_count AS (
select
      p.segment,s.fiscal_year,
      count(distinct s.product_code) as product_count
from fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
group by p.segment,s.fiscal_year )

select
      pc20.segment,
      pc20.product_count as product_count_2020,
      pc21.product_count as product_count_2021,
      pc21.product_count-pc20.product_count as difference
from product_count pc20
join product_count pc21
on pc20.segment=pc21.segment and 
pc20.fiscal_year=2020 and
pc21.fiscal_year= 2021
order by difference desc;

#Request 5

select 
      p.product_code,
      p.product, cost_year,
      mc.manufacturing_cost
from fact_manufacturing_cost mc
join dim_product p
on p.product_code = mc.product_code
where manufacturing_cost in ( select max(manufacturing_cost) from fact_manufacturing_cost)
or 
manufacturing_cost in ( select min(manufacturing_cost) from fact_manufacturing_cost); 


# Request 6 Top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

select
      c.customer_code,
      c.customer,
      round(avg(pre.pre_invoice_discount_pct),4) as average_discount_percentage
from 
     fact_pre_invoice_deductions pre
join 
     dim_customer c on pre.customer_code = c.customer_code
where 
     market = "India" and fiscal_year = 2021
group by 
	 c.customer_code, c.customer
order by 
	 average_discount_percentage desc
limit 5;

# Request 7

with cte1 as (Select
      customer,
      monthname(date) as Month_name,
      month(date) as Month_number,
      year(date) as Year,
      (g.gross_price*s.sold_quantity) as gross_sales
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code
join dim_customer c
on s.customer_code = c.customer_code
where c.customer = "Atliq Exclusive")

select 
Month_name,
Year,
concat(round(sum(gross_sales)/1000000,2)," M") as Gross_sales_Amount
from cte1
group by year, Month_name, Month_number
order by year, Month_number asc;

# Request 8 In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,

SELECT 
    CASE 
        WHEN date BETWEEN '2019-09-01' AND '2019-11-01' THEN 'Quarter1'
        WHEN date BETWEEN '2019-12-01' AND '2020-02-01' THEN 'Quarter2'
        WHEN date BETWEEN '2020-03-01' AND '2020-05-01' THEN 'Quarter3'
        WHEN date BETWEEN '2020-06-01' AND '2020-08-01' THEN 'Quarter4'
    END AS Quarter,
    Concat(round(SUM(sold_quantity)/1000000,2),"M") AS total_sold_quantity
FROM 
    fact_sales_monthly
WHERE 
    fiscal_year = 2020
GROUP BY 
    Quarter
ORDER BY 
    total_sold_quantity DESC;
    
# Result 9

with channel_sales as(
select
      c.channel,
      sum(g.gross_price*s.sold_quantity) as gross_sales,
      sum(sum(g.gross_price*s.sold_quantity)) over() as total_sales
from fact_sales_monthly s
join fact_gross_price g on s.product_code = g.product_code
join dim_customer c on s.customer_code= c.customer_code

where s.fiscal_year = 2021
group by c.channel)

select 
channel,
round(gross_sales/1000000,2) as gross_sales_mln,
round((gross_sales/total_sales)*100,2) as percentage_contribution

from channel_sales
order by gross_sales_mln desc;

# Result 10 

with product_sales as (
select p.division, 
s.product_code,
p.product,
sum(s.sold_quantity) as total_sold_quantity
from fact_sales_monthly s
join dim_product p
on s.product_code = p.product_code
where
    s.fiscal_year=2021
group by p.division,s.product_code,p.product),

product_rank as (select division,
product_code,
product,
total_sold_quantity,
rank() over(partition by division order by total_sold_quantity desc) as rank_order
from product_sales)

select 
ps.division, ps.product_code, ps.product, ps.total_sold_quantity,pr.rank_order
from product_sales ps
join product_rank pr
on ps.product_code=pr.product_code
where rank_order <= 3;

