USE [Portfolio Project]
GO

SELECT *
FROM dbo.CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM dbo.CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
ORDER BY 1,2


-- Looking at the total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases, 0))*100 AS Death_Percentage
FROM dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases, 0))*100 AS Death_Percentage
FROM dbo.CovidDeaths
WHERE location like '%ghana%'
ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what percentage of populaton got Covid
SELECT location, date,population, total_cases, (total_cases/ population)*100 AS Population_Percentage_Infected
FROM dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

SELECT location, date,population, total_cases, (total_cases/ population)*100 AS Population_Percentage_Infected
FROM dbo.CovidDeaths
WHERE location like '%ghana%'
ORDER BY 1,2

--Looking at Countries with Highest Infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/ population))*100 AS Population_Percentage_Infected
FROM dbo.CovidDeaths
--WHERE location like '%states%'
GROUP BY population, location
ORDER BY Population_Percentage_Infected desc

--Showing Countries with Highest Death Count per Population
SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Lets break things down by continent
-- Showing continents with the highest death count per population
SELECT continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT date,
       SUM(new_cases) AS Total_New_Cases,
       SUM(CAST(new_deaths AS int)) AS Total_New_Deaths,
       (SUM(CAST(new_deaths AS int))/ NULLIF(SUM(new_cases),0))*100 AS Death_Percentage
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY Date
ORDER BY 1,2

SELECT --date,
       SUM(new_cases) AS Total_New_Cases,
       SUM(CAST(new_deaths AS int)) AS Total_New_Deaths,
       (SUM(CAST(new_deaths AS int))/ NULLIF(SUM(new_cases),0))*100 AS Death_Percentage
FROM dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY Date
ORDER BY 1,2


-- COVID VACCINATIONS
SELECT *
FROM dbo.CovidVaccinations



-- Looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS Rolling_People_Vaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Use CTE
WITH PopvsVac (Continent, Location, Date, Population,new_vaccinations, Rolling_People_Vaccinated)
AS
(
     SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
     SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location,
     dea.date) AS Rolling_People_Vaccinated
     FROM dbo.CovidDeaths AS dea
     JOIN dbo.CovidVaccinations AS vac
     ON dea.location = vac.location
     AND dea.date = vac.date
     WHERE dea.continent IS NOT NULL
     --ORDER BY 2,3
)

SELECT *, Rolling_People_Vaccinated/Population * 100
FROM PopvsVac


-- TEMP TABLE
DROP TABLE IF EXISTS #PopulationVaccinatedPercent
Create Table #PopulationVaccinatedPercent
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PopulationVaccinatedPercent
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS Rolling_People_Vaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, 
    (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0)) * 100 AS Vaccination_Percentage
FROM #PopulationVaccinatedPercent;


-- Creating view to store data for later visualizations
Create view PopulationVaccinatedPercent AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location,
  dea.date) AS Rolling_People_Vaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PopulationVaccinatedPercent

