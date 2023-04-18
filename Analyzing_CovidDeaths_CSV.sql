SELECT *
	FROM PortfolioProject..CovidDeaths_csv
	WHERE continent is not null
	ORDER BY 3,4

--SELECT *
--	FROM PortfolioProject..CovidVaccinations
--	ORDER BY 3,4

-- Select Data that we are going to be using

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population

FROM PortfolioProject..CovidDeaths_csv
WHERE continent is not null
	ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS DeathPercentage

FROM PortfolioProject..CovidDeaths_csv
WHERE location like '%states%'
 AND continent is not null
	ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid

SELECT
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS InfectedPopulationPercentage

FROM PortfolioProject..CovidDeaths_csv
WHERE location like '%states%'
AND continent is not null
	ORDER BY 1,2

-- Looking at countries with Highest Infection Rate compared to Population

SELECT
	location,
	population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS InfectedPopulationPercentage

FROM PortfolioProject..CovidDeaths_csv
--WHERE location like '%states%'
WHERE continent is not null
	GROUP BY location, population
	ORDER BY InfectedPopulationPercentage DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT

SELECT
	continent,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount

FROM PortfolioProject..CovidDeaths_csv
--WHERE location like '%satetes%'
WHERE continent is not null
	GROUP BY continent
	ORDER BY TotalDeathCount DESC


-- Showing the countries with Highest Death Count per Population

SELECT
	location,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount

FROM PortfolioProject..CovidDeaths_csv
--WHERE location like '%states%'
WHERE continent is not null
	GROUP BY location
	ORDER BY TotalDeathCount DESC

-- Showing continents with the Highest Death Count per population

SELECT
	continent,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount

FROM PortfolioProject..CovidDeaths_csv
--WHERE location like '%satetes%'
WHERE continent is not null
	GROUP BY continent
	ORDER BY TotalDeathCount DESC


-- Global Numbers

SELECT
	SUM(CAST(new_cases AS int)) AS total_cases,
	SUM(CAST(new_deaths AS int)) As total_deaths
	
FROM PortfolioProject..CovidDeaths_csv
--WHERE location like '%states%'
 WHERE continent is not null
	--GROUP BY date
	ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

-- Query 1

 SELECT *
 FROM PortfolioProject..CovidDeaths dea
 JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Query 2

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
ORDER BY 2,3

-- Query 3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location) AS total_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	ORDER BY 2,3

--Query 4 (cast as int gave an "arithmetic overflow error" so I casted as FLOAT)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location) AS total_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	ORDER BY 2,3

--Query 5 (last query added up everything by location and when we had new vaccnations, it failed to add them to the existing number)
--To resolve this, we add an ORDER BY location and date clause aand run query again

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_rolling_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	ORDER BY 2,3

--Query 6 - USE CTE

with PopvsVac (continent, location, date, population, new_vaccinations, total_rolling_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_rolling_vaccinations
--, (total_rolling_vaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3
)
SELECT *, (total_rolling_vaccinations/population)*100 AS Percentage_TRV
FROM PopvsVac


-- TEMP TABLE

-- Query 1

Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_rolling_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_rolling_vaccinations
--, (total_rolling_vaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT *, (total_rolling_vaccinations/population)*100 AS percentage_vac
FROM #PercentPopulationVaccinated

-- Query 2 (Add the DROP TABLE IF EXISTS phrase to prevent the "table already exists" error message

DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_rolling_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_rolling_vaccinations
--, (total_rolling_vaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	--WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT *, (total_rolling_vaccinations/population)*100 AS percentage_vac
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_rolling_vaccinations
--, (total_rolling_vaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated