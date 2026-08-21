# Business Questions — Healthcare Analytics DB

**Database:** `Healthcare_Analytics_DB`
**Last Updated:** 2026-08-21

## Overview

This document catalogs every analytical business question answered in the project's SQL scripts, organized by theme: data quality, patient analytics, doctor/clinical analytics, revenue analytics, and advanced/operational analytics. For each question: the business objective, the source file, the SQL technique used, and the resulting business value.

**Source files referenced:**
| File | Theme |
|---|---|
| `02_exploratory_analysis.sql` | Data profiling & quality checks |
| `03_patient_analysis.sql` | Patient-centric analysis |
| `04_doctor_analysis.sql` | Doctor-centric analysis |
| `05_revenue_analysis.sql` | Revenue & billing analysis |
| `06_advanced_sql.sql` | Advanced window-function analytics |
| `07_database_operations.sql` | Operational automation (triggers, procedures, views) |

---

## 1. Data Quality & Exploration (`02_exploratory_analysis.sql`)

These queries establish trust in the dataset before analysis: structure, volume, nulls, duplicates, category distributions, date ranges, and numeric summaries across all six tables.

| # | Business Question | Technique |
|---|---|---|
| 1.1 | What tables exist and how are they structured? | `SHOW TABLES`, `DESCRIBE` on each table |
| 1.2 | How many records does each table hold? | `COUNT(*)` per table |
| 1.3 | What does sample data look like in each table? | `SELECT * ... LIMIT 10` per table |
| 1.4 | Which business-critical columns contain unexpected nulls (e.g. `department_id`, `doctor_id`, `diagnosis`)? | `SUM(column IS NULL)` per table |
| 1.5 | Are there duplicate doctors, patients, or appointments? | `GROUP BY` candidate natural keys `HAVING COUNT(*) > 1` |
| 1.6 | What is the distribution of categorical fields — doctor gender/status/specialization, patient gender/blood group, appointment status, payment mode/status, medication status? | `GROUP BY ... ORDER BY count DESC` |
| 1.7 | What date ranges does the data span (joining dates, DOB, admissions, appointments, billing, prescriptions)? | `MIN()` / `MAX()` per date column |
| 1.8 | What are the numeric ranges/averages for experience, consultation fees, department staffing/budget, and bill amounts/discounts/net revenue? | `MIN()`, `MAX()`, `AVG()`, `SUM()` |

**Business value:** Confirms referential completeness (e.g. whether `doctor_id` is ever null on patients/appointments), surfaces potential duplicate-entry issues, and gives baseline statistics that later revenue/clinical KPIs can be sanity-checked against.

---

## 2. Patient Analysis (`03_patient_analysis.sql`)

### 2.1 Patients from Bengaluru
**Objective:** Identify patients located in Bengaluru for regional outreach or reporting.
**Technique:** Simple filter — `WHERE city = 'Bengaluru'`, returning `patient_id`, full name, city, and blood group.
**Business value:** Supports city-level operational and marketing decisions (e.g. regional health camps, blood-donation drives).

### 2.2 Top 5 Highest-Paying Patients
**Objective:** Identify the five patients who have generated the most billing revenue overall.
**Technique:** `JOIN patients ... bills USING (patient_id)`, `SUM(net_amount)`, `GROUP BY patient_id`, `ORDER BY total DESC LIMIT 5`.
**Business value:** Identifies VIP patients for relationship management and retention efforts.

### 2.3 Top 3 Earning Patients Per City
**Objective:** Within each city, identify the three patients with the highest total spend.
**Technique:** Subquery aggregating `SUM(net_amount)` per patient, with `DENSE_RANK() OVER (PARTITION BY city ORDER BY total_paid DESC)`, filtered to `city_rank <= 3`.
**Business value:** Enables city-level VIP segmentation rather than a single hospital-wide ranking, useful for regional account management.

---

## 3. Doctor Analysis (`04_doctor_analysis.sql`)

### 3.1 Active Doctors with Over 10 Years of Experience
**Objective:** Identify senior, currently-practicing doctors.
**Technique:** `WHERE status = 'Active' AND experience_years > 10`.
**Business value:** Supports staffing decisions, senior-mentor assignment, and identifying doctors qualified for complex cases or leadership roles.

### 3.2 Top 5 Departments by Total Revenue
**Objective:** Rank departments by total net revenue generated from all bills (regardless of payment status).
**Technique:** `JOIN departments ... doctors ... bills`, `SUM(net_amount) GROUP BY department_name ORDER BY DESC LIMIT 5`.
**Business value:** Identifies the hospital's most financially significant departments for budget and investment prioritization. *(Note: this query is repeated verbatim in `05_revenue_analysis.sql`; see §4.2 for the revenue-file version, which is functionally identical.)*

