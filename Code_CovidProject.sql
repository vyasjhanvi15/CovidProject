-- Full Dataset
SELECT * 
FROM CovidDeaths
ORDER BY location, date


SELECT * 
FROM CovidVaccinations
ORDER BY location, date

-- Total Cases vs Total Deaths 
-- Showing likelyhood of dying in the country

SELECT 
	location
,	date
,	total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%states%'
and continent is not null 
ORDER BY iso_code, continent

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT 
	location
,	date 
,	Population
,	total_cases
,	(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE location like '%states%'
ORDER BY iso_code, continent



-- Countries with Highest Infection Rate compared to Population

SELECT 
	location
,	Population
,	MAX(total_cases) as HighestInfectionCount
,	Max((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, Population
ORDER BY PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

SELECT 
	location
,	MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null 
GROUP BY location
ORDER BY TotalDeathCount desc



-- Showing contintents with the highest death count per population

SELECT 
	continent
,	MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount desc


-- GLOBAL NUMBERS

SELECT 
	SUM(new_cases) as total_cases
,	SUM(cast(new_deaths as int)) as total_deaths
,	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null 
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
	death.continent
,	death.location
,	death.date
,	death.population
,	vaccine.new_vaccinations
,	SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths AS death
Join CovidVaccinations AS vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
WHERE death.continent IS NOT NULL 
ORDER BY 2,3



-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
	death.continent
,	death.location
,	death.date
,	death.population
,	vaccine.new_vaccinations
,	SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths AS death
Join CovidVaccinations AS vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
WHERE death.continent IS NOT NULL 
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPeopleVaccinatedPercentbyPop
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	death.continent
,	death.location
,	death.date
,	death.population
,	vaccine.new_vaccinations
,	SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
--WHERE death.continent is not null 
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPeopleVaccinatedPercentbyPop
FROM #PercentPopulationVaccinated



 --Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
	SELECT
		death.continent
	,	death.location
	,	death.date
	,	death.population
	,	vaccine.new_vaccinations
	,	SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.Date) AS RollingPeopleVaccinated
--	, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
WHERE death.continent IS NOT NULL
