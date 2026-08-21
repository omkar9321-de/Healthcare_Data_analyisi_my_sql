# Data Dictionary — Healthcare Analytics DB

**Database:** `Healthcare_Analytics_DB`
**Engine:** MySQL 8.0+ (InnoDB, `utf8mb4` / `utf8mb4_0900_ai_ci`)
**Version:** 1.0
**Last Updated:** 2026-08-21

## Overview

`Healthcare_Analytics_DB` models the day-to-day operations of a multi-department hospital network: departments and their staffing/budget, doctors and their specializations, patients and admissions, appointments, billing, and prescribed medications. The schema is fully relational — every transactional table (`doctors`, `patients`, `appointments`, `bills`, `medications`) is tied back to `departments` and/or `doctors`/`patients` via foreign keys, which is what makes the cross-table revenue, utilization, and clinical-quality analysis in this project possible.

**Entity relationship summary:**

```
departments ─┬──< doctors ─┬──< appointments >──┬── patients
             │              │                    │
             └── (head_doctor_id, no FK) ─────────┘
                            ├──< bills           │
                            └──< medications ─────┘
appointments ──1:1── bills
appointments ──1:N── medications
```

- One **department** has many **doctors**.
- One **doctor** has many **patients** (as attending physician), **appointments**, **bills**, and **medications** prescribed.
- One **patient** has many **appointments**, **bills**, and **medications**.
- One **appointment** has exactly one **bill** (1:1, enforced by a `UNIQUE` constraint) and can generate zero or more **medications**.

---

## Table: `departments`

Hospital departments/wards — one row per department, including its location, staffing, and budget.

| Column | Type | Nullable | Key | Default | Description |
|---|---|---|---|---|---|
| `department_id` | INT | NO | PK, AUTO_INCREMENT | — | Unique identifier for the department. |
| `department_name` | VARCHAR(100) | NO | | — | Department name (e.g. Cardiology, Neurology). |
| `city` | VARCHAR(80) | NO | Indexed (`ix_departments_city`) | — | City where the department is physically located. |
| `location_floor` | VARCHAR(20) | NO | | — | Building floor code (e.g. `F3`). |
| `phone_extension` | VARCHAR(10) | NO | | — | Internal phone extension. |
| `total_staff` | INT | NO | | 0 | Total staff headcount assigned to the department. |
| `budget_allocation` | DECIMAL(12,2) | NO | | 0 | Annual budget allocated to the department (₹). |
| `established_year` | INT | NO | | — | Calendar year the department was established. |
| `shift_timing` | VARCHAR(50) | NO | | — | Operating hours (e.g. `08:00-16:00`). |
| `head_doctor_id` | INT | YES | | NULL | ID of the doctor heading the department. **Not FK-enforced** — no `REFERENCES doctors(doctor_id)` constraint exists in the schema, so this value should be treated as informational only until validated against `doctors.doctor_id`. |

**Indexes:** `PRIMARY KEY (department_id)`, `ix_departments_city (city)`

---

## Table: `doctors`

Physicians employed across departments, including specialization, employment status, and fee.

| Column | Type | Nullable | Key | Default | Description |
|---|---|---|---|---|---|
| `doctor_id` | INT | NO | PK, AUTO_INCREMENT | — | Unique identifier for the doctor. |
| `first_name` | VARCHAR(50) | NO | | — | Doctor's first name. |
| `last_name` | VARCHAR(50) | NO | | — | Doctor's last name. |
| `gender` | ENUM('Male','Female','Other') | NO | | — | Doctor's gender. |
| `specialization` | VARCHAR(100) | NO | | — | Medical specialty (e.g. Cardiology, Family Medicine). Free text — not constrained to the department's name, so a doctor's specialization and department name may differ. |
| `department_id` | INT | NO | FK → `departments.department_id`, Indexed (`ix_doctors_dept`) | — | Department the doctor belongs to. |
| `city` | VARCHAR(80) | NO | Indexed (`ix_doctors_city`) | — | City the doctor is based in. |
| `experience_years` | INT | NO | CHECK (`experience_years >= 0`) | — | Years of professional experience. |
| `phone` | VARCHAR(15) | NO | UNIQUE | — | Contact phone number. |
| `email` | VARCHAR(100) | NO | UNIQUE | — | Contact email address. |
| `joining_date` | DATE | NO | | — | Date the doctor joined the hospital. |
| `consultation_fee` | DECIMAL(10,2) | NO | CHECK (`consultation_fee >= 0`) | — | Standard consultation fee (₹). |
| `status` | ENUM('Active','On Leave','Retired') | NO | | 'Active' | Current employment status. Appointments cannot be booked with doctors whose status is `Retired` or `On Leave` (see `trg_appointments_validate_doctor`). |

