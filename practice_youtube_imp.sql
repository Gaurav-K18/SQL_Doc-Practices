CREATE DATABASE practice
use practice;

/*find out the no of matches played , wins and lossed */
create table icc_world_cup
(
Team_1 Varchar(20),
Team_2 Varchar(20),
Winner Varchar(20)
);
INSERT INTO icc_world_cup values('India','SL','India');
INSERT INTO icc_world_cup values('SL','Aus','Aus');
INSERT INTO icc_world_cup values('SA','Eng','Eng');
INSERT INTO icc_world_cup values('Eng','NZ','NZ');
INSERT INTO icc_world_cup values('Aus','India','India');

select * from icc_world_cup;

with cte1 as (select distinct team_1  from icc_world_cup 
union 
select distinct team_2 as team_1 from icc_world_cup)
,cte2 as (
select c1.team_1,count(winner) as count_win 
from icc_world_cup iwc full join cte1 as c1 on iwc.Winner=c1.Team_1 group by c1.Team_1  ) 
,cte3 as  ( select  team_1  from icc_world_cup 
union  all
select  team_2 as team_1 from icc_world_cup) 
,cte4 as
(select c2.Team_1,count(c3.team_1) matches_played ,c2.count_win no_of_win 
from cte2 c2 join cte3 c3 on c2.Team_1=c3.Team_1 group by c2.Team_1,c2.count_win)
select *,matches_played-no_of_win as matches_lossed  from cte4

------------------------------------------------------------------------------------------------------------
/* find out the new and repeat customer */
create table  customer_orders (
order_id integer,
customer_id integer,
order_date date,
order_amount integer
);

insert into customer_orders values(1,100,cast('2022-01-01' as date),2000),(2,200,cast('2022-01-01' as date),2500),(3,300,cast('2022-01-01' as date),2100)
,(4,100,cast('2022-01-02' as date),2000),(5,400,cast('2022-01-02' as date),2200),(6,500,cast('2022-01-02' as date),2700)
,(7,100,cast('2022-01-03' as date),3000),(8,400,cast('2022-01-03' as date),1000),(9,600,cast('2022-01-03' as date),3000)

select * from customer_orders;

with cte1 as (
select * ,lag(order_date) over( partition by customer_id order by order_date asc) flag_col 
from customer_orders)
--select * from cte1
,cte2 as (
select *,case when flag_col is null then 1 else 0 end new_cust ,
case when flag_col is not null then 1 else 0 end repet_cust
from cte1)
 --select * from cte2
select order_date, sum(new_cust) as new_cust ,sum(repet_cust) repeat_cust from cte2 
group by order_date;


with cte1 as (
select *, ROW_NUMBER() over(partition by customer_id order by order_date  ) rk
from customer_orders )
,cte2 as (
select order_date,COUNT(customer_id) new_cust
from cte1 
where rk =1
group by order_date)
,cte3 as (
select order_date,COUNT(customer_id) total_cust
from cte1 
group by order_date)
select cte2.order_date,cte2.new_cust ,total_cust- cte2.new_cust
from cte2 join cte3
on cte2.order_date= cte3.order_date;

---------------------------------------------------------------------
/* find out the total visit floor,most visit floor ,distinct of resources by name  */
create table entries ( 
name varchar(20),
address varchar(20),
email varchar(20),
floor int,
resources varchar(10));

insert into entries 
values ('A','Bangalore','A@gmail.com',1,'CPU'),('A','Bangalore','A1@gmail.com',1,'CPU'),('A','Bangalore','A2@gmail.com',2,'DESKTOP')
,('B','Bangalore','B@gmail.com',2,'DESKTOP'),('B','Bangalore','B1@gmail.com',2,'DESKTOP'),('B','Bangalore','B2@gmail.com',1,'MONITOR')

select * from entries;
with cte1 as(
select name, count(email) total_visit  from entries group by name
)
,cte2 as
(select name,floor most_visit_floor,count(floor) as count_floor,
rank() over(partition by name order by count(floor) desc )  rn
from entries group by name,floor )
,cte3 as (select distinct name ,resources from entries)
,cte4 as (select name,STRING_AGG(resources ,',') agg_reso from cte3 group by name)
select C1.NAME,C1.total_visit,c2.most_visit_floor,string_agg(c3.agg_reso,',')
from cte1 c1 join cte2 c2 on c1.name=c2.name join cte4  c3 on c1.name=c3.name  where rn=1
group by C1.NAME,C1.total_visit,c2.most_visit_floor 


with cte1 as (
select name ,COUNT(name) ct1
from entries 
group by name)
,cte2 as (
select name ,floor, COUNT(floor) ct2
from entries
group by name ,floor)
,cte3 as (
select * ,MAX(ct2) over(partition by name) ct3
from cte2)
,cte5 as (
select distinct name , resources
from entries)
select cte1.name , ct1 as total_visit , cte3.floor as mostVisitFloor,
STRING_AGG(cte5.resources,',')
from cte1 join cte3 
on cte1.name = cte3.name
join cte5 on cte1.name= cte5.name
where cte3.ct2 = cte3.ct3
group by cte1.name,ct1,cte3.floor


