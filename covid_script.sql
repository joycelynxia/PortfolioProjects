select *
from project.coviddeaths
order by 3,4;

-- table 1
-- total percentage of death by covid 
create view death_percentage as
select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as death_percentage
from project.coviddeaths
where continent is not null
order by 1,2;

-- table 2
-- highest death count per population
create view total_death_count as
select location, sum(new_deaths) as total_death_count
from project.coviddeaths 
where continent is null
and location not in ('World', 'European Union','International')
group by location
order by total_death_count desc;

-- table 3
-- countries with highest infection rate compared to population
create view percent_population_infected as
select location, population, date, max(total_cases) as highest_infection_count, (max(total_cases)/population)*100 as percent_population_infected
from project.coviddeaths
Group by location, population
order by percent_population_infected desc;

-- table 4
-- running count of percent population infected per day
create view running_percent_population_infected as
select location, population, date, max(total_cases) as highest_infection_count, max(total_cases/population)*100 as percent_population_infected
from project.coviddeaths
group by location, population, date
order by percent_population_infected desc;





-- TESTING ---- ---- ---- ----  ---- ---- ---- ---- ---- ---- ---- --
-- Select *
-- from project.covidvaccinations
-- order by 3,4;

Select location, date, total_cases, new_cases, total_deaths, population
From project.coviddeaths
order by 1,2;

-- comparing total cases vs total deaths
-- shows running likelihood of dying from covid in the US
select location, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from project.coviddeaths
where location like '%states%'
order by 1,2;

-- running likelihood of dying from covid (regardless of vax status)
-- create view death_percentage as
select date, location, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from project.coviddeaths
order by 2, 1;



-- comparing total cases vs population
-- shows percentage of population with covid
select location, total_cases, population, (total_cases/population)*100 as percentage_with_covid
from project.coviddeaths
where location like '%states%'
order by 1,2;




-- highest death count per continent
create view total_death_count_per_continent as
select continent, max(total_deaths) as total_death_count
from project.coviddeaths 
where continent is not null
group by continent
order by total_death_count desc;

-- **CORRECT** highest death count per continent
-- select location, max(total_deaths) as total_death_count
-- from project.coviddeaths 
-- where continent is null
-- group by location
-- order by total_death_count desc

-- GLOBAL STATS
select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as death_percentage
from project.coviddeaths
where continent is not null
group by date
order by 1,2;

select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as death_percentage
from project.coviddeaths
where continent is null
group by continent
order by 1,2;

-- total population vs vaccination by continent
select dea.location, max(population), max(total_vaccinations), max(total_vaccinations)/max(population)*100 as percent_vaccinated
from project.coviddeaths dea
join project.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is null
group by dea.location;

-- new vaccinations for each country per day
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from project.coviddeaths dea
join project.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3;

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_vac -- restart when we hit new location  
    -- rolling_vac/dea.population*100 as percent_vaccinated
from project.coviddeaths dea
join project.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null ;

-- CTE
with PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_vac -- restart when we hit new location  
    -- rolling_vac/dea.population*100 as percent_vaccinated
from project.coviddeaths dea
join project.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
select *, (rolling_people_vaccinated/population)*100 as percent_vaccinated
from PopvsVac;

-- Temp Table
drop table if exists percent_population_vaccinated;
Create Table percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric, 
new_vaccinations numeric,
rolling_people_vaccinated numeric
);

insert into percent_population_vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_vac -- restart when we hit new location  
    -- rolling_vac/dea.population*100 as percent_vaccinated
from project.coviddeaths dea
join project.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date;
-- where dea.continent is not null

select *, (rolling_people_vaccinated/population)*100 as percent_vaccinated
from percent_population_vaccinated;

create view percent_population_vaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_vac -- restart when we hit new location  
    -- rolling_vac/dea.population*100 as percent_vaccinated
from project.coviddeaths dea
join project.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3

