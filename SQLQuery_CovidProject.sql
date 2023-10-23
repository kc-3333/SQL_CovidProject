-- Select data that we are going to use
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM  PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM  PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths at specific location
-- Show likelihood of dying if you contract covid in 'xxx' country.
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM  PortfolioProject_Covid..CovidDeaths
WHERE location like 'United States'
and continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows infection rate
SELECT location,date,total_cases,population,(total_cases/population)*100 AS infection_rate
FROM PortfolioProject_Covid..CovidDeaths
WHERE location like 'United States'
and continent IS NOT NULL
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location,population,MAX(total_cases) AS highest_infection_count,MAX(total_cases/population)*100 AS max_infection_rate
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY 4 DESC

-- Showing countries with highest death count per population **as total_deaths is varchar type, we set it to integer
SELECT location,population,MAX(cast(total_deaths as int)) AS max_death_count
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC

-- By continent
SELECT location,MAX(cast(total_deaths as int)) AS max_death_count
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC

-- Showing continents with the highest death count per population
SELECT location,population,MAX(cast(total_deaths as int)) AS max_death_count, (MAX(cast(total_deaths as int))/population*100) AS max_death_rate
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NULL
GROUP BY location,population
ORDER BY 2 DESC

-- GLOBAL NUMBERS Day by Day
SELECT date, SUM(new_cases) AS daily_total_new_cases, SUM(CAST(new_deaths as int)) AS daily_total_new_deaths,
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS daily_new_death_rate
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Average death rate vs new cases along the period
SELECT SUM(new_cases) AS daily_total_new_cases, SUM(CAST(new_deaths as int)) AS daily_total_new_deaths,
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS daily_new_death_rate
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Using 2 tables
SELECT*
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
ORDER BY dea.date


-- Looking at total population vs new_vaccination
SELECT dea.continent,dea.location,dea.date,dea.population,CAST(vac.new_vaccinations AS INT) AS new_vaccinations
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
and dea.location = 'United States'
ORDER BY 2,3

-- Looking at total population vs new_vaccination (Using Partition)
SELECT dea.continent,dea.location,dea.date,dea.population,CAST(vac.new_vaccinations AS INT) AS new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location) AS total_vaccinations
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
and dea.location = 'Malaysia'
ORDER BY 2,3

-- Find the Differences
SELECT dea.continent,dea.location,dea.date,dea.population,CAST(vac.new_vaccinations AS INT) AS new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location) AS total_vaccinations
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Looking at total population vs new_vaccination (Cummulative)/Rolling
SELECT dea.continent,dea.location,dea.date,dea.population,CAST(vac.new_vaccinations AS INT) AS new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS cumulative_total_vaccinations
, ((SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date))/dea.population)*100 AS vaccination_rate
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
and dea.location = 'Malaysia'
ORDER BY 2,3

-- Same operation with CTE. (Column number of CTE must be matched to the columne number of SELECT)
WITH  PopvsVac (continent,location,date,population,new_vaccinations, cumulative_total_vaccinations)
AS
(
SELECT dea.continent,dea.location,dea.date,dea.population,CAST(vac.new_vaccinations AS INT) AS new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS cumulative_total_vaccinations
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL)

SELECT *,(PopvsVac.cumulative_total_vaccinations/population)*100 AS vaccination_rate /*Select all and 'vaccination_rate'*/
FROM PopvsVac
WHERE location='United States'

--Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,CAST(vac.new_vaccinations AS INT) AS new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS cumulative_total_vaccinations
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *,(rollingpeoplevaccinated/population)*100 AS vaccination_rate /*Select all and 'vaccination_rate'*/
FROM #PercentPopulationVaccinated
WHERE location='United States'

-- Creating view to store data for later visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,CAST(vac.new_vaccinations AS INT) AS new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS cumulative_total_vaccinations
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT*
FROM PercentPopulationVaccinated

--QUIZ: Find the earliest new case, new death, vaccination