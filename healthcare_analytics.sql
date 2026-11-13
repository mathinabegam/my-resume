CREATE DATABASE IF NOT EXISTS healthcare_analytics;
USE healthcare_analytics;

DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS diagnoses;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS patients;

CREATE TABLE patients (
    patient_id      INT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    age             INT,
    gender          VARCHAR(10),
    address         VARCHAR(255),
    contact_number  VARCHAR(20)          -- text so LIKE / string functions work
);

CREATE TABLE doctors (
    doctor_id         INT PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    specialization    VARCHAR(100),
    experience_years  INT,
    contact_number    VARCHAR(20)
);

CREATE TABLE appointments (
    appointment_id    INT PRIMARY KEY,
    patient_id        INT NOT NULL,
    doctor_id         INT NOT NULL,
    appointment_date  DATE,
    reason            VARCHAR(50),
    status            VARCHAR(20),       -- Completed / Cancelled / Scheduled
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id),
    INDEX idx_appt_patient_doctor (patient_id, doctor_id),
    INDEX idx_appt_status (status)
);

CREATE TABLE diagnoses (
    diagnosis_id    INT PRIMARY KEY,
    patient_id      INT NOT NULL,
    doctor_id       INT NOT NULL,
    diagnosis_date  DATE,
    diagnosis       VARCHAR(100),
    treatment       VARCHAR(100),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id),
    INDEX idx_dx_patient_doctor (patient_id, doctor_id)
);

CREATE TABLE medications (
    medication_id    INT PRIMARY KEY,
    diagnosis_id     INT NOT NULL,
    medication_name  VARCHAR(100),
    dosage           VARCHAR(50),
    start_date       DATE,
    end_date         DATE,
    FOREIGN KEY (diagnosis_id) REFERENCES diagnoses(diagnosis_id),
    INDEX idx_med_name (medication_name)
);

-- Load order matters (parents first). Edit the paths below.
LOAD DATA LOCAL INFILE 'data/patients.csv'     INTO TABLE patients
    FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/doctors.csv'      INTO TABLE doctors
    FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/appointments.csv' INTO TABLE appointments
    FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/diagnoses.csv'    INTO TABLE diagnoses
    FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/medications.csv'  INTO TABLE medications
    FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Sanity check: expect 5000 / 300 / 10000 / 15000 / 12000
SELECT (SELECT COUNT(*) FROM patients)     AS patients,
       (SELECT COUNT(*) FROM doctors)      AS doctors,
       (SELECT COUNT(*) FROM appointments) AS appointments,
       (SELECT COUNT(*) FROM diagnoses)    AS diagnoses,
       (SELECT COUNT(*) FROM medications)  AS medications;


/* =====================================================================
   Q1 : INNER JOIN
   Purpose : Details of all completed appointments with patient name,
             doctor name and specialization.
   Output  : one row per completed appointment (3,392 rows).
   ===================================================================== */
-- Q1
SELECT a.appointment_id,
       a.appointment_date,
       a.reason,
       p.name            AS patient_name,
       d.name            AS doctor_name,
       d.specialization
FROM appointments a
INNER JOIN patients p ON p.patient_id = a.patient_id
INNER JOIN doctors  d ON d.doctor_id  = a.doctor_id
WHERE a.status = 'Completed'
ORDER BY a.appointment_date, a.appointment_id;


/* =====================================================================
   Q2 : LEFT JOIN + NULL handling
   Purpose : Patients who have never had an appointment (of any status).
   Output  : name, contact, address (662 patients).
   ===================================================================== */
-- Q2
SELECT p.patient_id,
       p.name,
       COALESCE(p.contact_number, 'N/A') AS contact_number,
       COALESCE(p.address, 'N/A')        AS address
FROM patients p
LEFT JOIN appointments a ON a.patient_id = p.patient_id
WHERE a.appointment_id IS NULL
ORDER BY p.patient_id;


/* =====================================================================
   Q3 : RIGHT JOIN + aggregate
   Purpose : Total diagnoses per doctor, keeping doctors with none.
   Output  : doctor, specialization, total_diagnoses (300 rows).
   Note    : in this dataset every doctor has >= 1 diagnosis, so no zeros
             appear, but the RIGHT JOIN would keep them if they existed.
   ===================================================================== */
-- Q3
SELECT d.name AS doctor_name,
       d.specialization,
       COUNT(dg.diagnosis_id) AS total_diagnoses   -- COUNT(col) ignores NULLs -> 0 for no match
FROM diagnoses dg
RIGHT JOIN doctors d ON d.doctor_id = dg.doctor_id
GROUP BY d.doctor_id, d.name, d.specialization
ORDER BY total_diagnoses DESC, d.name;


/* =====================================================================
   Q4 : FULL OUTER JOIN (emulated) - appointments vs diagnoses
   Purpose : Find mismatches between the two tables. Because diagnoses
             has no appointment_id, rows are compared at the
             (patient, doctor) level:
               Appointment only  = patient saw doctor, no diagnosis recorded
               Diagnosis only    = diagnosis recorded, no appointment on file
               Matched           = both exist
   ===================================================================== */
