/*

Data used to extract excel documents and import them to Tableu

*/

-- Table 1: Global stats
SELECT 
	SUM(CAST(new_cases AS NUMERIC)) AS total_cases, 
	SUM(CAST(new_deaths AS NUMERIC)) AS total_deaths, 
	SUM(CAST(new_deaths AS NUMERIC))/SUM(CAST(new_cases AS NUMERIC))*100 AS DeathPercentage
FROM dbo.deaths
WHERE location = 'World'
ORDER BY 1


-- Table 2: Breaking down the stats grouped by continent
SELECT 
	location, 
	SUM(new_deaths) AS death_count
FROM dbo.deaths
WHERE location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC 


-- Table 3: Percentage of the population infected by country
SELECT
	location, 
	population, 
	MAX(total_cases) AS max_cases, 
	MAX(CAST(total_cases AS NUMERIC)/CAST(population AS NUMERIC))*100 AS population_infected
FROM dbo.deaths
WHERE location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')
GROUP BY location, population
ORDER BY 4 DESC


-- Table 4: Increase in the percentage of cases over time by country.
SELECT
	location, 
	population,
	date,
	MAX(total_cases) AS max_cases, 
	MAX(CAST(total_cases AS NUMERIC)/CAST(population AS NUMERIC))*100 AS population_infected
FROM dbo.deaths
WHERE location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')
	AND total_cases <> 0 
GROUP BY location, population, date
ORDER BY 1, 3


-- Table 5: Count and Percentage of people vaccinated over time
WITH percentage_vaccinated AS (
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	CAST(MAX(vac.total_vaccinations) AS BIGINT) AS rollingvaccinations
FROM deaths AS dea
JOIN vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')
GROUP BY dea.continent, dea.location, dea.date, dea.population
)

SELECT *, (CAST(rollingvaccinations AS NUMERIC)/CAST(population AS NUMERIC))*100 AS rolling_percentage_vaccinated
FROM percentage_vaccinated
WHERE rollingvaccinations <> 0
ORDER BY 2, 3


-- Table 6: Total deaths by country
SELECT location, SUM(CAST(new_deaths AS INT)) AS total_death_count
FROM deaths
WHERE location NOT IN ('World', 'High income', 'Upper middle income', 'Europe', 'North America', 'Asia', 'South America', 'Lower middle income', 'European Union', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC
