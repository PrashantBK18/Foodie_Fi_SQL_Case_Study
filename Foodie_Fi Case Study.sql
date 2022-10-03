
### Introduction to Case

/* Ron and his buddies founded Foodie-Fi and began selling monthly and annual 
subscriptions, providing clients with unrestricted on-demand access to exclusive cuisine 
videos from around the world.
This case study focuses on the use of subscription-style digital data to answer critical 
business questions about the customer journey, payments, and business performance. */

### Table ‘plans’ Description

/* There are 5 customer plans:
Trial— Customers sign up for a 7-day free trial and will be automatically enrolled in the pro monthly subscription plan 
unless they unsubscribe, downgrade to basic, or upgrade to an annual pro plan during the trial.
Basic plan — Customers have limited access and can only stream their videos with the basic package, which is only 
available monthly for $9.90.
Pro plan — Customers on the Pro plan have no watch time limits and can download videos for offline viewing. Pro 
plans begin at $19.90 per month or $199 for a yearly subscription.
When clients cancel their Foodie-Fi service, a Churn plan record with a null pricing is created, but their plan continues 
until the end of the billing cycle. */

### Table ‘subscriptions’ Description

/* Customer subscriptions display the precise date on which their specific plan id begins.
If a customer downgrades from a pro plan or cancels their subscription — the higher program will remain in place until 
the period expires — the start date in the subscriptions table will reflect the date the actual plan changes.
When clients upgrade their account from a basic plan to a pro or annual pro plan, the higher plan becomes active 
immediately.
When customers cancel their subscription, they will retain access until the end of their current billing cycle, but the 
start date will be the day they opted to quit their service. */

select * from plans;

select * from subscriptions;

-- How many customers has Foodie-Fi ever had?

SELECT 
COUNT(DISTINCT customer_id) AS unique_customer
FROM subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset?

SELECT
EXTRACT(month FROM start_date) AS month_num,
DATE_FORMAT(start_date,'%M') AS month_name, 
COUNT(*) AS trial_subscriptions
FROM subscriptions s
JOIN plans p
 ON s.plan_id = p.plan_id
WHERE s.plan_id = 0
GROUP BY 1, 2
ORDER BY 1 ASC;

-- What plan start_date values occur after the year 2020 for our dataset? 
-- Show the breakdown by count of events for each plan_name.

SELECT 
 p.plan_id,
 p.plan_name,
 COUNT(*) AS events
FROM subscriptions s
JOIN plans p
 ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY 1, 2
ORDER BY p.plan_id;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
 COUNT(*) AS churn_count,
 ROUND(100 * COUNT(*)/ (
 SELECT COUNT(DISTINCT customer_id) 
 FROM subscriptions),1) AS churn_percentage
FROM subscriptions s
JOIN plans p
 ON s.plan_id = p.plan_id
WHERE s.plan_id = 4; 

-- How many customers have churned straight after their initial free trial? 
-- what percentage is this rounded to the nearest whole number?

WITH ranking AS (
SELECT 
 s.customer_id, 
 s.plan_id, 
 p.plan_name,
 ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.plan_id) AS plan_rank 
FROM subscriptions s
JOIN plans p
 ON s.plan_id = p.plan_id)
 
SELECT 
 COUNT(*) AS churn_count,
 ROUND(100 * COUNT(*) / (
 SELECT COUNT(DISTINCT customer_id) 
 FROM subscriptions),0) AS churn_percentage
FROM ranking
WHERE plan_id = 4 -- Filter to churn plan
 AND plan_rank = 2
 
 -- What is the number and percentage of customer plans after their initial free trial?

WITH next_plan_cte AS(
SELECT 
 customer_id, 
 plan_id, 
 LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
FROM subscriptions)

SELECT 
 next_plan, 
 COUNT(*) AS conversions,
 ROUND(100 * COUNT(*)/ (
 SELECT COUNT(DISTINCT customer_id) 
 FROM subscriptions),1) AS conversion_percentage
FROM next_plan_cte
WHERE next_plan IS NOT NULL 
 AND plan_id = 0
GROUP BY 1
ORDER BY 1;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020–12–31?

WITH next_plan AS(
SELECT 
 customer_id, 
 plan_id, 
 start_date,
 LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM subscriptions
WHERE start_date <= '2020-12-31'
),

customer_breakdown AS (
 SELECT 
 plan_id, 
 COUNT(DISTINCT customer_id) AS customers
 FROM next_plan
 WHERE 
 (next_date IS NOT NULL AND (start_date < '2020-12-31' 
 AND next_date > '2020-12-31'))
 OR (next_date IS NULL AND start_date < '2020-12-31')
 GROUP BY 1)
 
 SELECT plan_id, customers, 
 ROUND(100 * customers / (
 SELECT COUNT(DISTINCT customer_id) 
 FROM subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY 1, 2
ORDER BY 1;

-- How many customers have upgraded to an annual plan in 2020?

SELECT 
 COUNT(DISTINCT customer_id) AS unique_customer
FROM subscriptions
WHERE plan_id = 3
 AND start_date <= '2020-12-31';
 
 -- How many days on average does it take a customer to an annual plan from the day they join Foodie-Fi?
 
 -- Filter results to customers at trial plan = 0
WITH trial_plan AS 
 (SELECT 
 customer_id, 
 start_date AS trial_date
 FROM subscriptions
 WHERE plan_id = 0
),

-- Filter results to customers at pro annual plan = 3
annual_plan AS
(SELECT 
 customer_id, 
 start_date AS annual_date
 FROM subscriptions
 WHERE plan_id = 3
)
SELECT 
 ROUND(AVG(datediff(annual_date,trial_date)),0) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
 ON tp.customer_id = ap.customer_id;

-- How many customers downgraded from a pro-monthly to a basic monthly plan in 2020?

WITH next_plan_cte AS (
 SELECT 
 customer_id, 
 plan_id, 
 start_date,
 LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
 FROM subscriptions)

SELECT 
COUNT(*) AS downgraded
FROM next_plan_cte
WHERE start_date <= '2020-12-31'
 AND plan_id = 2
 AND next_plan = 1;
 