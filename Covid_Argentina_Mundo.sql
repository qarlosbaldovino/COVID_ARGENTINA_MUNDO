-- COVID EN ARGENTINA Y EN EL MUNDO

-- Mostramos la probabilidad de muerte si contraes covid en tu pais.
-- A partir, de los casos y muertes por fecha.
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as PorcentajeMuerte
FROM
	PrimerProyecto..CovidDeaths$
WHERE location like '%Argentina%'
ORDER BY
	1,2


-- Muestra que porcentaje de la poblacion tuvo Covid
SELECT 
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 as PorcentajePoblacionInfectada
FROM
	PrimerProyecto..CovidDeaths$
WHERE location like '%Argentina%'
ORDER BY
	1,2

-- (MUNDIAL)Países con mayor tasa de infeccion comparados con su poblacion
SELECT 
	location,
	population,
	MAX(total_cases) as MayorCantidadInfectados,
	MAX((total_cases/population))*100 as PorcentajePoblacionInfectada
FROM
	PrimerProyecto..CovidDeaths$
GROUP BY
	location, population
ORDER BY
	PorcentajePoblacionInfectada desc


-- (MUNDIAL)Paises con numero mas alto de muertes por poblacion
SELECT 
	location,
	MAX(cast(total_deaths as int)) as CantidadTotalMuertes
FROM
	PrimerProyecto..CovidDeaths$
WHERE
	continent is not null
GROUP BY
	location
ORDER BY
	CantidadTotalMuertes desc

-- (MUNDIAL) Total de muertes por CONTINENTE
SELECT 
	location,
	MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM
	PrimerProyecto..CovidDeaths$
WHERE
	continent is null 
	AND
	location NOT like '%income%'
	AND
	location NOT like '%International%'
GROUP BY
	location
ORDER BY
	TotalDeathCount desc

-- (MUNDIAL)Numeros Globales por día
SELECT
	date,
	SUM(new_cases) as CasosTotal,
	SUM(cast(new_deaths as int)) as MuertesTotal,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as PorcentajeMuerte
FROM
	PrimerProyecto..CovidDeaths$
WHERE
	continent is not null
GROUP BY date
Order by 1,2

-- Numeros Globales general
SELECT
	SUM(new_cases) as totalCasos,
	SUM(cast(new_deaths as int)) as totalMuertes,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as PorcentajeMuerte
FROM
	PrimerProyecto..CovidDeaths$
WHERE
	continent is not null
Order by 1,2

-- Poblacion Total vs Vacunados
SELECT	
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER
	(Partition by dea.location ORDER BY dea.location, dea.date) as PersonasVacunadas
FROM
	PrimerProyecto..CovidDeaths$ dea
	JOIN
	PrimerProyecto..CovidVaccinations$ vac
ON dea.location = vac.location 
and
   dea.date = vac.date
WHERE
	dea.continent is not null
ORDER BY 2,3


-- Usando CTE
With PobVsVac (Continent, Location, Date, Population, New_Vaccinations, PersonasVacunadas)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PersonasVacunadas
From PrimerProyecto..CovidDeaths$ dea
Join PrimerProyecto..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

Select *, (PersonasVacunadas/Population)*100 as PorcentajeVacunados
From PobVsVac

-- Usamos una tabla temporal 

DROP Table if exists #PorcentajeVacunados
Create Table #PorcentajeVacunados
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PersonasVacunadas numeric
)

Insert into #PorcentajeVacunados
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PersonasVacunadas
From PrimerProyecto..CovidDeaths$ dea
Join PrimerProyecto..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date

Select *, (PersonasVacunadas/Population)*100 AS PorcentajeVacunados
From #PorcentajeVacunados

-- Creamos una VISTA para futuras visualizaciones

Create View PorcentajeVacunados as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PersonasVacunadas
From PrimerProyecto..CovidDeaths$ dea
Join PrimerProyecto..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
