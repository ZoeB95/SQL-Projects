/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL 
ORDER BY 3,4

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL 
ORDER BY 1,2

-- How many deaths per case? (Total Deaths vs. Total Cases)
-- Likelihood of dying if you contract COVID in a specific country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE location = 'Barbados'
AND continent IS NOT NULL 
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY date ASC

-- Total Cases vs Population (What percentage of the population contracted COVID) 
SELECT location, date, population, total_cases, (total_cases/population)*100 AS Percentage_Pop_Infected
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Which Country has the highest infection rate in their overall population?
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Percentage_Pop_Infected
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Percentage_Pop_Infected DESC

-- Countries with the highest Death Count per population due to COVID
SELECT location, MAX(cast(total_deaths AS int)) AS Total_Death_Count
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

--DATA BY CONTINENT
-- Highest Death Count Per Continent 
SELECT location, MAX(cast(total_deaths AS int)) AS Total_Death_Count
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

SELECT continent, MAX(cast(Total_deaths AS int)) AS Total_Death_Count
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- GLOBAL NUMBERS
-- BY Date
SELECT date, SUM(new_cases) AS Total_Daily_Cases, SUM(cast(new_deaths AS int)) AS Total_Daily_Deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS Death_Per_By_Date
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY date

-- Global Death Percentage as of Early June 2022
SELECT SUM(new_cases) AS Total_Daily_Cases, SUM(cast(new_deaths AS int)) AS Total_Daily_Deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS Global_Death_Per
FROM Portfolio_Project.dbo.Covid_Deaths
WHERE continent IS NOT NULL


-- Exploring Covid_Vaccinations Table
SELECT *
FROM Portfolio_Project.dbo.Covid_Vaccinations

-- JOIN Tables
SELECT *
FROM Portfolio_Project.dbo.Covid_Deaths AS death
JOIN Portfolio_Project.dbo.Covid_Vaccinations AS vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL

-- Total # of ppl in the world who have been vaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
FROM Portfolio_Project.dbo.Covid_Deaths AS death
JOIN Portfolio_Project.dbo.Covid_Vaccinations AS vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3

SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Rolling_Ppl_Vaccinatated
FROM Portfolio_Project.dbo.Covid_Deaths AS death
JOIN Portfolio_Project.dbo.Covid_Vaccinations AS vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3

--  Using a CTE (Common Table Expression) to perform Calculation on Partition By in previous query
WITH Pop_Vs_Vacc (Continent, Location, Date, Population, New_Vaccinations, Rolling_Ppl_Vaccinated)
AS 
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Rolling_Ppl_Vaccinatated
FROM Portfolio_Project.dbo.Covid_Deaths AS death
JOIN Portfolio_Project.dbo.Covid_Vaccinations AS vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL
)
SELECT *, (Rolling_Ppl_Vaccinated/Population)*100 AS Perc_Ppl_Vacc
FROM Pop_Vs_Vacc

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS  #Percent_Population_Vaccinated
CREATE TABLE  #Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_Ppl_Vaccinated numeric
)

INSERT INTO #Percent_Population_Vaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Rolling_Ppl_Vaccinatated
FROM Portfolio_Project.dbo.Covid_Deaths AS death
JOIN Portfolio_Project.dbo.Covid_Vaccinations AS vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL

SELECT *, (Rolling_Ppl_Vaccinated/Population)*100 AS Perc_Ppl_Vacc
FROM  #Percent_Population_Vaccinated

-- Create View to store for later visualization
CREATE VIEW  Percent_Population_Vaccinated AS
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Rolling_Ppl_Vaccinatated
FROM Portfolio_Project.dbo.Covid_Deaths AS death
JOIN Portfolio_Project.dbo.Covid_Vaccinations AS vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL