/* ============================================================
   BLM4522 - Proje 3: Veritabani Guvenligi ve Erisim Kontrolu
   01 - Veritabani ve Ornek Hassas Veri (MSSQL)
   ------------------------------------------------------------
   Senaryo: Bir musteri/calisan veritabani. Icinde hassas
   bilgiler var (TC, maas, kredi karti). Bu projede bu verileri
   yetki, sifreleme ve denetim ile koruyacagiz.
   ============================================================ */

-- Tekrar calistirilabilir olmasi icin DB'yi yeniden kur
USE master;
GO
IF DB_ID('Guvenlik_Proje3') IS NOT NULL
BEGIN
    ALTER DATABASE Guvenlik_Proje3 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Guvenlik_Proje3;
END
GO
CREATE DATABASE Guvenlik_Proje3;
GO

USE Guvenlik_Proje3;
GO

-- Hassas veri iceren ornek tablo
CREATE TABLE dbo.Calisanlar (
    CalisanID    INT IDENTITY(1,1) PRIMARY KEY,
    AdSoyad      NVARCHAR(100) NOT NULL,
    TCKimlik     CHAR(11)      NOT NULL,   -- hassas
    Maas         DECIMAL(10,2) NOT NULL,   -- hassas
    Departman    NVARCHAR(50),
    Email        NVARCHAR(100)
);
GO

INSERT INTO dbo.Calisanlar (AdSoyad, TCKimlik, Maas, Departman, Email) VALUES
(N'Ahmet Yilmaz',   '11111111111', 45000.00, N'Muhasebe',  N'ahmet@firma.com'),
(N'Ayse Demir',     '22222222222', 52000.00, N'Yazilim',   N'ayse@firma.com'),
(N'Mehmet Kaya',    '33333333333', 38000.00, N'Satis',     N'mehmet@firma.com'),
(N'Fatma Sahin',    '44444444444', 61000.00, N'Yonetim',   N'fatma@firma.com'),
(N'Can Ozturk',     '55555555555', 41000.00, N'Yazilim',   N'can@firma.com');
GO

SELECT * FROM dbo.Calisanlar;
GO

PRINT '>> Guvenlik_Proje3 veritabani ve Calisanlar tablosu olusturuldu.';
GO
