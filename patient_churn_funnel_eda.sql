-- Funnel and Exploratory Data Analysis with MySQL

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 1: Setup - Create a joined view with 3 datasets

CREATE OR REPLACE VIEW patient_churn_joined AS
SELECT
	d.Patient_Id, 
    d.Age, 
    d.Age_Groups, 
    d.Gender, 
    d.State, 
    d.Primary_Diagnosis, 
    d.Department_Specialty, 
    d.Insurance_Provider, 
    d.Out_of_Pocket_YTD, 
    
    a.Referral_Sources, 
    a.Website_Visits, 
    a.Page_Views, 
    a.Booking_Time_Mins, 
    a.Avg_Wait_Time_Mins, 
    a.Avg_Appointment_Time_Mins, 
    a.Total_Visits, 
    a.Missed_Appointments, 
    a.Last_Visit_Date, 
    a.Satisfaction_Score, 
    a.Churn_Status_Updated, 
    a.Churn_Status_Boolean, 
    
    c.Phone_Number, 
    c.Email, 
    c.Last_Patient_Outreach_Date, 
    c.Last_Patient_Response_Date, 
    ((c.Phone_Number IS NOT NULL AND c.Phone_Number <> '') OR (c.Email IS NOT NULL AND c.Email <> '')) AS Has_Contact_Info, 
    (c.Last_Patient_Response_Date IS NOT NULL AND c.Last_Patient_Response_Date <> '') AS Responded_To_Outreach, 
    DATEDIFF('2026-09-01', a.Last_Visit_Date) AS Days_Since_Last_Visit, 
    DATEDIFF('2026-09-01', c.Last_Patient_Outreach_Date) AS Days_Since_Outreach, 
    DATEDIFF(c.Last_Patient_Response_Date, c.Last_Patient_Outreach_Date) AS Days_Between_Outreach_And_Response, 
    CASE WHEN a.Total_Visits = 1 THEN 1 ELSE 0 END AS Booked_Only_Once
    
FROM demographics d
INNER JOIN appointment_metrics a ON d.Patient_ID = a.Patient_ID
INNER JOIN contact c ON d.Patient_ID = c.Patient_ID;

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 2: Funnel Analysis - Identifying at which stage patients drop off or remain at

/**2.1 Overall funnel with the average value at each stage and how stage varies in patient experience
(STDDEV used for Booking_Time_Mins and Avg_Wait_Time_Mins columns since these are factors that be improved through operations)**/
SELECT
    ROUND(AVG(Website_Visits), 1) AS avg_website_visits, 
    ROUND(AVG(Page_Views), 1) AS avg_page_views, 
    ROUND(AVG(Booking_Time_Mins), 1) AS avg_booking_time_mins, 
    ROUND(STDDEV(Booking_Time_Mins), 1) AS stddev_booking_time_mins, 
    ROUND(AVG(Avg_Wait_Time_Mins), 1) AS avg_wait_time_mins, 
    ROUND(STDDEV(Avg_Wait_Time_Mins), 1) AS stddev_wait_time_mins, 
    ROUND(AVG(Avg_Appointment_Time_Mins), 1) AS avg_appointment_time_mins, 
    ROUND(AVG(Total_Visits), 1) AS avg_total_visits, 
    ROUND(AVG(Missed_Appointments), 1) AS avg_missed_appointments
FROM patient_churn_joined;

/**2.2 Finding booking friction by separating Booking_Time_Mins into bins to see if patients that have longer booking times 
are more likely to miss appointments or churn later**/
SELECT
    CASE
        WHEN Booking_Time_Mins < 5 THEN '1) Under 5 mins'
        WHEN Booking_Time_Mins < 10 THEN '2) 5-10 mins'
        WHEN Booking_Time_Mins < 20 THEN '3) 10-20 mins'
        ELSE '4) 20+ mins'
    END AS booking_time_bins, 
    COUNT(*) AS patients, 
    ROUND(AVG(Missed_Appointments), 1) AS avg_missed_appointments, 
    ROUND(AVG(Satisfaction_Score), 1) AS avg_satisfaction, 
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY booking_time_bins
ORDER BY booking_time_bins;

/**2.3 Comparing website engagement and booking to see if patients who browse more or have high Page_Views per visit 
lead to more total visits**/
SELECT
    CASE
        WHEN Website_Visits = 0 THEN '1) 0 visits'
        WHEN Website_Visits <= 3 THEN '2) 1-3 visits'
        WHEN Website_Visits <= 7 THEN '3) 4-7 visits'
        ELSE '4) 8+ visits'
    END AS website_visit_bins, 
    COUNT(*) AS patients, 
    ROUND(AVG(Page_Views), 1) AS avg_page_views, 
    ROUND(AVG(Total_Visits), 1) AS avg_total_visits, 
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY website_visit_bins
ORDER BY website_visit_bins;