--using stuff
WITH cte1 AS (
  SELECT name, COUNT(email) AS total_visit
  FROM entries
  GROUP BY name
),
cte2 AS (
  SELECT
    name,
    FLOOR AS most_visit_floor,
    COUNT(floor) AS count_floor,
    RANK() OVER (PARTITION BY name ORDER BY COUNT(floor) DESC) AS rn
  FROM entries
  GROUP BY name, FLOOR
),
cte3 AS (
  SELECT DISTINCT name, resources
  FROM entries
),
cte4 AS (
  SELECT
    name,
    (
      SELECT STUFF((
        SELECT ',' + resources
        FROM cte3 AS sub
        WHERE sub.name = cte3.name
        FOR XML PATH(''), TYPE
      ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
    ) AS agg_reso
  FROM cte3
  GROUP BY name
)

SELECT
  c1.NAME,
  c1.total_visit,
  CONVERT(INT, c2.most_visit_floor) AS most_visit_floor,
  c4.agg_reso AS concatenated_resources
FROM cte1 c1
JOIN cte2 c2 ON c1.name = c2.name
JOIN cte4 c4 ON c1.name = c4.name
WHERE rn = 1;

-------------------------------------------------------------------------------------------------------------------------------------------

use AdventureWorks2019
select * from [Sales].[SalesTaxRate]

select SalesTaxRateID,TaxRate,sum(taxrate) over(order by taxrate desc range  between unbounded preceding and current row)
from [Sales].[SalesTaxRate] 
group by SalesTaxRateID,TaxRate

with cte1 as (
select SalesTaxRateID,TaxRate,sum(SalesTaxRateID) over(order by salestaxrateid asc ROWS BETWEEN 1 PRECEDING AND current row) as moving_avg
from [Sales].[SalesTaxRate] 
group by SalesTaxRateID,TaxRate)
select salestaxrateid,taxrate,moving_avg/2 from cte1

WITH cte1 AS (
    SELECT
        SalesTaxRateID,
        TaxRate,
        SUM(SalesTaxRateID) OVER (ORDER BY SalesTaxRateID ASC ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS moving_sum
    FROM [Sales].[SalesTaxRate]
)
SELECT
    SalesTaxRateID,
    TaxRate,
 (  moving_sum*1.0) /2
FROM cte1;


-----------------------------------------------------------------------------------------------------------
-- https://www.youtube.com/watch?v=SfzbR69LquU&list=PLBTZqjSKn0IeKBQDjLmzisazhqQy4iGkb&index=6
use practice
CREATE TABLE person$ (
    PersonID INT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    Score INT
);

INSERT INTO person$ (PersonID, Name, Email, Score) VALUES
(1, 'Alice', 'alice2018@hotmail.com', 88),
(2, 'Bob', 'bob2018@hotmail.com', 11),
(3, 'Davis', 'davis2018@hotmail.com', 27),
(4, 'Tara', 'tara2018@hotmail.com', 45),
(5, 'John', 'john2018@hotmail.com', 63);

CREATE TABLE friends$ (
    PersonID INT,
    FriendID INT,
    PRIMARY KEY (PersonID, FriendID)
);

INSERT INTO friends$ (PersonID, FriendID) VALUES
(1, 2),
(1, 3),
(2, 1),
(2, 3),
(3, 5),
(4, 2),
(4, 3),
(4, 5);

/* write query to find personID ,NAME ,no of frieds,sum of marks of person who have 
friends with total score greater than 100  */

select  * from person$;
select * from friends$;

with cte1 as (
select p.personid as personid,p.name 
, count(f.personid) no_of_friends 
from person$ p join friends$ f on p.personid=f.personid group by p.personid,p.name)
,cte2 as
(select f.personid as personid,sum(p.score)  over(partition by f.personid) flag
from person$ p join friends$ f on p.personid=f.friendid )
select distinct c1.personid,c1.name ,no_of_friends ,flag from cte1 c1 join cte2 c2 on c1.personid =c2.personid
where flag >= 100

--------------------------------------------------------------------------------
Create table  Trips (id int, client_id int, driver_id int, city_id int, status varchar(50), request_at varchar(50));
Create table Users (users_id int, banned varchar(50), role varchar(50));
Truncate table Trips;
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('1', '1', '10', '1', 'completed', '2013-10-01');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('2', '2', '11', '1', 'cancelled_by_driver', '2013-10-01');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('3', '3', '12', '6', 'completed', '2013-10-01');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('4', '4', '13', '6', 'cancelled_by_client', '2013-10-01');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('5', '1', '10', '1', 'completed', '2013-10-02');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('6', '2', '11', '6', 'completed', '2013-10-02');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('7', '3', '12', '6', 'completed', '2013-10-02');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('8', '2', '12', '12', 'completed', '2013-10-03');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('9', '3', '10', '12', 'completed', '2013-10-03');
insert into Trips (id, client_id, driver_id, city_id, status, request_at) values ('10', '4', '13', '12', 'cancelled_by_driver', '2013-10-03');
Truncate table Users;
insert into Users (users_id, banned, role) values ('1', 'No', 'client');
insert into Users (users_id, banned, role) values ('2', 'Yes', 'client');
insert into Users (users_id, banned, role) values ('3', 'No', 'client');
insert into Users (users_id, banned, role) values ('4', 'No', 'client');
insert into Users (users_id, banned, role) values ('10', 'No', 'driver');
insert into Users (users_id, banned, role) values ('11', 'No', 'driver');
insert into Users (users_id, banned, role) values ('12', 'No', 'driver');
insert into Users (users_id, banned, role) values ('13', 'No', 'driver');

select * from Trips;
select * from Users;

with cte1 as (
select request_at,count(client_id) no_o_trips
from Trips t 
join Users u on t.client_id=u.users_id --and t.client_id=u.users_id
where t.client_id not in (select users_id from users where banned='yes')
group by request_at)
, cte2 as 
(select request_at,count(status) count_status from Trips 
where status like '%cancelled%'  
and client_id  not in (select users_id from users where banned='yes')
group by request_at )
--select * from cte1 c1 full outer join  cte2 c2 on c1.request_at=c2.request_at 
select c1.request_at,isnull(c2.count_status,0)*1.0/isnull(c1.no_o_trips,0) 
from cte1 c1 full outer join  cte2 c2 on c1.request_at=c2.request_at 
--group by c1.request_at


WITH cte1 AS (
    SELECT
        request_at,
        COUNT(client_id) AS no_o_trips
    FROM Trips t
    JOIN Users u ON t.client_id = u.users_id
    WHERE t.client_id NOT IN (SELECT users_id FROM users WHERE banned = 'yes')
    GROUP BY request_at
),
cte2 AS (
    SELECT
        request_at,
        COUNT(status) AS count_status
    FROM Trips
    WHERE status LIKE '%cancelled%' AND client_id NOT IN (SELECT users_id FROM users WHERE banned = 'yes')
    GROUP BY request_at
)
SELECT
    c1.request_at,
    CASE
        WHEN c1.no_o_trips = 0 THEN NULL  -- Handle division by zero
        ELSE c2.count_status * 1.0 / c1.no_o_trips  -- Multiply by 1.0 to ensure decimal division
    END AS cancelled_ratio
FROM cte1 c1
FULL OUTER JOIN cte2 c2 ON c1.request_at = c2.request_at;

--------------------------------------------------------------------------------------------------------------
use practice
/* find out the hightest run score (hightst run should be consider 
as frist score and second score)
player by group_id if there is two same run scorer player
for same group id consider the lowest player id record */ 
create table players
(player_id int,
group_id int)

insert into players values (15,1);
insert into players values (25,1);
insert into players values (30,1);
insert into players values (45,1);
insert into players values (10,2);
insert into players values (35,2);
insert into players values (50,2);
insert into players values (20,3);
insert into players values (40,3);

create table matches
(
match_id int,
first_player int,
second_player int,
first_score int,
second_score int)

insert into matches values (1,15,45,3,0);
insert into matches values (2,30,25,1,2);
insert into matches values (3,30,15,2,0);
insert into matches values (4,40,20,5,2);
insert into matches values (5,35,50,1,1);

select * from players;
select  * from matches;

with cte1 as(
select first_player player_id,first_score score from matches 
union all
select second_player player_id,second_score score from matches)
,cte2 as (
select t1.player_id,t2.group_id,sum(score)  main_score 
from cte1 t1 full outer join players t2 on t1.player_id =t2.player_id 
group by t1.player_id ,t2.group_id )
,cte3 as(
select * ,rank() over(partition by group_id order by main_score desc,player_id) rank_1
,rank() over(partition by group_id order by player_id ) rank_2 from cte2 )
--,cte4 as (
select player_id,group_id,main_score ,rank_1,min(player_id) over(partition by group_id) min_id 
from cte3 where rank_1 =1 

--------------------------------------------------------------------------------------------------------------
use practice
create table users_tbl2 (
user_id         int     ,
 join_date       date    ,
 favorite_brand  varchar(50));

 create table orders (
 order_id       int     ,
 order_date     date    ,
 item_id        int     ,
 buyer_id       int     ,
 seller_id      int 
 );

 create table items
 (
 item_id        int     ,
 item_brand     varchar(50)
 );


 insert into users_tbl2 values (1,'2019-01-01','Lenovo'),(2,'2019-02-09','Samsung'),(3,'2019-01-19','LG'),(4,'2019-05-21','HP');

 insert into items values (1,'Samsung'),(2,'Lenovo'),(3,'LG'),(4,'HP');

 insert into orders values (1,'2019-08-01',4,1,2),(2,'2019-08-02',2,1,3),(3,'2019-08-03',3,2,3),(4,'2019-08-04',1,4,2)
 ,(5,'2019-08-04',1,3,4),(6,'2019-08-05',2,2,4);

 select * from users_tbl2;
 select * from orders;
 select * from items;
 
 -- Get flag for all the user who brought first item is favorite item OR not
 with cte1 as (
 select * , rank() over(partition by buyer_id order by order_date) as rk1
 from orders )
 select *,
 case when favorite_brand = item_brand then 1 else 0 end 
 from cte1 t1
 right join users_tbl2  t2 on t1.buyer_id = t2.user_id and t1.rk1 = 1
 join items t3 on t3.item_id = t1.item_id

-------------------------------------------------------------------------------------------
use practice

create table tasks2 (
date_value date,
state varchar(10)
);

insert into tasks2  values ('2019-01-01','success'),('2019-01-02','success'),('2019-01-03','success'),('2019-01-04','fail')
,('2019-01-05','fail'),('2019-01-06','success')

/* if after 2019-01-06 there is 2019-03-07 and we want 2019-01-06 as startdate and 2019-03-08
as enddate this query did not work */
select * from tasks2;
with cte1 as (
select date_value,state ,rank() over(partition by state order by date_value) ranks,
DATEADD(day,-1 *(rank() over(partition by state order by date_value)),date_value) flag_1
from tasks2 
)
select min(date_value) as start_date,max(date_value) as max_date ,state 
from cte1
group by flag_1, state order by start_date


/* this solution is risky if i get rk2 same even if interval is different like 
if there is again one record for success like 2019-03-07  success
then rk2 value for both the date 2019-01-06 and 2019-03-07 is 2 which form the group and then we 
got the 2019-01-06 as startdate and 2019-03-07 as enddate its true if we don't care about the 
sequential date like 1,2,3,4,5 but if we care then its wrong so instead of getting number values
get date value as above to  do the group by */
with cte1 as (
select *,
SUM(1) over(partition by state order by date_value) rk 
from tasks2)
,cte2 as (
select * , DAY(date_value) - rk as rk2
from cte1)
select MIN(date_value) as start_date,MAX(date_value) as end_date ,MAX(state)
from cte2 
group by rk2;


/* IMP 
here is the query if there is any gap between the dates how can we tackle that here i have consider
like if there is state missing for the perticular date or not present for the perticular date 
i will take the above state for that missing date */

WITH RecursiveDates AS (
    SELECT 
        CAST('2019-01-01' AS DATE) AS start_value,
        CAST('2019-01-01' AS DATE) AS date_value
    UNION ALL
    SELECT 
        CAST(DATEADD(DAY, 1, start_value) AS DATE),
        CAST(DATEADD(DAY, 1, start_value) AS DATE)
    FROM RecursiveDates 
    WHERE start_value < '2019-01-11'
)
-- select * from RecursiveDates
,FilledCTE AS (
    SELECT 
        rd.start_value,
        rd.date_value,
        t.state,
        ROW_NUMBER() OVER (ORDER BY rd.start_value) AS rn
    FROM RecursiveDates rd
    LEFT JOIN tasks2 t ON rd.date_value = t.date_value
) --select * from FilledCTE
SELECT 
    start_value,
    date_value,state,FilledCTE.rn,
    COALESCE(
        state,
        (
            SELECT TOP 1 state
            FROM FilledCTE prev
            WHERE prev.rn < FilledCTE.rn
                AND prev.state IS NOT NULL
            ORDER BY prev.rn DESC
        )
    ) AS filled_state
FROM FilledCTE
ORDER BY start_value;

--------------------------------------------------------------------------------------------------------
use practice
Create Table Trade_tbl(
TRADE_ID varchar(20),
Trade_Timestamp time,
Trade_Stock varchar(20),
Quantity int,
Price Float
)

Insert into Trade_tbl Values('TRADE1','10:01:05','ITJunction4All',100,20)
Insert into Trade_tbl Values('TRADE2','10:01:06','ITJunction4All',20,15)
Insert into Trade_tbl Values('TRADE3','10:01:08','ITJunction4All',150,30)
Insert into Trade_tbl Values('TRADE4','10:01:09','ITJunction4All',300,32)
Insert into Trade_tbl Values('TRADE5','10:10:00','ITJunction4All',-100,19)
Insert into Trade_tbl Values('TRADE6','10:10:01','ITJunction4All',-300,19)

select * from Trade_tbl;
with cte1 as(
select t1.trade_id trade_s_id,t2.TRADE_ID trade_e_id,
t1.price t1_price,t2.Price t2_price, 
t1.Trade_Timestamp trade_timestamp_s,t2.Trade_Timestamp trade_timestamp_e,
abs(((t1.Price-t2.Price)/t1.Price)*100) per_diff,
abs(DATEDIFF(second,t1.Trade_Timestamp,t2.Trade_Timestamp)) diff_s 
,right(t1.TRADE_ID,1) t1_ind ,RIGHT(t2.TRADE_ID,1) t2_ind
from Trade_tbl t1 cross join Trade_tbl t2 

)
select trade_s_id,trade_e_id,t1_price,t2_price,per_diff from cte1
where diff_s<=10 and diff_s !=0 and per_diff>=10
and trade_timestamp_s<trade_timestamp_e
-------------------------------------------------------------------------------------------------------------
/*IMP PROBLEM DYNAMIC QUERY
  we need to obtain the list of department with avg salary lowar than the overall salary 
  of the company however when calculating the company avg salary 
  you must exclude the salary of the department you are compairing it with .
  for instance when compairing the avg salary of hr department 
  with the company avg salary ,the hr department salary shouldnt be taken into consideration */

use practice
create table emp2(
emp_id int,
emp_name varchar(20),
department_id int,
salary int,
manager_id int,
emp_age int);

insert into emp2
values
(1, 'Ankit', 100,10000, 4, 39);
insert into emp2
values (2, 'Mohit', 100, 15000, 5, 48);
insert into emp2
values (3, 'Vikas', 100, 10000,4,37);
insert into emp2
values (4, 'Rohit', 100, 5000, 2, 16);
insert into emp2
values (5, 'Mudit', 200, 12000, 6,55);
insert into emp2
values (6, 'Agam', 200, 12000,2, 14);
insert into emp2
values (7, 'Sanjay', 200, 9000, 2,13);
insert into emp2
values (8, 'Ashish', 200,5000,2,12);
insert into emp2
values (9, 'Mukesh',300,6000,6,51);
insert into emp2
values (10, 'Rakesh',300,7000,6,50);

select * from emp2;

WITH CTE1 AS(
select distinct dep_id,  avg(salary) AVG_SALARY,COUNT(*) EMP_COUNT,SUM(SALARY) SUM_SALARY
from emp2  group by dep_id)
select * from (
select t1.dep_id, T1.AVG_SALARY,sum(t2.sum_salary)/sum(t2.emp_count) AVG_SALARY_FINAL
from cte1 t1
join cte1 t2 on t1.dep_id!=t2.dep_id
group by t1.dep_id,t1.avg_salary ) final_table
WHERE avg_salary<AVG_SALARY_FINAL

-----------------------------------------------------------------------------
use practice
create table event_status
(
event_time varchar(10),
status varchar(10)
);
insert into event_status 
values
('10:01','on'),('10:02','on'),('10:03','on'),('10:04','off'),('10:07','on'),('10:08','on'),('10:09','off')
,('10:11','on'),('10:12','off');

select * from event_status;

with cte as(
select *,
sum(case when status='on' and lead_status='off' then 1 else 0 end ) 
over(order by event_time asc) group_column
from 
(select * ,lag(status,1,status) over(order by event_time asc) lead_status
from event_status) as A)
select min(event_time) login ,max(event_time) logout ,count(*)-1  on_count from cte
group by group_column 


-------------------------------------------------------------------------------------------
--https://www.youtube.com/watch?v=4MLVfsQEGl0&list=RDCMUCk7NcgnqCmui1AV7MTXZwOw&index=11
/* The table logs the spending history of the users that make purchases from an online shopping 
website which has a desktop and a mobile application 
Write an sql query to find the total number of the users and the total amount spent using mobile 
only and both mobile and desktop together for each date */
create table spending 
(
user_id int,
spend_date date,
platform varchar(10),
amount int
);

insert into spending values(1,'2019-07-01','mobile',100),(1,'2019-07-01','desktop',100),(2,'2019-07-01','mobile',100)
,(2,'2019-07-02','mobile',100),(3,'2019-07-01','desktop',100),(3,'2019-07-02','desktop',100);

select * from spending order by spend_date asc;

with cte1 as (
select spend_date, user_id,max(platform) platform,sum(amount) total_amount 
from spending --max(platform) because if i didn't do that then i need to put platform in group by which affect the hole result set
group by spend_date ,user_id having count(distinct platform) =1 --count(distinct platform) =1 will give only those user which use only one platform 
union all
select spend_date,user_id,'both' as platform,sum(amount) total_amount from spending 
group by spend_date ,user_id having count(distinct platform) =2
union all
select distinct spend_date, null as user_id,'both' as platform,0 as amount from spending   --dummy record
)
select spend_date,platform,sum(total_amount) to_amount,count(distinct user_id) total_user from cte1
group by spend_date,platform
order by spend_date,platform desc

with cte1 as (
select user_id,spend_date,
COUNT(distinct user_id) no_user ,SUM(amount) amount 
,case when COUNT(case when platform = 'mobile' or platform = 'desktop' 
then user_id else null end) =2  then 'both' 
when count(case when platform = 'mobile' then user_id else null end) = 1
then 'mobile' 
when count(case when platform = 'desktop' then user_id else null end) = 1
then 'desktop'end as plat
from spending 
group by spend_date ,user_id
union
select null as user_id, spend_date, null as no_user, 0 as amount ,'both' as plat
from spending)
 select spend_date, COUNT(distinct no_user) , SUM(amount) ,plat from cte1
 group by spend_date  ,plat

---------------------------------------------------------------------------------------------------------------
--https://www.youtube.com/watch?v=51ryMCf-fvU&list=RDCMUCk7NcgnqCmui1AV7MTXZwOw&index=12
create table billings 
(
emp_name varchar(10),
bill_date date,
bill_rate int
);

insert into billings values
('Sachin','01-JAN-1990',25)
,('Sehwag' ,'01-JAN-1989', 15)
,('Dhoni' ,'01-JAN-1989', 20)
,('Sachin' ,'05-Feb-1991', 30)
;

create table HoursWorked 
(
emp_name varchar(20),
work_date date,
bill_hrs int
);
insert into HoursWorked values
('Sachin', '01-JUL-1990' ,3)
,('Sachin', '01-AUG-1990', 5)
,('Sehwag','01-JUL-1990', 2)
,('Sachin','01-JUL-1991', 4)
,('sachin','1991-02-05',1)

select * from billings ;
select * from  HoursWorked;
 --calculate the total charge for the emp based bill_date and work_date
 /* like if bill_date is '2001-01-01' and work_date is '2001-04-05' then price of that bill date
 as soon as the new bill_date is found for the same person and have the work_date after that day
 or the same day we need to consider that like for the same person bill date is '2001-06-01' and 
 work_date is '2001-06-01' that bill_date rate should be applid to that work_date hours */
with cte1 as (
select distinct t1.emp_name,bill_date,bill_rate,
lead(dateadd(day,-1,bill_date),1,
dateadd(day,1,getdate())) over(partition by t1.emp_name order by bill_date asc) lead_flag --dateadd because if work date is same as work_date then it will not satisfy the where condition of  bill_date<work_date and lead_flag>work_date
from billings t1 
)
,cte2 as (
select t1.emp_name, bill_rate*bill_hrs total_work_amount
from cte1 t1 join HoursWorked t2 on t1.emp_name= t2.emp_name 
where bill_date<=work_date and lead_flag>work_date)
select emp_name,sum(total_work_amount) from cte2 group by emp_name


-- logic is like frist create the start and end date column to get the rate based on that
with cte1 as (
select emp_name ,bill_date , bill_rate,
LEAD(dateadd(day,-1,bill_date),1,'1999-01-01') 
over(partition by emp_name order by bill_date asc) end_date -- to get start and end date for compaire
from billings)
select  t1.emp_name , sum(bill_rate * bill_hrs)
from cte1 t1 
join HoursWorked hw 
on  t1.emp_name = hw.emp_name and hw.work_date  between t1.bill_date and t1.end_date 
group by t1.emp_name 

----------------------------------------------------------------------------------------------------
--write sql to find detail of employee with third highst salary in each department
--in case there are less than 3 employee in department then employee detail with lowest salary in dept

CREATE TABLE [emp2](
 [emp_id] [int] NULL,
 [emp_name] [varchar](50) NULL,
 [salary] [int] NULL,
 [manager_id] [int] NULL,
 [emp_age] [int] NULL,
 [dep_id] [int] NULL,
 [dep_name] [varchar](20) NULL,
 [gender] [varchar](10) NULL
) ;
insert into emp2 values(1,'Ankit',14300,4,39,100,'Analytics','Female')
insert into emp2 values(2,'Mohit',14000,5,48,200,'IT','Male')
insert into emp2 values(3,'Vikas',12100,4,37,100,'Analytics','Female')
insert into emp2 values(4,'Rohit',7260,2,16,100,'Analytics','Female')
insert into emp2 values(5,'Mudit',15000,6,55,200,'IT','Male')
insert into emp2 values(6,'Agam',15600,2,14,200,'IT','Male')
insert into emp2 values(7,'Sanjay',12000,2,13,200,'IT','Male')
insert into emp2 values(8,'Ashish',7200,2,12,200,'IT','Male')
insert into emp2 values(9,'Mukesh',7000,6,51,300,'HR','Male')
insert into emp2 values(10,'Rakesh',8000,6,50,300,'HR','Male')
insert into emp2 values(11,'Akhil',4000,1,31,500,'Ops','Male')
select * from emp2;
--#1
with cte as (
select * ,DENSE_RANK() over(partition by dep_id order by salary desc) as rk,
count(1) over(partition by dep_id) ct  from emp2 )
select * from cte
where rk=3 or (ct<3 and ct=rk)
--#2
with cte as (
select * ,DENSE_RANK() over(partition by dep_id order by salary desc) as rk from emp2)
,cte2 as (
select *,max(rk) over(partition by dep_id) ct  from cte)
select * from cte2
where rk=3 or (ct<3 and ct=rk)


-------------------------------------------------------------------------------------------------------
--find the missing qurter for store
CREATE TABLE STORES (
Store varchar(10),
Quarter varchar(10),
Amount int);

INSERT INTO STORES (Store, Quarter, Amount)
VALUES ('S1', 'Q1', 200),
('S1', 'Q2', 300),
('S1', 'Q4', 400),
('S2', 'Q1', 500),
('S2', 'Q3', 600),
('S2', 'Q4', 700),
('S3', 'Q1', 800),
('S3', 'Q2', 750),
('S3', 'Q3', 900)
/* the logic here to solve is as we know we need to find the missing quarter so if i get all the
quarter with all the store like 
for store S1 all the quarter like (Q1,Q2,Q3) same for all store then i will join the origenal 
table with this table which contain store with all the Qurter on both the joining condition of
store and quarter with left join so that if for the store qurter is not present even after that 
i will get that record with null like if fot the store1 qurter 3 is missing i will get record like
s1 q1 s1    q1
s1 q2 s1    q2
s1 q3 null null 
s1 q4 s1    q4  so where ever there is null i can say that quarter is missing */
select * from STORES;
with cte1 as (
select t1.Quarter t1_Q,t2.Quarter T2_Q,T1.Store t1_s,t2.Store t2_s
from STORES t1 cross join STORES t2 
)
,cte2 AS (
select t3.T1_Q,T3.T2_Q,t2_s,T4.Store t4_s,T4.Quarter t4_q 
from cte1 t3 left join STORES t4 on t3.T1_Q=t4.Quarter AND T3.T2_S=T4.Store)
select distinct  t2_s store ,t1_q quarter from cte2
where t4_s is null

--method 2 
select Store,'Q' + cast(10-sum(cast(RIGHT(Quarter,1)as int)) as char(2)) from STORES  ---1+2+3+4=10 thats why we took 10
group by Store


--------------------------------------------------------------------------

create table input (
id int,
formula varchar(10),
value int
)
insert into input values (1,'1+4',10),(2,'2+1',5),(3,'3-2',40),(4,'4-1',20);

select * from input;

with cte1 as (
select left(formula,1) left_value,right(formula,1)right_value,SUBSTRING(formula,2,1) operator 
from input)
,cte2 as (
select left_value,right_value,operator,id as id_1,formula formula_true, value value_1 
from cte1 t1 join input t2 on t1.left_value=t2.id)
,cte3 as(
select left_value,right_value,operator,id_1, formula_true, value_1 ,t4.value as value_2 
from cte2 t3 join input t4 on t3.right_value=t4.id)
--select * from cte3
,cte4 as(
select  left_value,formula_true,
case when operator='+' then value_1 + value_2 else value_1 - value_2 end as new_value
 from cte3)
select t6.id,formula_true,t6.value,new_value from cte4 t5 join input t6 on t5.formula_true=t6.formula

--------------------------------------------------------------------------------------------------------------------------

--recursive cte

with cte as (
select 1 as num
union all
select num + 1 
from cte 
where num<6 )
select * from cte

-----------------------------------------------------------------------------------------------------------------------------
--https://www.youtube.com/watch?v=ewmEHQSQYRM&list=PLBTZqjSKn0IeKBQDjLmzisazhqQy4iGkb&index=12

create table sales (
product_id int,
period_start date,
period_end date,
average_daily_sales int
);

insert into sales values(1,'2019-01-25','2019-02-28',100),(2,'2018-12-01','2020-01-01',10),(3,'2019-12-01','2020-01-31',1);

/* total sales by year like for third row 3	2019-12-01	2020-01-31	1
there are 62 days 2019 - 31 day and 2020 -- 31 day */

select * from sales;

with cte1 as 
(select min(period_start) start_day,max(period_end) end_day from sales
union all
select DATEADD(DAY,1,start_day) ,end_day from cte1 
where start_day < end_day)
,cte2 as(
select product_id,start_day,period_start,period_end,average_daily_sales
from cte1 t1 
join sales t2 on start_day between period_start and period_end
 )
select product_id,YEAR(start_day) year,SUM(average_daily_sales) total_avg_sales
from cte2 
group by product_id,YEAR(start_day)
order by product_id,YEAR(start_day)
option(maxrecursion 1000)


---------------------------------------------------------------------------------------------------------
CREATE TABLE flights 
(
    cid VARCHAR(512),
    fid VARCHAR(512),
    origin VARCHAR(512),
    Destination VARCHAR(512)
);

INSERT INTO flights (cid, fid, origin, Destination) VALUES ('1', 'f1', 'Del', 'Hyd');
INSERT INTO flights (cid, fid, origin, Destination) VALUES ('1', 'f2', 'Hyd', 'Blr');
INSERT INTO flights (cid, fid, origin, Destination) VALUES ('2', 'f3', 'Mum', 'Agra');
INSERT INTO flights (cid, fid, origin, Destination) VALUES ('2', 'f4', 'Agra', 'Kol');

select * from flights;
select f1.cid,f1.origin f1_org,f1.Destination f1_dest,f2.origin f2_org,f2.Destination f2_dest
from flights f1
join flights f2 on f1.Destination=f2.origin;


----------------------------------------------------------------------------------------

CREATE TABLE sales2 
(
    order_date date,
    customer VARCHAR(512),
    qty INT
);

INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-01-01', 'C1', '20');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-01-01', 'C2', '30');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-02-01', 'C1', '10');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-02-01', 'C3', '15');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-03-01', 'C5', '19');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-03-01', 'C4', '10');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-04-01', 'C3', '13');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-04-01', 'C5', '15');
INSERT INTO sales2 (order_date, customer, qty) VALUES ('2021-04-01', 'C6', '10');
-- find out the new customer by month
select * from sales2;

with cte1 as (
select *,MONTH(order_date) flag3 ,
lead(customer) over(partition by customer order by order_date desc) flag
from sales2)
,cte2 as(
select flag3, case when flag is null then 1 else 0 end flag2 from cte1)
select flag3 ,sum(flag2) from cte2 
group by flag3


-------------------------------------------------------------------------------------------------------------
--https://www.youtube.com/watch?v=9Kh7EnZlhUg&list=PLBTZqjSKn0IeKBQDjLmzisazhqQy4iGkb&index=13
-- find out product pair purchase together 
create table orders1
(
order_id int,
customer_id int,
product_id int,
);

insert into orders1 VALUES 
(1, 1, 1),
(1, 1, 2),
(1, 1, 3),
(2, 2, 1),
(2, 2, 2),
(2, 2, 4),
(3, 1, 5);

create table products (
id int,
name varchar(10)
);
insert into products VALUES 
(1, 'A'),
(2, 'B'),
(3, 'C'),
(4, 'D'),
(5, 'E');


select * from orders1;
select * from products;

with cte1 as(
select o1.order_id ,o1.product_id p1, o2.product_id p2 
from orders1 o1 inner join orders1 o2 on o1.order_id=o2.order_id
where  o1.product_id!=o2.product_id and o1.product_id<o2.product_id)
,cte2 as (
select p1 ,p2 ,count(order_id) count_product from cte1
group by p1,p2)
select t2.name +' ' +t3.name,count_product 
from cte2 t1 inner join products t2 on t1.p1=t2.id inner join 
products t3 on t1.p2=t3.id

