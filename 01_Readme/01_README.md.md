# 🏥 Healthcare Data Analytics | SQL

> **A SQL-driven healthcare analytics project focused on patient, doctor, department, billing, medication, and operational analysis using MySQL.**

---

## 📌 Project Overview

This project analyzes a relational healthcare database to uncover operational and financial insights across patients, doctors, departments, appointments, medications, and billing records.

The project was designed as a practical **Data Analyst portfolio project**, with an emphasis on turning business questions into structured SQL analysis rather than simply demonstrating isolated SQL syntax.

The analysis covers:

- Patient and city-level analysis
- Doctor workload and performance
- Department revenue
- Patient payment behavior
- Billing and payment-mode analysis
- Medication and department analysis
- Ranking patients within cities
- Doctor appointment analysis
- SQL views, CTEs, window functions, and triggers
- Controlled database operations and validation

---

## 🎯 Business Objective

Healthcare organizations generate large amounts of operational and financial data. This project uses SQL to answer questions that can support better reporting and decision-making.

### Key business questions

1. Which cities have the largest patient populations?
2. Which doctors have the highest patient workload?
3. Which departments generate the most revenue?
4. Which doctors generate the highest revenue from paid bills?
5. Who are the highest-value patients based on total payments?
6. How does revenue vary by payment method?
7. Which patients are the top earners within each city?
8. Which departments prescribe the largest variety of medications?
9. Which doctors have handled the highest number of appointments?
10. How can billing data be safely updated and validated?

---

## 🗂️ Database Overview

The project is built around a relational healthcare database containing the following core entities:

| Table | Purpose |
|---|---|
| `patients` | Patient demographic and healthcare-related information |
| `doctors` | Doctor details, specialization, experience, and status |
| `departments` | Hospital department information |
| `bills` | Patient billing, payment, discount, and insurance information |
| `appointments` | Doctor-patient appointment records |
| `medications` | Medication records associated with doctors/patients |

The database relationships allow analysis across multiple business areas using SQL joins and aggregations.

---

## 🧩 Analytical Workflow

The project follows a practical analytics workflow:

```text
Healthcare Database
        ↓
Data Exploration
        ↓
Data Validation
        ↓
SQL Transformations
        ↓
Business Analysis
        ↓
Advanced SQL Analysis
        ↓
Key Insights
        ↓
Business Recommendations
```

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| **MySQL** | Database creation and SQL analysis |
| **SQL** | Data exploration, transformation, aggregation, and analysis |
| **MySQL Workbench** | Query development and database management |
| **GitHub** | Version control and project portfolio |

---

## 🧠 SQL Skills Demonstrated

This project demonstrates both foundational and advanced SQL techniques.

### Core SQL

- `SELECT`
- `WHERE`
- `ORDER BY`
- `LIMIT`
- `DISTINCT`
- `LIKE`
- `CONCAT`
- Aggregate functions
- `GROUP BY`
- `HAVING`

### Data Analysis

- `COUNT()`
- `SUM()`
- `AVG()`
- `COALESCE()`
- Multi-table `JOIN`
- `LEFT JOIN`
- Business metric calculations
- Ranking and segmentation

### Advanced SQL

- Common Table Expressions (`CTE`)
- Window functions
- `RANK()`
- `DENSE_RANK()`
- `PARTITION BY`
- SQL Views
- Triggers
- Conditional logic
- Database and table creation
- Data modification and validation

---

## 📊 Analysis Areas

### 1. Patient Analysis

The project analyzes:

- Patients by city
- Patient payment behavior
- Highest-paying patients
- Top patients within each city

Example business question:

> **Who are the top 3 highest-paying patients in each city?**

This analysis uses aggregation followed by a window function with `PARTITION BY`.

---

### 2. Doctor Performance Analysis

The project evaluates:

- Active doctors
- Doctor experience
- Number of patients handled
- Number of appointments handled
- Doctor-level revenue

Example business question:

> **Which doctors have handled the highest number of patients and appointments?**

This helps demonstrate how operational workload can be analyzed at the individual doctor level.

---

### 3. Department Revenue Analysis

Revenue is analyzed by connecting:

```text
Departments
     ↓
Doctors
     ↓
Bills
```

The analysis identifies the highest-revenue departments using joins, aggregation, and ranking.

Example business question:

> **Which departments generate the highest total revenue from patient bills?**

---

### 4. Billing & Payment Analysis

The project analyzes:

- Paid bills
- Pending bills
- Revenue by payment mode
- Total net amount
- Patient payment totals
- Discount updates

Example business question:

> **Which payment methods contribute the most to paid revenue?**

---

### 5. Medication Analysis

Medication records are connected with doctors and departments to identify medications prescribed by doctors belonging to departments whose names contain `"ology"`.

This demonstrates multi-table joins and filtering across related entities.

---

## 🔍 Advanced SQL Analysis

### Window Functions

Patient spending is ranked within each city using:

```sql
DENSE_RANK() OVER (
    PARTITION BY p.city
    ORDER BY SUM(b.net_amount) DESC
)
```

This allows the analysis to answer:

> **Who are the highest-paying patients within each city?**

---

### Common Table Expression

A CTE is used to identify doctors who have handled more than a specified number of appointments.

```sql
WITH DoctorAppointments AS (
    SELECT
        d.doctor_id,
        CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
        COUNT(a.appointment_id) AS appointment_count
    FROM doctors d
    JOIN appointments a
        ON d.doctor_id = a.doctor_id
    GROUP BY
        d.doctor_id,
        d.first_name,
        d.last_name
)
```

