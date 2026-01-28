--LeetCode Hard 615 Average Salary: Departments VS Company (mark higher, lower and same)

CREATE TABLE Employee (
    emp_id INT,
    department_id INT
);

CREATE TABLE Salary (
    id int primary key identity(1,1),
    emp_id INT,
    amount INT,
    pay_date DATE
);


INSERT INTO Employee (emp_id, department_id) VALUES
(1, 1),
(2, 1),
(3, 2),
(4, 2),
(5, 1),
(6, 2);


INSERT INTO Salary (emp_id, amount, pay_date) VALUES
-- January salaries
(1, 9000, '2017-01-31'),
(2, 6000, '2017-01-31'),
(3, 10000,'2017-01-31'),
(4, 8000, '2017-01-31'),
(5, 7000, '2017-01-31'),
(6, 9000, '2017-01-31'),

-- February salaries
(1, 9500, '2017-02-28'),
(2, 6500, '2017-02-28'),
(3, 10500,'2017-02-28'),
(4, 8500, '2017-02-28'),
(5, 7200, '2017-02-28'),
(6, 8800, '2017-02-28');

select * from Employee
select * from Salary;

with cte1 as (
select format(pay_date,'yyyy-MM') pay_date ,avg(amount) company_avg
from Salary
group by format(pay_date, 'yyyy-MM') )

,cte2 as (
select e.department_id, format(pay_date, 'yyyy-MM') pay_date, avg(amount) department_avg
from Employee e 
join Salary s on e.emp_id = s.emp_id
group by e.department_id, format(pay_date, 'yyyy-MM'))
select t1.pay_date, t2.department_id,
case 
    when company_avg > department_avg then 'lower'
    when company_avg < department_avg then 'higher'
    else 'same' end 
from cte1 t1
join cte2 t2 on t1.pay_date = t2.pay_date

-------------------------------------------------------------------------------------------------------------------

-- LeetCode Hard 569 "Median Employee Salary" Google Interview SQL
/* 
If the number of employees is odd ? the middle salary
If even ? the two middle salaries (return both rows, not the average)
*/

CREATE TABLE Employee2 (
    id INT,
    company VARCHAR(10),
    salary INT
);

INSERT INTO Employee2 VALUES
(1, 'A', 2341),
(2, 'A', 341),
(3, 'A', 15),
(4, 'A', 15314),
(5, 'A', 451),
(6, 'A', 513),
(7, 'B', 15),
(8, 'B', 13),
(9, 'B', 1154),
(10,'B', 1345),
(11,'B', 1221),
(12,'B', 234),
(13,'C', 2345),
(14,'C', 2645),
(15,'C', 2645),
(16,'C', 2652),
(17,'C', 65);

with cte1 as (
select * ,ROW_NUMBER() over(partition by company order by salary) rn,
COUNT(id) over(partition by company) total_record
from Employee2 )
select *
from cte1 
where (total_record % 2 = 0 and rn between total_record / 2 and (total_record /2 ) + 1)
 or (total_record % 2 = 1 and rn = CEILING(cast(total_record as float) /2));


 WITH cte1 AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY company ORDER BY salary) AS rn,
           COUNT(*) OVER (PARTITION BY company) AS cnt
    FROM Employee2
)
SELECT *
FROM cte1
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 ); -- so if count is 5 then  7/3 = 3 and 6/3 = 3 


------------------------------------------------------------------------------------------------------------------
-- LeetCode Hard 2004 "Number of Seniors and Juniors"

CREATE TABLE Candidates (
    employee_id INT PRIMARY KEY,
    experience VARCHAR(10),   -- 'Senior' or 'Junior'
    salary INT
);

INSERT INTO Candidates (employee_id, experience, salary) VALUES
(1, 'Senior', 20000),
(2, 'Senior', 20000),
(3, 'Senior', 50000),
(4, 'Junior', 40000),
(5, 'Junior', 10000),
(6, 'Junior', 15000);

/*
You have a budget of 70,000.
Hiring rules:
Hire as many Seniors as possible first (lowest salary first)
With the remaining budget, hire as many Juniors as possible
Return how many Seniors and Juniors are hired  */