-------------------------------------------------------------------------------------------------------------

/*
Given the following two tables, return the fraction of users, rounded to two decimal places,
who accessed Amazon music and upgraded to prime membership within the first 30 days of signing up.
p means prime */ 

create table users1
(
user_id integer,
name varchar(20),
join_date date
);
insert into users1
values (1, 'Jon', CAST('2-14-20' AS date)), 
(2, 'Jane', CAST('2-14-20' AS date)), 
(3, 'Jill', CAST('2-15-20' AS date)), 
(4, 'Josh', CAST('2-15-20' AS date)), 
(5, 'Jean', CAST('2-16-20' AS date)), 
(6, 'Justin', CAST('2-17-20' AS date)),
(7, 'Jeremy', CAST('2-18-20' AS date));

create table events
(
user_id integer,
type varchar(10),
access_date date
);

insert into events values
(1, 'Pay', CAST('3-1-20' AS date)), 
(2, 'Music', CAST('3-2-20' AS date)), 
(2, 'P', CAST('3-12-20' AS date)),
(3, 'Music', CAST('3-15-20' AS date)), 
(4, 'Music', CAST('3-15-20' AS date)), 
(1, 'P', CAST('3-16-20' AS date)), 
(3, 'P', CAST('3-22-20' AS date));

select * from users1
select * from events;


