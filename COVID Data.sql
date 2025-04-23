SELECT * from Portfolio..CovidDeaths
SELECT * from Portfolio..CovidVaccinations

-- Select data that we are going to be using 
Select location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio..CovidDeaths
order by 1,2

-- Looking at the Total Cases vs Total Deaths 
-- shows the likelihood of dying with covid in your country
Select location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / total_cases)*100 as DeathPercentage
FROM Portfolio..CovidDeaths
WHERE location= 'United States' and continent is not null
order by 1,2

-- Looking at the Total Cases vs Population
-- shows the population of who got covid
Select location, date, population, total_cases, (CAST(total_cases AS FLOAT) / population)*100 as GotCovid
FROM Portfolio..CovidDeaths
--WHERE location= 'United States' and continent is not null
order by 1,2

-- Looking at countries with highest infection rate compared to population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((CAST(total_cases AS FLOAT) / population))*100 as PercentPopulationInfected
FROM Portfolio..CovidDeaths
--WHERE location= 'United States' 
Group By location, population
order by PercentPopulationInfected desc

-- Looking at countries with highest death count per population
Select location, MAX(total_deaths) AS TotalDeathCount
FROM Portfolio..CovidDeaths
--WHERE location= 'United States'
WHERE continent is not null
Group By location
order by TotalDeathCount desc

-- LETS BREAK THINGS DOWN BY CONTINENT

-- Looking at continents with the highest death count per population
Select continent, MAX(total_deaths) AS TotalDeathCount
FROM Portfolio..CovidDeaths
--WHERE location= 'United States'
WHERE continent is not null
Group By continent
order by TotalDeathCount desc


-- GLOABL NUMBERS 

SELECT SUM(CAST(new_cases AS FLOAT)) AS cases, SUM(CAST(new_deaths AS FLOAT)) AS deaths,
  (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
--Group by date
ORDER BY 1, 2;

-- JOINING 2 TABLES TOGETHER 
-- Looking at Total Population Vs Vaccinations 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date) 
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths deaths JOIN Portfolio..CovidVaccinations vac
    ON deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not null
order by 2,3


-- USE CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date) 
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths deaths JOIN Portfolio..CovidVaccinations vac
    ON deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not null
--order by 2,3
)
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS VaccinationRate
from PopvsVac


--TEMP TABLE 
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated NUMERIC
)

INSERT into #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date) 
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths deaths JOIN Portfolio..CovidVaccinations vac
    ON deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not null
--order by 2,3
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS VaccinationRate
from #PercentPopulationVaccinated

--CREATING VIEW TO STORE DATA FOR LATER VISUALS 

CREATE View PercentPopulationVaccinated as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by deaths.location, deaths.date) 
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths deaths JOIN Portfolio..CovidVaccinations vac
    ON deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not null
--order by 2,3

Select * from PercentPopulationVaccinated


