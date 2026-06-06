
USE AdventureWorks2022;
GO

-- Olcum ayarlarini ac
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

/* ============================================================
   ADIM 1: iNDEKS YOKKEN (kotu performans) - BASELINE
   ============================================================ */
PRINT '===== INDEKS YOKKEN =====';
GO

-- Test sorgusu A: belirli bir musterinin siparisleri
-- Indeks olmadigi icin TABLE SCAN yapacak (tum 500K satiri tarar)
SELECT OrderID, OrderDate, Quantity, UnitPrice
FROM dbo.SalesOrdersBig
WHERE CustomerID = 12345;
GO

-- Test sorgusu B: bolge + durum filtresi + tarih siralama
SELECT TOP 100 OrderID, CustomerID, OrderDate, UnitPrice
FROM dbo.SalesOrdersBig
WHERE Region = N'Ege' AND Status = N'Completed'
ORDER BY OrderDate DESC;
GO

/* >>> Bu noktada Messages sekmesindeki "logical reads" ve
       "elapsed time" degerlerini NOT AL. Bunlar baseline.    */


/* ============================================================
   ADIM 2: iNDEKSLERi OLUSTUR
   ============================================================ */
PRINT '===== INDEKSLER OLUSTURULUYOR =====';
GO

-- 2.1 Clustered index (PK rolu): tablonun fiziksel sirasi
CREATE CLUSTERED INDEX CIX_SalesOrdersBig_OrderID
    ON dbo.SalesOrdersBig (OrderID);
GO

-- 2.2 CustomerID icin nonclustered index (Test A'yi hizlandirir)
CREATE NONCLUSTERED INDEX IX_SalesOrdersBig_CustomerID
    ON dbo.SalesOrdersBig (CustomerID)
    INCLUDE (OrderDate, Quantity, UnitPrice);   -- covering index
GO

-- 2.3 Region+Status+OrderDate icin composite index (Test B'yi hizlandirir)
CREATE NONCLUSTERED INDEX IX_SalesOrdersBig_Region_Status_Date
    ON dbo.SalesOrdersBig (Region, Status, OrderDate DESC)
    INCLUDE (CustomerID, UnitPrice);
GO

PRINT '>> Indeksler olusturuldu.';
GO


/* ============================================================
   ADIM 3: iNDEKS VARKEN (iyi performans) - ayni sorgular
   ============================================================ */
PRINT '===== INDEKS VARKEN =====';
GO

-- Ayni Test A: artik INDEX SEEK yapacak (sadece ilgili satirlar)
SELECT OrderID, OrderDate, Quantity, UnitPrice
FROM dbo.SalesOrdersBig
WHERE CustomerID = 12345;
GO

-- Ayni Test B
SELECT TOP 100 OrderID, CustomerID, OrderDate, UnitPrice
FROM dbo.SalesOrdersBig
WHERE Region = N'Ege' AND Status = N'Completed'
ORDER BY OrderDate DESC;
GO

/* >>> Simdi logical reads ve elapsed time'i tekrar NOT AL.
       Baseline ile karsilastir: okuma sayisi binlerden
       birkac sayfaya dusmus olmali. Iste optimizasyon bu.    */


/* ============================================================
   ADIM 4: SORGU iYiLESTiRME ORNEGi (SARGABILITY)
   ------------------------------------------------------------
   Kotu yazilmis sorgu indeksi kullanamaz. Ayni sonucu veren
   iki sorgu, yazim sekline gore cok farkli performans verir.
   ============================================================ */
PRINT '===== SORGU YAZIMI: KOTU vs IYI =====';
GO

-- KOTU: kolona fonksiyon uygulaninca indeks kullanilamaz (scan)
SELECT COUNT(*) FROM dbo.SalesOrdersBig
WHERE YEAR(OrderDate) = 2024;
GO

-- IYI: aralik kullaninca indeks kullanilabilir (seek)
SELECT COUNT(*) FROM dbo.SalesOrdersBig
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';
GO

/* >>> Iki sorgu ayni sonucu verir ama ikincisi indeks
       kullanabildigi icin cok daha az okuma yapar.           */


/* ============================================================
   ADIM 5: GEREKSiZ iNDEKSiN KALDIRILMASI
   ------------------------------------------------------------
   Hic kullanilmayan indeks yer kaplar ve INSERT/UPDATE'i
   yavaslatir. Ornek olarak gereksiz bir indeks olusturup
   sonra kaldiriyoruz.                                         */
PRINT '===== GEREKSIZ INDEKS YONETIMI =====';
GO

CREATE NONCLUSTERED INDEX IX_Gereksiz_Quantity
    ON dbo.SalesOrdersBig (Quantity);
GO
-- (Bu indeksin kullanilmadigini 02_monitoring'deki usage
--  sorgusu ile gosterebilirsin: user_seeks = 0)
DROP INDEX IX_Gereksiz_Quantity ON dbo.SalesOrdersBig;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

PRINT '>> Indeks yonetimi ve sorgu iyilestirme tamamlandi.';
GO