### 3.3 Prescribed Medications from 'Ology' Departments
**Objective:** Retrieve all medications prescribed by doctors in departments whose name contains "ology" (Cardiology, Neurology, Oncology, etc.).
**Technique:** `JOIN medications ... doctors ... departments`, `WHERE department_name LIKE '%ology%'`, `SELECT DISTINCT` on drug/prescriber/department.
**Business value:** Enables pharmacy and formulary analysis scoped to specialist ("-ology") departments, useful for stocking and procurement decisions.

### 3.4 Doctors With More Than 8 Appointments (+ Automated Billing Discount)
**Objective:** Identify high-volume doctors (more than 8 appointments handled), and ensure new bills automatically receive a 10% discount when none is specified.
**Technique:** CTE `DoctorAppointments` aggregating `COUNT(appointment_id)` per doctor, filtered `HAVING appointment_count > 8`, `ORDER BY appointment_count DESC`. The discount automation itself is implemented as the trigger `trg_bills_before_insert_combined`, documented in `data_dictionary.md` and consolidated in `07_database_operations.sql` (see the in-file note explaining why the original standalone `trg_update_discount` trigger was merged into it, to avoid an unordered-trigger conflict).
**Business value:** Flags doctors driving the highest patient throughput (useful for workload balancing) and guarantees billing consistency at the database layer rather than relying on application-side logic.

---

## 4. Revenue Analysis (`05_revenue_analysis.sql`)

### 4.1 Paid Bill Summary by Payment Mode
**Objective:** Understand how much revenue has been *collected* (not just billed), broken down by payment mode (Cash, Card, Insurance, UPI).
**Technique:** `WHERE payment_status = 'Paid'`, `GROUP BY payment_mode`, `COUNT(*)` and `SUM(net_amount)`.
**Business value:** Reveals which payment channels drive actual cash flow, informing payment-processing and insurance-partnership priorities.

### 4.2 Top 5 Departments by Total Revenue
**Objective:** Same as §3.2 — rank departments by total net billed revenue.
**Technique:** Identical join/aggregation logic across `departments → doctors → bills`.
**Business value:** Reused as a standard revenue-ranking report; confirms department revenue standing independent of payment status.

