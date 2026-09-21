# Patient Churn Funnel Analysis
This project performs data cleaning, funnel analysis, and exploratory data analysis utilizing patient churn data to identify drop-off points and bottlenecks based on the patient experience (from Website_Views to Total_Visits). It employs advanced Excel and SQL techniques to standardize data and analyze how patients are retained or lost through the different funnel stages.

#### -- Project Status: [Active, In Progress]

___

### Objectives
The purpose of the project is to:
 - Clean, standardize, and deduplicate raw churn data
 - Going through the various funnel events (Website_Views to Total_Visits)
 - Analyze patient churn across top states, department specialities, diagnoses, and more
 - Identify key drop-off stages and bottlenecks that prevent patients from returning
 - Deliver a detailed funnel report with next steps

### Technologies
 - Google Gemini
 - Claude
 - Google Sheets
 - MySQL

### Methods
- Data Cleaning (PROPER, TRIM, ABS, FLOOR, IF, LOWER, and REGEXREPLACE)
- Window Functions (ROW_NUMBER(), RANK(), LEAD (), LAG())
- Common Table Expressions (CTEs) and Subqueries
- CASE statements, Grouping, and filtering

### Funnel Events Considered
These represent a typical patient journey when booking and having an appointment.
- Website_Visits
- Page_Views
- Booking_Time_Mins
- Avg_Wait_Time_Mins
- Avg_Appointment_Time_Mins
- Total_Visits
- Missed_Appointments

___

### Steps
1) Generated raw data by combining patient churn datasets from Kaggle and enriching data set using Google Gemini and Claude
2) Cleaned data in Google Sheets using filtering to correct misspellings and functions like PROPER, TRIM, ABS, FLOOR, IF, LOWER, and REGEXREPLACE
3) Performed funnel analysis and exploratory data analysis in MySQL by employing grouping and filtering, CASE statements, window functions (ROW_NUMBER(), RANK(), LEAD (), LAG()), common table expressions (CTEs), and subqueries

___

### Key Insights
- Patients with longer appointment times are less likely to churn than patients with shorter appointment times. Patients with higher satisfaction scores are less likely to churn than patients with lower satisfaction scores.
- The General Practice practice department has the most patients that only book once and do not return, most likely due to booking elsewhere that specifically treats their concern.
- Older patients and patients with Medicare tend to have lower churn rate (of about 29%) than patients that are in younger age groups. Most patients come in from doing their own research and more patients churn when they are able to book elsewhere through ZocDoc.

### Future Considerations
- Utilizing Python to visual the funnel
- Develop a Tableau or Power BI dashboard to present to stakeholders
- Obtain more data such as outreach or response frequency to better analyze patient retention
