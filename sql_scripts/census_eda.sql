/*
Exploratory Data Analysis of 2022 Census Microdata Sample for all states including District of Columbia.
Stakeholder questions to answer: Which states have the greatest sample population size and what percent of the sample do they take up?
								 How does race, gender, and disability impact education attainment and employment?
								 Is there a relationship between education and income?
								 What is the usual age group per each level of attained education?
								 Is there a relationship between household income and the costs that each household pays?
								 Is there a relationship between school attainment/enrollment and accesss to technology?
								 
Author:   John Butler
Created:  02/09/2024
Modified: 02/17/2024
*/

/*
Store the results of quering the views into a temp table, so that the
view doesn't have to keep running the calculations every time they're used.
*/
SELECT *
INTO #adjusted_income_costs
FROM adjusted_income_costs_view;

-- See what the data looks like.
SELECT TOP 5 * FROM demographics;
SELECT TOP 5 * FROM education;
SELECT TOP 5 * FROM employment;
SELECT TOP 5 * FROM #adjusted_income_costs;
SELECT TOP 5 * FROM languages;
SELECT TOP 5 * FROM tech_access;
SELECT TOP 5 * FROM transportation;


/** Which states have the greatest sample population size and what percent of the sample do they take up? **/
-- Find the percentages of the top 5 state sample populations.
SELECT TOP 5
	state,
	COUNT(*) AS sample_cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM demographics) * 100, 2) AS pct
FROM demographics
GROUP BY state
ORDER BY 2 DESC;


/** How does race, gender, and disability impact education attainment and employment? **/
/*
For this part of the analysis, lets use records from individuals who are of primary working age
according to the Bureau of Labor Statistics: 25 - 54
*/
-- Lets create two categories of employment: employed and unemployed.
SELECT
	e.id,
	sex,
	race_group_1 AS race,
	disability,
	CASE WHEN worker_class IN ('N/A (less than 16 years old/NILF who last worked more than 5 years ago or never worked)',
							 'Unemployed and last worked 5 years ago or earlier or never worked',
							 'Working without pay in family business or farm') THEN 'Unemployed'
		 ELSE 'Employed' END AS employment
INTO #employment_status
FROM employment e
	JOIN demographics d ON e.id = d.id
WHERE age BETWEEN 25 AND 54;

-- Find the percentage of the prime employment age sample population of each race, gender, and disabled.
SELECT
	race,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #employment_status) * 100, 2) AS pct
FROM #employment_status
GROUP BY race
ORDER BY 3 DESC;

SELECT
	sex,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #employment_status) * 100, 2) AS pct
FROM #employment_status
GROUP BY sex
ORDER BY 3 DESC;

SELECT
	disability,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #employment_status) * 100, 2) AS pct
FROM #employment_status
GROUP BY disability
ORDER BY 3 DESC;

-- Find the percentage of each employment status from the prime employment age sample population.
SELECT
	employment,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #employment_status) * 100, 2) AS pct
FROM #employment_status
GROUP BY employment

-- Fine the sex percentage for each employment status.
SELECT
	sex,
	employment,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(employment) FROM #employment_status) * 100, 2) AS pct, 
	SUM(COUNT(*)) OVER(PARTITION BY sex ORDER BY sex) AS cnt_sex_total,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY sex ORDER BY sex) * 100, 2) AS pct_sex_total
FROM #employment_status
GROUP BY sex, employment
ORDER BY 1 DESC, 4 DESC;

-- Find is the race percentage for each employment status.
SELECT
	race,
	employment,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM employment) * 100, 2) AS pct,
	SUM(COUNT(*)) OVER(PARTITION BY race ORDER BY race) AS cnt_race,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY race ORDER BY race) * 100, 2) AS pct_race
FROM #employment_status
GROUP BY race, employment
ORDER BY 1 ASC, 3 DESC;

