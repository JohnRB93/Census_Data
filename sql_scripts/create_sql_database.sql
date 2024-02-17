/*
Creates the Census_2022_Microdata database and its tables.
Tables include: demographics, education, employment, languages, tech_access, transportation, and income_costs.
Author:        John Butler
Date Created:  1/29/2024
Last Modified: 2/10/2024
*/

DROP DATABASE IF EXISTS Census_2022_Microdata;
CREATE DATABASE Census_2022_Microdata;

GO

USE Census_2022_Microdata;

DROP TABLE IF EXISTS demographics;
CREATE TABLE demographics
(
	id									VARCHAR(50)			NOT NULL,
	state								VARCHAR(50)			NOT NULL,
	division							VARCHAR(200)		NOT NULL,
	age									INT					NULL,
	sex									VARCHAR(200)		NULL,
	race_group_1						VARCHAR(200)		NULL,
	race_group_2						VARCHAR(200)		NULL,
	race_group_3						VARCHAR(200)		NULL,
	marital_status						VARCHAR(200)		NULL,
	disability							VARCHAR(200)		NULL
);

DROP TABLE IF EXISTS education;
CREATE TABLE education
(
	id									VARCHAR(50)			NOT NULL,
	school_enrollment					VARCHAR(200)		NULL,
    current_grade_level					VARCHAR(200)		NULL,
    attained_education					VARCHAR(200)		NULL
);

DROP TABLE IF EXISTS employment;
CREATE TABLE employment
(
	id									VARCHAR(50)			NOT NULL,
	worker_class						VARCHAR(200)		NULL,
    usual_hrs_worked_per_week			VARCHAR(200)		NULL
);


DROP TABLE IF EXISTS languages;
CREATE TABLE languages
(
	id									VARCHAR(50)			NOT NULL,
	lang_spoken_at_home					VARCHAR(200)		NULL,
	non_engl_lang_spoken_at_home		VARCHAR(200)		NULL,
	limited_engl_speaking_household		VARCHAR(200)		NULL
);

DROP TABLE IF EXISTS tech_access;
CREATE TABLE tech_access
(
	id									VARCHAR(50)			NOT NULL,
	smartphone							VARCHAR(200)		NULL,
	telephone_service					VARCHAR(200)		NULL,
	cell_data_plan						VARCHAR(200)		NULL,
    computer							VARCHAR(200)		NULL,
    tablet								VARCHAR(200)		NULL,
    intnt_access						VARCHAR(200)		NULL,
    satellite_intnt_service				VARCHAR(200)		NULL,
    high_speed_intnt					VARCHAR(200)		NULL,
    other_intnt_service					VARCHAR(200)		NULL
);

DROP TABLE IF EXISTS transportation;
CREATE TABLE transportation
(
	id									VARCHAR(50)			NOT NULL,
	num_of_vehicles						VARCHAR(200)		NULL
);

DROP TABLE IF EXISTS income_costs;
CREATE TABLE income_costs
(
	id									VARCHAR(50)			NOT NULL,
	state								VARCHAR(50)			NOT NULL,
	household_income					VARCHAR(200)		NULL,
    monthly_electricity_cost			VARCHAR(200)		NULL,
    monthly_gas_cost					VARCHAR(200)		NULL,
    monthly_rent						VARCHAR(200)		NULL,
    property_taxes						VARCHAR(200)		NULL,
    annual_water_cost					VARCHAR(200)		NULL
);