
-- First, we need to load the tables to see the import process from Excel has been successful
-- Note we have divided the original data source into two tables so we can practice joins

SELECT *
FROM vaccinations
ORDER BY 3,4

SELECT *
FROM deaths
ORDER BY 3,4

-- Now, we must select the data we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM deaths
WHERE continent IS NOT NULL -- where location is the continent name, the continent is NULL
ORDER BY 1,2

-- Finding when the mortality rate across all countries
-- Shows the likelihood of death if COVID-19 is contracted

SELECT location, date, total_cases, total_deaths,
(CAST(total_deaths AS decimal)/(CAST(total_cases AS decimal)))*100 AS mortality_rate
FROM deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- To narrow down, let's look at which countries were the worst in terms of mortality percentage on average
/*Note that we are excluding Mauritania because it has questionable data:
For some dates it has total deaths exceeding total cases, which inflates the country's average mortality to 89%*/

SELECT location,
AVG((CAST(total_deaths AS decimal)/(CAST(total_cases AS decimal)))*100) AS avg_mortality_rate
FROM deaths
WHERE location <> 'Mauritania' and continent IS NOT NULL
GROUP by location
ORDER BY 2 DESC

-- Finding when the mortality rate in the U.S. - which month was worst for survivability?
-- From the results we can see the Month of May in 2020 was the worst for survivability in the U.S

SELECT location, date, total_cases, total_deaths,
(CAST(total_deaths AS decimal)/(CAST(total_cases AS decimal)))*100 AS mortality_rate
FROM deaths
WHERE location LIKE '%states'
ORDER BY 5 DESC
OFFSET 0 ROWS FETCH FIRST 30 ROWS ONLY

/*Since COVID is no longer declared a pandemic in many countries let's see
what percentage of the population got it and which countries had it the worst*/

SELECT location, population, MAX(total_cases) AS most_infected,
MAX((CAST(total_cases AS decimal)/(CAST(population AS decimal))))*100 AS infected_percentage
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Looking specifically at the U.S.
-- 30.52% or 103,266,404 Americans ended up COVID-19
-- Note we are using most recent data point (5/3/23)

SELECT location, date, population, total_cases,
(CAST(total_cases AS decimal)/(CAST(population AS decimal)))*100 AS infected_percentage
FROM deaths
WHERE location LIKE '%states' AND date = '2023-05-03 00:00:00.000'

-- This query will show the highest number of deaths out of the entire population, not just the infected
-- Peru has the unfortunate #1 spot

SELECT location, population, MAX(total_deaths) AS most_dead,
MAX((CAST(total_deaths AS decimal)/(CAST(population AS decimal))))*100 AS "percentage dead out of population"
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- This query will rank the countries based on the highest total number of deaths
-- It seems that the U.S is the only country with over a million deaths, followed by Brazil with ~701k

SELECT location, MAX(CAST(total_deaths AS int)) AS total_deaths
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- Same as above but broken down by continent instead of country
-- North America is highest with 1,124,063 deaths and Oceania is lowest with 20,119

SELECT continent, MAX(CAST(total_deaths AS int)) AS total_deaths
FROM deaths
WHERE location NOT LIKE ('%income%') AND continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- And once again deaths broken down but this time by income class
-- Somewhat surprisingly, there are the most deaths among high income individuals

SELECT location, MAX(CAST(total_deaths AS int)) AS total_deaths
FROM deaths
WHERE location LIKE ('%income%')
GROUP BY location
ORDER BY 2 DESC

-- Global numbers:
-- ~765 million people across the world contracted Covid, ~6.9 million passed away
-- This equates to a 0.9% global mortality rate

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
SUM(new_deaths)/SUM(new_cases)*100 AS mortality_percentage
FROM deaths
WHERE continent IS NOT NULL

-- Now let's join the two tables to further our insights
-- Looking at how many people got vaccinated out of the population

-- Using a CTE (common table expressions)

WITH popvsvac (continent, location, date, population, new_vaccinations, running_total_vaccinations)
AS 
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CONVERT(bigint,v.new_vaccinations))
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS running_total_vaccinations
FROM deaths d
JOIN vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, running_total_vaccinations/population*100 AS rolling_vaccination_percent
FROM popvsvac

-- Using temp tables

DROP TABLE IF EXISTS #percent_pop_vaccinated
CREATE TABLE #percent_pop_vaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
running_total_vaccinations numeric)

INSERT INTO #percent_pop_vaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CONVERT(bigint,v.new_vaccinations))
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS running_total_vaccinations
FROM deaths d
JOIN vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, running_total_vaccinations/population*100 AS rolling_vaccination_percent
FROM #percent_pop_vaccinated

-- Creating view to store data for later visualizations

CREATE VIEW percent_pop_vaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CONVERT(bigint,v.new_vaccinations))
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS running_total_vaccinations
FROM deaths d
JOIN vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL

-- Testing the view we created above

SELECT *
FROM percent_pop_vaccinated

-- END
-- THANK YOU!