### 4.3 Doctor Revenue Analysis View (`vw_doctor_revenue`)
**Objective:** Provide a reusable, always-current view of total *paid* revenue per doctor, and surface doctors generating more than ₹1,000 in net revenue.
**Technique:** `CREATE VIEW vw_doctor_revenue` using `LEFT JOIN bills ... AND payment_status = 'Paid'`, `COALESCE(SUM(net_amount), 0)`, then queried with `WHERE Total Revenue > 1000`.
**Business value:** Turns a common report into a persistent, queryable object rather than a one-off query — supports recurring doctor-performance reviews. *(See the data dictionary's note on this view being redefined later in `07_database_operations.sql`, which is the version that ultimately persists.)*

### 4.4 Top 5 Patients by Total Amount Paid (Paid Bills Only)
**Objective:** A stricter version of §2.2 — ranks patients by amount actually collected (`payment_status = 'Paid'` bills implied by using paid totals), not just billed.
**Technique:** Same join/aggregation pattern as §2.2.
**Business value:** More financially precise VIP-patient list for finance/collections teams, as opposed to the gross-billing view used for relationship management.

### 4.5 City-Wise Patient Payment Ranking
**Objective:** Same as §2.3 — rank the top 3 patients by spend within each city, using window functions.
**Technique:** `DENSE_RANK() OVER (PARTITION BY city ORDER BY SUM(net_amount) DESC)`.
**Business value:** Duplicate of the patient-analysis city ranking, reused here as part of the consolidated revenue report set.

---

## 5. Advanced Analytics (`06_advanced_sql.sql`)

### 5.1 Doctor Revenue Performance & Departmental Share
**Objective:** Rank doctors within their own department by revenue, and quantify what percentage of the department's total revenue each doctor contributes.
**Technique:** CTE `DoctorRevenue` aggregates `SUM(net_amount)` per doctor (joining `doctors → departments → appointments → bills`, filtered to `payment_status = 'Paid'`). Outer query applies `DENSE_RANK() OVER (PARTITION BY department_id ORDER BY total_doctor_revenue DESC)` and computes each doctor's share via `total_doctor_revenue / SUM(total_doctor_revenue) OVER (PARTITION BY department_id)`.
**Business value:** Identifies top-performing doctors *within* their peer group (not hospital-wide), and highlights revenue concentration risk — e.g. departments overly dependent on a single doctor.

### 5.2 Financial Growth & Revenue Trajectory (Month-over-Month)
**Objective:** Track month-over-month (MoM) growth in collected revenue and the cumulative revenue trend over time.
**Technique:** CTE `Monthly_Billing` aggregates paid revenue by `DATE_FORMAT(billing_date, '%Y-%m')`. Outer query uses `LAG(monthly_revenue) OVER (ORDER BY billing_month)` for the prior month, computes `% growth` with `NULLIF` to guard against division by zero, and a running total via `SUM(...) OVER (ORDER BY billing_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`.
**Business value:** Core financial-trend reporting — supports forecasting, board reporting, and early detection of revenue slowdowns.

### 5.3 Operational Efficiency & Hospital Utilization Analysis
**Objective:** Measure appointment completion, cancellation, and pending rates by department.
**Technique:** `LEFT JOIN departments → appointments`, conditional aggregation with `SUM(CASE WHEN status = ... THEN 1 ELSE 0 END)` for Completed/Cancelled/Scheduled counts, percentage rates via `NULLIF`-guarded division, `HAVING COUNT(appointment_id) > 0` to exclude departments with no appointments.
**Business value:** Surfaces departments with high cancellation or low completion rates — an operational red flag for scheduling practices, staffing, or patient communication issues.

### 5.4 Clinical Quality & Patient Readmission (30-Day Window)
**Objective:** Identify patients who returned for a completed follow-up visit within 30 days of a prior completed consultation — a proxy for readmission/frequent-care patterns.
**Technique:** CTE `patient_visit_sequence` uses `LAG(appointment_date) OVER (PARTITION BY patient_id ORDER BY appointment_date)` restricted to `status = 'Completed'` appointments, then filters to visits where `DATEDIFF(current, prior) <= 30`.
**Business value:** A clinical-quality signal — frequent short-interval returns can indicate either good continuity of care or unresolved conditions requiring closer review, both relevant to quality-improvement programs.

### 5.5 Revenue Realization & Receivables Risk Profiling
**Objective:** Compare gross billing, discounts, insurance claims, and outstanding/pending receivables across payment modes.
**Technique:** `GROUP BY payment_mode` with `SUM()` across `total_amount`, `discount`, `insurance_amount`, `net_amount`, plus conditional `SUM(CASE WHEN payment_status = 'Pending' ...)` for pending receivables and a `pending_risk_pct`.
**Business value:** A financial-risk view for the finance team — identifies which payment modes carry the highest proportion of uncollected revenue (e.g. insurance claims pending longer than cash payments).

### 5.6 Top-Decile VIP Patient Lifetime Value (LTV) Segmentation
**Objective:** Identify the top 10% of patients by total paid spend, and their average spend per consultation.
**Technique:** CTE `VIP_patients` aggregates distinct completed appointments and total paid spend per patient (`payment_status = 'Paid'`), applies `NTILE(10) OVER (ORDER BY SUM(net_amount) DESC)` to bucket patients into deciles, then filters to `spend_decile = 1` (top 10%).
**Business value:** A more rigorous LTV segmentation than a flat "Top 5" list — supports patient-loyalty programs, premium-service targeting, and city-level VIP concentration analysis (via the `city` field included in the output).

---

## 6. Operational Automation (`07_database_operations.sql`)

While not "business questions" in the query sense, these objects encode operational business rules directly into the database layer:

| Object | Business Rule Encoded |
|---|---|
| `trg_bills_before_insert_combined` | Every bill gets a consistent, server-enforced discount default (10% when unspecified), a correctly recalculated `net_amount`, and a default 14-day payment due date — removing dependence on the application layer to get billing math right. |
| `trg_appointments_validate_doctor` | Appointments cannot be booked with doctors who are `Retired` or `On Leave`, preventing invalid scheduling at the source. |
| `sp_discharge_patient` | A patient cannot be discharged while they still have unpaid (`Pending`) bills, enforced transactionally with automatic rollback on error. |
| `vw_active_inpatients` | Standing report: which patients are currently admitted, how long they've been in, and under whose care. |
| `vw_outstanding_bills` | Standing report: real-time accounts-receivable list with days-overdue calculation. |
| `vw_doctor_revenue` | Standing report: per-doctor realized revenue from paid bills (authoritative version; see data dictionary note on the duplicate earlier definition). |
| `idx_payment_status` | Performance optimization — dedicated index to keep `payment_status`-filtered queries (used throughout §4–§6) fast as bill volume scales. |

---

## Cross-Cutting Observations

- **Revenue definitions vary by query** — some reports (e.g. §3.2/§4.2 "Top 5 Departments by Total Revenue") sum `net_amount` across *all* bills regardless of `payment_status`, while others (e.g. §4.1, §4.3, §4.4, §5.1, §5.6) restrict to `payment_status = 'Paid'` only. When comparing figures across reports, confirm which definition — *billed* vs. *collected* revenue — is in use.
- **Duplicate queries across files** are intentional carry-overs (e.g. the "Top 3 Earning Patients Per City" query appears in both `03_patient_analysis.sql` and `05_revenue_analysis.sql`; "Top 5 Departments by Total Revenue" appears in both `04_doctor_analysis.sql` and `05_revenue_analysis.sql`) rather than errors — each file groups the same underlying report under a different thematic lens (patient-centric vs. revenue-centric).
- **Window functions** (`DENSE_RANK`, `LAG`, `NTILE`, running `SUM() OVER`) are used consistently from `03_patient_analysis.sql` onward for any "top N within a group" or "trend over time" question, since these cannot be expressed with simple `GROUP BY` aggregation alone.
