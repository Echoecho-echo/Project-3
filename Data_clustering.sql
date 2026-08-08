-- Clustering the data

SELECT *
FROM employee

-- Observation: The email column seems to be empty for employees, so for the first part of the project
-- I will be adding their emails, made up of the name + surname with a ndogowater.gov domain.

SELECT 
	CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') 
AS new_email --replacing the space with a full stop, making it lower case then adding '@ndogowater.gov' to the name
FROM employee

-- Adding the data to the official email column
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov')

-- Checking the phone number
SELECT LEN(phone_number)
FROM employee
-- Observation: The common length, by manual counting, of the numbers seems to be 11. 
-- But the len function returns twelve, indicating that there must be a space after the last digit
-- which i will address by using the TRIM() function

SELECT TRIM(phone_number) AS new_number
FROM employee

-- The replace with the cast function seem to do the trick
SELECT REPLACE(cast(phone_number as bigint), ' ', '') AS new_number,
LEN(REPLACE(cast(phone_number as bigint), ' ', '') ) AS length_of_new_number
FROM employee

-- Finding out how many employees live in a specific town
SELECT town_name, COUNT(town_name) AS  number_of_employees
FROM employee
GROUP BY town_name
ORDER BY number_of_employees

-- Top 3 employee_ids with the highest number of locations visited
SELECT TOP 3 assigned_employee_id, SUM(visit_count) AS number_of_visits
FROM visits
GROUP BY assigned_employee_id
ORDER BY number_of_visits DESC

-- Using the assigned employee IDs to find the names, emails, and phone numbers of the employees
SELECT TOP 3 e.employee_name, SUM(visit_count) AS number_of_visits, e.address, e.phone_number, e.email
FROM employee e
LEFT JOIN visits v
ON e.assigned_employee_id = v.assigned_employee_id
GROUP BY e.employee_name, e.address, e.phone_number, e.email
ORDER BY number_of_visits DESC

-- Counting the number of records per town
SELECT town_name, COUNT(town_name) Records_per_town
FROM location
GROUP BY town_name
ORDER BY Records_per_town DESC

-- Counting the number of records by province
SELECT province_name, COUNT(province_name) Records_per_province
FROM location
GROUP BY province_name
ORDER BY Records_per_province DESC

-- Showing both counts
SELECT province_name, town_name, COUNT(town_name) Records_per_town
FROM location
GROUP BY town_name, province_name
ORDER BY province_name 

-- Number of records by location type
SELECT DISTINCT location_type, COUNT(location_type) Records
FROM location
GROUP BY location_type
ORDER BY Records

-- Percentage of records focusing on both area types
SELECT (23590 / (15775 + 23590) * 100) Percentage_of_rural
SELECT (15775 / (15775 + 23590) * 100) Percentage_of_urban

-- Observation: The majority of water sources being in the rural location types has a stronger impact on the decisions that need to be made
-- regarding the improvement of service delivery to all towns.


-- Total people surveyed, total water sources, people sharing a water source on average, people getting water from type of source
-- Ranking each water source type by the number of people that use it to determine which requires urgent attention.
SELECT SUM(number_of_people_served) Total_people_surveyed
FROM water_source

SELECT DISTINCT type_of_water_source, COUNT(type_of_water_source) Total_water_source_types
FROM water_source
GROUP BY type_of_water_source

SELECT DISTINCT type_of_water_source, ROUND(AVG(number_of_people_served), 0) Average_people_sharing
FROM water_source
GROUP BY type_of_water_source

SELECT DISTINCT type_of_water_source, SUM(number_of_people_served) People_using_source
FROM water_source
GROUP BY type_of_water_source

SELECT DISTINCT type_of_water_source, SUM(number_of_people_served) People_using_source,
RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS Rank_by_population
FROM water_source
GROUP BY type_of_water_source

-- Rank the records and partition the results by the water source.
SELECT DISTINCT source_id, type_of_water_source, SUM(number_of_people_served) People_using_source,
RANK() OVER (PARTITION BY type_of_water_source ORDER BY SUM(number_of_people_served) DESC) AS Priority_rank
FROM water_source
GROUP BY type_of_water_source, source_id

-- Analysing the queues
--	How long did the survey take?
SELECT DATEDIFF_BIG(DAYOFYEAR, MIN(time_of_record), MAX(time_of_record))
FROM visits
--Result: The survey took 924 days, which approximates to 2 and a half years.

--	How long do people have to queue in Maji Ndogo, on average?
SELECT ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS Average_queuetime 
FROM visits
--The average queue time in Maji Ndogo, excluding homes with taps in them because they do not have queues

-- Average queue times aggragated by the day of the week.
SELECT DATENAME(WEEKDAY, time_of_record) as day_of_week, ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS average_queuetime
FROM visits
GROUP BY DATENAME(WEEKDAY, time_of_record) --, Average_queuetime
ORDER BY day_of_week ASC

-- Common water-collection hour, What time during the day do people collect water the most?
SELECT FORMAT(time_of_record, 'HH:00') as hour_of_day, ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS average_queuetime
FROM visits
GROUP BY FORMAT(time_of_record, 'HH:00') --, Average_queuetime
ORDER BY hour_of_day DESC

-- Observation: The mornings and evenings seem to be the busiest, showing average times of 149 and 168 respectively.
-- People get water before going to work, and after coming back from work. 


--Compare queue times for each day, hour by hour	
SELECT FORMAT(time_of_record, 'HH:00') as hour_of_day,-- ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS average_queuetime,
ROUND(AVG(CASE 
	WHEN DATENAME(WEEKDAY, time_of_record) = 'Sunday' THEN time_in_queue
	ELSE NULL
END ),0) AS Sundays,
ROUND(AVG(CASE 
	WHEN DATENAME(WEEKDAY, time_of_record) = 'Monday' THEN time_in_queue
	ELSE NULL
END ),0) AS Mondays,
ROUND(AVG(CASE
	WHEN DATENAME(WEEKDAY, time_of_record) = 'Tuesday' THEN time_in_queue
	ELSE NULL
END), 0) AS Tuesdays,
ROUND(AVG(CASE
	WHEN DATENAME(WEEKDAY, time_of_record) = 'Wednesday' THEN time_in_queue
	ELSE NULL
END), 0) AS Wednesdays,
ROUND(AVG(CASE
	WHEN DATENAME(WEEKDAY, time_of_record) = 'Thursday' THEN time_in_queue
	ELSE NULL
END), 0) AS Thursdays,
ROUND(AVG(CASE
	WHEN DATENAME(WEEKDAY, time_of_record) = 'Friday' THEN time_in_queue
	ELSE NULL
END), 0) AS Fridays,
ROUND(AVG(CASE
	WHEN DATENAME(WEEKDAY, time_of_record) = 'Saturday' THEN time_in_queue
	ELSE NULL
END), 0) AS Saturdays
FROM visits
GROUP BY FORMAT(time_of_record, 'HH:00')--, average_queuetime
ORDER BY hour_of_day ASC