-- ============================================================================
-- File: 06_advanced_sql.sql
-- Description: Advanced Business Analytics Queries for Healthcare Dataset
-- Tables Used: departments, doctors, patients, appointments, bills, medications
-- ============================================================================

USE Healthcare_Analytics_DB;

-- ----------------------------------------------------------------------------
-- Objective: Doctor Revenue Performance & Departmental Share
-- Business Question: How do doctors rank within their department by revenue, 
-- and what percentage of department revenue does each doctor generate?
-- ----------------------------------------------------------------------------
WITH DoctorRevenue AS (
SELECT
d.department_id,
d.department_name,
doc.doctor_id,
CONCAT('Dr. ' , doc.first_name, ' ' ,doc.last_name) AS doctor_name,
SUM(bi.net_amount) AS total_doctor_revenue
FROM doctors AS doc
JOIN departments as d USING (department_id)
JOIN appointments AS a USING(doctor_id)
JOIN bills AS bi USING(appointment_id)
WHERE bi.payment_status = 'Paid'
 GROUP BY  d.department_id,
d.department_name,
doc.doctor_id,
doc.first_name,
doc.last_name )

SELECT 
department_name,
doctor_name,
total_doctor_revenue,
DENSE_RANK () 
OVER ( PARTITION BY department_id ORDER BY total_doctor_revenue DESC ) AS dept_revenue_rank,
CONCAT(
 ROUND(
 (total_doctor_revenue / sum(total_doctor_revenue) OVER (PARTITION BY department_id)) * 100,2), '%') AS pct_share_of_dept_revenue 
FROM DoctorRevenue
ORDER BY department_name, dept_revenue_rank;


-- ----------------------------------------------------------------------------
-- Objective: Financial Growth & Revenue Trajectory
-- Business Question: What is the Month-over-Month (MoM) growth rate of net 
-- collections, and what is the cumulative revenue trajectory over time?
-- ----------------------------------------------------------------------------

WITH Monthly_Billing AS (
Select DATE_FORMAT(billing_date , '%Y-%m') AS billing_month,
SUM(net_amount) as monthly_revenue
FROM bills
WHERE payment_status = 'Paid'
GROUP BY DATE_FORMAT(billing_date , '%Y-%m')
)
SELECT billing_month,
monthly_revenue,
LAG(monthly_revenue ,1)OVER (ORDER BY billing_month) AS previous_month_revenue,
CONCAT(ROUND(
	((monthly_revenue - LAG(monthly_revenue ,1) OVER (ORDER BY billing_month))
    / NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY billing_month),0))* 100,2),'%') AS mom_growth_pct,
    SUM(monthly_revenue)OVER (
    ORDER BY billing_month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_running_revenue
    FROM Monthly_Billing;
    
    
    -- ----------------------------------------------------------------------------
-- Objective: Operational Efficiency & Hospital Utilization Analysis
-- Business Question: What are the appointment completion, cancellation, and 
-- no-show conversion rates across departments?
-- ----------------------------------------------------------------------------

SELECT d.department_name,
COUNT(a.appointment_id) AS total_appointments,
SUM(CASE WHEN a.STATUS = 'Completed' THEN 1 ELSE 0 END ) AS completed_count,
SUM(CASE WHEN a.STATUS = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
SUM(CASE WHEN a.STATUS = 'Scheduled' THEN 1 ELSE 0 END) AS pending_count,
CONCAT(ROUND(
	(SUM(CASE WHEN  a.STATUS = 'Completed' THEN 1 ELSE 0 END) / NULLIF (COUNT(a.appointment_id),0))*100,2), '%')
    AS Completion_rate_pct,
CONCAT(ROUND(
	(SUM(CASE WHEN a.STATUS = 'Cancelled' THEN 1 ELSE 0 END) / NULLIF(COUNT(a.appointment_id),0))*100,2), '%')
    AS Cancellation_rate_pct
FROM departments d
LEFT JOIN appointments a ON d.department_id = a.department_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(a.appointment_id) >0
ORDER BY total_appointments DESC;


-- ----------------------------------------------------------------------------
-- Objective: Clinical Quality & Patient Readmission (30-Day Window)
-- Business Question: Which patients had a follow-up visit within 30 days of 
-- a completed consultation, indicating frequent care requirements or readmission?
-- ----------------------------------------------------------------------------

WITH patient_visit_sequence AS (
SELECT patient_id,
appointment_id,
doctor_id,
appointment_date,
LAG(appointment_date)OVER (
PARTITION BY patient_id
ORDER BY appointment_date) AS prior_visit_date
FROM appointments
WHERE STATUS = 'Completed'
)
SELECT 
	p.patient_id,
    CONCAT(p.first_name ,' ' , p.last_name) AS patient_name,
    a.appointment_date AS current_visit,
    a.prior_visit_date,
    DATEDIFF(a.appointment_date, a.prior_visit_date) AS days_between_visits,
    '30-Day RETURN' AS visit_interval_category
FROM patient_visit_sequence a
JOIN patients p ON a.patient_id = p.patient_id
WHERE a.prior_visit_date IS NOT NULL 
AND DATEDIFF(a.appointment_date, a.prior_visit_date) <= 30
ORDER BY days_between_visits ASC;


-- ----------------------------------------------------------------------------
-- Objective: Revenue Realization & Receivables Risk Profiling
-- Business Question: What is the insurance claim clearance rate versus out-of-pocket 
-- pending receivables across different payment modes?
-- ----------------------------------------------------------------------------

SELECT 
	payment_mode,
    COUNT(bill_id) AS total_bills_issued,
    SUM(total_amount) AS gross_bill_amount,
    SUM(discount) AS total_discount_given,
    SUM(insurance_amount) AS total_insurance_claimed,
    SUM(net_amount) AS total_net_amount,
    SUM(CASE WHEN payment_status = 'Pending' THEN net_amount Else 0 END) AS pending_receivables,
    CONCAT(ROUND(
		(SUM(CASE WHEN payment_status = 'Pending' THEN net_amount ELSE 0 END) / NULLIF(SUM(net_amount),0))*100,2
        ), '%') AS pending_risk_pct
FROM bills
GROUP BY payment_mode
ORDER BY total_net_amount DESC;


-- ----------------------------------------------------------------------------
-- Objective: Top Decile VIP Patient Lifetime Value (LTV) Segmentation
-- Business Question: Who are the top 10% highest-spending patients in the hospital, 
-- and what is their average spend per consultation?
-- ----------------------------------------------------------------------------

WITH VIP_patients AS (
SELECT 
	p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name ) AS patient_name,
    p.city,
    COUNT(DISTINCT a.appointment_id) AS total_consultations,
    SUM(b.net_amount) AS total_spend,
    NTILE(10) OVER (ORDER BY SUM(b.net_amount) DESC) AS spend_decile
FROM patients p
JOIN appointments a ON p.patient_id  = a.patient_id
JOIN bills b  ON a.appointment_id = b.appointment_id
WHERE b.payment_status = 'Paid'
GROUP BY p.patient_id, p.first_name, p.last_name, p.city
)
SELECT 
patient_id,
patient_name,
city,
total_consultations,
total_spend,
ROUND(total_spend / NULLIF(total_consultations, 0),2) AS avg_spend_per_visit
FROM VIP_patients
WHERE spend_decile = 1
ORDER BY total_spend DESC;