-- Q4a : detail rows for mismatches only, with patient and doctor details
WITH appt_pairs AS (
    SELECT patient_id, doctor_id, COUNT(*) AS appointment_count
    FROM appointments GROUP BY patient_id, doctor_id
),
dx_pairs AS (
    SELECT patient_id, doctor_id, COUNT(*) AS diagnosis_count
    FROM diagnoses GROUP BY patient_id, doctor_id
),
full_pairs AS (
    SELECT a.patient_id, a.doctor_id, a.appointment_count, d.diagnosis_count
    FROM appt_pairs a
    LEFT JOIN dx_pairs d ON d.patient_id = a.patient_id AND d.doctor_id = a.doctor_id
    UNION ALL
    SELECT d.patient_id, d.doctor_id, a.appointment_count, d.diagnosis_count
    FROM appt_pairs a
    RIGHT JOIN dx_pairs d ON d.patient_id = a.patient_id AND d.doctor_id = a.doctor_id
    WHERE a.patient_id IS NULL                 -- avoids duplicating matched rows
)
SELECT p.name AS patient_name,
       d.name AS doctor_name,
       d.specialization,
       COALESCE(f.appointment_count, 0) AS appointments,
       COALESCE(f.diagnosis_count, 0)   AS diagnoses,
       CASE WHEN f.diagnosis_count   IS NULL THEN 'Appointment only'
            WHEN f.appointment_count IS NULL THEN 'Diagnosis only'
            ELSE 'Matched' END          AS match_status
FROM full_pairs f
JOIN patients p ON p.patient_id = f.patient_id
JOIN doctors  d ON d.doctor_id  = f.doctor_id
WHERE f.diagnosis_count IS NULL OR f.appointment_count IS NULL
ORDER BY p.patient_id, d.doctor_id;

-- Q4b : summary of how the two tables line up
WITH appt_pairs AS (
    SELECT DISTINCT patient_id, doctor_id FROM appointments
),
dx_pairs AS (
    SELECT DISTINCT patient_id, doctor_id FROM diagnoses
),
full_pairs AS (
    SELECT a.patient_id AS a_pid, d.patient_id AS d_pid
    FROM appt_pairs a
    LEFT JOIN dx_pairs d ON d.patient_id = a.patient_id AND d.doctor_id = a.doctor_id
    UNION ALL
    SELECT a.patient_id, d.patient_id
    FROM appt_pairs a
    RIGHT JOIN dx_pairs d ON d.patient_id = a.patient_id AND d.doctor_id = a.doctor_id
    WHERE a.patient_id IS NULL
)
SELECT CASE WHEN d_pid IS NULL THEN 'Appointment only'
            WHEN a_pid IS NULL THEN 'Diagnosis only'
            ELSE 'Matched' END AS match_status,
       COUNT(*) AS patient_doctor_pairs
FROM full_pairs
GROUP BY match_status;


/* =====================================================================
   Q5 : WINDOW FUNCTION - RANK
   Purpose : For each doctor, rank patients by number of appointments
             (descending). Ties share a rank (RANK); use DENSE_RANK to
             avoid gaps.
   ===================================================================== */
-- Q5a : full ranking for every doctor
WITH patient_visits AS (
    SELECT doctor_id, patient_id, COUNT(*) AS appointment_count
    FROM appointments
    GROUP BY doctor_id, patient_id
)
SELECT d.name AS doctor_name,
       p.name AS patient_name,
       pv.appointment_count,
       RANK()       OVER (PARTITION BY pv.doctor_id ORDER BY pv.appointment_count DESC) AS visit_rank,
       DENSE_RANK() OVER (PARTITION BY pv.doctor_id ORDER BY pv.appointment_count DESC) AS visit_dense_rank
FROM patient_visits pv
JOIN doctors  d ON d.doctor_id  = pv.doctor_id
JOIN patients p ON p.patient_id = pv.patient_id
ORDER BY d.doctor_id, visit_rank, p.patient_id;

-- Q5b : only each doctor's top-ranked patient(s)
WITH patient_visits AS (
    SELECT doctor_id, patient_id, COUNT(*) AS appointment_count
    FROM appointments
    GROUP BY doctor_id, patient_id
),
ranked AS (
    SELECT pv.*, RANK() OVER (PARTITION BY doctor_id ORDER BY appointment_count DESC) AS visit_rank
    FROM patient_visits pv
)
SELECT d.name AS doctor_name, p.name AS patient_name, r.appointment_count
FROM ranked r
JOIN doctors  d ON d.doctor_id  = r.doctor_id
JOIN patients p ON p.patient_id = r.patient_id
WHERE r.visit_rank = 1
ORDER BY d.doctor_id, p.patient_id;