**Indexes:** `PRIMARY KEY (doctor_id)`, `ix_doctors_dept (department_id)`, `ix_doctors_name (last_name, first_name)`, `ix_doctors_city (city)`, unique indexes on `phone` and `email`

**Foreign keys:** `fk_doc_dept: department_id → departments.department_id`

---

## Table: `patients`

Patient master record, including demographics, admission status, and attending physician.

| Column | Type | Nullable | Key | Default | Description |
|---|---|---|---|---|---|
| `patient_id` | INT | NO | PK, AUTO_INCREMENT | — | Unique identifier for the patient. |
| `first_name` | VARCHAR(50) | NO | | — | Patient's first name. |
| `last_name` | VARCHAR(50) | NO | | — | Patient's last name. |
| `gender` | ENUM('Male','Female','Other') | NO | | — | Patient's gender. |
| `date_of_birth` | DATE | NO | | — | Date of birth. |
| `phone` | VARCHAR(15) | NO | UNIQUE | — | Contact phone number. |
| `email` | VARCHAR(100) | NO | UNIQUE | — | Contact email address. |
| `address` | VARCHAR(255) | NO | | — | Street address. |
| `city` | VARCHAR(80) | NO | Indexed (`ix_patients_city`) | — | City of residence. |
| `blood_group` | ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') | NO | | — | Blood group. |
| `admission_date` | DATE | YES | | NULL | Date of hospital admission; `NULL` if the patient has never been admitted (outpatient only). |
| `discharge_date` | DATE | YES | | NULL | Date of discharge. `NULL` with a non-null `admission_date` indicates an **active inpatient** (see `vw_active_inpatients`). |
| `doctor_id` | INT | YES | FK → `doctors.doctor_id`, Indexed (`ix_patients_doctor`) | NULL | Primary/attending doctor. |
| `insurance_provider` | VARCHAR(100) | YES | | NULL | Name of the patient's insurance provider, if any. |

**Indexes:** `PRIMARY KEY (patient_id)`, `ix_patients_city (city)`, `ix_patients_doctor (doctor_id)`, `ix_patients_name (last_name, first_name)`, unique indexes on `phone` and `email`

**Foreign keys:** `fk_patient_doctor: doctor_id → doctors.doctor_id`

---

## Table: `appointments`

Individual patient-doctor consultations/visits.

| Column | Type | Nullable | Key | Default | Description |
|---|---|---|---|---|---|
| `appointment_id` | INT | NO | PK, AUTO_INCREMENT | — | Unique identifier for the appointment. |
| `patient_id` | INT | NO | FK → `patients.patient_id`, Indexed (`ix_appt_patient`) | — | Patient attending the appointment. |
| `doctor_id` | INT | NO | FK → `doctors.doctor_id`, Indexed (`ix_appt_doctor`) | — | Doctor conducting the appointment. |
| `department_id` | INT | NO | FK → `departments.department_id`, Indexed (`ix_appt_dept`) | — | Department the appointment is booked under. |
| `appointment_date` | DATE | NO | Indexed (`ix_appt_status_date`, composite) | — | Date of the appointment. |
| `appointment_time` | TIME | NO | | — | Time of the appointment. |
| `purpose` | VARCHAR(100) | NO | | — | Stated reason for the visit. |
| `diagnosis` | VARCHAR(255) | YES | | NULL | Diagnosis recorded during/after the visit. |
| `status` | ENUM('Scheduled','Completed','Cancelled') | NO | Indexed (`ix_appt_status_date`, composite) | — | Current status of the appointment. |
| `follow_up_required` | BOOLEAN | NO | | FALSE | Whether a follow-up visit is required. |
| `follow_up_date` | DATE | YES | | NULL | Scheduled follow-up date, if any. |
| `created_at` | DATETIME | NO | | `CURRENT_TIMESTAMP` | Timestamp the record was created. |

**Indexes:** `PRIMARY KEY (appointment_id)`, `ix_appt_patient (patient_id)`, `ix_appt_doctor (doctor_id)`, `ix_appt_dept (department_id)`, `ix_appt_status_date (status, appointment_date)`

**Foreign keys:** `fk_appt_patient: patient_id → patients.patient_id`, `fk_appt_doctor: doctor_id → doctors.doctor_id`, `fk_appt_department: department_id → departments.department_id`

**Business rule:** `trg_appointments_validate_doctor` (BEFORE INSERT) blocks any new appointment where the target doctor's `status` is `'Retired'` or `'On Leave'`, raising `SQLSTATE '45000'`.

---

## Table: `bills`

One financial record per appointment.

| Column | Type | Nullable | Key | Default | Description |
|---|---|---|---|---|---|
| `bill_id` | INT | NO | PK, AUTO_INCREMENT | — | Unique identifier for the bill. |
| `appointment_id` | INT | NO | FK → `appointments.appointment_id`, **UNIQUE** | — | Appointment this bill was generated for. The `UNIQUE` constraint enforces a 1:1 relationship between appointments and bills. |
| `patient_id` | INT | NO | FK → `patients.patient_id`, Indexed (`ix_bills_patient`) | — | Billed patient (denormalized from the appointment for query convenience). |
| `doctor_id` | INT | NO | FK → `doctors.doctor_id`, Indexed (`ix_bills_doctor`) | — | Billed doctor (denormalized from the appointment). |
| `total_amount` | DECIMAL(10,2) | NO | CHECK (`total_amount >= 0`) | — | Gross billed amount before discount/insurance (₹). |
| `discount` | DECIMAL(10,2) | NO | CHECK (`discount >= 0`) | 0 | Discount applied (₹). Auto-populated by `trg_bills_before_insert_combined` when left `NULL` on insert (see below). |
| `insurance_amount` | DECIMAL(10,2) | YES | CHECK (`insurance_amount >= 0`) | NULL | Amount covered by insurance (₹), if applicable. |
| `net_amount` | DECIMAL(10,2) | NO | | — | Final payable amount. **Always recalculated server-side** by `trg_bills_before_insert_combined` as `total_amount - discount - COALESCE(insurance_amount, 0)`, regardless of what is supplied on `INSERT`. |
| `payment_mode` | ENUM('Cash','Card','Insurance','UPI') | NO | | — | Mode of payment. |
| `payment_status` | ENUM('Paid','Pending','Rejected') | NO | Indexed (`ix_bills_status_date`, composite; `idx_payment_status`) | 'Pending' | Current payment status. |
| `billing_date` | DATE | NO | Indexed (`ix_bills_status_date`, composite) | — | Date the bill was issued. |
| `due_date` | DATE | NO | | — | Payment due date. Auto-populated to `billing_date + 14 days` by `trg_bills_before_insert_combined` when left `NULL` on insert. |
| `insurance_claimed` | BOOLEAN | NO | | FALSE | Whether an insurance claim has been filed for this bill. |

**Indexes:** `PRIMARY KEY (bill_id)`, `UNIQUE (appointment_id)`, `ix_bills_patient (patient_id)`, `ix_bills_doctor (doctor_id)`, `ix_bills_status_date (payment_status, billing_date)`, `idx_payment_status (payment_status)`

