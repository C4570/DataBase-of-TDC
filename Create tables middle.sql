use middle;

CREATE TABLE [Mid_Customer] (
	[CUSTOMER_KEY] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[CUSTOMER_ID] int,
    [FIRST_NAME] VARCHAR(255),
    [LAST_NAME] VARCHAR(255),
    [CITY] NVARCHAR(255),
    [STATE] NVARCHAR(255),
    [ZIPCODE] BIGINT,
    [TYPE] VARCHAR(50),
    [BIRTH_DATE] DATE,
	[AGE] INT
)

CREATE TABLE [Mid_Employee] (
    [EMPLOYEE_ID] FLOAT,
    [FULL_NAME] NVARCHAR(255),
    [CATEGORY] NVARCHAR(255),
    [EMPLOYMENT_DATE] NVARCHAR(255),
    [BIRTH_DATE] NVARCHAR(255),
    [EDUCATION_LEVEL] NVARCHAR(255),
    [GENDER] NVARCHAR(255)
)

CREATE TABLE [Mid_Employee_Fix] (
	[EMPLOYEE_KEY] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[EMPLOYEE_ID] INT,
    [FIRST_NAME] VARCHAR(255),
    [LAST_NAME] VARCHAR(255),
    [CATEGORY] NVARCHAR(255),
    [EMPLOYMENT_DATE] DATE,
    [BIRTH_DATE] DATE,
	[AGE] INT,
    [EDUCATION_LEVEL] NVARCHAR(255),
    [GENDER] VARCHAR(50)
)

CREATE TABLE [Mid_Product] (
    [PRODUCT_ID] varchar(50),
    [DETAIL] varchar(50),
    [FIX_PACKAGE] nvarchar(50)
)

CREATE TABLE [Mid_Product_Fix] (
    [PRODUCT_KEY] INT,
    [DETAIL] VARCHAR(50),
    [CONTAINER_CAPACITY] DECIMAL(3,2),
    [UNIT] NVARCHAR(88)
)

CREATE TABLE [Mid_Date] (
    [date] datetime
)

CREATE TABLE [Mid_Date_Fix] (
    [DATE_KEY] INT,
    [SEMESTER] NVARCHAR(16),
    [BIMESTER] NVARCHAR(10),
    [DATE] DATE,
    [YEAR] INT,
    [MONTH] INT,
    [DAY] INT
)

CREATE TABLE [Mid_Billing] (
    [DATE] datetime,
    [BILLING_ID] int,
    [REGION] varchar(45),
    [BRANCH_ID] int,
    [CUSTOMER_ID] smallint,
    [EMPLOYEE_ID] smallint
)

CREATE TABLE [Mid_Billing_history] (
    [id] int,
    [billing_id] int,
    [date] datetime,
    [customer_id] int,
    [employee_id] int,
    [product_id] int,
    [quantity] int,
    [region] nvarchar(45)
)

CREATE TABLE [Mid_Billing_Detail] (
    [BILLING_ID] int,
    [PRODUCT_ID] smallint,
    [QUANTITY] smallint
)

CREATE TABLE [Mid_Price] (
    [PRODUCT_ID] int,
    [DATE] datetime,
    [PRICE] float
)

CREATE TABLE [Mid_Discounts] (
    [DISCOUNT_ID] int,
    [DESDE] datetime,
    [HASTA] datetime,
    [TOTAL_BILLING] float,
    [PERCENTAGE] smallint
)