WITH CTE1 AS (
select * ,
sum(salary) over(order by salary ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RK
from Candidates
where experience  = 'Senior' )
,CTE2 AS (
SELECT COUNT(employee_id) Senior_count, MAX(RK) max_salary
FROM CTE1
WHERE RK <= 70000)
,CTE3 AS (
select * ,
sum(salary) over(order by salary ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RK
from Candidates
where experience  = 'Junior' )
, CTE4 AS (
SELECT COUNT(employee_id) junior_count
FROM CTE3
WHERE RK <= (70000 - (SELECT max_salary FROM CTE2 )))
SELECT Senior_count, 'Senior' FROM CTE2
union 
select junior_count , 'Junior' from CTE4

------------------------------------------------------------------------------------------------------------------

--  Detect users whose values are strictly increasing over time
CREATE TABLE user_metrics (
    user_id INT,
    activity_date DATE,
    value INT
);

INSERT INTO user_metrics (user_id, activity_date, value) VALUES
(1, '2024-01-01', 10),
(1, '2024-01-02', 20),
(1, '2024-01-03', 30),
(2, '2024-01-01', 10),
(2, '2024-01-02', 8),
(2, '2024-01-03', 15),
(3, '2024-01-01', 10);

INSERT INTO user_metrics (user_id, activity_date, value) VALUES
(4, '2024-01-01', -20),
(4, '2024-01-02', -10),
(4, '2024-01-03', 10);

select * from user_metrics;

-- in this query if first value is negative then -20-0 is (-20) and even then next number in increasing order it will not give the 
-- user_id as (lag_value < 0) fail
with cte1 as (
select user_id
, value - lag(value, 1, 0) over(partition by user_id order by activity_date) lag_value
from user_metrics )
select distinct  user_id
from cte1  c1
where not exists (select * from cte1 c2 where c1.user_id = c2.user_id and lag_value < 0)

-- final query
with cte1 as (
select user_id,
value , lag(value) over(partition by user_id order by activity_date) lag_value,
case 
when lag(value) over(partition by user_id order by activity_date) is null then 0 
when value > lag(value) over(partition by user_id order by activity_date) then 0
else 1 end flag
from user_metrics )
select   user_id
from cte1  c1
group by user_id
having max(flag) <> 1
and count(*) > 1  -- exclude if you have only one record

-----------------------------------------------------------------------------------------------

-- LeetCode Hard 2199 Facebook “Finding the Topic of Each Post"

CREATE TABLE Topics (
    topic_id INT ,
    word VARCHAR(50)
);

CREATE TABLE Posts (
    post_id INT PRIMARY KEY,
    content VARCHAR(255)
);

INSERT INTO Topics (topic_id, word) VALUES
(1, 'education'),
(1, 'student'),
(2, 'science'),
(2, 'research'),
(3, 'sports'),
(3, 'football'),
(4, 'technology'),
(4, 'ai');

INSERT INTO Posts (post_id, content) VALUES
(1, 'AI is transforming technology and science'),
(2, 'Football is the most popular sport'),
(3, 'Education is important for every student'),
(4, 'Scientific research drives innovation'),
(5, 'This post has no matching topic');

INSERT INTO Posts (post_id, content) VALUES
(6, 'ronaldo is greate footboaller');

INSERT INTO Posts (post_id, content) VALUES
(7, 'ronaldo is greate footballer');

select * from Topics
select * from Posts;
-- concat('% ',t.word, ' %') :- added space before and after so that footballer should not match
-- concat(' ',p.content,' ') :- added space before and after so that if the starting or ending word is in topic table

with cte1 as (
select distinct p.post_id,t.topic_id
from Topics t
right join Posts p on concat(' ',p.content,' ') like concat('% ',t.word, ' %')  -- added space before and after so that footballer should not match
)
select post_id, isnull(string_agg(topic_id,','), 'ambigious')
from cte1 
group by post_id;

-----------------------------------------------------------------------------------------------
--  YAHOO LeetCode Hard 1412 “Quiet Students in All Exams"
/* 
Never got the highest score
Never got the lowest score
in any exam they appeared in */

CREATE TABLE Student (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50)
);

CREATE TABLE Exam (
    exam_id INT,
    student_id INT,
    score INT,
    PRIMARY KEY (exam_id, student_id)
);

INSERT INTO Student (student_id, student_name) VALUES
(1, 'Daniel'),
(2, 'Jade'),
(3, 'Stella'),
(4, 'Jonathan'),
(5, 'Will');

INSERT INTO Exam (exam_id, student_id, score) VALUES
(10, 1, 70),
(10, 2, 80),
(10, 3, 90),
(20, 1, 80),
(20, 2, 70),
(20, 4, 90),
(30, 1, 90),
(30, 3, 80),
(30, 5, 70);

INSERT INTO Student (student_id, student_name) VALUES
(7, 'pranay')

INSERT INTO Exam (exam_id, student_id, score) VALUES
(10, 6, 80),
(20, 6, 80),
(30, 6, 80)

select * from Student;
select * from Exam;

with cte1 as (
    SELECT
        exam_id,
        student_id,
        score,
        MIN(score) OVER (PARTITION BY exam_id) AS min_score,
        MAX(score) OVER (PARTITION BY exam_id) AS max_score
    FROM Exam)
-- get all the student who got the lowest or highest marks at least once
,cte2 as (
select distinct student_id
from cte1
where score = min_score or score = max_score)
select distinct s.student_id, student_name
from Student s 
join Exam e on s.student_id = e.student_id  -- join so that only get the stude
where s.student_id not in  (select student_id from cte2); -- exclude that student

WITH ranked AS (
    SELECT
        exam_id,
        student_id,
        score,
        MIN(score) OVER (PARTITION BY exam_id) AS min_score,
        MAX(score) OVER (PARTITION BY exam_id) AS max_score
    FROM Exam
)
SELECT r.exam_id,
    s.student_id,
    s.student_name, r.student_id, r.score, r.min_score, r.max_score
FROM Student s
JOIN Exam e
  ON s.student_id = e.student_id
left JOIN ranked r
  ON s.student_id = r.student_id
 AND (r.score = r.min_score OR r.score = r.max_score)
WHERE r.student_id IS NULL
GROUP BY s.student_id, s.student_name
ORDER BY s.student_id;


-------------------------------------------------------------------------------------------------------------

-- LeetCode Hard 2362 “Generate the Invoice"
Create table  Products (product_id int, price int)
Create table  Purchases (invoice_id int, product_id int, quantity int)

insert into Products (product_id, price) values ('1', '100')
insert into Products (product_id, price) values ('2', '200')

insert into Purchases (invoice_id, product_id, quantity) values ('1', '1', '2')
insert into Purchases (invoice_id, product_id, quantity) values ('3', '2', '1')
insert into Purchases (invoice_id, product_id, quantity) values ('2', '2', '3')
insert into Purchases (invoice_id, product_id, quantity) values ('2', '1', '4')
insert into Purchases (invoice_id, product_id, quantity) values ('4', '1', '10')

/* 
Total price of an invoice = sum of (quantity × price) for all products in that invoice.
If two or more invoices tie for the highest price, return the one with the smallest invoice_id. 
*/

select * from  Products 
select * from  Purchases;

-- my query
with cte1 as (
select pp.invoice_id , sum(p.price * pp.quantity ) total_price
from  Products p 
join Purchases pp on p.product_id = pp.product_id
group by pp.invoice_id )
,cte2 as (
select *, rank() over(order by  total_price desc ,invoice_id ) rk
from cte1 )
select p.invoice_id, pp.product_id,  pp.price * p.quantity
from cte2 
join Purchases p on cte2.invoice_id = p.invoice_id
join Products pp on p.product_id = pp.product_id
where rk = 1;

-- use subquery
WITH invoice_total AS (
    SELECT
        pu.invoice_id,
        SUM(pr.price * pu.quantity) AS total_price
    FROM Purchases pu
    JOIN Products pr
        ON pu.product_id = pr.product_id
    GROUP BY pu.invoice_id
)
SELECT
    pu.invoice_id,
    pu.product_id,
    pu.quantity * pr.price AS price
FROM Purchases pu
JOIN Products pr
    ON pu.product_id = pr.product_id
WHERE pu.invoice_id = (
    SELECT TOP 1 invoice_id
    FROM invoice_total
    ORDER BY total_price DESC, invoice_id
);

-- use top , filer the row using the top 
with cte1 as (
SELECT top 1
    pu.invoice_id,
    sum(pu.quantity * pr.price) AS price
FROM Purchases pu
JOIN Products pr
 ON pu.product_id = pr.product_id
 group by   pu.invoice_id 
 order by  price desc, pu.invoice_id )
 select p.invoice_id, p.product_id , p.quantity * pp.price 
 from cte1 c1 
 join Purchases p on c1.invoice_id = p.invoice_id
 join Products pp on pp.product_id = p.product_id;


------------------------------------------------------------------------------------------------------------------
-- GOOGLE LeetCode Hard 1767 “Subtasks That Did Not Execute" Interview SQL Question Explanation | EDS
Create table  Tasks (task_id int, subtasks_count int)
Create table  Executed (task_id int, subtask_id int)
Truncate table Tasks
insert into Tasks (task_id, subtasks_count) values ('1', '3')
insert into Tasks (task_id, subtasks_count) values ('2', '2')
insert into Tasks (task_id, subtasks_count) values ('3', '4')
Truncate table Executed
insert into Executed (task_id, subtask_id) values ('1', '2')
insert into Executed (task_id, subtask_id) values ('3', '1')
insert into Executed (task_id, subtask_id) values ('3', '2')
insert into Executed (task_id, subtask_id) values ('3', '3')
insert into Executed (task_id, subtask_id) values ('3', '4')

-- Find all subtasks that were NOT executed
select * from Tasks
select * from Executed;

-- create recursive cte to get genrate the numbers
with cte1 as (
select 1 as n , max(subtasks_count) max_count from Tasks
union all
select n + 1, max_count
from cte1
where n < max_count )
,cte2 as (
select * 
from cte1 t1
join Tasks t2 on t1.n <= t2.subtasks_count)
select  t1.task_id, t1.n
from cte2 t1
left join Executed t2 on t1.task_id = t2.task_id and t2.subtask_id = t1.n
where t2.task_id is null
order by t1.task_id

-- create recursive cte to get genrate the numbers and use not exists to filter the rows 
with cte1 as (
select 1 as n , max(subtasks_count) max_count from Tasks
union all
select n + 1, max_count
from cte1
where n < max_count )
-- ,cte2 as (
select t2.task_id , t1.n
from cte1 t1
join Tasks t2 on t1.n <= t2.subtasks_count
where not exists ( select 1  from Executed t3 where t1.n = t3.subtask_id and t2.task_id = t3.task_id)
order by t2.task_id

-- use the table directly into the recursive CTE
with cte1 as (
select task_id, subtasks_count from Tasks
union all 
select task_id, subtasks_count - 1 as subtasks_count  -- subtracting 1 to get all the combination
from cte1
where subtasks_count > 1)
select  * 
from cte1 t1
where not exists ( select 1  from Executed t3 where t1.subtasks_count = t3.subtask_id and t1.task_id = t3.task_id)
order by t1.task_id, subtasks_count


-- use the table directly but here we are adding the value to generate the series
with cte1 as (
select task_id,subtasks_count, 1 as n from Tasks
union all
select task_id ,subtasks_count, n  + 1 as n  -- adding 1 to get all combination
from cte1
where n < subtasks_count
)
select t1.task_id, t1.n 
from cte1 t1
where not exists ( select 1  from Executed t3 where t1.n = t3.subtask_id and t1.task_id = t3.task_id)
order by t1.task_id, subtasks_count

-------------------------------------------------------------------------------------------------------------
-- Leetcode Hard 1225: Find Continuous Dates META Advanced SQL Data Science Interview Question Solved!
Create table Failed (fail_date date)
Create table Succeeded (success_date date)

-- Find continuous date ranges where the state is the same.
insert into Failed (fail_date) values ('2018-12-28')
insert into Failed (fail_date) values ('2018-12-29')
insert into Failed (fail_date) values ('2019-01-04')
insert into Failed (fail_date) values ('2019-01-05')

insert into Succeeded (success_date) values ('2018-12-30')
insert into Succeeded (success_date) values ('2018-12-31')
insert into Succeeded (success_date) values ('2019-01-01')
insert into Succeeded (success_date) values ('2019-01-02')
insert into Succeeded (success_date) values ('2019-01-03')
insert into Succeeded (success_date) values ('2019-01-06')

select * from Failed
select * from Succeeded;

with cte1 as (
select fail_date as date , 'Failed' as status from Failed
union all
select success_date as date, 'Succeeded' as status from Succeeded )
,cte2 as (
select date ,status ,DATEADD(DAY, - ROW_NUMBER() Over(partition by status order by date), date) date_flag
from cte1
where date > = '2019-01-01' )
select  status, min(date) as startDate, max(date) as MaxDate
from cte2
group by date_flag , status
order by startDate

---------------------------------------------------------------------------------------------------------------------------

-- Leetcode HARD 3057 - Employees Project Allocation
Create table Project (project_id int, employee_id int, workload int)
Create table Employees (employee_id int, name varchar(20), team varchar(20))

insert into Project (project_id, employee_id, workload) values ('1', '1', '45')
insert into Project (project_id, employee_id, workload) values ('1', '2', '90')
insert into Project (project_id, employee_id, workload) values ('2', '3', '12')
insert into Project (project_id, employee_id, workload) values ('2', '4', '68')

insert into Employees (employee_id, name, team) values ('1', 'Khaled', 'A')
insert into Employees (employee_id, name, team) values ('2', 'Ali', 'B')
insert into Employees (employee_id, name, team) values ('3', 'John', 'B')
insert into Employees (employee_id, name, team) values ('4', 'Doe', 'A')

select * from Project
select * from Employees;

-- find employee who's workload is grater than the avg workload of their corrospoding team
with cte1 as (
select t1.employee_id, name, team, workload, avg(cast(workload as float)) over(partition by team) as avg_value
from Project t1
join Employees t2 on t1.employee_id = t2.employee_id )
select *
from cte1
where workload > avg_value
order by employee_id

-------------------------------------------------------------------------------------------------------------------

--  Leetcode HARD 2793 - Status of Flight Ticket 
Create table  Flights(flight_id int,capacity int)
Create table  Passengers (passenger_id int,flight_id int,booking_time datetime)
Truncate table Flights
insert into Flights (flight_id, capacity) values ('1', '2')
insert into Flights (flight_id, capacity) values ('2', '2')
insert into Flights (flight_id, capacity) values ('3', '1')
Truncate table Passengers
insert into Passengers (passenger_id, flight_id, booking_time) values ('101', '1', '2023-07-10 16:30:00')
insert into Passengers (passenger_id, flight_id, booking_time) values ('102', '1', '2023-07-10 17:45:00')
insert into Passengers (passenger_id, flight_id, booking_time) values ('103', '1', '2023-07-10 12:00:00')
insert into Passengers (passenger_id, flight_id, booking_time) values ('104', '2', '2023-07-05 13:23:00')
insert into Passengers (passenger_id, flight_id, booking_time) values ('105', '2', '2023-07-05 09:00:00')
insert into Passengers (passenger_id, flight_id, booking_time) values ('106', '3', '2023-07-08 11:10:00')
insert into Passengers (passenger_id, flight_id, booking_time) values ('107', '3', '2023-07-08 09:10:00')

-- find the confimed and waiting customer based on the capacity based on the booking_time
select * From Flights ;

with cte1 as (
select *, ROW_NUMBER() over(partition by flight_id order by booking_time) rn
from Passengers )
select  t1.passenger_id, case when rn <= capacity then 'confirmed' else 'waiting' end flag
from cte1 t1 
join Flights t2 on t1.flight_id = t2.flight_id
order by t1.passenger_id

-----------------------------------------------------------------------------------------------------------------

-- Leetcode HARD 1159 - Market Analysis II
Create table  Users2 (user_id int, join_date date, favorite_brand varchar(10))
Create table  Orders2 (order_id int, order_date date, item_id int, buyer_id int, seller_id int)
Create table  Items2 (item_id int, item_brand varchar(10))

insert into Users2 (user_id, join_date, favorite_brand) values ('1', '2019-01-01', 'Lenovo')
insert into Users2 (user_id, join_date, favorite_brand) values ('2', '2019-02-09', 'Samsung')
insert into Users2 (user_id, join_date, favorite_brand) values ('3', '2019-01-19', 'LG')
insert into Users2 (user_id, join_date, favorite_brand) values ('4', '2019-05-21', 'HP')

insert into Orders2 (order_id, order_date, item_id, buyer_id, seller_id) values ('1', '2019-08-01', '4', '1', '2')
insert into Orders2 (order_id, order_date, item_id, buyer_id, seller_id) values ('2', '2019-08-02', '2', '1', '3')
insert into Orders2 (order_id, order_date, item_id, buyer_id, seller_id) values ('3', '2019-08-03', '3', '2', '3')
insert into Orders2 (order_id, order_date, item_id, buyer_id, seller_id) values ('4', '2019-08-04', '1', '4', '2')
insert into Orders2 (order_id, order_date, item_id, buyer_id, seller_id) values ('5', '2019-08-04', '1', '3', '4')
insert into Orders2 (order_id, order_date, item_id, buyer_id, seller_id) values ('6', '2019-08-05', '2', '2', '4')

insert into Items2 (item_id, item_brand) values ('1', 'Samsung')
insert into Items2 (item_id, item_brand) values ('2', 'Lenovo')
insert into Items2 (item_id, item_brand) values ('3', 'LG')
insert into Items2 (item_id, item_brand) values ('4', 'HP')

/* find if the brand of the second item they sold equal to their favorite brand?
if user didn't sold less than 1 item then no */
select * from Users2
select * from Orders2
select * from items2;

with cte1 as (
select  * , ROW_NUMBER() over(partition by seller_id order by order_date) rk1
from Orders2)
select user_id,
case when t3.item_brand <> t1.favorite_brand or t2.order_id is null then 'no'
else 'yes' end as status
from Users2 t1
left join cte1 t2 on t1.user_id = t2.seller_id and rk1 = 2
left join items2 t3 on t2.item_id = t3.item_id
order by user_id

----------------------------------------------------------------------------------------------------------
-- Leetcode HARD 1194 - Tournament Winners MULTI-COLUMN JOIN TRICK

Create table  Players2 (player_id int, group_id int)
Create table  Matches2 (match_id int, first_player int, second_player int, first_score int, second_score int)

Truncate table Players
insert into Players2 (player_id, group_id) values ('10', '2')
insert into Players2 (player_id, group_id) values ('15', '1')
insert into Players2 (player_id, group_id) values ('20', '3')
insert into Players2 (player_id, group_id) values ('25', '1')
insert into Players2 (player_id, group_id) values ('30', '1')
insert into Players2 (player_id, group_id) values ('35', '2')
insert into Players2 (player_id, group_id) values ('40', '3')
insert into Players2 (player_id, group_id) values ('45', '1')
insert into Players2 (player_id, group_id) values ('50', '2')
Truncate table Matches
insert into Matches2 (match_id, first_player, second_player, first_score, second_score) values ('1', '15', '45', '3', '0')
insert into Matches2 (match_id, first_player, second_player, first_score, second_score) values ('2', '30', '25', '1', '2')
insert into Matches2 (match_id, first_player, second_player, first_score, second_score) values ('3', '30', '15', '2', '0')
insert into Matches2 (match_id, first_player, second_player, first_score, second_score) values ('4', '40', '20', '5', '2')
insert into Matches2 (match_id, first_player, second_player, first_score, second_score) values ('5', '35', '50', '1', '1')


/* For each group, find the player who has the highest total score.
Rules:
1. Score = sum of all points scored in matches
2. If tie → choose smallest player_id
3. Every group must return exactly one winner   */

select * From Players2
select * from Matches2 ;

with cte1 as (
select first_player player, first_score score 
from Matches2
union all
select second_player player, second_score score
from Matches2 )
,cte2 as (
select player, sum(score) total_score
from cte1 
group by player )
,cte3 as (
select t2.group_id, t1.player, 
ROW_NUMBER() over(partition by group_id order by total_score desc , t1.player) rk1
from cte2 t1 
join Players2 t2 on t1.player = t2.player_id )
select group_id, player
from cte3
where rk1 = 1

-- using multiple column join trick 

select * From Players2
select * from Matches2 ;

with cte1 as (
select t1.player_id , t1.group_id, 
 sum (case when t1.player_id = t2.first_player then first_score
when t1.player_id = t2.second_player then second_score end ) as total_score 
from Players2 t1
left join Matches2  t2 on t1.player_id = t2.first_player or t1.player_id = t2.second_player
group by t1.player_id , t1.group_id )
,cte2 as (
select * , 
ROW_NUMBER() over(partition by group_id order by total_score desc, player_id ) rk1
from cte1 )
select group_id, player_id
from cte2
where rk1 = 1


-------------------------------------------------------------------------------------------------------------

-- Leetcode HARD 1972 - First & Last Call on Same Day
Create table  Calls (caller_id int, recipient_id int, call_time datetime)
Truncate table Calls
insert into Calls (caller_id, recipient_id, call_time) values ('8', '4', '2021-08-24 17:46:07')
insert into Calls (caller_id, recipient_id, call_time) values ('4', '8', '2021-08-24 19:57:13')
insert into Calls (caller_id, recipient_id, call_time) values ('5', '1', '2021-08-11 05:28:44')
insert into Calls (caller_id, recipient_id, call_time) values ('8', '3', '2021-08-17 04:04:15')
insert into Calls (caller_id, recipient_id, call_time) values ('11', '3', '2021-08-17 13:07:00')
insert into Calls (caller_id, recipient_id, call_time) values ('8', '11', '2021-08-17 22:22:22');
 -- note :- (caller_id, recipient_id) - PK
/*
Find user_ids such that:
On at least one day,
the first call and the last call of that day
were made to the same person.
⚠️ Important:
Calls can be incoming or outgoing
Caller OR recipient → both count as “calls of that user” */

select * from Calls;


/* note :- this will give those user where first and last call happened between same user on particular day,
but we need to find those users whos first and last call with each other in same day*/

with cte1 as (
select * , 
ROW_NUMBER() over(partition by cast (call_time as date) order by call_time) rk1,  -- first call on that day
ROW_NUMBER() over(partition by cast (call_time as date) order by call_time desc) rk2 -- last call on that day
from Calls)
,cte2 as (
select *
from cte1 
where rk1 =1 or rk2 = 1 )
 ,cte3 as (
select caller_id, cast(call_time as date) call_date
from cte2 
union all 
select recipient_id, cast(call_time as date) call_date
from cte2 )
,cte4 as (
select  call_date, 
count(distinct caller_id)  dist_count
from cte3 
group by call_date )
select distinct caller_id
from cte3 t1
join cte4 t2 on t1.call_date = t2.call_date and dist_count = 2;

--  this will give the user who has first and last call with same user on any of the day
with cte1 as (
select * from Calls
union all 
select recipient_id, caller_id, call_time from Calls )
,cte2 as (
select * , FIRST_VALUE(recipient_id) over(partition by caller_id, cast (call_time as date) order by call_time asc) first_call,
FIRST_VALUE(recipient_id) over(partition by caller_id, cast (call_time as date) order by call_time desc) last_call
from cte1 )
select  distinct caller_id
from cte2
where first_call = last_call;

---------------------------------------------------------------------------------------------------------------
Create table  Matches1 (player_id int, match_day date, result varchar(100))
Truncate table Matches1
insert into Matches1 (player_id, match_day, result) values ('1', '2022-01-17', 'Win')
insert into Matches1 (player_id, match_day, result) values ('1', '2022-01-18', 'Win')
insert into Matches1 (player_id, match_day, result) values ('1', '2022-01-25', 'Win')
insert into Matches1 (player_id, match_day, result) values ('1', '2022-01-31', 'Draw')
insert into Matches1 (player_id, match_day, result) values ('1', '2022-02-08', 'Win')
insert into Matches1 (player_id, match_day, result) values ('2', '2022-02-06', 'Lose')
insert into Matches1 (player_id, match_day, result) values ('2', '2022-02-08', 'Lose')
insert into Matches1 (player_id, match_day, result) values ('3', '2022-03-30', 'Win')

select * from Matches1;
-- find highest win strik by user

with cte2 as (
select * ,  ROW_NUMBER() over(partition by player_id order by match_day) rk
from Matches1
 )
,cte3 as (
select *,dateadd(day,rk, '9999-01-01') con_day   -- add dummy '9999-01-01' to get the continuose date
from cte2 )
,cte4 as (
select *,DATEADD(day, - ROW_NUMBER() over(partition by player_id, result order by con_day), con_day) cons_date
from cte3)
 , cte5 as (
select  player_id, result, cons_date,count(*) count_result -- count of strik
, row_number() over(partition by player_id order by count(*) desc)   rk  -- to get the rank based on highest strik
from cte4
where result = 'Win'
group by  player_id, result, cons_date )
select  distinct t1.player_id, isnull(count_result ,0)
from Matches1 t1  -- to get all player_id
left join (select * from cte5 where rk = 1) t2 on t1.player_id = t2.player_id;


with cte1 as (
select *,
ROW_NUMBER() over(partition by player_id order by match_day) rk1,   -- use to get the continuose days 
ROW_NUMBER() over(partition by player_id ,result order by  match_day) rk2  -- use to get the continuose days
from Matches1 )
,cte2 as (
select player_id,rk1- rk2 diff_day, count(rk1- rk2) count_win,
ROW_NUMBER() over(partition by player_id order by count(rk1- rk2) desc) rk
from cte1
where result = 'win'
group by player_id , rk1- rk2 )
select distinct t1.player_id, isnull(t2.count_win,0)
from Matches1 t1
left join (select * from cte2 where rk = 1) t2 on t1.player_id = t2.player_id

---------------------------------------------------------------------------------------------------------------------
-- Leetcode HARD 2474 - Customers with Strictly Increasing Purchase
-- for any year order is not placed consider it as 0 
Create table Orders1 (order_id int, customer_id int, order_date date, price int)
Truncate table Orders
insert into Orders1 (order_id, customer_id, order_date, price) values ('1', '1', '2019-07-01', '1100')
insert into Orders1 (order_id, customer_id, order_date, price) values ('2', '1', '2019-11-01', '1200')
insert into Orders1 (order_id, customer_id, order_date, price) values ('3', '1', '2020-05-26', '3000')
insert into Orders1 (order_id, customer_id, order_date, price) values ('4', '1', '2021-08-31', '3100')
insert into Orders1 (order_id, customer_id, order_date, price) values ('5', '1', '2022-12-07', '4700')
insert into Orders1 (order_id, customer_id, order_date, price) values ('6', '2', '2015-01-01', '700')
insert into Orders1 (order_id, customer_id, order_date, price) values ('7', '2', '2017-11-07', '1000')
insert into Orders1 (order_id, customer_id, order_date, price) values ('8', '3', '2017-01-01', '900')
insert into Orders1 (order_id, customer_id, order_date, price) values ('9', '3', '2018-11-07', '900');

with cte1 as (
select customer_id,YEAR(order_date) year_no , sum(price) sum_price From Orders1
group by customer_id,YEAR(order_date) )
, cte2 as (select customer_id, min(year(order_date)) min_year, max(year(order_date)) max_year  
 from Orders1 
 group by customer_id
 union all
 select customer_id, min_year + 1 , max_year
 from cte2
 where min_year < max_year)
 , cte3 as (
 select t1.customer_id, t1.min_year
 --, isnull(sum_price,0),
 -- LEAD(isnull(sum_price,0)) over(partition by t1.customer_id order by t1.min_year),
 ,case 
 when isnull(sum_price,0) < LEAD(isnull(sum_price,0)) over(partition by t1.customer_id order by t1.min_year) 
 or LEAD(isnull(sum_price,0)) over(partition by t1.customer_id order by t1.min_year) is null then 1 
 else 0  end as flag
 from cte2  t1 
 left join cte1 t2 on t1.customer_id = t2.customer_id and t1.min_year  = t2.year_no )
 select  distinct customer_id
from cte3
WHERE customer_id NOT IN (select customer_id from cte3 where flag = 0 );

-- youtube solution 
with cte1 as (
select customer_id
, year(order_date) year_no 
, sum(price) total_price
, max(year(order_date)) over(partition by customer_id) - min(year(order_date)) over(partition by customer_id) + 1 num_yr
, DENSE_RANK() over(partition by customer_id order by year(order_date)) rnk_year
, DENSE_RANK() over(partition by customer_id order by sum(price)) rnk_price
-- ,count( year(order_date) ) over(partition by customer_id )
from Orders1
group by customer_id, year(order_date))
select customer_id
from cte1
group by customer_id
having sum(case when rnk_price = rnk_year then 1 else 0 end ) = max(num_yr)

-------------------------------------------------------------------------------------------------------------------------
-- Leetcode HARD 3214 - Year on Year Growth Rate
Create Table  user_transactions( transaction_id int, product_id int, spend decimal(10,2), 
transaction_date datetime)
Truncate table user_transactions
insert into user_transactions (transaction_id, product_id, spend, transaction_date) values ('1341', '123424', '1500.6', '2019-12-31 12:00:00')
insert into user_transactions (transaction_id, product_id, spend, transaction_date) values ('1423', '123424', '1000.2', '2020-12-31 12:00:00')
insert into user_transactions (transaction_id, product_id, spend, transaction_date) values ('1623', '123424', '1246.44', '2021-12-31 12:00:00')
insert into user_transactions (transaction_id, product_id, spend, transaction_date) values ('1322', '123424', '2145.32', '2022-12-31 12:00:00')


select product_id, YEAR(transaction_date) , 
lag(sum(spend)) over(partition by product_id order by YEAR(transaction_date))  previose_year,
sum(spend) current_year,
(( sum(spend) - lag(sum(spend)) over(partition by product_id order by YEAR(transaction_date))) / 
lag(sum(spend)) over(partition by product_id order by YEAR(transaction_date)) ) * 100
from user_transactions
group by product_id, YEAR(transaction_date) 

--------------------------------------------------------------------------------------------------------------