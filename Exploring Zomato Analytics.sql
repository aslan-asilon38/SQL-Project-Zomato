use portfolio;

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(
userid int,
gold_signup_date date); 


select * from goldusers_signup;

INSERT INTO goldusers_signup VALUES 
(1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;

CREATE TABLE users(
userid int,
signup_date date);

select * from users;

INSERT INTO users(userid,signup_date) VALUES 
(1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;

CREATE TABLE sales
(userid int,
created_date date,
product_id int);

 INSERT INTO sales(userid,created_date,product_id) VALUES 
(1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);

select * from sales;

drop table if exists product;

CREATE TABLE product
(product_id int,
product_name varchar(50),
price int);

INSERT INTO product(product_id,product_name,price) VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330); 

select * from product;
select * from sales;
select * from goldusers_signup;
select * from users;

-- ---1. what is the total amount each coustomer spent on zomato?
select a.userid, sum(b.price) as total_amt_spend from sales as a inner join product as b on a.product_id = b.product_id group by userid order by userid;

-- ---2.How many days has each customer visited zomato?
select userid, count(distinct created_date) as customer_visit from sales group by userid;

-- ---3.What was the first product purchased by each customer?
select * from
(select *,rank() over (partition by userid order by created_date) rnk from sales)as a
where rnk=1;

-- ---4.What is the most purchased item on the menu & how many time was it purchased by all customer?
select product_id, count(product_id) from sales group by product_id order by count(product_id) desc;

select userid, count(product_id) as cnt from sales where product_id =
(select product_id from sales group by product_id order by count(product_id) desc limit 1)
group by userid;

-- ---5.Which item was the most popular for each customer?
select * from
(select *,rank() over (partition by userid order by cnt desc) rnk from
(select userid, product_id, count(product_id) as cnt from sales group by userid, product_id)a)b
where rnk= 1;

-- ---6.Which item was purchased first by the customer after they become a member?
select * from
(select C.*,rank() over (partition by userid order by created_date) as rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales as a inner join goldusers_signup As b on a.userid = b.userid and created_date >= gold_signup_date)c)d where rnk =1;

-- ---7.Which item was purchased just before the customer become a member?
select * from
(select C.*,rank() over (partition by userid order by created_date desc) as rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales as a inner join goldusers_signup As b on a.userid = b.userid and created_date <= gold_signup_date)c)d where rnk =1;

-- ---8.What is the total orders and amount spent for each member before they become a member?
select userid, count(created_date) As order_purchased, sum(price) As total_amt_spent from
(select c.*, d.price from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales as a inner join goldusers_signup As b on a.userid = b.userid and created_date <= gold_signup_date)c inner join product d
on c.product_id =d.product_id)e group by userid;

-- ---9.If buying each product generates points for eg.5rs = 2 zomato point and each product has diffrent purchasing points for eg. for p1 5rs.=1 zomato point, for p2 10rs.=5Zomato point and p3 5rs.=1 zomato point, calculate points collected by each customers and for which product most points hav been given till now.alter
select userid, sum(total_points) as total_point_earn from
(select e.*,amt/points as total_points from  
(select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amt from
(select a.*,b.price from sales a inner join product b on a.product_id = b.product_id)c
group by userid,product_id)d)e)f group by userid;    

select * from
(select* ,rank() over(order by total_point_earn desc) rnk from 
(select product_id, sum(total_points) as total_point_earn from
(select e.*,amt/points as total_points from  
(select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amt from
(select a.*,b.price from sales a inner join product b on a.product_id = b.product_id)c
group by userid,product_id)d)e)f group by product_id)f)g where rnk = 1;

-- ---10.In the first one year after a customer joins the gold program(including their join date) irrespective of what the customer has purchased they earn 5 zomato points for every 10rs. spent who earned more 1 or 3 & what was their point earning in their first year?
select c.*, d.price * 0.5 total_points_earn from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales as a inner join goldusers_signup As b on a.userid = b.userid and created_date >= gold_signup_date and created_date <= date_add(year,1,gold_signup_date))c
inner join product d on c.product_id=d.product_id);

-- ---11.rank all the transaction of the customer.
select *,rank()over (partition by userid order by created_date) rnk from sales;

-- ---12.rank all the transaction for each member whenever they are a zomato gold member for every non gold member transaction mark as NA
select c.*, case when gold_signup_date is null then 'NA' else rank() over (partition by userid order by created_date desc) end as rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales as a left join goldusers_signup As b on a.userid = b.userid and created_date >= gold_signup_date)c; 