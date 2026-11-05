create database if not exists zomato_db;
use zomato_db;
create database zomato_db;
use zomato_db;
show tables;
rename table `zomato_orders -updated` to zomato_orders,
`zomato_restaurants -updated` to zomato_restaurants;
## basic data cleaning
use zomato_db;
set sql_safe_updates =0;
update zomato_orders set total_cost =0 where total_cost is null;
update zomato_orders set item_count =1 where item_count is null;
update zomato_orders set payment_method ="unkown" where payment_method is null;
update zomato_restaurants set city ="unknown" where city is null;
update zomato_restaurants set cuisine ="unknown" where cuisine is null;
update zomato_restaurants set avg_rating = 0 where avg_rating is null;
## data exploratin (city restaurant)
select city ,count(*) as restaurant_count
from zomato_restaurants
group by city
order by restaurant_count desc;
## data exploratin( top 5 cities
select r.city, count(o.order_id) as total_orders
from zomato_orders o
join zomato_restaurants r on o.restaurant_id =r.restaurant_id
group by r.city
order by total_orders desc
limit 5;
### data exploratin (restaurants total revenue
select r.restaurant_id, r.restaurant_name,sum(o.total_cost) as total_revenue
from zomato_orders o 
join zomato_restaurants r on o.restaurant_id = r.restaurant_id
group by r.restaurant_id, r.restaurant_name
order by total_revenue desc;
## 3 data aggregation city avg order amt
select r.city,round(avg(o.total_cost),2) as avg_order_amount
from zomato_orders o 
join zomato_restaurants r on o.restaurant_id =r.restaurant_id
group by r.city
order by avg_order_amount desc;
## 3 data aggregation top 5 restaurants
select r.restaurant_name,sum(o.total_cost)as total_sales
from zomato_orders o 
join zomato_restaurants r on o.restaurant_id =r.restaurant_id
group by r.restaurant_id, r.restaurant_name
order by total_sales desc
limit 5;
## 4 data join
 select o.order_id,o.restaurant_id,r.restaurant_name,r.city,r.area,
 r.cuisine, o.customer_id,o.order_date,o.order_time,
 o.delivery_time,o.total_cost,o.item_count,
 o.payment_method,o.customer_rating
 from zomato_orders o 
 join zomato_restaurants r on o.restaurant_id =r.restaurant_id;