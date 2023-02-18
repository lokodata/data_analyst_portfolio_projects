/* 
covid 19 data exploration v1

skills used: joins, cte's, temp tables, windows functions, aggregate functions, creating views, converting data types
*/


-- check data of coviddeaths
select * 
from portfolioproject_covid..coviddeaths
where continent is not null
order by 3, 4

-- check data of covidvaccinations
select * 
from portfolioproject_covid..covidvaccinations
order by 3, 4

-- select data that we are going to be starting with
select location, date, total_cases, new_cases, total_deaths, population
from portfolioproject_covid..coviddeaths
order by 1, 2

-- total cases vs total deaths
-- Shows the likelihood of dying if you contract covid in a certain country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from portfolioproject_covid..coviddeaths
where location = 'Philippines'
order by 1, 2

-- total cases vs population
-- Shows what percentage of population got covid in a certain country
select location, date, population, total_cases, (total_cases/population)*100 as percentpopulationinfected
from portfolioproject_covid..coviddeaths
where location like 'Philippines'
order by 1, 2

-- Looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as highestinfectioncount, max((total_cases/population))*100 as percentpopulationinfected
from portfolioproject_covid..coviddeaths
-- where location like 'Philippines'
group by location, population
order by 4 desc


-- Show countries with highest death count per population
select location, max(cast(total_deaths as int)) as totaldeathcount
from portfolioproject_covid..coviddeaths
where continent is not null
--where location like 'Philippines'
group by location
order by 2 desc



-- breaking things down by continent 

-- Show countries with highest death count per population
select location, max(cast(total_deaths as int)) as totaldeathcount
from portfolioproject_covid..coviddeaths
where continent is null
group by location
order by 2 desc

-- Showing continent with highest death count per population
select continent, max(cast(total_deaths as int)) as totaldeathcount
from portfolioproject_covid..coviddeaths
where continent is not null
group by continent
order by 2 desc



-- Global numbers

-- Shows total cases and deaths per date with deathpercentage
select date, sum(new_Cases) as totalcases, sum(cast(new_deaths as int)) as totaldeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as deathpercentage
from portfolioproject_covid..coviddeaths
where continent is not null
group by date
order by 1



-- check data of join table covid deaths and covidvaccinations
select * 
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
order by 2, 3

-- Shows total cases and deaths with death percentage
select sum(new_Cases) as totalcases, sum(cast(new_deaths as int)) as totaldeaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as deathpercentage
from portfolioproject_covid..coviddeaths
where continent is not null
order by 1

-- total population vs vaccinations
-- shows percentage of population that has recieved at least one covid vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3


-- Using CTE to perfrom calculation on partition by in previous query
with populationvsvaccination (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as (select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null)

select *, (rollingpeoplevaccinated/population)*100
from populationvsvaccination


--Using Temp Table to perform calculation on partition by in previous query
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rollingpeoplevaccinated numeric)

insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null

select *, (rollingpeoplevaccinated/population)*100
from #percentpopulationvaccinated


-- creating view to store data for later data visualization
drop view if exists percentpopulationvaccinated


create view percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select * from percentpopulationvaccinated
