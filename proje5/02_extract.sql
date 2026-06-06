

USE ETL_Proje5;
GO

-- Once tablonun var oldugundan emin ol (01 calistirilmadiysa uyar)
IF OBJECT_ID('dbo.staging_customers', 'U') IS NULL
BEGIN
    RAISERROR('staging_customers tablosu yok! Once 01_create_tables.sql calistir.', 16, 1);
    RETURN;
END
GO

-- Tekrar calistirma icin staging'i temizle (idempotent)
TRUNCATE TABLE dbo.staging_customers;
GO

BULK INSERT dbo.staging_customers
FROM 'C:\etl\customers_raw.csv'
WITH (
    FIRSTROW        = 2,          -- baslik satirini atla
    FIELDTERMINATOR = ',',        -- virgul ayrac
    ROWTERMINATOR   = '0x0a',     -- satir sonu (LF); CSV CRLF ise '0x0d0a' dene
    CODEPAGE        = '65001',    -- UTF-8
    TABLOCK
);
GO

-- Kontrol: kac kayit yuklendi, ornek satirlar
SELECT COUNT(*) AS yuklenen_kayit FROM dbo.staging_customers;
SELECT TOP 100 * FROM dbo.staging_customers;
GO

/* --- ALTERNATIF (BULK INSERT calismadiysa) -------------------
   SSMS'te veritabanina sag tik > Tasks > Import Flat File...
   sihirbazi ile de yukleyebilirsin. Hedef tablo: staging_customers
   Tum kolonlari NVARCHAR olarak isaretle.                      */
