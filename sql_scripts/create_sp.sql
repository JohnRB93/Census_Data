/*
Formula for Correlation Coefficient:     covariance(x,y)		| Formula for Covariance: n * sum(xy) - sum(x) * sum(y)
                                       -------------------		|
                                       stdev(x) * stdev(y)		| Formula for stdev(x) * stdev(y): sqrt((n * sum(x^2) - sum(x)^2) * (n * sum(y^2) - sum(y)^2))
*/

USE Census_2022_Microdata;
IF OBJECT_ID('spCalculateCorrelationCoefficient') IS NOT NULL
	DROP PROC spCalculateCorrelationCoefficient;

GO

CREATE PROC spCalculateCorrelationCoefficient
		@input_table input_table READONLY
AS

DECLARE @n INT;
DECLARE @sum_x FLOAT;
DECLARE @sum_y FLOAT;
DECLARE @sum_xy FLOAT;
DECLARE @sum_sqr_x FLOAT;
DECLARE @sqr_sum_x FLOAT;
DECLARE @sum_sqr_y FLOAT;
DECLARE @sqr_sum_y FLOAT;

SET @n = (SELECT COUNT(*) FROM @input_table);
SET @sum_x = (SELECT SUM(x) FROM @input_table);
SET @sum_y = (SELECT SUM(y) FROM @input_table);
SET @sum_xy = (SELECT SUM(x * y) FROM @input_table);
SET @sum_sqr_x = (SELECT SUM(SQUARE(x)) FROM @input_table);
SET @sqr_sum_x = (SELECT SQUARE(SUM(x)) FROM @input_table);
SET @sum_sqr_y = (SELECT SUM(SQUARE(y)) FROM @input_table);
SET @sqr_sum_y = (SELECT SQUARE(SUM(y)) FROM @input_table);

DECLARE @corr FLOAT;
SET @corr = (@n * @sum_xy - @sum_x * @sum_y) / SQRT((@n * @sum_sqr_x - @sqr_sum_x) * (@n * @sum_sqr_y - @sqr_sum_y));
PRINT(@corr);