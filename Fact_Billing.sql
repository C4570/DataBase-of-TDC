--Seleciona la bse de datos--
use datawarehouse;

--Juntamos en una tabla temporal llamada "BILLING_TEMP" las tablas Mid_Billing y Mid_Billing_Detail de la base de datos intermedia
SELECT billing.*, detail.PRODUCT_ID, detail.QUANTITY
INTO #Billing
FROM middle.dbo.Mid_Billing billing 
JOIN middle.dbo.Mid_Billing_Detail detail
ON billing.BILLING_ID = detail.BILLING_ID

--Unimos la tabal temporal #Billing con la tabla Mid_Billing_history en una nueva tabla temporal llamada #Fact_Billing
SELECT 
    history.date AS DATE,
    history.billing_id AS BILLING_ID,
    history.region AS REGION,
    history.customer_id AS CUSTOMER_ID,
    history.employee_id AS EMPLOYEE_ID,
    history.product_id AS PRODUCT_ID,
    history.quantity AS QUANTITY

INTO #Fact_Billing
FROM middle.dbo.Mid_Billing_history history

UNION ALL

SELECT 
    temp.DATE,
    temp.BILLING_ID,
    temp.REGION,
    temp.CUSTOMER_ID,
    temp.EMPLOYEE_ID,
    temp.PRODUCT_ID,
    temp.QUANTITY
FROM #Billing temp;

--Minimo
SELECT PRODUCT_ID, min(DATE) as Minimo 
INTO #minimo
FROM middle.dbo.Mid_Price
group by PRODUCT_ID

--Medio
SELECT medio.PRODUCT_ID, min(medio.DATE) as Medio 
INTO #medio
FROM middle.dbo.Mid_Price medio
	left join #minimo minimo
		ON medio.PRODUCT_ID = minimo.PRODUCT_ID
		and medio.DATE = minimo.Minimo
WHERE 1=1
	and minimo.Minimo is null
group by medio.PRODUCT_ID

--Maximo
SELECT PRODUCT_ID, max(DATE) as Maximo 
INTO #maximo
FROM middle.dbo.Mid_Price
--WHERE PRODUCT_ID = 3
group by PRODUCT_ID

--Desde hasta
SELECT minimo.PRODUCT_ID, minimo.minimo AS Desde, medio.medio AS Hasta
INTO #PriceWithFromTo
FROM #minimo minimo
	join #medio medio
		ON minimo.PRODUCT_ID = medio.PRODUCT_ID
union all
SELECT medio.PRODUCT_ID, medio.medio, maximo.maximo
FROM #medio medio
	join #maximo maximo
		ON medio.PRODUCT_ID = maximo.PRODUCT_ID
union all
SELECT maximo.PRODUCT_ID, maximo.maximo, null
FROM #maximo maximo

--Agregar columna PRICE
SELECT PRODUCT_ID, Desde, Hasta, PRICE
INTO #PriceWithPrice
FROM (
	SELECT p.PRODUCT_ID, p.Desde, p.Hasta, m.PRICE,
		ROW_NUMBER() over (partition by p.PRODUCT_ID, p.Desde, p.Hasta order by m.DATE) as rn
	FROM #PriceWithFromTo p
		join middle.dbo.Mid_Price m
			ON p.PRODUCT_ID = m.PRODUCT_ID
	WHERE m.DATE between p.Desde and isnull(p.Hasta, m.DATE)
) t
WHERE rn = 1

--Agregar columna PRICE a #Fact
SELECT f.DATE, f.BILLING_ID, f.REGION, f.CUSTOMER_ID, f.EMPLOYEE_ID, f.PRODUCT_ID, f.QUANTITY, p.PRICE
INTO #Fact
FROM #Fact_Billing f
	join #PriceWithPrice p
		ON f.PRODUCT_ID = p.PRODUCT_ID
WHERE f.DATE between p.Desde and isnull(p.Hasta, f.DATE)

SELECT f.DATE, f.BILLING_ID, f.REGION, f.CUSTOMER_ID, f.EMPLOYEE_ID, f.PRODUCT_ID, f.QUANTITY, p.PRICE
INTO #Fact_Billing_With_Price
FROM #Fact_Billing f
	join #PriceWithPrice p
		ON f.PRODUCT_ID = p.PRODUCT_ID
WHERE f.DATE between p.Desde and isnull(p.Hasta, f.DATE)

--Agregar columna QUANTITY_LITER a #Fact_Billing_With_Price
select f.DATE, f.BILLING_ID, f.REGION, f.CUSTOMER_ID, f.EMPLOYEE_ID, f.PRODUCT_ID, f.QUANTITY, f.PRICE, d.CONTAINER_CAPACITY * f.QUANTITY as QUANTITY_LITER
into #Fact_Billing_With_Quantity_Liter
from #Fact_Billing_With_Price f
	join Dim_Product d
		on f.PRODUCT_ID = d.PRODUCT_KEY

--Agregar columna TOTAL_PRICE a #Fact_Billing_Quantity_Liter
SELECT DATE, BILLING_ID, REGION, CUSTOMER_ID, EMPLOYEE_ID, PRODUCT_ID, QUANTITY, PRICE, QUANTITY_LITER, QUANTITY * PRICE as TOTAL_PRICE
INTO #Fact_Billing_With_Total_Price
FROM #Fact_Billing_With_Quantity_Liter