**Foreign keys:** `fk_bill_appt: appointment_id → appointments.appointment_id`, `fk_bill_patient: patient_id → patients.patient_id`, `fk_bill_doctor: doctor_id → doctors.doctor_id`

**Business rule — `trg_bills_before_insert_combined` (BEFORE INSERT):**
1. If `discount IS NULL`, sets it to `10% of total_amount`. (Note: if the `discount` column is simply omitted from an `INSERT` statement rather than passed as explicit `NULL`, MySQL substitutes the column default of `0` before the trigger runs, and the 10% auto-discount will **not** apply — only an explicit `NULL` triggers it.)
2. Recalculates `net_amount = (total_amount - discount) - COALESCE(insurance_amount, 0)`, overriding any client-supplied value.
3. If `due_date IS NULL`, sets it to `billing_date + INTERVAL 14 DAY`.

This trigger replaces two earlier, separately-defined `BEFORE INSERT` triggers (`trg_update_discount` and an earlier `trg_bills_before_insert`) that were merged to remove a MySQL trigger-ordering hazard — see the note in `04_doctor_analysis.sql`.

---

## Table: `medications`

Medications prescribed during an appointment.

| Column | Type | Nullable | Key | Default | Description |
|---|---|---|---|---|---|
| `medication_id` | INT | NO | PK, AUTO_INCREMENT | — | Unique identifier for the medication record. |
| `appointment_id` | INT | NO | FK → `appointments.appointment_id`, Indexed (`ix_meds_appt`) | — | Appointment the medication was prescribed during. |
| `patient_id` | INT | NO | FK → `patients.patient_id`, Indexed (`ix_meds_patient`) | — | Patient the medication was prescribed to (denormalized). |
| `doctor_id` | INT | NO | FK → `doctors.doctor_id`, Indexed (`ix_meds_doctor`) | — | Prescribing doctor (denormalized). |
| `generic_name` | VARCHAR(100) | NO | Indexed (`ix_meds_names`, composite) | — | Generic drug name. |
| `brand_name` | VARCHAR(100) | NO | Indexed (`ix_meds_names`, composite) | — | Brand/trade name. |
| `dosage` | VARCHAR(50) | NO | | — | Dosage (e.g. `500mg`). |
| `frequency` | VARCHAR(50) | NO | | — | Dosing frequency (e.g. `twice daily`). |
| `start_date` | DATE | NO | | — | Date the medication course started. |
| `end_date` | DATE | YES | | NULL | Date the course ended/is scheduled to end; `NULL` if ongoing. |
| `notes` | VARCHAR(255) | YES | | NULL | Free-text clinical notes. |
| `status` | ENUM('Active','Completed') | NO | | 'Active' | Current status of the medication course. |
| `prescribed_date` | DATE | NO | | — | Date the prescription was issued. |

**Indexes:** `PRIMARY KEY (medication_id)`, `ix_meds_patient (patient_id)`, `ix_meds_doctor (doctor_id)`, `ix_meds_appt (appointment_id)`, `ix_meds_names (generic_name, brand_name)`

**Foreign keys:** `fk_med_appt: appointment_id → appointments.appointment_id`, `fk_med_patient: patient_id → patients.patient_id`, `fk_med_doctor: doctor_id → doctors.doctor_id`

---

## Derived Objects (Views)

### `vw_active_inpatients`
Patients currently admitted (`admission_date IS NOT NULL AND discharge_date IS NULL`), joined to their attending doctor and department.

| Column | Source | Description |
|---|---|---|
| `patient_id` | `patients.patient_id` | Patient identifier. |
| `patient_name` | `patients.first_name/last_name` | Concatenated full name. |
| `admission_date` | `patients.admission_date` | Admission date. |
| `current_stay_days` | `DATEDIFF(CURRENT_DATE, admission_date)` | Days elapsed since admission. |
| `attending_doctor` | `doctors.first_name/last_name` | Prefixed with "Dr. ". |
| `department_name` | `departments.department_name` | Attending doctor's department. |

