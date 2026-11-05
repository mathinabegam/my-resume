create database Amazon_fresh;
use amazon_fresh;
## data modeling and basice queies
## 1 er diagram

create database amazon_fresh;
use amazon_fresh;
select*from customers;
use amazon_fresh;
select*from product;
use amazon_fresh;
select*from orders;
#### 3 specific city
select*from customers
where city ="chennai";
select*from customers
where city ="patelberg";
## 3 prouct under the " frits"
select*from product
where category ="fruits";
## 4 a customer id
alter table customers
modify age int not null;
#3 4 b greathe than 18 
select*from customers
where age<=18;
## 4 c constraint for name
select name,count(*)
from customers
group by name
having count(*) >1;
## 5 insert 3 new row into product 
use amazon_fresh;
insert into product
(`product id`,productname,category,subcategory,
priceperunit,stockquantity,supplirI)
values
(1001,"apple","fruits","fresh fruits",120,50,"supplirI"),
(1002,"milk","dairy","milk products",60,40,"supplirI"),
(1003,"carrot","vegetables","fresh vegatables",40,30,"supplirI");
## 6 update stock quantity
set sql_safe_updates=0;
update product
set stockquantity =100
where `product id` =1001 ;
set sql_safe_updates=1;
## 7 delete supplier from a specifie city
use amazon_fresh;
set sql_safe_updates=0;
delete from suppliers
where city="chennai";
set sql_safe_updates=1;
## tesk 8 a review table are between 1 and 5
use amazon_fresh;
alter table reviews
add constraint chk_rating
 check (rating between 1 and 5);
##  tesk 8 b constraint for the prime member colunm "no"
alter table customers
modify primemember varchar(10)  default "no";
## tash 9 a where
select*from orders
where orderdate >'2024-01-01';
##tesk 9 b having product
select *from reviews limit 5;
select*from order_details limit 5;
### tesk 9 b find products with average rating
select `produt Id`as product_id,
avg(rating)as
average_rating
from reviews
group by `produt Id`
having avg(rating) > 4;
## 9c rank protucd by total sale
select
p.`product id`,
p.productname,
sum(od.quantity*od.unitprice)as total_sales
from product p
join order_details od
on p.`product id` = od.produtId
group by p.`product id`,
p.productname
order by total_sales desc;
##10 a tesk identifying high value customer
## total customer spenting
use amazon_fresh;
select
c.customerId, c.name,
sum(o. orderamount) as 
total_spending
from customers c
join orders o
on c.customerId =o.customerId
group by c.customerId, c.name;
##10 b tesk rank customera based on their spending
use amazon_fresh;
desc reviews;
desc order_details;
desc customers;
desc orders;
show columns from product;
## 10 b rank customer
use amazon_fresh;
select c.customerId,c.name,
sum(o.orderamount) as total_spenting,
rank() over (order by sum(o.orderamount)desc)as spending_rank
from customers c
join orders o on c.customerId=o.customerId
group by c.customerId,c.name;
## 10 c (5000 ku mela)
select c.customerId, c.name,
sum(o.orderamount)as total_spending
from customers c
join orders o on c.customerId = o.customerId
group by c.customerId, c.name
having sum(o.orderamount)>5000
order by total_spending desc;
## 11a total revenue per order (join)
use amazon_fresh;
select o.orders as order_id,
sum(od.Quantity*od.unitprice) as total_revenue
from orders o 
join order_details od on o.orders = od.orders
group by o.orders;
##11b customer who placed the most orders in a time prriod
select c.customerId,c.name,
count(o.orders)as total_orders
from customers c
join orders o on c.customerId = o.customerId
where o.orderdate between "2024-01-01" and "2024-12-31"
group by c.customerId ,c.name
order by total_orders desc
limit 10;
## 11 c supplier with the most products in stock
select supplirI as supplier_id,
count(*) as product_count,
sum(StockQuantity) as total_stock
from product
group by supplirI
order by product_count desc
limit 1;
## 12 normalize products to 3 nf
create table category (
category_id int auto_increment primary key,
category_name varchar(100) unique);
create table subcategory (
subcategory_id int auto_increment primary key,
subcategory_name varchar(100),
category_id int,
foreign key (category_id)references category(category_id));
insert into category (category_name)
select distinct category from product where category is not null;
insert into subcategory (subcategory_name,category_id)
select distinct p.subcategory,c.category_id
from product p
join category c on p.category = category_name;

create table producy_new as
select p.`product id` as product_id,p.productname,
s.subcategory_id, p.priceperunit, p.StockQuantity,p.supplirI as supplier_id
from product p 
join category c on p.category = c.category_name
join subcategory s on p.subcategroy=s.subcategory_name and s.category_id = c.category_id;
alter table subcategory modify subcategory_name varchar(100);

## 13 a top 3 products by sales revanue(subquery 
select productname
from product
where `product id` in (
select produtId from(
select produtId
from order_details
group by produtId
order by sum(quantity*unitprice)desc
limit 3
) t
);
## 13 b customers with no orders
select customerId, name
from customers
where customerId not in (
select customerId from orders);
## 14 a cities with highest prime member
select city,count(*) as prime_members
from customers
where primemember ="yes"
group by city
order by prime_members desc
limit 5;
## 14 b top 3 most order categories
select p.category,sum(od.Quantity) as total_ordered
from order_details od
join product p on od.produtId =p.`product id`
group by p.category
order by total_ordered desc
limit 3 ;
#### check
show create table category;
show create table subcategory;
show create table product;
show create table reviews;
show create table suppliers;
select 
table_name,
column_name,
column_key
from information_schema.columns
where table_schema ="amazon_fresh"
order by table_name;
## forien key
select
table_name,
column_name,
referenced_table_name,
referenced_column_name
from
information_schema.key_column_usage
where table_schema ="amazon_fresh"
and referenced_table_name is not null;
alter table product
add column subcategory_id int;

use amazon_fresh;
show tables;