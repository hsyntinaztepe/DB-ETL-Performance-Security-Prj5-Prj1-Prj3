
IF DB_ID('ETL_Proje5') IS NULL
    CREATE DATABASE ETL_Proje5;
GO

USE ETL_Proje5;
GO

-- Tekrar calistirilabilir olmasi icin once dusur
IF OBJECT_ID('dbo.etl_error_log', 'U') IS NOT NULL DROP TABLE dbo.etl_error_log;
IF OBJECT_ID('dbo.clean_customers', 'U') IS NOT NULL DROP TABLE dbo.clean_customers;
IF OBJECT_ID('dbo.staging_customers', 'U') IS NOT NULL DROP TABLE dbo.staging_customers;
GO

/* --- STAGING: Ham veri katmani -------------------------------
   Tum kolonlar NVARCHAR cunku CSV'deki veri kirli:
   tarihler metin, id'ler bazen sayisal degil, vs.            */
CREATE TABLE dbo.staging_customers (
    id           NVARCHAR(50),
    full_name    NVARCHAR(200),
    email        NVARCHAR(200),
    city         NVARCHAR(100),
    signup_date  NVARCHAR(50),
    phone        NVARCHAR(50)
);
GO

/* --- CLEAN: Temizlenmis hedef katman -------------------------
   Dogru veri tipleri. Sadece gecerli kayitlar buraya girer.  */
CREATE TABLE dbo.clean_customers (
    id           INT          PRIMARY KEY,
    full_name    NVARCHAR(200) NOT NULL,
    email        NVARCHAR(200) NOT NULL,
    city         NVARCHAR(100),
    signup_date  DATE,
    phone        NVARCHAR(20),
    loaded_at    DATETIME      DEFAULT GETDATE()
);
GO

/* --- ERROR LOG: Reddedilen kayitlar --------------------------
   Hangi kayit, hangi sebeple temizlenemedi -> kalite raporu.  */
CREATE TABLE dbo.etl_error_log (
    error_id     INT IDENTITY(1,1) PRIMARY KEY,
    source_id    NVARCHAR(50),
    error_type   NVARCHAR(100),
    error_detail NVARCHAR(500),
    logged_at    DATETIME DEFAULT GETDATE()
);
GO

PRINT 'Tablolar olusturuldu: staging_customers, clean_customers, etl_error_log';
GO