with cte1 as (
    select *,
    case when type = 'Music' then type end as music,
    case when type = 'P' then type end as p,
    case when type = 'Music' then access_date end as music_date,
    case when type = 'P' then access_date end as p_date
    from events
),
cte2 as (
    select user_id, MAX(music) music, MAX(p) p, MAX(music_date) music_date, MAX(p_date) p_date
    from cte1
    group by user_id
    having MAX(music_date) is not null and MAX(p_date) is not null
),
cte3 as (
    select t1.user_id, music, p, datediff(day, join_date, music_date) music_diff, datediff(day, join_date, p_date) p_diff
    from cte2 t1
    join users1 t2 on t1.user_id = t2.user_id
),
cte4 as (
    select COUNT(*) count_prime
    from cte3
    where music_diff < 30 and p_diff < 30
),
cte5 as (
    select COUNT(*) total_count
    from Users
)
select 
    cast((select count_prime from cte4)AS float) / cast((select total_count from cte5) AS float) 
	as ratio;

----------------------------------------------------------------------------------------
use practice
CREATE TABLE user_interactions (
    user_id varchar(10),
    event varchar(15),
    event_date DATE,
    interaction_type varchar(15),
    game_id varchar(10),
    event_time TIME
);

-- Insert the data
/* find out the category of games 
1) no social interaction (no massage ,emojis or gifts during the game)
2) one sided interaction ( message ,emojis or gifts sent during the game by only one player)
3) both sided interaction without custom_type_messages
4) both sided interaction with custom_type_messages form at least one player  */

