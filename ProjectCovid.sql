-- Covid EDA --

-- Dataset contains data from 24 Feb 2020 - 07 Jan 2022

-- Total cases vs Total deaths
-- Show death percentage from covid for each country 
SELECT
	location,
    date,
    total_cases,
    total_deaths,
    100*(total_deaths / total_cases) AS death_percentage
FROM covid.deaths
WHERE continent IS NOT NULL 
AND location LIKE '%states%'
ORDER BY 
	location,
    date
    ;



-- Total Cases vs Population
-- Shows the percentage of the population is infected with Covid 
SELECT
	location,
    date,
    total_cases,
    population,
    100*(total_cases / population) AS InfectionPercentage
FROM covid.deaths
WHERE continent IS NOT NULL 
ORDER BY 
	location,
    date
    ;
   
   
   
-- Infection percentage per location
-- Show highest infection percentage compared to population
SELECT
	location,
	population,
	SUM(new_cases) AS HighestInfectionCount,
    (SUM(new_cases) / MAX(population)) * 100 AS InfectionPercentage
FROM covid.deaths
WHERE continent IS NOT NULL 
GROUP BY 
	location, 
    population
ORDER BY InfectionPercentage DESC
;



-- Total Deaths per location
-- Showing countries with highest death count 
SELECT
	location,
	MAX(total_deaths) AS TotalDeathCount
FROM covid.deaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY 2 DESC
;



-- Breaking down by Continent --

-- Total death by continent / World Grouping
--  Showing death counts per continents 
-- Not including iso_code 'OWID_%C' to remove entries like high income, low income, etc from showing in the location column
SELECT
	location,
	SUM(new_deaths) AS TotalDeathCount
FROM covid.deaths
WHERE continent IS NULL AND iso_code NOT LIKE 'OWID_%C' 
GROUP BY location 
ORDER BY TotalDeathCount DESC
;




-- Total cases, deaths and death percentage of the world -- 
SELECT 
	SUM(new_cases) AS cases ,
    SUM(new_deaths) AS deaths,
    (SUM(new_deaths)/SUM(new_cases)) * 100 AS DeathPercentage
FROM covid.deaths
WHERE continent IS NOT NULL 
;

-- Breakdown of the world's total cases, deaths and death percentage daily view --
CREATE VIEW DailyDeathPercent AS(
	SELECT 
	 date,
	SUM(new_cases) AS cases ,
    SUM(new_deaths) AS deaths,
    (SUM(new_deaths)/SUM(new_cases)) * 100 AS DeathPercentage
FROM covid.deaths
WHERE continent IS NOT NULL 
GROUP BY date)
;
SELECT *
FROM DailyDeathPercent;

-- Creating CTE --
-- Comparing the country's fully vaccinated percentage with the infection_percentage and mortality rate
WITH CountryDeathVac (Location, Population, Cases, Deaths, Fully_vaccinated_percentage) AS
(
-- Population vs Vaccinations
SELECT 
	cd.location,
    cd.population,
    MAX(cd.total_cases) AS cases,
	MAX(cd.total_deaths) AS death,
	(MAX(cv.people_fully_vaccinated)/population) * 100 AS fully_vaccinated_percentage
FROM deaths AS cd
JOIN vaccine AS cv
	ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
GROUP BY cd.location,cd.population)

-- Uncomment the WHERE clause to get the information only for United States
SELECT 
	location,
    population,
    fully_vaccinated_percentage,
	(cases/population) *100 AS infection_percentage,
    (deaths/population) *1000 AS mortality
FROM CountryDeathVac
-- WHERE location LIKE '%states%'
ORDER BY infection_percentage DESC
;

    


-- Temp Table PopVsVac
-- Creating a temp table to get number of vaccinations per day for each country
DROP Table IF EXISTS PopVsVac;
CREATE TEMPORARY TABLE PopVsVac AS(
	SELECT 
	cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated,
    cv.people_vaccinated AS OneDose,
    cv.people_fully_vaccinated AS BothDose
FROM deaths AS cd
JOIN vaccine AS cv
	ON cd.location = cv.location
    AND cd.date= cv.date
WHERE cd.continent IS NOT NULL
)
;

-- Compare the daily One Vs Both doses percentage
SELECT *, 
(OneDose/population)*100 AS OneDosePercentage,
(BothDose/population)*100 AS BothDosePercentage
FROM PopvsVac
;


-- Covid Data Viz -- 

-- Table 1 -- 
-- Total Cases vs Total Deaths --
SELECT
	SUM(new_cases) AS Cases,
    SUM(new_deaths) AS Deaths,
    100 * (SUM(new_deaths)/ SUM(new_cases)) AS Death_Percentage
FROM covid.deaths
-- WHERE location LIKE '%states%' 
WHERE continent IS NOT NULL
;

    
	
-- Table 2 -- 
-- Total Deaths by Continents --
SELECT
	location,
	SUM(new_deaths) AS TotalDeathCount
FROM covid.deaths
WHERE continent IS NULL AND iso_code NOT LIKE 'OWID_%C' AND location NOT IN ( 'World','International', 'European Union')
GROUP BY location 
ORDER BY TotalDeathCount DESC
;


-- Table 3 -- 
-- Infection Count vs Infection Percentage by Country  --
SELECT
	location,
	population,
	SUM(new_cases) AS HighestInfectionCount,
    (SUM(new_cases) / MAX(population)) * 100 AS InfectionPercentage
FROM covid.deaths
WHERE continent IS NOT NULL 
GROUP BY 
	location, 
    population
ORDER BY InfectionPercentage DESC
;

-- Table 4 --
-- Total Cases vs Infection Percentage by Date --
SELECT
	location,
    date,
    total_cases,
    population,
    100*(total_cases / population) AS InfectionPercentage
FROM covid.deaths
WHERE continent IS NOT NULL 
ORDER BY 
	location,
    date
    ;