### `vw_outstanding_bills`
Accounts-receivable tracker for bills with `payment_status = 'Pending'`.

| Column | Source | Description |
|---|---|---|
| `bill_id` | `bills.bill_id` | Bill identifier. |
| `patient_id` | `bills.patient_id` | Patient identifier. |
| `patient_name` | `patients.first_name/last_name` | Concatenated full name. |
| `patient_phone` | `patients.phone` | Contact number. |
| `net_amount` | `bills.net_amount` | Amount owed. |
| `due_date` | `bills.due_date` | Payment due date. |
| `days_overdue` | `DATEDIFF(CURRENT_DATE, due_date)` | Positive = overdue; negative = not yet due. |

### `vw_doctor_revenue`
Total realized revenue per doctor from paid bills only (`payment_status = 'Paid'`).

> **Note:** This view is defined twice across the project — once in `05_revenue_analysis.sql` (columns: `doctor_id`, `Full name`, `Total Revenue`) and once, as the authoritative version, in `07_database_operations.sql` via `CREATE OR REPLACE VIEW` (columns below). The `07_database_operations.sql` definition is the one that persists after both scripts run, since it overwrites the earlier one.

| Column | Source | Description |
|---|---|---|
| `doctor_id` | `doctors.doctor_id` | Doctor identifier. |
| `doctor_name` | `doctors.first_name/last_name` | Concatenated full name. |
| `specialization` | `doctors.specialization` | Doctor's specialty. |
| `total_revenue` | `SUM(bills.net_amount)` via `LEFT JOIN ... AND payment_status = 'Paid'`, `COALESCE(...,0)` | Total revenue from paid bills; doctors with none show `0`. |

---

## Stored Procedures

### `sp_discharge_patient(p_patient_id INT, p_discharge_date DATE)`
Safely discharges a patient by setting `patients.discharge_date`, but only after confirming there are no outstanding (`payment_status = 'Pending'`) bills for that patient.

- Runs inside an explicit transaction (`START TRANSACTION` / `COMMIT` / `ROLLBACK`).
- If pending bills exist: rolls back and raises `SQLSTATE '45000'` — *"Discharge Error: Patient has pending unpaid bills that must be settled first."*
- If any unhandled SQL exception occurs mid-transaction: an `EXIT HANDLER` rolls back and raises *"System error: Transaction rolled back to maintain data integrity."*

---

## Triggers Summary

| Trigger | Table | Timing/Event | Purpose |
|---|---|---|---|
| `trg_bills_before_insert_combined` | `bills` | BEFORE INSERT | Defaults `discount` to 10% of `total_amount` when `NULL`; recalculates `net_amount`; defaults `due_date` to `billing_date + 14 days` when `NULL`. Supersedes the earlier `trg_update_discount` and `trg_bills_before_insert`. |
| `trg_appointments_validate_doctor` | `appointments` | BEFORE INSERT | Blocks appointment creation if the target doctor's `status` is `'Retired'` or `'On Leave'`. |

---

## Data Quality Notes

- `departments.head_doctor_id` references a doctor conceptually but is **not** enforced by a foreign key — values should be validated against `doctors.doctor_id` before being trusted in reporting.
- `bills.net_amount` is not client-supplied in practice — it is always recomputed by `trg_bills_before_insert_combined`, so any analysis of "raw" billing input should look at `total_amount`, `discount`, and `insurance_amount` instead.
- `patients.admission_date` / `discharge_date` and `medications.end_date` are nullable by design and carry business meaning (ongoing admission, ongoing medication course) rather than representing missing data.
- Two versions of `vw_doctor_revenue` exist across the SQL scripts; only the later `CREATE OR REPLACE VIEW` definition (in `07_database_operations.sql`) is authoritative once both scripts have run.
