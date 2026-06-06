

USE ETL_Proje5;
GO

-- Guvenlik kontrolleri: gerekli tablolar ve ham veri var mi?
IF OBJECT_ID('dbo.staging_customers', 'U') IS NULL
BEGIN
    RAISERROR('staging_customers yok! Once 01_create_tables.sql calistir.', 16, 1);
    RETURN;
END
IF NOT EXISTS (SELECT 1 FROM dbo.staging_customers)
BEGIN
    RAISERROR('staging_customers bos! Once 02_extract.sql calistir.', 16, 1);
    RETURN;
END
GO

-- Tekrar calistirma icin hedef ve log temizle (idempotent)
TRUNCATE TABLE dbo.clean_customers;
DELETE FROM dbo.etl_error_log;
GO

/* =============== TRANSFORM (staging uzerinde yerinde) ========= */

-- 3.1 Bas/son bosluklari temizle (isim, email, sehir)
UPDATE dbo.staging_customers
SET full_name = LTRIM(RTRIM(full_name)),
    email     = LTRIM(RTRIM(email)),
    city      = LTRIM(RTRIM(city)),
    id        = LTRIM(RTRIM(id)),
    signup_date = LTRIM(RTRIM(signup_date));
GO

-- 3.2 Sehir adlarini standartlastir (hepsi BUYUK harf)
UPDATE dbo.staging_customers
SET city = UPPER(city);
GO

-- 3.3 Email'leri kucuk harfe cevir (standart)
UPDATE dbo.staging_customers
SET email = LOWER(email);
GO

-- 3.4 Telefonu sadece rakamlara indirgemek icin yardimci:
--     MSSQL'de tek seferde regex yok; TRANSLATE ile temizlik.
UPDATE dbo.staging_customers
SET phone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            phone,' ',''),'(',''),')',''),'-',''),'+',''),'.','');
GO

/* =============== HATA TESPiTi + LOGLAMA ====================== *
   Her kural icin reddedilecek kayitlari error log'a yaz.
   TRY_CONVERT: cevrilemezse NULL doner (hata firlatmaz).        */

-- Gecersiz id (sayisal degil)
INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'INVALID_ID', 'id sayisal degil: ' + ISNULL(id,'(null)')
FROM dbo.staging_customers
WHERE TRY_CONVERT(INT, id) IS NULL;

-- Bos/null isim
INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'NULL_NAME', 'isim bos'
FROM dbo.staging_customers
WHERE full_name IS NULL OR full_name = '';

-- Gecersiz email (basit desen: x@y.z)
INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'INVALID_EMAIL', 'gecersiz email: ' + ISNULL(email,'(null)')
FROM dbo.staging_customers
WHERE email NOT LIKE '%_@_%.__%' OR email IS NULL;

-- Gecersiz tarih (dd.mm.yyyy = format 104; cevrilemeyen NULL)
INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'INVALID_DATE', 'tarih cevrilemedi: ' + ISNULL(signup_date,'(null)')
FROM dbo.staging_customers
WHERE TRY_CONVERT(DATE, signup_date, 104) IS NULL;

-- Tekrar eden email (ilk gecen kabul, sonrakiler reddedilir)
INSERT INTO dbo.etl_error_log (source_id, error_type, error_detail)
SELECT id, 'DUPLICATE_EMAIL', 'tekrar eden email: ' + email
FROM (
    SELECT id, email,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY TRY_CONVERT(INT,id)) AS rn
    FROM dbo.staging_customers
    WHERE email LIKE '%_@_%.__%'
) t
WHERE rn > 1;
GO

/* =============== LOAD (sadece TUM kurallari gecenler) ======== */
INSERT INTO dbo.clean_customers (id, full_name, email, city, signup_date, phone)
SELECT
    TRY_CONVERT(INT, s.id),
    s.full_name,
    s.email,
    s.city,
    TRY_CONVERT(DATE, s.signup_date, 104),
    s.phone
FROM dbo.staging_customers s
WHERE TRY_CONVERT(INT, s.id)            IS NOT NULL   -- id gecerli
  AND s.full_name <> ''                                -- isim dolu
  AND s.email LIKE '%_@_%.__%'                          -- email gecerli
  AND TRY_CONVERT(DATE, s.signup_date, 104) IS NOT NULL -- tarih gecerli
  -- duplicate email: sadece ilk gelen
  AND NOT EXISTS (
        SELECT 1 FROM dbo.staging_customers s2
        WHERE s2.email = s.email
          AND TRY_CONVERT(INT, s2.id) < TRY_CONVERT(INT, s.id)
          AND s2.email LIKE '%_@_%.__%'
  );
GO

PRINT 'TRANSFORM + LOAD tamamlandi.';
SELECT COUNT(*) AS temiz_kayit FROM dbo.clean_customers;
SELECT COUNT(*) AS hata_kaydi  FROM dbo.etl_error_log;
GO