---

### SQL View

The project creates a reusable view:

```text
vw_doctor_revenue
```

The view summarizes total revenue collected from paid bills at the doctor level.

This demonstrates how SQL views can simplify repeated reporting and analysis.

---

### SQL Trigger

The project also demonstrates a database trigger:

```text
trg_update_discount
```

The trigger automatically assigns a discount when a newly inserted bill has a `NULL` discount value.

This demonstrates basic database automation in addition to analytical SQL.

---

## 📁 Project Structure

The repository is organized to separate database setup, analysis, documentation, and supporting assets.

```text
Healthcare-Data-Analytics/
│
├── README.md
│
├── data/
│   └── healthcare_analytics_database.sql
│
├── sql/
│   ├── 01_database_exploration.sql
│   ├── 02_patient_analysis.sql
│   ├── 03_doctor_analysis.sql
│   ├── 04_revenue_analysis.sql
│   ├── 05_department_analysis.sql
│   ├── 06_advanced_sql.sql
│   └── 07_database_operations.sql
│
├── documentation/
│   ├── data_dictionary.md
│   └── business_questions.md
│
├── insights/
│   └── key_insights.md
│
└── images/
    ├── healthcare_schema.png
    ├── revenue_analysis.png
    ├── doctor_performance.png
    └── patient_analysis.png
```

> **Note:** The repository structure above represents the planned professional structure. Files will be added as the project is progressively organized and enhanced.

---

## 📈 Key Insights

> This section will be populated with **actual results from the completed analysis** rather than assumptions.

The final project will summarize findings such as:

- Highest-revenue departments
- Highest-revenue doctors
- Highest-value patients
- Patient spending patterns by city
- Payment-mode performance
- Doctor workload distribution
- Appointment volume
- Billing and payment-status patterns

### Example insight format

```text
Department Performance
→ Department X generated the highest total revenue.

Patient Value
→ Patient Y had the highest total amount paid.

Doctor Workload
→ Doctor Z handled the highest number of appointments.
```

Actual values will be added after the final SQL analysis is completed and validated.

---

## 💡 Business Recommendations

The final analysis will translate SQL results into business-oriented recommendations.

Potential recommendation areas include:

- Monitor high-revenue departments for capacity planning.
- Review doctor workload distribution to identify resource constraints.
- Identify high-value patients for improved service and retention strategies.
- Monitor pending bills to improve payment collection.
- Evaluate payment-mode trends to improve billing operations.
- Use recurring SQL views for standardized management reporting.

Recommendations will be finalized using the actual results produced by the completed project.

---

## ▶️ How to Run the Project

### Prerequisites

- MySQL Server
- MySQL Workbench or another MySQL-compatible SQL client
- Git

### Step 1 — Clone the repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

### Step 2 — Open MySQL Workbench

Create/connect to your MySQL server.

### Step 3 — Create the database

Run the database setup script:

```sql
CREATE DATABASE healthcare_analytics_db;
USE healthcare_analytics_db;
```

### Step 4 — Load the healthcare tables

Execute the database setup SQL file.

### Step 5 — Run analysis scripts

Execute the SQL scripts in the recommended order:

```text
01_database_exploration.sql
02_patient_analysis.sql
03_doctor_analysis.sql
04_revenue_analysis.sql
05_department_analysis.sql
06_advanced_sql.sql
07_database_operations.sql
```

### Step 6 — Review results

Review the output tables and validate the results against the corresponding business questions.

---

## ✅ Data Quality & Validation

The project includes validation steps before and after data operations.

Examples include:

- Checking record counts
- Previewing records before updates
- Validating pending bills
- Reviewing calculated revenue
- Checking joins between related entities
- Verifying updated billing values

This helps reduce the risk of incorrect results and demonstrates an analytical approach beyond simply writing SQL queries.

---

## 🚀 Future Enhancements

The project can be extended into a broader healthcare analytics solution by adding:

- 📊 Power BI dashboard
- 📈 KPI reporting
- 🧹 Dedicated data-cleaning scripts
- 📚 Data dictionary
- 🗺️ Entity Relationship Diagram (ERD)
- 📸 Query-result screenshots
- 🧠 Additional business insights
- 📅 Time-based revenue and appointment analysis
- 🔎 More advanced patient and department segmentation

---

## 🎓 What This Project Demonstrates

This project demonstrates the ability to:

> **Understand a relational database → translate business questions into SQL → combine multiple tables → perform analytical calculations → use advanced SQL techniques → validate results → communicate findings for business decision-making.**

The goal is not only to demonstrate SQL syntax, but to show how SQL can be used as an **analytical tool for solving practical healthcare business problems**.

---

## 👤 About

**Omkar Sawant**  
Aspiring Data Analyst

**Core Skills:** SQL • Excel • Power BI • Tableau • Python • Data Analysis

This project is part of my Data Analytics portfolio and demonstrates my practical SQL and analytical problem-solving skills.

---

## 📌 Project Status

**Current Status:** 🚧 In Progress

The project is being progressively enhanced with:

- Professional SQL organization
- Data dictionary
- ER diagram
- Business-focused analysis
- Key insights
- Result screenshots
- Portfolio-ready documentation

---

⭐ If you find this project useful, feel free to explore the SQL scripts and analysis.
