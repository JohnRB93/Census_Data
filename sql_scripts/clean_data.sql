/*
Cleans the data in the database for exploration and aggregation.
Author:   John Butler
Created:  02/09/2024
Modified: 02/09/2024
*/

-- See what the data looks like.
SELECT TOP 3 * FROM demographics;
SELECT TOP 3 * FROM education;
SELECT TOP 3 * FROM employment;
SELECT TOP 3 * FROM income_costs;
SELECT TOP 3 * FROM languages;
SELECT TOP 3 * FROM tech_access;
SELECT TOP 3 * FROM transportation;

/*
In the income_costs table, change the values of each cost and income to numeric values
so that they can be used in calculations and aggregated. A value of -1 will mean n/a or no value.
Do the same for num_of_vehichles from the transportation table.
*/

UPDATE income_costs
SET household_income = '-1'
WHERE household_income = '-60000';

UPDATE income_costs
SET monthly_electricity_cost = '-1'
WHERE monthly_electricity_cost = 'N/A (GQ/vacant/included in rent or in condo fee/no charge or electricity not used)';

UPDATE income_costs
SET monthly_gas_cost = '-1'
WHERE monthly_gas_cost = 'N/A (GQ/vacant/included in rent or in condo fee/included in electricity payment/no charge or gas not used)';

UPDATE income_costs
SET monthly_rent = '-1'
WHERE monthly_rent = '0';

UPDATE income_costs
SET annual_water_cost = '-1'
WHERE annual_water_cost = 'N/A (GQ/vacant/included in rent or in condo fee/no charge)';

UPDATE transportation
SET num_of_vehicles = '-1'
WHERE num_of_vehicles = 'N/A (GQ/vacant)';

GO

/*
Apply ADJHSG(multiply 1.042311) to the household income, electricity cost,
gas cost, rent, and water cost to adjust to constant dollars.
*/
CREATE VIEW adjusted_income_costs_view AS
	SELECT
		id,
		state,
		household_income * 1.042311 AS adjusted_household_income,
		monthly_electricity_cost * 1.042311 AS adjusted_monthly_electricity_cost,
		monthly_gas_cost * 1.042311 AS adjusted_monthly_gas_cost,
		monthly_rent * 1.042311 AS adjusted_monthly_rent,
		annual_water_cost * 1.042311 AS adjusted_annual_water_cost,
		property_taxes
	FROM (
		SELECT
			i.id,
			state,
			CAST(household_income AS NUMERIC) AS household_income,
			CAST(monthly_electricity_cost AS NUMERIC) AS monthly_electricity_cost,
			CAST(monthly_gas_cost AS NUMERIC) AS monthly_gas_cost,
			CAST(monthly_rent AS NUMERIC) AS monthly_rent,
			CAST(annual_water_cost AS NUMERIC) AS annual_water_cost,
			CAST(property_taxes AS NUMERIC) AS property_taxes
		FROM income_costs i
			JOIN transportation t ON i.id = t.id
	) AS sub

GO

-- Create a view to store the result of casting the num_of_vehicles to INT.
CREATE VIEW transportation_view AS
	SELECT
		id,
		CASE
			WHEN LEFT(num_of_vehicles, 2) = 'No'
				THEN CAST('0' as INT)
			ELSE CAST(LEFT(num_of_vehicles, 2) AS INT)
		END AS num_of_vehicles
	FROM transportation;

GO