INSERT INTO user_interactions 
VALUES
('abc', 'game_start', '2024-01-01', null, 'ab0000', '10:00:00'),
('def', 'game_start', '2024-01-01', null, 'ab0000', '10:00:00'),
('def', 'send_emoji', '2024-01-01', 'emoji1', 'ab0000', '10:03:20'),
('def', 'send_message', '2024-01-01', 'preloaded_quick', 'ab0000', '10:03:49'),
('abc', 'send_gift', '2024-01-01', 'gift1', 'ab0000', '10:04:40'),
('abc', 'game_end', '2024-01-01', NULL, 'ab0000', '10:10:00'),
('def', 'game_end', '2024-01-01', NULL, 'ab0000', '10:10:00'),
('abc', 'game_start', '2024-01-01', null, 'ab9999', '10:00:00'),
('def', 'game_start', '2024-01-01', null, 'ab9999', '10:00:00'),
('abc', 'send_message', '2024-01-01', 'custom_typed', 'ab9999', '10:02:43'),
('abc', 'send_gift', '2024-01-01', 'gift1', 'ab9999', '10:04:40'),
('abc', 'game_end', '2024-01-01', NULL, 'ab9999', '10:10:00'),
('def', 'game_end', '2024-01-01', NULL, 'ab9999', '10:10:00'),
('abc', 'game_start', '2024-01-01', null, 'ab1111', '10:00:00'),
('def', 'game_start', '2024-01-01', null, 'ab1111', '10:00:00'),
('abc', 'game_end', '2024-01-01', NULL, 'ab1111', '10:10:00'),
('def', 'game_end', '2024-01-01', NULL, 'ab1111', '10:10:00'),
('abc', 'game_start', '2024-01-01', null, 'ab1234', '10:00:00'),
('def', 'game_start', '2024-01-01', null, 'ab1234', '10:00:00'),
('abc', 'send_message', '2024-01-01', 'custom_typed', 'ab1234', '10:02:43'),
('def', 'send_emoji', '2024-01-01', 'emoji1', 'ab1234', '10:03:20'),
('def', 'send_message', '2024-01-01', 'preloaded_quick', 'ab1234', '10:03:49'),
('abc', 'send_gift', '2024-01-01', 'gift1', 'ab1234', '10:04:40'),
('abc', 'game_end', '2024-01-01', NULL, 'ab1234', '10:10:00'),
('def', 'game_end', '2024-01-01', NULL, 'ab1234', '10:10:00');

select * from user_interactions

select game_id ,
case when COUNT(interaction_type) = 0 then 'no social interaction'  
when  COUNT(distinct(case when interaction_type IS not null then user_id end)) = 1 
then'one sided interaction'
when COUNT(distinct ( case when interaction_type IS not null then user_id end ))=2 and
count(DISTINCT(case when interaction_type = 'custom_typed' then user_ID END )) = 0 
THEN 'both sided interaction without custom_type_messages'
WHEN COUNT(distinct (case WHEN interaction_type is not null then user_id end )) =2 
and count(distinct(case when interaction_type = 'custom_typed' then user_id end)) >=1
then 'both sided interaction with custom_type_messages form at least one player'
end as condition
from user_interactions
group by game_id 

--------------------------------------------------------------------------------------------
-- https://www.youtube.com/watch?v=J9wwR4huimI 
/* find out the record which is not comman in both the table based on id and say mismatch if 
id is comman but name is different */
use practice

create table source(id int, name varchar(5))
create table target(id int, name varchar(5))
insert into source values(1,'A'),(2,'B'),(3,'C'),(4,'D')
insert into target values(1,'A'),(2,'B'),(4,'X'),(5,'F');

select * from source;
select * from target;

with cte1 as (
select s.id ,s.name, t.id as new_id
from source s 
left join target t on s.id= t.id)
,cte2 as (
select t.id,t.name,s.id as new_id
from source s 
right join target t on s.id= t.id)
,cte3 as (
select s.id 
 from source s 
 join target t on s.id= t.id and s.name<> t.name)
select id,'new in source' as status
from cte1 where new_id is null 
union all
select id,'new in target' as status from cte2
 where new_id is null 
 union all
 select cte3.id ,'mistmatch' as status
 from cte3 


 ------------------------------------------------------------------------------
-- https://www.youtube.com/watch?v=tVQUsozKkyI
use practice
-- extract first,middle and last name from the customer name 
create table customers  (customer_name varchar(30))
insert into customers values ('Ankit Bansal')
,('Vishal Pratap Singh')
,('Michael'); 

select * from customers
/* logic is 
1)Find the empty spaces so that we can know how many words are their in customer_name
2) use that flag to get the first ,middle and last name
*/

