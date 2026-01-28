
CREATE TABLE payment_events (
    payment_id INT,
    event_type VARCHAR(30),
    event_time DATETIME
);

INSERT INTO payment_events VALUES
-- Valid payment
(101, 'payment_created',  '2024-01-01 10:00'),
(101, 'payment_captured', '2024-01-01 10:01'),
(101, 'payment_settled',  '2024-01-01 10:05'),

-- Missing capture
(102, 'payment_created',  '2024-01-01 11:00'),
(102, 'payment_settled',  '2024-01-01 11:10'),

-- Missing settlement
(103, 'payment_created',  '2024-01-01 12:00'),
(103, 'payment_captured', '2024-01-01 12:01'),

-- Refund without settlement
(104, 'payment_created',  '2024-01-01 13:00'),
(104, 'payment_captured', '2024-01-01 13:01'),
(104, 'payment_refunded', '2024-01-01 13:02'),

-- Out-of-order events
(105, 'payment_captured', '2024-01-01 14:00'),
(105, 'payment_created',  '2024-01-01 14:01'),
(105, 'payment_settled',  '2024-01-01 14:02')


-- all valid

INSERT INTO payment_events VALUES
(106, 'payment_created',  '2024-01-01 10:00'),
(106, 'payment_captured', '2024-01-01 10:01'),
(106, 'payment_settled',  '2024-01-01 10:05'),
(106, 'payment_refunded',  '2024-01-01 10:07')

/*
Goal:
Detect broken Stripe payment event chains using window functions
and explicit validation logic in a CTE.
Valid flow:
payment_created -> payment_captured -> payment_settled -> (optional) payment_refunded
*/

INSERT INTO payment_events VALUES
(107, 'payment_created',  '2024-01-01 15:00'),
(107, 'payment_captured', '2024-01-01 15:01'),
(107, 'payment_captured', '2024-01-01 15:01'), -- duplicate retry
(107, 'payment_settled',  '2024-01-01 15:05');

-- it will not handle the duplicate event_type
with cte1 as (
select * , case
when event_type = 'payment_created' then 1
when event_type =  'payment_captured' then 2
when event_type = 'payment_settled' then 3 
when event_type = 'payment_refunded' then 4 end as squence 
from payment_events )
,cte2 as (
select *, ROW_NUMBER() over (partition by payment_id order by event_time , squence) flag1
,max(squence) over(partition by payment_id ) flag2
from cte1 )
select *
from cte2
where squence <> flag1 
or flag2 < 3  -- To confirm that user has done all the 3 event not 1 or 2


-- handle duplicate event_type
WITH seq_events AS (
    SELECT *,
           CASE event_type
               WHEN 'payment_created'  THEN 1
               WHEN 'payment_captured' THEN 2
               WHEN 'payment_settled'  THEN 3
               WHEN 'payment_refunded' THEN 4
           END AS seq
    FROM payment_events
)
 ,checks AS (
    SELECT *,
           LAG(seq) OVER (PARTITION BY payment_id ORDER BY event_time) AS prev_seq,
           SUM(CASE WHEN seq = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY payment_id) AS has_created,
           SUM(CASE WHEN seq = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY payment_id) AS has_captured,
           SUM(CASE WHEN seq = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY payment_id) AS has_settled
    FROM seq_events
)
SELECT DISTINCT payment_id
FROM checks
WHERE
      -- Out-of-order events
      seq < prev_seq

   -- Missing mandatory steps
   OR has_created = 0
   OR has_captured = 0
   OR has_settled = 0

   -- Refund before settlement
   OR (seq = 4 AND prev_seq < 3);


