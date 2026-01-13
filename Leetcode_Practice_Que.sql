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