--
-- Agregar columna DISCOUNT a #Fact_Billing_With_Total_Price
SELECT f.DATE, f.BILLING_ID, f.REGION, f.CUSTOMER_ID, f.EMPLOYEE_ID, f.PRODUCT_ID, f.QUANTITY, f.PRICE, f.QUANTITY_LITER, f.TOTAL_PRICE, ISNULL(d.PERCENTAGE, 0) as DISCOUNT
INTO #Fact_Billing_With_Discount
FROM #Fact_Billing_With_Total_Price f
LEFT JOIN middle.dbo.Mid_Discounts d
    ON f.TOTAL_PRICE >= d.TOTAL_BILLING
    AND (f.DATE BETWEEN d.DESDE AND ISNULL(d.HASTA, f.DATE))

-- Aplicar descuento a TOTAL_PRICE
SELECT DATE, BILLING_ID, REGION, CUSTOMER_ID, EMPLOYEE_ID, PRODUCT_ID, QUANTITY, PRICE, QUANTITY_LITER, TOTAL_PRICE, TOTAL_PRICE * (1 - DISCOUNT / 100.0) as TOTAL_PRICE_WITH_DISCOUNT, DISCOUNT
INTO #Fact_Billing_With_Discount_And_Total_Price
FROM #Fact_Billing_With_Discount

-- Crear tabla Fact_Billing
SELECT
    D.DATE_KEY,
    CONCAT(e.EMPLOYEE_KEY, c.CUSTOMER_KEY, p.PRODUCT_KEY) as BILLING_KEY,
    F.REGION,
    C.CUSTOMER_KEY,
    E.EMPLOYEE_KEY,
    P.PRODUCT_KEY,
    F.QUANTITY,
    F.PRICE,
    F.QUANTITY_LITER,
    F.TOTAL_PRICE,
    F.TOTAL_PRICE_WITH_DISCOUNT,
    F.DISCOUNT
INTO Fact_Billing
FROM 
    #Fact_Billing_With_Discount_And_Total_Price AS F
JOIN 
    Dim_Date AS D ON CAST(F.DATE AS DATE) = D.DATE
JOIN 
	Dim_Customer as C ON F.CUSTOMER_ID = C.CUSTOMER_ID
JOIN 
	Dim_Product as P ON F.PRODUCT_ID = 1 + P.PRODUCT_KEY
JOIN 
	Dim_Employee as E ON F.EMPLOYEE_ID = E.EMPLOYEE_ID

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM #PriceWithFromTo 
SELECT * FROM #PriceWithPrice --WHERE PRODUCT_ID = 1
SELECT * FROM #Fact_Billing --WHERE PRODUCT_ID=1 and DATE < '2006-02-01'
--Cuando añadimos el precio si nos fijamos #Fact_Billing_With_Price va a tener menor filas que #Fact_Billing 
--porque hay algunos DATE que son anteriores a la fecha minima y por lo tanto no tiene ningun precio que asiganarle
SELECT * FROM #Fact_Billing_With_Price --WHERE PRODUCT_ID=1
SELECT * FROM #Fact_Billing_With_Quantity_Liter 
SELECT * FROM #Fact_Billing_With_Total_Price --WHERE PRICE > 2 AND QUANTITY >80 
--no hay ningun precio total superior a los 500 es decir que el descuento de 500 y 600 no se aplica a ninguno
SELECT * FROM #Fact_Billing_With_Discount
SELECT * FROM #Fact_Billing_With_Discount_And_Total_Price --WHERE DISCOUNT = 15 --1.642.971

SELECT * FROM Fact_Billing --1.592.731

SELECT * FROM Dim_Product
SELECT * FROM Dim_Employee
SELECT * FROM Dim_Customer
SELECT * FROM Dim_Date
SELECT * FROM middle.dbo.Mid_Date

-- vemos si la stg billing history tiene datos nulos
SELECT * FROM staging.dbo.STG_BILLING_HISTORY
WHERE id  IS NULL
OR billing_id IS NULL
OR date IS NULL
OR customer_id IS NULL
OR employee_id IS NULL
OR product_id IS NULL
OR quantity IS NULL
OR region IS NULL;

-- vemos si la stg billing tiene datos nulos
SELECT * FROM staging.dbo.STG_BILLING
WHERE BILLING_ID  IS NULL
OR DATE IS NULL
OR EMPLOYEE_ID IS NULL
OR CUSTOMER_ID IS NULL
OR BRANCH_ID IS NULL
OR REGION IS NULL;

-- vemos si la stg billing detail tiene datos nulos
SELECT * FROM staging.dbo.STG_BILLING_DETAIL
WHERE BILLING_ID  IS NULL
OR PRODUCT_ID IS NULL
OR QUANTITY IS NULL;

-- vemos si la fact temporal tiene datos nulos
SELECT * FROM #Fact_Billing
WHERE DATE  IS NULL
OR BILLING_ID IS NULL
OR REGION IS NULL
OR CUSTOMER_ID IS NULL
OR EMPLOYEE_ID IS NULL
OR PRODUCT_ID IS NULL
OR QUANTITY IS NULL;