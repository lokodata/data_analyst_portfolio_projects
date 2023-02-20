/* 

data exploration of covid data

skills used: joins, cte's, temp tables, windows functions, aggregate functions, creating views, converting data types, concate, playing with dates

generalization: this project shows my skills to analyze the data and understand what I could use for data visualization.
- the following sql code shows
	1. shows total no. cases, deaths, recoveries, cases vs recoveries, cases vs death per country
	2. shows what percentage of population got covid in a certain country (infectionrate)
	3. shows infection rate per month and year in a country (infectionrate per month)
	4. show countries with highest infection rate compared to population
	5. show countries with highest death count per population
	6. shows the likelihood of dying if you contract covid in a certain country (mortalityrate)
	7. shows mortality rate per month (mmm) and year (yyyy) of a country
	8. shows the likelihood of dying if you contract covid in a specific country today based on current data (mortalityrate)
	9. shows total number people that has recieved at least one covid vaccine through time per country
	10. shows percentage of vaccinated per country 
*/

-- shows all the data in the table
select *
from portfolioproject_covid..coviddata
where continent is not null -- filter to remove continent and only shows the countries data
order by 2, 3 asc


-- shows the iso_code (primary key) for "Philippines" and use it to make writing easier
-- but for readability I will mostly use location like 'country'
--where iso_code = 'phl' ---- to get specific countries
select distinct iso_code
from portfolioproject_covid..coviddata
where location like 'Phil%'


-- shows total no. cases, deaths, recoveries, cases vs recoveries, cases vs death per country
drop view if exists generaldata_per_country

create view generaldata_per_country as
select location, max(total_cases) as total_cases, 
max(convert(int, total_deaths)) as total_deaths, 
(max(total_cases) - max(total_deaths)) as  total_recoveries,
((max(total_cases) - max(total_deaths)) / max(total_cases))*100 as recoveryrate,
(max(total_deaths) / max(total_cases))*100 as moratalityrate
from portfolioproject_covid..coviddata
--where location like 'Philippines%' ---- to get specific countries
group by location
--order by 1

select * from portfolioproject_covid..generaldata_per_country order by 1


-- shows what percentage of population got covid in a certain country (infectionrate)
-- total cases vs population
select location, date, population, total_cases, (total_cases/population)*100 as infectionrate
from portfolioproject_covid..coviddata
where location like 'Philippines'
order by 1, 2


-- using temp table
-- shows infection rate per month and year in a country (infectionrate per month)
drop table if exists #monthyear_infection
create table #monthyear_infection (
location nvarchar(255),
year numeric,
month numeric,
population numeric,
new_cases numeric)

insert into #monthyear_infection 
select distinct location, year(date) as year, month(date) as month, population, new_cases
from portfolioproject_covid..coviddata

select location, cast(month as varchar) + '/' + cast(year as varchar) as month_year, sum(new_cases) as total_cases, population, (sum(new_cases)/population)*100 as infectionrate
from #monthyear_infection
--where location like 'Phil%'
group by location, population, month, year
order by location, year, month


-- show countries with highest infection rate compared to population
select location, population, max(total_cases) as highestinfectioncount, (max(total_cases)/population)*100 as infectionrate
from portfolioproject_covid..coviddata
-- where location like 'Philippines'
group by location, population
order by 4 desc


-- Show countries with highest death count per population
select location, max(cast(total_deaths as int)) as totaldeathcount
from portfolioproject_covid..coviddata
where continent is null
group by location
order by 2 desc


-- Showing continent with highest death count per population
select continent, max(cast(total_deaths as int)) as totaldeathcount
from portfolioproject_covid..coviddata
where continent is not null
group by continent
order by 2 desc


-- using cte's
-- shows mortality rate per month (mmm) and year (yyyy) of a country
-- total deaths vs total cases
with get_month_year as (select distinct location, year(date) as year, month(date) as month, new_cases, new_deaths
from portfolioproject_covid..coviddata)

select location, cast(month as varchar) + '/' + cast(year as varchar) as month_year, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int)) / sum(new_cases))*100 as mortalityrate
from get_month_year
where location like 'Phil%'
group by location, month, year
order by location, year, month


-- shows the likelihood of dying if you contract covid in a certain country (mortalityrate)
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as mortalityrate
from portfolioproject_covid..coviddata
where iso_code = 'PHL'
order by 1, 2


-- shows the likelihood of dying if you contract covid in all the countries today based on current (mortalityrate)
drop view if exists current_mortalityrate_country

create view current_mortalityrate_country as 
select t1.location, t1.date, t1.total_cases, t1.total_deaths, (total_deaths/total_cases)*100 as mortalityrate
from portfolioproject_covid..coviddata as t1
join (select location, max(date) as maxdate
from portfolioproject_covid..coviddata
group by location) t2
on t1.location = t2.location and t1.date = t2.maxdate

select * from current_mortalityrate_country 
where location like 'Philippines%' ---- to get specific countries 
order by mortalityrate desc


-- shows total number people that has recieved at least one covid vaccine through time per country
select continent, location, date, population, new_vaccinations, sum(convert(bigint, new_vaccinations)) over (partition by location order by location, date) as totalvaccinated
from portfolioproject_covid..coviddata
--where iso_code = 'phl'
--where continent like 'asia%'
--where new_vaccinations is not null
order by 2, 3


-- shows percentage of vaccinated per country 
select location, population, sum(convert(bigint, new_vaccinations)) total_vaccinations,
(sum(convert(bigint, new_vaccinations)) / population)*100 vaccinatedpercentage
from portfolioproject_covid..coviddata
group by location, population
order by 1


-- additional using 2 tables
-- total population vs vaccinations
-- shows percentage of population that has recieved at least one covid vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3


-- Using CTE to perfrom calculation on partition by in previous query
with populationvsvaccination (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as (select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null)

select *, (rollingpeoplevaccinated/population)*100 as vaccinatepercentage
from populationvsvaccination
where location like 'argen%'


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
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null


select *, (rollingpeoplevaccinated/population)*100 as vaccinatedpercent
from #percentpopulationvaccinated


-- creating view to store data for later data visualization
drop view if exists percentpopulationvaccinated


create view percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from portfolioproject_covid..coviddeaths dea
join portfolioproject_covid..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select * from percentpopulationvaccinated


/*
notes

if i get more time to understand the age data, additional queries would be:

total no. of cases, deaths, recoveries of each age
or by range of age like kids (-11), teen (12-17), adult (18-59), elderly (60+)

mortality rate per age / age group

infection rate per age / age group

vaccination rate per age / age group

*/