-- Find the disability percentage for each employment status.
SELECT
	disability,
	employment,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #employment_status) * 100, 2) AS pct,
	SUM(COUNT(*)) OVER(PARTITION BY disability ORDER BY disability) AS cnt_disability_total,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY disability ORDER BY disability) * 100, 2) AS pct_disability_total
FROM #employment_status
GROUP BY disability, employment
ORDER BY 1 ASC, 2 ASC;

/*
Lets create a table variable to store categories of education attainment for the
Sample Population that is of prime employment age (25 - 54).
*/
DROP TABLE IF EXISTS #education;
SELECT
	d.id,
	age,
	sex,
	race_group_1 AS race,
	disability,
	school_enrollment,
	current_grade_level,
	CASE WHEN attained_education NOT IN ('Bachelor''s degree', 'Master''s degree', 'Associate''s degree',
		'GED or alternative credential', 'Professional degree beyond a bachelor''s degree',
		'Doctorate degree', 'Regular high school diploma', '1 or more years of college credit, no degree',
		'Some college, but less than 1 year') THEN 'Below high school' 
		ELSE attained_education END AS attained_education
INTO #education
FROM education e
	JOIN demographics d ON e.id = d.id
WHERE age BETWEEN 25 AND 54;

-- Find the percent of the sample population per each level of education.
SELECT
	attained_education,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #education) * 100, 2) AS pct
FROM #education
GROUP BY attained_education
ORDER BY 3 DESC;

-- Find the percentage of each sex per each level of education.
SELECT
	sex,
	attained_education,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #education) * 100, 2) AS pct,
	SUM(COUNT(*)) OVER(PARTITION BY sex ORDER BY sex) AS cnt_sex,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY sex ORDER BY sex) * 100, 2) AS pct_sex
FROM #education
GROUP BY sex, attained_education
ORDER BY 1 ASC, 2 ASC;

-- Find the count of each race per each level of education.
-- Counts will be found by using a PIVOT function here, percentages will be calculated in Excel.
SELECT *
FROM (
	SELECT id, race, attained_education
	FROM #education
) AS sub
PIVOT (
	COUNT(id)
	FOR attained_education IN ([Below high school], [Regular high school diploma], [GED or alternative credential],
								[Some college, but less than 1 year], [1 or more years of college credit, no degree], [Associate's degree],
								[Bachelor's degree], [Master's degree], [Professional degree beyond a bachelor's degree], [Doctorate degree])
) AS my_pivot
ORDER BY race;

-- Find the percentage of each disability status per each level of education.
SELECT
	disability,
	attained_education,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #education) * 100, 2) AS pct,
	SUM(COUNT(*)) OVER(PARTITION BY disability ORDER BY disability) AS cnt_disability,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY disability ORDER BY disability) * 100, 2) AS pct_disability
FROM #education
GROUP BY disability, attained_education
ORDER BY 1 ASC, 2 ASC;

-- Find how education attainment relates to employment.
SELECT
	attained_education,
	employment AS emp_status,
	COUNT(*) AS cnt,
	ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM #education) * 100, 2) AS pct,
	SUM(COUNT(*)) OVER(PARTITION BY employment ORDER BY employment) AS cnt_employment,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY employment ORDER BY employment) * 100, 2) AS pct_employment
FROM #education edu
	JOIN #employment_status emp ON edu.id = emp.id
GROUP BY attained_education, employment
ORDER BY 2 ASC, 1 ASC;


/** Is there a relationship between education and income? **/
/*
For this analysis, There is not a direct link between the education and income tables,
the education table has data on individuals while the income table has data on households.
So, the way to make a connection between to two is based on aggregations by state.
We'll also use the same age grop from the previous section (25 - 54).
*/
DROP TABLE IF EXISTS #education;
SELECT
	d.id,
	state,
	division,
	age,
	sex,
	race_group_1 AS race,
	disability,
	school_enrollment,
	current_grade_level,
	CASE WHEN attained_education NOT IN ('Bachelor''s degree', 'Master''s degree', 'Associate''s degree',
		'GED or alternative credential', 'Professional degree beyond a bachelor''s degree',
		'Doctorate degree', 'Regular high school diploma', '1 or more years of college credit, no degree',
		'Some college, but less than 1 year') THEN 'Below high school' 
		ELSE attained_education END AS attained_education
