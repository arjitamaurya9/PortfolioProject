--Selecting Data to work on
SELECT location,date,total_cases, new_cases,total_deaths, population
FROM CovidDeaths
Order BY 1,2

--Total Cases Vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country
SELECT location,date,total_cases,total_deaths,
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM CovidDeaths
WHERE location = 'India' AND continent is not null
Order BY 1,2

--Total Cases Vs Population
--Shows what percentage of population has got covid
SELECT location,date,population,total_cases,
(CONVERT(float, total_cases) / NULLIF(CONVERT(float,population), 0)) * 100 AS InfectedPopulationPercentage
FROM CovidDeaths
WHERE continent is not null
Order BY 1,2

--Looking at countries with highest infection rate compared to population
SELECT location,population,max(cast(total_cases as int)) AS HighestInfectionCount,
MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float,population), 0))) * 100 AS MaxInfectedPopulationPercentage
FROM CovidDeaths
WHERE continent is not null
Group BY location,population
Order BY MaxInfectedPopulationPercentage DESC

--Showing Countries with Highest Death Count
SELECT location,max(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
Group BY location
Order BY TotalDeathCount DESC

--BREAK DOWN BY CONTINENT

--Looking at continents with highest infection rate compared to population
SELECT continent,max(cast(total_cases as int)) AS HighestInfectionCount,
MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float,population), 0))) * 100 AS MaxInfectedPopulationPercentage
FROM CovidDeaths
WHERE continent is not null
Group BY continent
Order BY MaxInfectedPopulationPercentage DESC

--Showing Countries with Highest Death Count
SELECT continent,max(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
Group BY continent
Order BY TotalDeathCount DESC

--Global Numbers
--Death Percentage globally perday
SELECT date,Sum(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths,(SUM(cast(new_deaths as int))/NULLIF(Sum(new_cases),0))*100 as DeathPercentage
FROM CovidDeaths 
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--OVERALL Death Percentage globally
SELECT Sum(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths,(SUM(cast(new_deaths as int))/NULLIF(Sum(new_cases),0))*100 as DeathPercentage
FROM CovidDeaths 
WHERE continent is not null

--Looking at Total Population VS Total Vaccinations
--USING CTE 
WITH PopVSVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
   ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent is not null
--ORDER  BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PopulationVaccinatedPercentage
FROM PopVSVac

--USING TEMP TABLE
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, 
New_Vaccinations numeric, RollingPeopleVaccinated numeric
)
INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
   ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent is not null
--ORDER  BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PopulationVaccinatedPercentage
FROM #PercentagePopulationVaccinated

--CREATING VIEW FOR STORING DATA FOR VIZUALIZATIONS

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,
dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
   ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent is not null
--ORDER  BY 2,3

SELECT *
FROM PercentagePopulationVaccinated