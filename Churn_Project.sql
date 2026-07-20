-- ============================================
-- Telecom Customer Churn Analysis
-- SQL Practice Queries
-- ============================================

-- 1) What is the overall churn rate (%)?
with cte as (
select count(customerid) as total_customers,sum(case when churn='Yes' then 1 else 0 END) as churned_customers from churn)
select Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte

-- Overall churn rate is 26.54%, confirming the Python EDA finding.
-- This SQL result validates the pipeline consistency across tools.

--2) What is the churn rate by contract type?
with cte as (
select contract as Contracts,count(customerid) as total_customers,sum(case when churn='Yes' then 1 else 0 END) as churned_customers from churn
group by contract)
select contracts, Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte order by "churn_rate%" desc

--month-to-month contracts churn at 42.71% — over 15x higher than two-year contracts (2.83%).
--Result matches Python EDA exactly, validating the analysis pipeline. 

--3) Average Tenure and Average monthly charges,split by churn status?
select churn,round(avg(tenure)::numeric,2) as avg_tenure,
round(avg(monthlycharges)::numeric,2 )as avg_monthly_charges from churn
group by churn

--churned customers average just 17.98 months tenure (vs 37.57 for retained) and 
--pay ₹74.44/month on average (vs ₹61.27) — a 21% higher bill.

--4) What is the churn rate by internet type?
with cte as (
select internetservice as internet_type,count(customerid) as total_customers,sum(case when churn='Yes' then 1 else 0 END) as churned_customers from churn
group by internetservice)
select internet_type, Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte order by "churn_rate%" desc

-- Fiber optic customers churn at 41.89%, more than double DSL (18.96%) and nearly 6x higher than customers without internet (7.40%).

--5) What is the churn rate by payment method?
with cte as (
select paymentmethod as payment_method,count(customerid) as total_customers,
sum(case when churn='Yes' then 1 else 0 END) as churned_customers from churn
group by paymentmethod)
select payment_method, Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte order by "churn_rate%" desc

-- Electronic check customers churn at 45.29% — roughly 3x higher ,
-- than either automatic payment method (bank transfer 16.71%, credit card 15.24%).

--6) Tenure buckets(0-12,13-24,25-48,49+ months) and find churn rate per bucket
with cte as (
select count(customerid) as total_customers,
sum(case when churn='Yes' then 1 else 0 END) as churned_customers,
case
when tenure<=12 then '0-12 months'
when tenure<=24 then '13-24 months'
when tenure<=48 then '25-48 months'
else '49+ months'
end as tenure_bucket from churn
group by case
when tenure<=12 then '0-12 months'
when tenure<=24 then '13-24 months'
when tenure<=48 then '25-48 months'
else '49+ months'end
)
select tenure_bucket,Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte order by "churn_rate%" desc

-- Churn risk decreases sharply and consistently as tenure increases — customers in their first year churn at nearly 5x the rate of customers with 49+ months tenure (47.44% vs 9.51%). 
-- This is a clean, monotonic decline across every bucket, reinforcing the earlier finding that early tenure is the highest-risk period

--7) Does having Tech support reduce churn?
with cte as (
select techsupport,count(customerid) as total_customers,
sum(case when churn='Yes' then 1 else 0 END) as churned_customers from churn
group by techsupport)
select techsupport,Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte order by "churn_rate%" desc

-- Customers without Tech Support churn at 41.64% — nearly 3x higher than customers who do have it (15.17%). This suggests Tech Support meaningfully improves customer satisfaction/retention, likely by resolving issues before frustration leads to cancellation.
-- Offering free or discounted Tech Support trials to at-risk customers (month-to-month, Fiber optic, short tenure) could be a concrete retention lever.

--8) Churn rate by Senior Citizen status, broken down further by Contract type
with cte as (
select seniorcitizen,contract,count(customerid) as total_customers,
sum(case when churn='Yes' then 1 else 0 END) as churned_customers from churn
group by seniorcitizen,contract )
select seniorcitizen,contract,Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte order by "churn_rate%" desc

-- Senior citizens churn more than non-seniors within every contract type, but the gap is most severe on month-to-month plans — senior citizens on month-to-month contracts churn at a striking 54.65%, over half of them leaving.
-- This shows the two risk factors (senior citizen status + flexible contract) don’t just add up, they seem to reinforce each other. 
-- This makes month-to-month senior citizens the single highest-risk segment identified across the entire analysis — a clear, specific group for the company to prioritize with a retention offer, such as a discounted annual contract upgrade specifically targeted at senior customers.

--9) Top 5 Customer Ranking by Monthly Charges within each Contract type
with cte as (select customerid,contract as contract_type,monthlycharges as monthly_charges,
dense_rank() over(partition by contract order by monthlycharges desc)as rnk from churn
)
select * from cte where rnk<=5

-- Within Month-to-month contracts, the highest-paying customer (₹117.45/month) sits at rank 1 — useful for identifying premium customers within each contract segment.
-- This ranking can help target retention offers specifically at high-value customers within the highest-churn contract group (month-to-month), rather than treating all month-to-month customers the same.

--10) What % of total customers does each Contract type represent?
SELECT contract, COUNT(customerid) AS total_customers,
ROUND(COUNT(customerid) * 100.0 /
        SUM(COUNT(customerid)) OVER (),
        2
    ) AS customer_percentage
FROM churn GROUP BY contract

-- One-Year and Two-Year contracts represent a smaller percentage of customers but are generally associated with higher customer commitment. 
-- Increasing the adoption of long-term contracts can reduce churn and create more stable recurring revenue.

--11) For each customer, show their MonthlyCharges alongside the average MonthlyCharges for their InternetService type
with cte as (select customerid,monthlycharges as monthly_charges,internetservice,
avg(monthlycharges)over(partition by internetservice) as avg_monthly_charge
from churn)
select * from cte 

-- Average Monthly Charges vary across Internet Service categories. Customers paying significantly above their group’s average may be on premium plans, while those below average may be on discounted or basic plans.
-- This comparison will support pricing analysis and targeted marketing strategies.

-- 12) Running total of customer count as tenure increases
with cte as (
select tenure,count(customerid)as customer_count from churn
group by tenure)
select tenure,customer_count,sum(customer_count)over(order by tenure) as running_total from cte
group by tenure,customer_count

-- Tracking the running total by tenure helps identify customer retention patterns over time. 
-- Reducing early-stage churn can lead to a larger base of long-tenured customers, improving recurring revenue and overall business stability.

--13) find the highest-churn combination of Contract + InternetService together
with cte as(
select contract,internetservice,count(customerid) as total_customers,
sum(case when churn='Yes'then 1 else 0 end) as churned_customers,
Round(( sum(case when churn='Yes'then 1 else 0 end)*100.0)/count(customerid),2) as "churn_rate%",
dense_rank()over(partition by contract order by Round((sum(case when churn='Yes'then 1 else 0 end) *100.0)/count(customerid),2)desc ) as rnk from churn
group by contract,internetservice
)
select * from cte where rnk =1

-- Month-to-month customers using Fiber optic internet have the highest churn rate (54.61%).This is the highest-risk customer segment.
-- More than half of these customers leave the company.As contract length increases, churn decreases significantly.
-- Fiber optic is the highest-churn internet service within every contract type.

--14) Calculate churn rate by tenure bucket AND contract type together
with cte as(select count(customerid) as total_customers,sum(case when churn='Yes' then 1 else 0 end) as churned_customers,contract,
case
when tenure<=12 then '0-12 months'
when tenure<=24 then '13-24 months'
when tenure<=48 then '25-48 months'
else '49+ months'
end as tenure_bucket from churn
group by contract,
case
when tenure<=12 then '0-12 months'
when tenure<=24 then '13-24 months'
when tenure<=48 then '25-48 months'
else '49+ months'
end )
select tenure_bucket,contract,Round((churned_customers *100.0)/total_customers,2) as "churn_rate%" from cte

-- Customers on Month-to-month contracts consistently have the highest churn, especially those with 13–24 months tenure (37.72%). 
-- In contrast, Two-year contracts show the lowest churn (0–3.33%), indicating that longer-term commitments are highly effective at improving customer retention.

--15) Using a CTE + NTILE, identify the top 25% highest-paying customers who also churned
WITH cte AS (
SELECT customerID,monthlycharges,churn,
NTILE(4) OVER (ORDER BY MonthlyCharges DESC) AS quartile from churn
)
SELECT customerID,monthlycharges,churn
FROM cte WHERE quartile = 1 AND Churn = 'Yes'

-- Among the top 25% highest-paying customers (ranked by MonthlyCharges), 578 customers have churned. These customers represent a high-value revenue segment, so their loss has a greater financial impact than losing lower-paying customers. 
-- This indicates the company should prioritize retention efforts for premium customers through personalized offers, loyalty rewards, proactive customer support, and dedicated account management.
 