/**2.4 Analyzing no-shows or missed appointments to see if there are related to the department or wait time**/
SELECT
    Missed_Appointments, 
    COUNT(*) AS patients, 
    ROUND(AVG(Avg_Wait_Time_Mins), 1) AS avg_wait_time_mins, 
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Missed_Appointments
ORDER BY Missed_Appointments;

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 3: Patient Experience Impact - Discovering wait time or appointment time affects satisfaction and total visits

/**3.1 Satisfaction and churn by wait time bins**/
SELECT
    CASE
        WHEN Avg_Wait_Time_Mins < 15 THEN '1) Under 15 min'
        WHEN Avg_Wait_Time_Mins < 30 THEN '2) 15-30 min'
        WHEN Avg_Wait_Time_Mins < 45 THEN '3) 30-45 min'
        ELSE '4) 45-60 min'
    END AS wait_time_bins, 
    COUNT(*) AS patients, 
    ROUND(AVG(Satisfaction_Score), 1) AS avg_satisfaction, 
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY wait_time_bins
ORDER BY wait_time_bins;

/**3.2  Satisfaction and churn by appointment time bins**/
SELECT
    CASE
        WHEN Avg_Appointment_Time_Mins < 15 THEN '1) Under 15 min'
        WHEN Avg_Appointment_Time_Mins < 30 THEN '2) 15-25 min'
        WHEN Avg_Appointment_Time_Mins < 45 THEN '3) 25-35 min'
        ELSE '4) 35+ min'
    END AS appt_time_bins, 
    COUNT(*) AS patients, 
    ROUND(AVG(Satisfaction_Score), 1) AS avg_satisfaction, 
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY appt_time_bins
ORDER BY appt_time_bins;

/**3.3  Does satisfaction align with churn status? (sanity check)**/
SELECT
    Satisfaction_Score, 
    COUNT(*) AS patients, 
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Satisfaction_Score
ORDER BY Satisfaction_Score;

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 4: Causes of Patients Not Returning

/**4.1 Gaining a profile on patients that only booked once**/
SELECT
    Booked_Only_Once,
    COUNT(*) AS patients,
    ROUND(AVG(Satisfaction_Score), 1) AS avg_satisfaction,
    ROUND(AVG(Avg_Wait_Time_Mins), 1) AS avg_wait_time_mins,
    ROUND(AVG(Booking_Time_Mins), 1) AS avg_booking_time_mins,
    ROUND(AVG(Out_of_Pocket_YTD), 0) AS avg_out_of_pocket,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Booked_Only_Once;

/**4.2  Which departments/diagnoses have the highest number of patients that only book once? (High value meaning patients try 
the department once and do not return)**/
SELECT
    Department_Specialty, 
    COUNT(*) AS total_patients, 
    SUM(Booked_Only_Once) AS one_and_done_patients, 
    ROUND(100.0 * SUM(Booked_Only_Once) / COUNT(*), 1) AS booked_only_once_pct
FROM patient_churn_joined
GROUP BY Department_Specialty
ORDER BY booked_only_once_pct DESC;

/**4.3 Do churned patients have higher Out_of_Pocket_YTD under the same department specialty?**/
SELECT
    Department_Specialty, 
    Churn_Status_Updated, 
    COUNT(*) AS patients, 
    ROUND(AVG(Out_of_Pocket_YTD), 0) AS avg_out_of_pocket
FROM patient_churn_joined
GROUP BY Department_Specialty, Churn_Status_Updated
ORDER BY Department_Specialty, Churn_Status_Updated;

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 5: Churn Based on Different Factors

/**5.1 Churn rate by Age_Groups**/
SELECT
    Age_Groups,
    COUNT(*) AS patients,
    SUM(Churn_Status_Boolean) AS churned_patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Age_Groups
ORDER BY churn_rate_pct DESC;

/**5.2 Churn rate by State**/
SELECT
    State,
    COUNT(*) AS patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY State
HAVING COUNT(*) >= 10
ORDER BY churn_rate_pct DESC;

/**5.3 Churn rate by Primary_Diagnosis**/
SELECT
    Primary_Diagnosis,
    COUNT(*) AS patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Primary_Diagnosis
ORDER BY churn_rate_pct DESC;

/**5.4 Churn rate by Department_Specialty**/
SELECT
    Department_Specialty,
    COUNT(*) AS patients,
    ROUND(AVG(Satisfaction_Score), 2) AS avg_satisfaction,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Department_Specialty
ORDER BY churn_rate_pct DESC;

