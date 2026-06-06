
USE AdventureWorks2022;
GO

-- Tekrar calistirilabilir olmasi icin once dusur
IF OBJECT_ID('dbo.SalesOrdersBig', 'U') IS NOT NULL
    DROP TABLE dbo.SalesOrdersBig;
GO

CREATE TABLE dbo.SalesOrdersBig (
    OrderID      INT          NOT NULL,   -- bilerek PK/indeks YOK (sonra ekleyecegiz)
    CustomerID   INT          NOT NULL,
    ProductID    INT          NOT NULL,
    OrderDate    DATETIME     NOT NULL,
    Quantity     INT          NOT NULL,
    UnitPrice    DECIMAL(10,2) NOT NULL,
    Region       NVARCHAR(50) NOT NULL,
    Status       NVARCHAR(20) NOT NULL
);
GO

/* --- 500.000 satir uret -------------------------------------
   GO 500000 yerine sayisal uretim kullaniyoruz (cok daha hizli).
   Numbers tablosu yaklasimi ile tek INSERT'te uretir.          */
;WITH N1 AS (SELECT 1 AS n UNION ALL SELECT 1),       -- 2
      N2 AS (SELECT 1 AS n FROM N1 a, N1 b),          -- 4
      N3 AS (SELECT 1 AS n FROM N2 a, N2 b),          -- 16
      N4 AS (SELECT 1 AS n FROM N3 a, N3 b),          -- 256
      N5 AS (SELECT 1 AS n FROM N4 a, N4 b),          -- 65.536
      N6 AS (SELECT 1 AS n FROM N5 a, N5 b),          -- ~4 milyar (kisitlayacagiz)
      Numbers AS (
        SELECT TOP (500000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
        FROM N6
      )
INSERT INTO dbo.SalesOrdersBig
    (OrderID, CustomerID, ProductID, OrderDate, Quantity, UnitPrice, Region, Status)
SELECT
    rn AS OrderID,
    (ABS(CHECKSUM(NEWID())) % 50000) + 1   AS CustomerID,   -- 1..50000
    (ABS(CHECKSUM(NEWID())) % 1000)  + 1   AS ProductID,    -- 1..1000
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 1825), GETDATE()) AS OrderDate, -- son 5 yil
    (ABS(CHECKSUM(NEWID())) % 10) + 1      AS Quantity,
    CAST((ABS(CHECKSUM(NEWID())) % 100000) / 100.0 AS DECIMAL(10,2)) AS UnitPrice,
	CASE ABS(CHECKSUM(NEWID())) % 5
         WHEN 0 THEN N'Marmara' WHEN 1 THEN N'Ege' WHEN 2 THEN N'Akdeniz'
         WHEN 3 THEN N'Ic Anadolu' ELSE N'Karadeniz' END AS Region,
    CASE ABS(CHECKSUM(NEWID())) % 3
         WHEN 0 THEN N'Completed' WHEN 1 THEN N'Pending' ELSE N'Cancelled' END AS Status
FROM Numbers;
GO

-- Kontrol: kac satir olustu
SELECT COUNT(*) AS toplam_satir FROM dbo.SalesOrdersBig;
SELECT TOP 10 * FROM dbo.SalesOrdersBig;
GO

PRINT '>> SalesOrdersBig tablosu 500.000 satir ile olusturuldu (indekssiz).';
GO
