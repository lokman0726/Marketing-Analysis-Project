
/*Creates additional columns where data format needs to be refined. Under this block, the newly created columns are defined */
ALTER TABLE marketingdata.consolidated_marketing_data
ADD COLUMN Target_Gender VARCHAR(50),
ADD COLUMN Target_Age_Range VARCHAR(50),
ADD COLUMN Duration_in_Days INT,
ADD COLUMN formatted_date VARCHAR(20),
ADD COLUMN formatted_date_new DATE,
add column Rolling_30D_Avg decimal(10,2);

UPDATE marketingdata.consolidated_marketing_data
SET
    Target_Gender = SUBSTRING_INDEX(Target_Audience, ' ', 1),
    Target_Age_Range = CASE 
        WHEN SUBSTRING_INDEX(Target_Audience, ' ', -1) = 'Ages' THEN 'All Age'
        ELSE SUBSTRING_INDEX(Target_Audience, ' ', -1)
    END,
    Duration_in_Days = CAST(SUBSTRING_INDEX(Duration, ' ', 1) AS UNSIGNED),
    formatted_date = DATE_FORMAT(STR_TO_DATE(`date`, '%c/%d/%Y'), '%m-%d-%Y'),
	formatted_date_new = DATE_FORMAT(STR_TO_DATE(formatted_date, '%m-%d-%Y'), '%Y-%m-%d'),
    acquisition_cost = CAST(REPLACE(REPLACE(your_column, '$', ''), ',', '') AS DECIMAL(10,2));


/*Calculate ROI rolling 30 day average using window function */
UPDATE marketingdata.consolidated_marketing_data t1
JOIN (
  SELECT campaign_id, AVG(ROI) OVER (
    ORDER BY formatted_date_new
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) AS rolling_30_day_avg
  FROM marketingdata.consolidated_marketing_data
) t2 ON t1.campaign_id = t2.campaign_id
SET t1.Rolling_30D_Avg  = t2.rolling_30_day_avg;

/*Creates the consolidated table for reporting combining all marketing campaign tables. */
create table consolidated_marketing_data as 
select *
from marketingdata.campaign_details T1 left join marketingdata.campaign_outcomes T2 on T1.campaign_ID = T2.campaign_ID
left join marketingdata.campaign_location T3 on T1.location_ID = T3.location_ID left join marketingdata.campaign_customer T4
on T1.Customer_ID = T4.Customer_ID;

/* Checks customer segments in the consolidated dataset */
select customer_segment
from marketingdata.consolidated_marketing_data
group by customer_segment;

/* Prepare final table for analysis and exports it as a CSV file */
(SELECT 'Campaign_ID', 'Company', 'Campaign_Type', 'Target_Audience', 'Target_Gender', 'Target_Age_Range', 'Duration_in_Days', 'Language', 'Channel_Used', 'Customer_Segment', 'Conversion_Rate', 'Acquisition_Cost', 'ROI', 'Clicks', 'Impressions', 'Engagement_Score', 'Location', 'formatted_date_new','Rolling_30D_Avg') -- Column headers as strings
UNION ALL
(SELECT Campaign_ID, Company, Campaign_Type, Target_Audience, Target_Gender, Target_Age_Range, Duration_in_Days, Language,  Channel_Used, Customer_Segment,  Conversion_Rate, Acquisition_Cost, ROI, Clicks, Impressions, Engagement_Score, Location, formatted_date_new,Rolling_30D_Avg FROM marketingdata.consolidated_marketing_data)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/marketingdatafinal.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';