-- Project objective: Exploratory data analysis (Addressing inconsistencies)

SELECT *
FROM location

SELECT TOP 10 * -- Limits the selection to 10 rows
FROM visits

-- Observation: both visits and location table share 'location id' so it would be easier to join

-- What kind of source is described in the water source table?
SELECT *
FROM water_source

SELECT DISTINCT type_of_water_source as watersource_types
FROM water_source
ORDER BY watersource_types

-- Retrieving records from visits where waiting time is longer than 8 hours
SELECT *
FROM visits
WHERE time_in_queue >= 500 
ORDER BY record_id ASC

-- Find out which water source type has people queueing for more than 8 hours
SELECT ws.type_of_water_source, v.record_id, v.time_in_queue, ws.source_id, ws.number_of_people_served, v.time_of_record, (v.time_in_queue/60) as tqueue_in_hours
FROM water_source AS ws
JOIN visits AS v
ON ws.source_id = v.source_id
WHERE time_in_queue <= 500
ORDER BY tqueue_in_hours DESC
-- Observation: The shared tap seems to, not only serve a large number of people but also, 
-- have a consistent waiting time of over 8 hours. The longest time seems to have been 8.98 hours, which rounded off is 9 hours

-- Calculate the average queueing time for the shared tap water source
SELECT ws.type_of_water_source, AVG(v.time_in_queue) AS avg_tqueue
FROM water_source ws
JOIN visits v
ON ws.source_id = v.source_id
WHERE ws.type_of_water_source = 'shared_tap'
GROUP BY ws.type_of_water_source
ORDER BY avg_tqueue

-- Computing the average queueing time by type of water source
SELECT ws.type_of_water_source, AVG(v.time_in_queue) AS avg_tqueue
FROM water_source ws
JOIN visits v
ON ws.source_id = v.source_id
GROUP BY ws.type_of_water_source
ORDER BY avg_tqueue

-- Checking whether there have been multiple visits to places with good water sources, like taps at home.

SELECT wq.record_id, v.visit_count, wq.subjective_quality_score, ws.type_of_water_source
FROM visits v
JOIN water_quality wq
ON v.record_id = wq.record_id
JOIN water_source ws
ON v.source_id = ws.source_id
WHERE ws.type_of_water_source = 'tap_in_home'
AND wq.subjective_quality_score = 10
AND v.visit_count > 1

-- Investigating pollution issues
-- Assessing the water quality by water source, whether its contaminated, and how many people are at risk of illness
SELECT wp.source_id, ws.type_of_water_source, wp.description, wp.results, ws.number_of_people_served
FROM well_pollution AS wp
JOIN water_source AS ws
ON wp.source_id= ws.source_id
-- Observation: The Well seems to be the most contaminated water source, with a handful of clean wells 

SELECT wp.source_id, ws.type_of_water_source, wp.description, wp.results, ws.number_of_people_served
FROM well_pollution AS wp
JOIN water_source AS ws
ON wp.source_id= ws.source_id
WHERE description LIKE '%clean%'

-- Observation: Although, some clean observations present "clean bacteria" that kind of 
-- makes me doubt the validity of the above results, which means there needs to an indepth analysis of the data and fixing of some data entry errors

-- Finding data entry errors where sources with biological contamination of over 0.01 are classififed as clean.
SELECT *
FROM well_pollution
WHERE results LIKE 'Clean%'
AND description LIKE 'Clean%'
AND cast(biological as float) > 0.01
ORDER BY biological ASC

-- Updating the data to reflect the given numbers
-- removing errors from descriptions with clean but a biological contamination above 0.01,
-- and results recorded as 'clean'.

UPDATE well_pollution
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli'

UPDATE well_pollution
SET description = 'Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia'

UPDATE well_pollution
SET results = 'Contaminated: Biological'
WHERE cast(biological as float) > 0.01 AND results = 'Clean'