with cte1 as(
select customer_name,LEN(customer_name) - len(REPLACE(customer_name,' ','')) flag
from customers)
select customer_name,flag,
case when flag = 0 then customer_name 
else LEFT(customer_name, charindex(' ',customer_name)) end as name
,charindex(' ',customer_name)
,case when flag<= 1 then null 
else SUBSTRING(customer_name,CHARINDEX(' ',customer_name) +1,
(CHARINDEX(' ',customer_name,charindex(' ',customer_name)+1) - CHARINDEX(' ',customer_name))
) end as middlename,
case when flag = 2 
then RIGHT(customer_name,len(customer_name) -charindex(' ',customer_name,charindex(' ',customer_name)+1))
else null end as last_name
from cte1 


---------------------------------------------------------------------------------------------------

-- https://www.youtube.com/watch?v=d7pZNZbpdo8

select * from emp_attendance;

-- my solution 
with cte1 as(
select employee, dates ,status,
rank() over(partition by employee , status order by dates) rk
from emp_attendance)
, cte2 as( 
select * , 
DATEADD(day,-rk,dates) rk2
From cte1
)
select employee, 
MIN(dates) from_date, MAX(dates) to_date , MAX(status) status
from cte2
group by employee,rk2 
order by employee, from_date;

-- youtube solution 
with cte as 
		(select *, row_number() over(partition by employee order by employee, dates) as rn 
		from emp_attendance),
	cte_present as
		(select *, row_number() over(partition by employee order by employee, dates) rn2
		, rn - row_number() over(partition by employee order by employee, dates) as flag
		from cte where status='PRESENT' ),
	cte_absent as
		(select *, row_number() over(partition by employee order by employee, dates) rn3
		, rn - row_number() over(partition by employee order by employee, dates) as flag
		from cte where status='ABSENT' )
select employee 
, first_value(dates) over(partition by employee, flag order by employee, dates) as from_date 
, last_value(dates) over(partition by employee, flag order by employee, dates
						range between unbounded preceding and unbounded following) as to_date 
, status						
from cte_present
union 
select  employee 
, first_value(dates) over(partition by employee, flag order by employee, dates) as from_date 
, last_value(dates) over(partition by employee, flag order by employee, dates
						range between unbounded preceding and unbounded following) as to_date 
, status						
from cte_absent
order by employee, from_date

------------------------------------------------------------------------------------------------

use practice
select * from users1
CREATE TABLE users2 (
    USER_ID INT PRIMARY KEY,
    USER_NAME VARCHAR(20) NOT NULL,
    USER_STATUS VARCHAR(20) NOT NULL
);

CREATE TABLE logins (
    USER_ID INT,
    LOGIN_TIMESTAMP DATETIME NOT NULL,
    SESSION_ID INT PRIMARY KEY,
    SESSION_SCORE INT,
    FOREIGN KEY (USER_ID) REFERENCES USERS2(USER_ID)
);

-- Users Table
INSERT INTO USERS2 VALUES (1, 'Alice', 'Active');
INSERT INTO USERS2 VALUES (2, 'Bob', 'Inactive');
INSERT INTO USERS2 VALUES (3, 'Charlie', 'Active');
INSERT INTO USERS2  VALUES (4, 'David', 'Active');
INSERT INTO USERS2  VALUES (5, 'Eve', 'Inactive');
INSERT INTO USERS2  VALUES (6, 'Frank', 'Active');
INSERT INTO USERS2  VALUES (7, 'Grace', 'Inactive');
INSERT INTO USERS2  VALUES (8, 'Heidi', 'Active');
INSERT INTO USERS2 VALUES (9, 'Ivan', 'Inactive');
INSERT INTO USERS2 VALUES (10, 'Judy', 'Active');

-- Logins Table 

INSERT INTO LOGINS  VALUES (1, '2023-07-15 09:30:00', 1001, 85);
INSERT INTO LOGINS VALUES (2, '2023-07-22 10:00:00', 1002, 90);
INSERT INTO LOGINS VALUES (3, '2023-08-10 11:15:00', 1003, 75);
INSERT INTO LOGINS VALUES (4, '2023-08-20 14:00:00', 1004, 88);
INSERT INTO LOGINS  VALUES (5, '2023-09-05 16:45:00', 1005, 82);

INSERT INTO LOGINS  VALUES (6, '2023-10-12 08:30:00', 1006, 77);
INSERT INTO LOGINS  VALUES (7, '2023-11-18 09:00:00', 1007, 81);
INSERT INTO LOGINS VALUES (8, '2023-12-01 10:30:00', 1008, 84);
INSERT INTO LOGINS  VALUES (9, '2023-12-15 13:15:00', 1009, 79);


-- 2024 Q1
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (1, '2024-01-10 07:45:00', 1011, 86);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (2, '2024-01-25 09:30:00', 1012, 89);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (3, '2024-02-05 11:00:00', 1013, 78);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (4, '2024-03-01 14:30:00', 1014, 91);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (5, '2024-03-15 16:00:00', 1015, 83);

INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (6, '2024-04-12 08:00:00', 1016, 80);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (7, '2024-05-18 09:15:00', 1017, 82);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (8, '2024-05-28 10:45:00', 1018, 87);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (9, '2024-06-15 13:30:00', 1019, 76);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (10, '2024-06-25 15:00:00', 1010, 92);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (10, '2024-06-26 15:45:00', 1020, 93);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (10, '2024-06-27 15:00:00', 1021, 92);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (10, '2024-06-28 15:45:00', 1022, 93);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (1, '2024-01-10 07:45:00', 1101, 86);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (3, '2024-01-25 09:30:00', 1102, 89);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (5, '2024-01-15 11:00:00', 1103, 78);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (2, '2023-11-10 07:45:00', 1201, 82);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (4, '2023-11-25 09:30:00', 1202, 84);
INSERT INTO LOGINS (USER_ID, LOGIN_TIMESTAMP, SESSION_ID, SESSION_SCORE) VALUES (6, '2023-11-15 11:00:00', 1203, 80);

select * from users2
select * from LOGINS;

-- 1) managment want to see all the user that did not login in past 5 month


with cte1 as (
select t2.USER_ID,USER_NAME, MAX(LOGIN_TIMESTAMP) max_time, DATEadd(month, -5, GETDATE()) month_back_5
from LOGINS t1
right join users2 t2 on T1.USER_ID = t2.USER_ID
GROUP BY t2.USER_ID,USER_NAME)
select USER_NAME
from cte1
where max_time < month_back_5

/* 2) For the business units quarterly analysis calculate how many users and how many sessions were
at each quarter
Return :- first day of the quarter ,user_cnt , session_cnt */

--Note :- here i have group by quarter and year calculating for each year
select datetrunc(quarter,MIN(login_timestamp)), COUNT(DISTINCT USER_ID),
COUNT(*)
from logins
group by DATEPART(YEAR,LOGIN_TIMESTAMP),DATEPART(QUARTER,LOGIN_TIMESTAMP);

-- 3) Desplay user id's that log-in in January 2024 and did not log-on november 2023
-- return -- user_id
with cte1 as (
select distinct user_id 
from logins 
where datepart(YEAR,login_timestamp) = 2024 and DATEPART(month,login_timestamp) = 1)
,cte2 as (
select distinct user_id 
from logins 
where datepart(YEAR,login_timestamp) = 2023 and DATEPART(month,login_timestamp) = 11)
select USER_ID
from cte1
where USER_ID not in (select USER_ID from cte2);

