-- request #1


select distinct(market) as Markets
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";


-- request #2


create view up_2020 as
select product_code,
count(distinct(product_code)) as unique_products_2020 
from fact_sales_monthly
where fiscal_year = 2020;

create view up_2021 as 
select product_code,count(distinct(product_code)) as unique_products_2021
from fact_sales_monthly
where fiscal_year = 2021;

select u0.unique_products_2020,
u1.unique_products_2021,
(u1.unique_products_2021-u0.unique_products_2020)*100/u0.unique_products_2020 as percentage_chg
from up_2020 u0
join up_2021 u1
using (product_code);


-- request #3


with cte1 as
(
	select segment,count(product_code) as product_count
	from dim_product
	group by segment
)
select *
from cte1
order by product_count desc;


-- request #4


create view segment_wise_products_count_2020 as
select p.segment,count(distinct(s.product_code)) as unique_products_2020
from fact_sales_monthly s
join dim_product p
using (product_code)
where s.fiscal_year = 2020
group by p.segment;

create view segment_wise_products_count_2021 as
select p.segment,count(distinct(s.product_code)) as unique_products_2021
from fact_sales_monthly s
join dim_product p
using (product_code)
where s.fiscal_year = 2021
group by p.segment;

with cte1 as
(
	select segment,s0.unique_products_2020 as product_count_2020,
	s1.unique_products_2021 as product_count_2021,
    (s1.unique_products_2021 - s0.unique_products_2020) as difference
	from segment_wise_products_count_2021 s1
	join segment_wise_products_count_2020 s0
	using (segment)
)

select *
from cte1
order by difference desc
limit 1;


-- question 5


(
	select p.product,
	c.product_code,
	c.manufacturing_cost
	from fact_manufacturing_cost c
	join dim_product p
	using (product_code)
	order by c.manufacturing_cost
	limit 1
)
union all
(
	select p.product,
	c.product_code,
	c.manufacturing_cost
	from fact_manufacturing_cost c
	join dim_product p
	using (product_code)
	order by c.manufacturing_cost desc
	limit 1
);


-- question 6

with cte1 as
(
	select c.customer_code,
	c.customer,
	round(avg(f.pre_invoice_discount_pct),3) as average_discount_percentage
	from fact_pre_invoice_deductions f
	join dim_customer c
	using (customer_code)
	where f.fiscal_year = 2021 and c.market = "India"
	group by c.customer_code
)
select *
from cte1
order by average_discount_percentage desc
limit 5;


-- question 7


with cte1 as
(
	select month(s.date) as Month,
	c.customer,
	c.market,
	s.customer_code,
	s.product_code,
	s.sold_quantity,
	g.gross_price,
	(g.gross_price * s.sold_quantity) as Gross_Sales_Amount,
	s.fiscal_year
	from fact_sales_monthly s
	join dim_customer c
	using (customer_code)
	join fact_gross_price g
	using (product_code)
	where c.customer = "Atliq Exclusive"
)
select Month,
fiscal_year,
sum(Gross_Sales_Amount) as Gross_sales_amount
from cte1
group by Month,fiscal_year
order by Month;

-- question 8


with cte1 as
(
	select date,
	product_code,
	customer_code,
	sold_quantity,
	
	case
		when month(date) between 9 and 11 then 'Q1'
		when month(date) between 3 and 5 then 'Q3'
		when month(date) between 6 and 8 then 'Q4'
		else 'Q2'
	end as Quarter
			
	from fact_sales_monthly
	where fiscal_year = 2020
)

select Quarter,
sum(sold_quantity) as total_sold_quantity
from cte1
group by Quarter
order by sum(sold_quantity) desc
limit 1;


-- question 9


with cte1 as
(
	select c.customer,
	c.channel,
	(sm.sold_quantity * gp.gross_price) as gross_sales
	from fact_sales_monthly sm
	join fact_gross_price gp
	using (product_code)
	join dim_customer c
	using (customer_code)
),

cte2 as
(
	select channel,
	sum(gross_sales)/1000000 as gross_sales_mln
	from cte1
	group by channel
)

select *,
round(gross_sales_mln * 100/(select sum(gross_sales_mln) from cte2),2) as percentage
from cte2
group by channel;


-- question 10


with cte1 as
(
	select p.division,
	p.product_code,
	p.product,
	sum(sm.sold_quantity) as total_sold_quantity,
	rank() over (partition by p.division order by sum(sm.sold_quantity) desc) as rank_order
	from dim_product p
	join fact_sales_monthly sm
	using (product_code)
	group by p.division, p.product_code
)
select *
from cte1
where rank_order <= 3;


