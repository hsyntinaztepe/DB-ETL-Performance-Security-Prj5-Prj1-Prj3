/* ============================================================
   03 - VERi SiFRELEME (Encryption)
   ------------------------------------------------------------
   iki seviye:
   A) TDE (Transparent Data Encryption): tum veritabani dosyasini
      diskte sifreler. Calinan .mdf dosyasi okunamaz.
   B) Kolon bazli sifreleme: tek bir hassas kolonu (TCKimlik)
      veritabani icinde sifreler.
   ============================================================ */

/* ============================================================
   A) TDE - TRANSPARENT DATA ENCRYPTION
   ============================================================ */
USE master;
GO

-- A.1 Master key (sunucu seviyesi, bir kez olusturulur)
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKey!Cok2024Guclu';
GO

-- A.2 Sertifika (TDE anahtarini korur)
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'TDE_Sertifika')
    CREATE CERTIFICATE TDE_Sertifika
        WITH SUBJECT = 'TDE icin sertifika';
GO

USE Guvenlik_Proje3;
GO

-- A.3 Veritabani sifreleme anahtari (DEK)
IF NOT EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('Guvenlik_Proje3'))
    CREATE DATABASE ENCRYPTION KEY
        WITH ALGORITHM = AES_256
        ENCRYPTION BY SERVER CERTIFICATE TDE_Sertifika;
GO

-- A.4 TDE'yi ac
ALTER DATABASE Guvenlik_Proje3 SET ENCRYPTION ON;
GO

-- A.5 Sifreleme durumunu kontrol et (3 = sifrelenmis)
SELECT DB_NAME(database_id) AS veritabani,
       encryption_state AS durum_kodu,
       CASE encryption_state
            WHEN 0 THEN 'Sifreleme yok'
            WHEN 1 THEN 'Sifrelenmemis'
            WHEN 2 THEN 'Sifreleniyor'
            WHEN 3 THEN 'Sifrelenmis'
            WHEN 4 THEN 'Anahtar degisiyor'
            ELSE 'Diger' END AS durum,
       key_algorithm AS algoritma
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID('Guvenlik_Proje3');
GO

PRINT '>> TDE etkinlestirildi (tum veritabani diskte sifreli).';
GO


/* ============================================================
   B) KOLON BAZLI SiFRELEME (TCKimlik kolonu)
   ============================================================ */
USE Guvenlik_Proje3;
GO

-- B.1 Bu DB icin master key
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'DBMasterKey!2024Guclu';
GO

-- B.2 Sertifika ve simetrik anahtar
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'KolonSertifika')
    CREATE CERTIFICATE KolonSertifika WITH SUBJECT = 'Kolon sifreleme';
GO
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'KolonAnahtar')
    CREATE SYMMETRIC KEY KolonAnahtar
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE KolonSertifika;
GO

-- B.3 Sifreli veriyi tutacak yeni kolon
IF COL_LENGTH('dbo.Calisanlar','TCKimlik_Sifreli') IS NULL
    ALTER TABLE dbo.Calisanlar ADD TCKimlik_Sifreli VARBINARY(256);
GO

-- B.4 Mevcut TC'leri sifrele
OPEN SYMMETRIC KEY KolonAnahtar DECRYPTION BY CERTIFICATE KolonSertifika;
    UPDATE dbo.Calisanlar
    SET TCKimlik_Sifreli = ENCRYPTBYKEY(KEY_GUID('KolonAnahtar'), TCKimlik);
CLOSE SYMMETRIC KEY KolonAnahtar;
GO

-- B.5 Sifreli hali (okunamaz) vs cozulmus hali (anahtar ile)
PRINT '--- Sifreli kolon ham hali (okunamaz) ---';
SELECT CalisanID, AdSoyad, TCKimlik_Sifreli FROM dbo.Calisanlar;
GO

PRINT '--- Anahtar ile cozulmus hali ---';
OPEN SYMMETRIC KEY KolonAnahtar DECRYPTION BY CERTIFICATE KolonSertifika;
    SELECT CalisanID, AdSoyad,
           CONVERT(CHAR(11), DECRYPTBYKEY(TCKimlik_Sifreli)) AS TC_Cozulmus
    FROM dbo.Calisanlar;
CLOSE SYMMETRIC KEY KolonAnahtar;
GO

PRINT '>> Kolon bazli sifreleme tamamlandi.';
GO
