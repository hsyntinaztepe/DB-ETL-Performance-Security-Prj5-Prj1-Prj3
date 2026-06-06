
SET NOCOUNT ON;

/* ---------- 0. Veritabani ---------- */
IF DB_ID('ETL_Proje5') IS NULL
    CREATE DATABASE ETL_Proje5;
GO
USE ETL_Proje5;
GO

/* ---------- 1. Tablolari (yeniden) kur ---------- */
IF OBJECT_ID('dbo.etl_error_log', 'U')   IS NOT NULL DROP TABLE dbo.etl_error_log;
IF OBJECT_ID('dbo.clean_customers', 'U') IS NOT NULL DROP TABLE dbo.clean_customers;
IF OBJECT_ID('dbo.staging_customers', 'U') IS NOT NULL DROP TABLE dbo.staging_customers;
GO

CREATE TABLE dbo.staging_customers (
    id NVARCHAR(50), full_name NVARCHAR(200), email NVARCHAR(200),
    city NVARCHAR(100), signup_date NVARCHAR(50), phone NVARCHAR(50)
);
CREATE TABLE dbo.clean_customers (
    id INT PRIMARY KEY, full_name NVARCHAR(200) NOT NULL, email NVARCHAR(200) NOT NULL,
    city NVARCHAR(100), signup_date DATE, phone NVARCHAR(20),
    loaded_at DATETIME DEFAULT GETDATE()
);
CREATE TABLE dbo.etl_error_log (
    error_id INT IDENTITY(1,1) PRIMARY KEY, source_id NVARCHAR(50),
    error_type NVARCHAR(100), error_detail NVARCHAR(500),
    logged_at DATETIME DEFAULT GETDATE()
);
GO
PRINT '>> Adim 1: Tablolar olusturuldu.';
GO

/* ---------- 2. EXTRACT: ham veriyi staging'e yukle ---------- */
BULK INSERT dbo.staging_customers
FROM 'C:\etl\customers_raw.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a',
      CODEPAGE = '65001', TABLOCK);
GO
PRINT '>> Adim 2: Ham veri staging tablosuna yuklendi.';
GO

/* ---------- 3. TRANSFORM: temizlik + standartlastirma ---------- */
UPDATE dbo.staging_customers
SET full_name = LTRIM(RTRIM(full_name)), email = LTRIM(RTRIM(email)),
    city = LTRIM(RTRIM(city)), id = LTRIM(RTRIM(id)),
    signup_date = LTRIM(RTRIM(signup_date));

UPDATE dbo.staging_customers SET city = UPPER(city);
UPDATE dbo.staging_customers SET email = LOWER(email);
UPDATE dbo.staging_customers
SET phone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            phone,' ',''),'(',''),')',''),'-',''),'+',''),'.','');
GO
PRINT '>> Adim 3a: Veri temizlendi ve standartlastirildi.';
GO

/* ---------- 3b. HATA TESPiTi: reddedilenleri logla ---------- */
INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'INVALID_ID', 'id sayisal degil: ' + ISNULL(id,'(null)')
FROM dbo.staging_customers WHERE TRY_CONVERT(INT, id) IS NULL;

INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'NULL_NAME', 'isim bos'
FROM dbo.staging_customers WHERE full_name IS NULL OR full_name = '';

INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'INVALID_EMAIL', 'gecersiz email: ' + ISNULL(email,'(null)')
FROM dbo.staging_customers WHERE email NOT LIKE '%_@_%.__%' OR email IS NULL;

INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'INVALID_DATE', 'tarih cevrilemedi: ' + ISNULL(signup_date,'(null)')
FROM dbo.staging_customers WHERE TRY_CONVERT(DATE, signup_date, 104) IS NULL;

INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'DUPLICATE_EMAIL', 'tekrar eden email: ' + email
FROM (SELECT id, email, ROW_NUMBER() OVER (PARTITION BY email ORDER BY TRY_CONVERT(INT,id)) AS rn
      FROM dbo.staging_customers WHERE email LIKE '%_@_%.__%') t
WHERE rn > 1;
GO
PRINT '>> Adim 3b: Reddedilen kayitlar loglandi.';
GO

/* ---------- 3c. LOAD: gecerli kayitlari clean'e yukle ---------- */
INSERT INTO dbo.clean_customers (id, full_name, email, city, signup_date, phone)
SELECT TRY_CONVERT(INT, s.id), s.full_name, s.email, s.city,
       TRY_CONVERT(DATE, s.signup_date, 104), s.phone
FROM dbo.staging_customers s
WHERE TRY_CONVERT(INT, s.id) IS NOT NULL
  AND s.full_name <> ''
  AND s.email LIKE '%_@_%.__%'
  AND TRY_CONVERT(DATE, s.signup_date, 104) IS NOT NULL
  AND NOT EXISTS (
        SELECT 1 FROM dbo.staging_customers s2
        WHERE s2.email = s.email
          AND TRY_CONVERT(INT, s2.id) < TRY_CONVERT(INT, s.id)
          AND s2.email LIKE '%_@_%.__%');
GO
PRINT '>> Adim 3c: Temiz veri clean_customers tablosuna yuklendi.';
GO

/* ---------- 4. KALiTE RAPORU ---------- */
SET NOCOUNT OFF;
PRINT '>> Adim 4: Veri kalitesi raporu';

SELECT
    (SELECT COUNT(*) FROM dbo.staging_customers) AS toplam_ham_kayit,
    (SELECT COUNT(*) FROM dbo.clean_customers)   AS temiz_kayit,
    (SELECT COUNT(*) FROM dbo.staging_customers) - (SELECT COUNT(*) FROM dbo.clean_customers) AS reddedilen_kayit,
    CAST(100.0 * (SELECT COUNT(*) FROM dbo.clean_customers)
         / (SELECT COUNT(*) FROM dbo.staging_customers) AS DECIMAL(5,2)) AS basari_orani_yuzde;

SELECT error_type AS hata_tipi, COUNT(*) AS adet
FROM dbo.etl_error_log GROUP BY error_type ORDER BY adet DESC;

SELECT city AS sehir, COUNT(*) AS musteri_sayisi
FROM dbo.clean_customers GROUP BY city ORDER BY musteri_sayisi DESC;
GO

PRINT '>> ETL sureci basariyla tamamlandi.';
GO
