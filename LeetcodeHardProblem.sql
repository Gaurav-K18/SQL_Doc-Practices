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