--4) Add to the query from 2 the percentage change in session from last quarter
-- Return : first day of the quarter, session_cnt, session_cnt_prev ,session_percent_change

with cte1 as(
select datetrunc(quarter,MIN(login_timestamp)) first_day, 
COUNT(*) session_cnt
from logins
group by DATEPART(YEAR,LOGIN_TIMESTAMP),DATEPART(QUARTER,LOGIN_TIMESTAMP))
select  * ,LAG(session_cnt) over(order by first_day) session_cnt_prev,
cast(session_cnt as float)/LAG(session_cnt) over(order by first_day) 
from cte1

------------------------------------------------------------------------------------------------
use practice
CREATE TABLE friends (
    user_id INT,
    friend_id INT
);

-- Insert data into friends table
INSERT INTO friends VALUES
(1, 2),
(1, 3),
(1, 4),
(2, 1),
(3, 1),
(3, 4),
(4, 1),
(4, 3);

-- Create likes table
CREATE TABLE likes (
    user_id INT,
    page_id CHAR(1)
);

-- Insert data into likes table
INSERT INTO likes VALUES
(1, 'A'),
(1, 'B'),
(1, 'C'),
(2, 'A'),
(3, 'B'),
(3, 'C'),
(4, 'B');

select * from friends;
select * from likes;
--https://www.youtube.com/watch?v=aGKzhAkkOP8
-- find the user ids and corresponding page ids	of the pages like by there frinds but not user itself

with cte1 as(
select * from likes)
, cte2 as (
select distinct f.user_id, f.friend_id,l.page_id
from friends f 
join likes l on f.friend_id = l.user_id )
select c2.user_id, c2.page_id
from cte2 c2
left join cte1 c1 on c1.user_id = c2.user_id and c1.page_id = c2.page_id
where c1.user_id is null


------------------------------------------------------------------------------------------------
-- write a query to provide the date for nth occurance of sunday in future from given date
-- datepart
-- sunday - 1
-- monday - 2
-- saturday - 7

declare @today_date date;
declare @n int;
set @today_date = '2022-02-03';
set @n = 3;

select dateadd(week,@n-1,dateadd(day, 8-Datepart(weekday,@today_date),@today_date))

------------------------------------------------------------------------------------------------


CREATE TABLE travel_data (
    customer VARCHAR(10),
    start_loc VARCHAR(50),
    end_loc VARCHAR(50)
);

INSERT INTO travel_data (customer, start_loc, end_loc) VALUES
    ('c1', 'New York', 'Lima'),
    ('c1', 'London', 'New York'),
    ('c1', 'Lima', 'Sao Paulo'),
    ('c1', 'Sao Paulo', 'New Delhi'),
    ('c2', 'Mumbai', 'Hyderabad'),
    ('c2', 'Surat', 'Pune'),
    ('c2', 'Hyderabad', 'Surat'),
    ('c3', 'Kochi', 'Kurnool'),
    ('c3', 'Lucknow', 'Agra'),
    ('c3', 'Agra', 'Jaipur'),
    ('c3', 'Jaipur', 'Kochi');

select * from travel_data;
-- using not exists
with cte1 as (
select customer, start_loc , 'start_loc' as flag
from travel_data t1
where not exists ( select * from travel_data t2 
where t1.customer = t2.customer and t1.start_loc = t2.end_loc)
union 
select customer, end_loc , 'end_loc' as flag
from travel_data t1 
where not exists ( select * from travel_data t2 
where t1.customer = t2.customer and t1.end_loc = t2.start_loc))
, cte2 as(
select customer, 
case when flag= 'start_loc' then start_loc end as start_loc,
case when flag = 'end_loc' then start_loc end  as end_loc
from cte1 )
select customer, MAX(start_loc) , MAX(end_loc)
from cte2 
group by customer ;

-- using union
with cte1 as (
select customer, start_loc as loc,'start_loc' as flag
from travel_data
union all 
select customer, end_loc  as loc, 'end_loc' as flag
from travel_data )
,cte2 as (
select customer, loc,flag,
COUNT(loc) OVER(PARTITION BY customer, loc) count_loc
from cte1 )
select customer, 
max(case when flag ='start_loc' then loc end) as start_loc,
max(case when flag = 'end_loc' then loc end) as end_loc
from cte2 
where count_loc =1
group by customer

-- using self join 
select t1_customer, 
max(case when t2_start_loc IS null then t1_start_loc end)  
,max(case when t3_end_loc IS null then t1_end_loc end)
from (
select t1.customer t1_customer,
t1.start_loc t1_start_loc
, t1.end_loc t1_end_loc
, t2.start_loc t2_start_loc
, t3.end_loc t3_end_loc
from travel_data t1
left join travel_data t2 on t1.customer = t2.customer and t1.start_loc = t2.end_loc
left join travel_data t3 on t1.customer = t3.customer and t1.end_loc = t3.start_loc) as tbl1
group by t1_customer


-----------------------------------------------------------------------------------------
-- https://www.youtube.com/watch?v=MQXfhH1d8K0
create table sku 
(
sku_id int,
price_date date ,
price int
);

insert into sku values 
(1,'2023-02-01',20)
,(1,'2023-02-15',15)
,(1,'2023-03-03',18)
,(1,'2023-03-27',15)
,(1,'2023-04-06',20)

-- CODE TO GET START OF MONTH
SELECT DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS StartOfMonth;
SELECT DATEADD(DAY, 1, EOMONTH(GETDATE(), -1)) AS StartOfMonth;


select * from sku
select * from (
select sku_id,price_date,DATEADD(DAY, 1, EOMONTH(price_date, -1))  start_date,
 CASE WHEN DATEADD(DAY, 1, EOMONTH(price_date, -1)) = price_date THEN price
 when DATEADD(DAY, 1, EOMONTH(price_date, -1)) <> price_date
 then LAG(price) over(partition by sku_id order by price_date) end price,
 ROW_NUMBER() over(partition by sku_id, month(price_date) order by price_date ) rn
from sku
) tbl1 
where rn =1


with cte1 as (
select * from sku
union all 
select sku_id,  dateadd(DAY,1,eomonth(MAX(price_date))),NULL 
from sku  -- the reasone to add this is because we need to find out the price of next month as well 
GROUP BY sku_id)
,cte2 as(
select sku_id, price_date,
case when price IS not null then price 
when price IS null then LAG(price) over(partition by sku_id 
order by price_date) end as price
from cte1 )
,cte3 as (
select sku_id,price_date,DATEADD(DAY, 1, EOMONTH(price_date, -1))  start_date,
 CASE WHEN DATEADD(DAY, 1, EOMONTH(price_date, -1)) = price_date THEN price
 when DATEADD(DAY, 1, EOMONTH(price_date, -1)) <> price_date 
 then LAG(price) over(partition by sku_id order by price_date) end price,
 ROW_NUMBER() over(partition by sku_id, month(price_date) order by price_date ) rn
from cte2) 
select * from cte3 
where rn = 1

-- ankit solution

select * from sku;
with cte1 as(
select * ,datetrunc(month,DATEADD(MONTH,1,price_date)) new_price_date,
ROW_NUMBER() over(Partition by sku_id,month(price_date) order by price_date desc) rn 
from sku)
select sku_id,price_date,price
FROM sku where DATEPART(day,price_date)= 1
union 
select sku_id,new_price_date,price from cte1
where rn =1