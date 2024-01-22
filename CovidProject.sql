/*
Covid 19 Data analysis and exploration

Skills put into practice:
- Join tables for statistical comparison , 
- Common table Expressions for calculations, 
- Temp Tables, 
- Windows Functions, 
- Aggregate Functions, 
- Creating Views for future visualizations, 
- Converting Data Types for more precise calculations
*/


-- Select the data that is relevant for our analysis
SELECT 
	continent, 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM dbo.deaths
ORDER BY location, date


/*
- Calculate the cases/deaths ratio 
- I live in Mexico so my focus in this query is to know Mexico's data, But it is up to each user to know the data for their country or globally.
- We can see the probability of dying if you contract covid in Mexico is 4.34% by January 2024
*/
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	CAST(total_deaths AS NUMERIC)/NULLIF(CAST(total_cases AS NUMERIC), 0)*100 AS cases_deaths_ratio
FROM dbo.deaths
WHERE total_cases <> 0 AND total_deaths <> 0
	-- AND location = 'Mexico'
ORDER BY 1, 2


-- Population/cases so we can see the percentage of the population that got covid for each country
SELECT 
	location, 
	date, 
	total_cases, 
	population, 
	(CAST(total_cases AS NUMERIC)/CAST(population AS NUMERIC))*100 AS percentage_cases
FROM dbo.deaths
WHERE total_cases <> 0
	-- AND location = 'Mexico'
ORDER BY 1, 2


-- Top 10 Countries that have the highest infection rate in our data set, we can call them "The most infectious covid-countries"
SELECT -- TOP 10
	location, 
	population, 
	MAX(total_cases) AS max_cases, 
	MAX(CAST(total_cases AS NUMERIC)/CAST(population AS NUMERIC))*100 AS population_infected
FROM dbo.deaths
GROUP BY location, population
ORDER BY 4 DESC


-- Top 10 Countries with the highest death count population, we can call them "the deadliest covid-countries"
SELECT -- TOP 10 
	location, 
	MAX(total_deaths) AS death_count
FROM dbo.deaths
WHERE location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC


-- Now let's break it down by continent and the total globally
SELECT 
	location, 
	MAX(total_deaths) AS death_count
FROM dbo.deaths
WHERE location IN ('World', 'Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC 


-- Let's take a look at the global stats since the beginning of covid to the present day
SELECT 
	SUM(CAST(new_cases AS NUMERIC)) AS total_cases, 
	SUM(CAST(new_deaths AS NUMERIC)) AS total_deaths, 
	SUM(CAST(new_deaths AS NUMERIC))/SUM(CAST(new_cases AS NUMERIC))*100 AS DeathPercentage
FROM dbo.deaths
ORDER BY 1


-- Looking at Vaccinations and cumulative count of vaccinations over time
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingvaccinations
FROM deaths AS dea
JOIN vaccinations AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE new_vaccinations <> 0 
	AND dea.location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')
ORDER BY 2, 3


-- Using a CTE to get the percentage of the population that has vaccinated over time for each country
WITH vaccinationsandpopulation AS(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingvaccinations
FROM deaths AS dea
JOIN vaccinations AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE new_vaccinations <> 0 AND dea.location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania'))

SELECT *, (rollingvaccinations/population)*100 AS percentage_vaccinated
FROM vaccinationsandpopulation
ORDER BY 2, 3


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingvaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingvaccinations
FROM deaths AS dea
JOIN vaccinations AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE new_vaccinations <> 0 
	AND dea.location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')

SELECT *, (rollingvaccinations/population)*100
FROM #PercentPopulationVaccinated
ORDER BY 2, 3


-- Creating a view for future use in dashboarding
CREATE VIEW percentpopulationvaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingvaccinations,
	(SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)/population)*100 AS percentagevaccinated
FROM deaths AS dea
JOIN vaccinations AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE new_vaccinations <> 0 
	AND dea.location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')


-- Checking view just to make sure everything is correct for our visualization
SELECT *
FROM percentpopulationvaccinated
ORDER BY 2, 3