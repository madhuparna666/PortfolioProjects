SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4


SELECT location,date,total_cases,new_cases, total_deaths , population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


----- total cases vs total deaths 

SELECT location, date, total_cases, total_deaths ,  (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where location like '%india%'
AND continent is not null
ORDER BY 1,2

-- total cases vs.population


SELECT location, date, total_cases, population ,  (total_cases/population)*100 as CovidPercentage
FROM PortfolioProject..CovidDeaths
where location like '%india%'
AND continent is not null
ORDER BY 1,2


---countries  highest infections rate compared to population

SELECT location, max(total_cases) as HighestInfectionCount , population ,  max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--where location like '%india%'
WHERE continent is not null
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC




--- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION


SELECT location, max(cast(TOTAL_DEATHS as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--where location like '%india%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC





-- let's break things down by continent

SELECT location, max(cast(TOTAL_DEATHS as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--where location like '%india%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

---- 
SELECT continent, max(cast(TOTAL_DEATHS as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--where location like '%india%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--- showing continents with the highest death count per population

SELECT continent, max(cast(TOTAL_DEATHS as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--where location like '%india%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--- GLOBAL NUMBERS


SELECT  date, sum(new_cases) AS total_cases ,SUM(CAST(NEW_DEATHS AS int)) AS total_deaths, 
SUM(CAST(NEW_DEATHS AS int)) / sum(new_cases) *100 AS DeathPercentage
--, total_deaths ,  (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--where location like '%india%'
where continent is not null
GROUP BY date
ORDER BY 1,2


-- sql joins 

Select *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location 
	and dea.date = vac.date

-- looking at total population vs. Vaccinations

Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3



-- looking at total population vs. Vaccinations with a new column , adding the previous row  with current row and showing the Rollong value
-- by using window functions

Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location 
ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--- this code will give error cause 'RollingPeopleVaccinated'is the column is just created and used right after it. and it's not supported

Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location 
ORDER BY dea.location,dea.date) as RollingPeopleVaccinated,
(RollingPeopleVaccinated/population) * 100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--- so as a solution , we either have to create CTE or Temp Table



--- WHAT IS CTE?
--- The Common Table Expressions (CTE) were introduced into standard SQL in order to simplify
--- various classes of SQL Queries for which a derived table was just unsuitable. 
--- CTE was introduced in SQL Server 2005, 
--- the common table expression (CTE) is a temporary named result set that you can reference 
--- within a SELECT, INSERT, UPDATE, or DELETE statement. 
--- You can also use a CTE in a CREATE a view, as part of the view’s SELECT query. 
--- In addition, as of SQL Server 2008, you can add a CTE to the new MERGE statement.



--- use CTE

With PopvsVac (Continent,Location, Date, Population,New_Vaccinations,RollingPeopleVaccinated)
as
(
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location 
ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select * , (RollingPeopleVaccinated/Population)*100
from PopvsVac


--- using TEMP table

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location 
ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location 
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select * , (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated



--- creating view to store the data for later visualizations


Create View PercentPopulationVaccinated as
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
     SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location 
     ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not nul
--order by 2,3


Select *
From PercentPopulationVaccinated



