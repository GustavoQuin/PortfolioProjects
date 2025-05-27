SELECT*
FROM [Portfolio Project COVID]..CovidDeaths
ORDER BY 3,4

-- Select data that we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project COVID]..CovidDeaths
ORDER BY 1,2  -- this bases the query on the location and the date

--Total cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, 
       CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS FLOAT), 0) AS death_rate
FROM [Portfolio Project COVID]..CovidDeaths
ORDER BY location, date;

--- Add a column with the percentage

SELECT location, date, total_cases, total_deaths, 
       CONCAT(ROUND(CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)*100, 2), '%') AS death_rate_percentage
FROM [Portfolio Project COVID]..CovidDeaths
ORDER BY location, date;
-- the result shows the 'probability' of dying if you get the disease in each country
-- for example in Afghanistan the chance of dying is 4.3% approximately.

-- Quiero filtrar para ver solo Argentina

SELECT location, date, total_cases, total_deaths, 
       CONCAT(ROUND(CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)*100, 2), '%') AS death_rate_percentage
FROM [Portfolio Project COVID]..CovidDeaths
WHERE location like '%Argentina%'
ORDER BY location, date;  -- en Arg la probabilidad de muerte es de 2.6% aprox

-- Now we look at Total Cases vs Population
-- We want to see what percentage of population got COVID

SELECT location, date, total_cases, population, 
       CONCAT(ROUND(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)*100, 2), '%') AS COVIDcase_rate_percentage
FROM [Portfolio Project COVID]..CovidDeaths
WHERE location like '%Argentina%'
ORDER BY location, date; -- 3.6%

-- In the US

SELECT location, date, total_cases, population, 
       CONCAT(ROUND(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)*100, 2), '%') AS COVIDcase_rate_percentage
FROM [Portfolio Project COVID]..CovidDeaths
WHERE location like '%states%'
ORDER BY location, date; -- higher than Arg: 6.1%

-- Volvemos a ver la tabla con los casos totales sobre poblacion

SELECT location, date, total_cases, population, 
       CONCAT(ROUND(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)*100, 2), '%') AS COVIDcase_rate_percentage
FROM [Portfolio Project COVID]..CovidDeaths
ORDER BY location, date;

-- Looking at countries with highest infection rates compared to population

SELECT location, population, 
       MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
	   MAX(CONCAT(ROUND(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)*100, 2), '%')) AS PercentPopulationInfected 
FROM [Portfolio Project COVID]..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC -- vemos el porcentaje de infectados en orden descendente

-- ahora veremos highest infection count en orden descendente

SELECT location, population, 
       MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
	   MAX(CONCAT(ROUND(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)*100, 2), '%')) AS PercentPopulationInfected 
FROM [Portfolio Project COVID]..CovidDeaths
GROUP BY location, population
ORDER BY HighestInfectionCount DESC

-- Showing countries with highest death count per population

SELECT location, 
       MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [Portfolio Project COVID]..CovidDeaths
WHERE continent is not null
      AND location NOT IN (
	  'World', 'Europe', 'Asia', 'Africa', 
	  'North America', 'South America', 'Oceania',
	  'European Union', 'International'
	  )
GROUP BY location
ORDER BY TotalDeathCount DESC;  -- excluimos a los continentes y mostramos solo paises y Total Death Count

-- Nos let's break it down by continent

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project COVID]..CovidDeaths
Where continent is not null
   AND continent != 'World'
   AND continent != 'International'
Group by continent
Order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select date, 
SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))*100/NULLIF(SUM(new_cases), 0) as DeathPercentage
FROM [Portfolio Project COVID]..CovidDeaths
where continent is not null
Group by date
Order by 1,2

-- We look at total cases

Select SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))*100/NULLIF(SUM(new_cases), 0) as DeathPercentage
FROM [Portfolio Project COVID]..CovidDeaths
where continent is not null
Order by 1,2

-- Join Covid Vaccinations and Covid Deaths

Select *
From [Portfolio Project COVID]..CovidDeaths dea
Join [Portfolio Project COVID]..CovidVaccinations vac
     On dea.location = vac.location
	 and dea.date = vac.date_corrected


-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From [Portfolio Project COVID]..CovidDeaths dea
Join [Portfolio Project COVID]..CovidVaccinations vac
     On dea.location = vac.location
	 and dea.date = vac.date_corrected
where dea.continent is not null
     and dea.continent != 'World'
	 and dea.continent != 'International'
order by vac.new_vaccinations desc


-- Rolling People Vaccinated (it adds up vaccinated people by location)

--We use CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location
    order by dea.location,
	dea.date) as RollingPeopleVaccinated
From [Portfolio Project COVID]..CovidDeaths dea
Join [Portfolio Project COVID]..CovidVaccinations vac
    On dea.location = vac.location
	and dea.date = vac.date_corrected
where dea.continent is not null
)

Select *
From PopvsVac

-- Porcentaje de Rolling People Vaccinated related to the population

With PopvsVac as(
  Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) 
        OVER (Partition by dea.location order by dea.location, dea.date) 
        as RollingPeopleVaccinated
  From [Portfolio Project COVID]..CovidDeaths dea
  Join [Portfolio Project COVID]..CovidVaccinations vac
    On dea.location = vac.location
	and dea.date = vac.date_corrected
  where dea.continent is not null
)

Select *, 
   CAST(RollingPeopleVaccinated AS FLOAT) * 100 / population as VaccionationPercentage
From PopvsVac
order by VaccionationPercentage desc;

-- Creamos una tabla temporal llamada Percent Population Vaccinated

-- TEMP table

DROP Table if exists #PercentPopulationVaccinated

Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
  Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) 
        OVER (Partition by dea.location order by dea.location, dea.date) 
        as RollingPeopleVaccinated
  From [Portfolio Project COVID]..CovidDeaths dea
  Join [Portfolio Project COVID]..CovidVaccinations vac
    On dea.location = vac.location
	and dea.date = vac.date_corrected
  where dea.continent is not null

Select *, 
   CAST(RollingPeopleVaccinated AS FLOAT) * 100 / population as VaccionationPercentage
From #PercentPopulationVaccinated;


-- Creating view to store data visualizations 

Create View PercentPopulationVaccinated as
 Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) 
        OVER (Partition by dea.location order by dea.location, dea.date) 
        as RollingPeopleVaccinated
  From [Portfolio Project COVID]..CovidDeaths dea
  Join [Portfolio Project COVID]..CovidVaccinations vac
    On dea.location = vac.location
	and dea.date = vac.date_corrected
  where dea.continent is not null

  Select *
  From PercentPopulationVaccinated


