/**5.5 Churn rate by Insurance_Provider**/
SELECT
    Insurance_Provider,
    COUNT(*) AS patients,
    ROUND(AVG(Out_of_Pocket_YTD), 0) AS avg_out_of_pocket,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Insurance_Provider
ORDER BY churn_rate_pct DESC;

/**5.6 Churn rate by Referral source in terms of volume brought in and quality**/
SELECT
    Referral_Sources,
    COUNT(*) AS patients_brought_in,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patient_churn_joined), 1) AS pct_of_total_patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct,
    ROUND(AVG(Satisfaction_Score), 2) AS avg_satisfaction
FROM patient_churn_joined
GROUP BY Referral_Sources
ORDER BY patients_brought_in DESC;

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 6: Patient Contact Effect on Retention

/**6.1 Does having contact information on file relate to churn?**/
SELECT
    Has_Contact_Info,
    COUNT(*) AS patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Has_Contact_Info;

/**6.2 Does responding to outreach relate to lower churn?**/
SELECT
    Responded_To_Outreach,
    COUNT(*) AS patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY Responded_To_Outreach;

/**6.3 Are patients who haven't been contacted for longer periods of time more likely to have churned?**/
SELECT
    CASE
        WHEN Days_Since_Outreach IS NULL THEN '5) Never contacted'
        WHEN Days_Since_Outreach <= 90 THEN '1) Contacted in last 90 days'
        WHEN Days_Since_Outreach <= 180 THEN '2) 91-180 days ago'
        WHEN Days_Since_Outreach <= 365 THEN '3) 181-365 days ago'
        ELSE '4) Over a year ago'
    END AS outreach_recency,
    COUNT(*) AS patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
GROUP BY outreach_recency
ORDER BY outreach_recency;

/**6.4 Does a faster response relate to lower churn?**/
SELECT
    CASE
        WHEN Days_Between_Outreach_And_Response <= 3   THEN '1) Responded within 3 days'
        WHEN Days_Between_Outreach_And_Response <= 7   THEN '2) 4-7 days'
        WHEN Days_Between_Outreach_And_Response <= 14  THEN '3) 8-14 days'
        ELSE '4) 15+ days'
    END AS response_speed,
    COUNT(*) AS patients,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM patient_churn_joined
WHERE Responded_To_Outreach = 1
GROUP BY response_speed
ORDER BY response_speed;

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 7: Root Cause of Why Patients Do Not Return

/**7.1 Ranking churned patients by varying factors**/
SELECT
    Churn_Status_Updated,
    ROUND(AVG(Avg_Wait_Time_Mins), 1) AS avg_wait_time,
    ROUND(AVG(Satisfaction_Score), 1) AS avg_satisfaction,
    ROUND(AVG(Missed_Appointments), 1) AS avg_missed_appts,
    ROUND(100.0 * SUM(CASE WHEN Responded_To_Outreach = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_never_responded,
    ROUND(AVG(Out_of_Pocket_YTD), 0) AS avg_out_of_pocket
FROM patient_churn_joined
GROUP BY Churn_Status_Updated;

/**7.2 Missed appointments by department and wait-time bin**/
SELECT
    Department_Specialty,
    CASE
        WHEN Avg_Wait_Time_Mins < 30 THEN 'Under 30 min wait'
        ELSE '30+ min wait'
    END AS wait_time_bin,
    COUNT(*) AS patients,
    ROUND(AVG(Missed_Appointments), 1) AS avg_missed_appointments
FROM patient_churn_joined
GROUP BY Department_Specialty, wait_time_bin
ORDER BY Department_Specialty, wait_time_bin;

--------------------------------------------------------------------------------------------------------------------------------------------

-- PART 8: Ranking Patient Churn by Various Categories

/**8.1 Display of the highest and lowest churn by State, Gender, Department_Specialty, Primary_Diagnosis, and Referral_Sources**/
WITH dimension_churn AS (
    SELECT 'State' AS dimension, 
		State AS value, 
        COUNT(*) AS patients,
		ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
    FROM patient_churn_joined GROUP BY State HAVING COUNT(*) >= 10
    UNION ALL
    SELECT 'Gender', 
		Gender, 
        COUNT(*),
		ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1)
    FROM patient_churn_joined GROUP BY Gender
    UNION ALL
    SELECT 'Department_Specialty', 
		Department_Specialty, COUNT(*),
		ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1)
    FROM patient_churn_joined GROUP BY Department_Specialty
    UNION ALL
    SELECT 'Primary_Diagnosis', 
		Primary_Diagnosis, COUNT(*),
		ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1)
    FROM patient_churn_joined GROUP BY Primary_Diagnosis
    UNION ALL
    SELECT 'Referral_Sources', 
		Referral_Sources, 
        COUNT(*),
		ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1)
    FROM patient_churn_joined GROUP BY Referral_Sources
)
SELECT
    dimension,
    value,
    patients,
    churn_rate_pct,
    RANK() OVER (PARTITION BY dimension ORDER BY churn_rate_pct DESC) AS rank_highest_churn,
    DENSE_RANK() OVER (PARTITION BY dimension ORDER BY churn_rate_pct DESC) AS dense_rank_highest_churn,
    RANK() OVER (PARTITION BY dimension ORDER BY churn_rate_pct ASC) AS rank_lowest_churn
FROM dimension_churn
ORDER BY dimension, rank_highest_churn;

/**8.2 Top 3 highest churn value for State, Department_Specialty, and Primary_Diagnosis**/
SELECT dimension, 
	value, 
    patients, 
    churn_rate_pct, 
    rn AS rank_position
FROM (
    SELECT
        dimension, 
        value, 
        patients, 
        churn_rate_pct,
        ROW_NUMBER() OVER (PARTITION BY dimension ORDER BY churn_rate_pct DESC) AS rn
    FROM (
        SELECT 'State' AS dimension, 
			State AS value, 
            COUNT(*) AS patients, 
			ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
        FROM patient_churn_joined GROUP BY State HAVING COUNT(*) >= 10
        UNION ALL
        SELECT 'Department_Specialty', 
			Department_Specialty, 
            COUNT(*), 
			ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1)
        FROM patient_churn_joined GROUP BY Department_Specialty
        UNION ALL
        SELECT 'Primary_Diagnosis', 
			Primary_Diagnosis, 
            COUNT(*), 
			ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1)
        FROM patient_churn_joined GROUP BY Primary_Diagnosis
    ) base
) ranked
WHERE rn <= 3
ORDER BY dimension, rank_position;

/**8.3 Out_of_Pocket_YTD quartiles and churn rate per quartile**/
WITH cost_quartiles AS (
    SELECT
        Patient_ID,
        Out_of_Pocket_YTD,
        Churn_Status_Boolean,
        NTILE(4) OVER (ORDER BY Out_of_Pocket_YTD) AS cost_quartile
    FROM patient_churn_joined
)
SELECT
    cost_quartile,
    COUNT(*) AS patients,
    ROUND(MIN(Out_of_Pocket_YTD), 0) AS min_cost_in_quartile,
    ROUND(MAX(Out_of_Pocket_YTD), 0) AS max_cost_in_quartile,
    ROUND(100.0 * SUM(Churn_Status_Boolean) / COUNT(*), 1) AS churn_rate_pct
FROM cost_quartiles
GROUP BY cost_quartile
ORDER BY cost_quartile;

/**8.4 Patient's wait-time percentile within their department speciality, where patients above the 90th percentile have a good outreach**/
SELECT * 
FROM (
	SELECT Patient_ID, 
    Department_Specialty, 
    Avg_Wait_Time_Mins, 
    Churn_Status_Updated, 
    ROUND(PERCENT_RANK() OVER (PARTITION BY Department_Specialty ORDER BY Avg_Wait_Time_Mins), 1) AS wait_time_percentile_in_dept
FROM patient_churn_joined
) ranked
WHERE wait_time_percentile_in_dept >= 0.90
ORDER BY Department_Specialty, wait_time_percentile_in_dept DESC;

/**8.5  Monthly churn trend with a running total and month-over-month change where Last_Visit_Date is used to truncated to 
month as a rough timeline**/
WITH monthly_churn AS (
    SELECT
        DATE_FORMAT(Last_Visit_Date, '%Y-%m-01') AS visit_month, 
        COUNT(*) AS patients_seen, 
        SUM(Churn_Status_Boolean) AS churned_patients
    FROM patient_churn_joined
    WHERE Last_Visit_Date IS NOT NULL
    GROUP BY visit_month
)
SELECT
    visit_month, 
    patients_seen, 
    churned_patients, 
    SUM(churned_patients) OVER (ORDER BY visit_month
								ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_churned,
    churned_patients - LAG(churned_patients) OVER (ORDER BY visit_month) AS change_vs_prior_month
FROM monthly_churn
ORDER BY visit_month;

/**8.6  Rank departments by average satisfaction and the gap to the next-best department**/
WITH dept_satisfaction AS (
    SELECT
        Department_Specialty, 
        ROUND(AVG(Satisfaction_Score), 1) AS avg_satisfaction
    FROM patient_churn_joined
    GROUP BY Department_Specialty
)
SELECT
    Department_Specialty, 
    avg_satisfaction, 
    RANK() OVER (ORDER BY avg_satisfaction DESC) AS satisfaction_rank, 
    avg_satisfaction - LEAD(avg_satisfaction) OVER (ORDER BY avg_satisfaction DESC) AS gap_to_next_department
FROM dept_satisfaction
ORDER BY satisfaction_rank;