INTO #education
FROM education e
	JOIN demographics d ON e.id = d.id
WHERE age BETWEEN 25 AND 54;

-- Find the typical education levels per each state and divisions.
SELECT *
FROM (
	SELECT id, state, attained_education
	FROM #education
) AS sub
PIVOT (
	COUNT(id)
	FOR attained_education IN ([Below high school], [Regular high school diploma], [GED or alternative credential],
								[Some college, but less than 1 year], [1 or more years of college credit, no degree], [Associate's degree],
								[Bachelor's degree], [Master's degree], [Professional degree beyond a bachelor's degree], [Doctorate degree])
) AS my_pivot
ORDER BY state;

SELECT *
FROM (
	SELECT id, division, attained_education
	FROM #education
) AS sub
PIVOT (
	COUNT(id)
	FOR attained_education IN ([Below high school], [Regular high school diploma], [GED or alternative credential],
								[Some college, but less than 1 year], [1 or more years of college credit, no degree], [Associate's degree],
								[Bachelor's degree], [Master's degree], [Professional degree beyond a bachelor's degree], [Doctorate degree])
) AS my_pivot
ORDER BY division;

-- Per each education level in each state, find the average household income.
SELECT
	state,
	AVG(adjusted_household_income) AS avg_household_income
FROM #adjusted_income_costs
GROUP BY state
ORDER BY 1;

/** What is the usual age group per each level of attained education? **/
WITH age_bins AS (
	SELECT
		value AS low_bin,
		value + 4 AS high_bin
	FROM GENERATE_SERIES(25, 54, 5)
), age_edu AS (
	SELECT
		age,
		CASE WHEN attained_education = 'Below high school' THEN 1 ELSE 0 END AS below_highschool,
		CASE WHEN attained_education = 'GED or alternative credential' THEN 1 ELSE 0 END AS ged_alternative,
		CASE WHEN attained_education = 'Regular high school diploma' THEN 1 ELSE 0 END AS highschool_diploma,
		CASE WHEN attained_education = 'Some college, but less than 1 year' THEN 1 ELSE 0 END AS less_1_year_college,
		CASE WHEN attained_education = '1 or more years of college credit, no degree' THEN 1 ELSE 0 END AS _1_year_or_more_college_no_degree,
		CASE WHEN attained_education = 'Associate''s degree' THEN 1 ELSE 0 END AS associate_degree,
		CASE WHEN attained_education = 'Bachelor''s degree' THEN 1 ELSE 0 END AS bachelor_degree,
		CASE WHEN attained_education = 'Professional degree beyond a bachelor''s degree' THEN 1 ELSE 0 END AS other_above_bachelor,
		CASE WHEN attained_education = 'Master''s degree' THEN 1 ELSE 0 END AS master_degree,
		CASE WHEN attained_education = 'Doctorate degree' THEN 1 ELSE 0 END AS doctorate_degree
	FROM #education
)
SELECT
	low_bin,
	high_bin,
	SUM(below_highschool) AS num_below_highschool,
	SUM(ged_alternative) AS num_ged_alternative,
	SUM(highschool_diploma) AS num_highschool_diploma,
	SUM(associate_degree) AS num_associate_degree,
	SUM(less_1_year_college) AS num_less_1_year_college,
	SUM(_1_year_or_more_college_no_degree) AS num_1_year_or_more_college_no_degree,
	SUM(bachelor_degree) AS num_bachelor_degree,
	SUM(other_above_bachelor) AS num_other_above_bachelor,
	SUM(master_degree) AS num_master_degree,
	SUM(doctorate_degree) AS num_doctorate_degree
FROM age_edu
	LEFT JOIN age_bins ON age_edu.age BETWEEN age_bins.low_bin AND age_bins.high_bin
GROUP BY low_bin, high_bin
ORDER BY 1 ASC;


/** Is there a relationship between household income and the costs that each household pays? **/
/*
Find the correlation coefficient for household income and each cost for household.
A stored porcedure: spCalculateCorrelationCoefficient has been defined in the database, we'll use it to calcualte
the correlation coefficient of two columns of data. It requires a table type to be passed as a parameter.
For each calculation of correlation, income will be x and y will be the cost values.
*/
DROP TYPE IF EXISTS input_table;
CREATE TYPE input_table AS TABLE (
	x FLOAT NOT NULL,
	y FLOAT NOT NULL
);
-- Correlation Coefficient of income and rent.
DECLARE @income_rent input_table;
INSERT INTO @income_rent
SELECT adjusted_household_income, adjusted_monthly_rent
FROM #adjusted_income_costs
WHERE adjusted_household_income >= 0 AND adjusted_monthly_rent >= 0;
EXEC spCalculateCorrelationCoefficient @income_rent;

-- Correlation Coefficient of income and electricity cost.
DECLARE @income_electricity_cost input_table;
INSERT INTO @income_electricity_cost
SELECT adjusted_household_income, adjusted_monthly_electricity_cost
FROM #adjusted_income_costs
WHERE adjusted_household_income >= 0 AND adjusted_monthly_electricity_cost >= 0;
EXEC spCalculateCorrelationCoefficient @income_electricity_cost;

-- Correlation Coefficient of income and gas cost.
DECLARE @income_gas_cost input_table;
INSERT INTO @income_gas_cost
SELECT adjusted_household_income, adjusted_monthly_gas_cost
FROM #adjusted_income_costs
WHERE adjusted_household_income >= 0 AND adjusted_monthly_gas_cost >= 0;
EXEC spCalculateCorrelationCoefficient @income_gas_cost;

-- Correlation Coefficient of income and water cost.
DECLARE @income_water_cost input_table;
INSERT INTO @income_water_cost
SELECT adjusted_household_income, adjusted_annual_water_cost
FROM #adjusted_income_costs
WHERE adjusted_household_income >= 0 AND adjusted_annual_water_cost >= 0;
EXEC spCalculateCorrelationCoefficient @income_water_cost;

-- Correlation Coefficient of income and property taxes.
DECLARE @income_property_taxes input_table;
INSERT INTO @income_property_taxes
SELECT adjusted_household_income, property_taxes
FROM #adjusted_income_costs
WHERE adjusted_household_income >= 0 AND property_taxes >= 0;
EXEC spCalculateCorrelationCoefficient @income_property_taxes;


/** Is there a relationship between school attainment/enrollment and accesss to technology? **/
DROP TABLE IF EXISTS #education;
SELECT
	d.id,
	state,
	division,
	school_enrollment,
	current_grade_level,
	CASE WHEN current_grade_level LIKE '%_raduate%' THEN 1
		ELSE 0 END AS enrolled_in_higher_edu,
	CASE WHEN attained_education NOT IN ('Bachelor''s degree', 'Master''s degree', 'Associate''s degree',
		'GED or alternative credential', 'Professional degree beyond a bachelor''s degree',
		'Doctorate degree', 'Regular high school diploma', '1 or more years of college credit, no degree',
		'Some college, but less than 1 year') THEN 'Below high school' 
		ELSE attained_education END AS attained_education
INTO #education
FROM education e
	JOIN demographics d ON e.id = d.id
WHERE age >= 18;

SELECT DISTINCT attained_education FROM education;
SELECT TOP 200 * FROM #education;

-- Find the percentages of enrolled_in_higher_edu and attained_education for each state.
SELECT
	state,
	COUNT(*) AS cnt_enrolled_in_higher_edu,
	ROUND(CAST(SUM(enrolled_in_higher_edu) AS FLOAT) / COUNT(*) * 100, 2) AS pct_enrolled_in_higher_edu
FROM #education
GROUP BY state
ORDER BY 1 ASC;

-- A pivot table for counts of attained education per each state will be returned from the below query, percentages will be calculated in Excel.
SELECT *
FROM (
	SELECT id, state, attained_education
	FROM #education
) AS sub
PIVOT (
	COUNT(id)
	FOR attained_education IN ([Below high school], [Regular high school diploma], [GED or alternative credential],
								[Some college, but less than 1 year], [1 or more years of college credit, no degree], [Associate's degree],
								[Bachelor's degree], [Master's degree], [Professional degree beyond a bachelor's degree], [Doctorate degree])
) AS my_pivot
ORDER BY state;

-- Find the percentage of households in each state that has a computer.
WITH state_computer AS (
	SELECT
		state,
		CASE WHEN computer = 'Yes' THEN 1
		ELSE 0 END AS has_computer
	FROM tech_access ta
		JOIN #adjusted_income_costs aic ON ta.id = aic.id
)
SELECT
	state,
	SUM(has_computer) AS cnt_has_smartphone,
	ROUND(CAST(SUM(has_computer) AS FLOAT) / COUNT(*) * 100, 2) AS pct_has_smartphone
FROM state_computer
GROUP BY state
ORDER BY 1 ASC;

-- Find the percentage of households in each state that has a smartphone.
WITH state_smartphone AS (
	SELECT
		state,
		CASE WHEN smartphone = 'Yes' THEN 1
		ELSE 0 END AS has_smartphone
	FROM tech_access ta
		JOIN #adjusted_income_costs aic ON ta.id = aic.id
)
SELECT
	state,
	SUM(has_smartphone) AS cnt_has_smartphone,
	ROUND(CAST(SUM(has_smartphone) AS FLOAT) / COUNT(*) * 100, 2) AS pct_has_smartphone
FROM state_smartphone
GROUP BY state
ORDER BY 1 ASC;

-- Find the percentage of households in each state that has a tablet.
WITH state_tablet AS (
	SELECT
		state,
		CASE WHEN tablet = 'Yes' THEN 1
		ELSE 0 END AS has_tablet
	FROM tech_access ta
		JOIN #adjusted_income_costs aic ON ta.id = aic.id
)
SELECT
	state,
	SUM(has_tablet) AS cnt_has_smartphone,
	ROUND(CAST(SUM(has_tablet) AS FLOAT) / COUNT(*) * 100, 2) AS pct_has_smartphone
FROM state_tablet
GROUP BY state
ORDER BY 1 ASC;

-- Find the percentage of households in each state that has access to internet.
WITH state_internet AS (
	SELECT
		state,
		CASE WHEN intnt_access LIKE 'Yes%' THEN 1
		ELSE 0 END AS has_intnt
	FROM tech_access ta
		JOIN #adjusted_income_costs aic ON ta.id = aic.id
)
SELECT
	state,
	SUM(has_intnt) AS cnt_has_intnt,
	ROUND(CAST(SUM(has_intnt) AS FLOAT) / COUNT(*) * 100, 2) AS pct_has_intnt
FROM state_internet
GROUP BY state
ORDER BY 1 ASC;

-- Find the percentage of households in each state that has access to high speed internet.
WITH state_high_speed_internet AS (
	SELECT
		state,
		CASE WHEN high_speed_intnt = 'Yes' THEN 1
		ELSE 0 END AS has_hs_intnt
	FROM tech_access ta
		JOIN #adjusted_income_costs aic ON ta.id = aic.id
)
SELECT
	state,
	SUM(has_hs_intnt) AS cnt_has_hs_intnt,
	ROUND(CAST(SUM(has_hs_intnt) AS FLOAT) / COUNT(*) * 100, 2) AS pct_has_hs_intnt
FROM state_high_speed_internet
GROUP BY state
ORDER BY 1 ASC;