/* =====================================================================
   Q6 : CASE - age groups
   Purpose : Bucket patients into 18-30, 31-50, 51+ and count each.
   Note    : ages in the data run 18-89; the ELSE catches NULL/under-18.
   ===================================================================== */
-- Q6
SELECT CASE WHEN age BETWEEN 18 AND 30 THEN '18-30'
            WHEN age BETWEEN 31 AND 50 THEN '31-50'
            WHEN age >= 51             THEN '51+'
            ELSE 'Unknown / under 18' END AS age_group,
       COUNT(*) AS patient_count
FROM patients
GROUP BY age_group
ORDER BY MIN(COALESCE(age, 0));


/* =====================================================================
   Q7 : String functions - UPPER, LIKE
   Purpose : Patients whose contact number ends in 1234, names in caps.
   ===================================================================== */
-- Q7
SELECT patient_id,
       UPPER(name)    AS patient_name,
       contact_number
FROM patients
WHERE contact_number LIKE '%1234';


/* =====================================================================
   Q8 : SUBQUERY - patients prescribed ONLY Insulin
   Purpose : Patients with at least one Insulin prescription and no
             other medication across all their diagnoses.
   ===================================================================== */
-- Q8
SELECT p.patient_id, p.name, p.age, p.gender
FROM patients p
WHERE EXISTS (                                  -- has at least one Insulin prescription
          SELECT 1
          FROM diagnoses dg
          JOIN medications m ON m.diagnosis_id = dg.diagnosis_id
          WHERE dg.patient_id = p.patient_id
            AND m.medication_name = 'Insulin')
  AND NOT EXISTS (                              -- and none that are not Insulin
          SELECT 1
          FROM diagnoses dg
          JOIN medications m ON m.diagnosis_id = dg.diagnosis_id
          WHERE dg.patient_id = p.patient_id
            AND m.medication_name <> 'Insulin')
ORDER BY p.patient_id;


/* =====================================================================
   Q9 : DATE functions - DATEDIFF
   Purpose : Average prescription duration (days) per diagnosis.
   DATA QUALITY : about half of medication rows have end_date earlier than
   start_date, producing negative durations. Both averages are shown.
   ===================================================================== */
-- Q9
SELECT dg.diagnosis,
       COUNT(*)                                                         AS prescriptions,
       ROUND(AVG(DATEDIFF(m.end_date, m.start_date)), 1)                AS avg_days_raw,
       ROUND(AVG(CASE WHEN m.end_date >= m.start_date
                      THEN DATEDIFF(m.end_date, m.start_date) END), 1)  AS avg_days_valid_only,
       SUM(m.end_date < m.start_date)                                   AS invalid_date_rows
FROM medications m
JOIN diagnoses dg ON dg.diagnosis_id = m.diagnosis_id
GROUP BY dg.diagnosis
ORDER BY dg.diagnosis;


/* =====================================================================
   Q10 : Joins + COUNT(DISTINCT)
   Purpose : Doctor who attended the most unique patients. "Attended" is
             taken as appointments with status = 'Completed'. RANK keeps
             ties. To count all appointments instead, delete the WHERE.
   ===================================================================== */
-- Q10
WITH doctor_patients AS (
    SELECT d.doctor_id, d.name, d.specialization,
           COUNT(DISTINCT a.patient_id) AS unique_patients
    FROM doctors d
    JOIN appointments a ON a.doctor_id = d.doctor_id
    WHERE a.status = 'Completed'
    GROUP BY d.doctor_id, d.name, d.specialization
),
ranked AS (
    SELECT dp.*, RANK() OVER (ORDER BY unique_patients DESC) AS rnk
    FROM doctor_patients dp
)
SELECT name AS doctor_name, specialization, unique_patients
FROM ranked
WHERE rnk = 1;


/* =====================================================================
   BONUS (from the PDF's business use cases)
   ===================================================================== */
-- B1 : Appointment trends - status by year and month
SELECT YEAR(appointment_date)  AS yr,
       MONTH(appointment_date) AS mth,
       COUNT(*)                                   AS total,
       SUM(status = 'Completed')                  AS completed,
       SUM(status = 'Cancelled')                  AS cancelled,
       SUM(status = 'Scheduled')                  AS scheduled,
       ROUND(100 * SUM(status = 'Cancelled') / COUNT(*), 1) AS cancel_pct
FROM appointments
GROUP BY yr, mth
ORDER BY yr, mth;

-- B2 : Most prescribed medications per diagnosis (DENSE_RANK)
WITH med_counts AS (
    SELECT dg.diagnosis, m.medication_name, COUNT(*) AS times_prescribed
    FROM medications m
    JOIN diagnoses dg ON dg.diagnosis_id = m.diagnosis_id
    GROUP BY dg.diagnosis, m.medication_name
)
SELECT diagnosis, medication_name, times_prescribed,
       DENSE_RANK() OVER (PARTITION BY diagnosis ORDER BY times_prescribed DESC) AS popularity_rank
FROM med_counts
ORDER BY diagnosis, popularity_rank, medication_name;
