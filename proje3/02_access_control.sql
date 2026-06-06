/* ============================================================
   02 - ERiSiM YONETiMi (Authentication & Authorization)
   ------------------------------------------------------------
   - SQL Server Authentication ile login olusturma
   - Windows Authentication aciklamasi
   - Rol bazli yetkilendirme (GRANT / DENY)
   - Kolon bazli yetki (maas/TC gizleme)
   ============================================================ */

USE Guvenlik_Proje3;
GO

/* --- 2.1 Temizlik (tekrar calistirilabilirlik) -------------- */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name='ik_kullanici')   DROP USER ik_kullanici;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name='rapor_kullanici') DROP USER rapor_kullanici;
GO
USE master;
GO
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name='ik_login')    DROP LOGIN ik_login;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name='rapor_login')  DROP LOGIN rapor_login;
GO

/* --- 2.2 SQL Server Authentication ile login'ler ------------
   Login = sunucuya giris kimligi. Sifre ile dogrulanir.        */
CREATE LOGIN ik_login    WITH PASSWORD = 'IK!Guclu2024';
CREATE LOGIN rapor_login WITH PASSWORD = 'Rapor!Guclu2024';
GO

/* --- 2.3 Windows Authentication (BiLGi) ---------------------
   SQL Auth yerine Windows hesabi ile de giris yapilabilir:
     CREATE LOGIN [DOMAIN\kullanici] FROM WINDOWS;
   Avantaji: ayri sifre yok, Windows oturumu kullanilir; daha
   guvenli kabul edilir. Bu projede SQL Auth gosteriyoruz cunku
   domain ortami gerektirmez.                                    */
GO

USE Guvenlik_Proje3;
GO

-- Veritabani kullanicilari (login'lere bagli)
CREATE USER ik_kullanici    FOR LOGIN ik_login;
CREATE USER rapor_kullanici FOR LOGIN rapor_login;
GO

/* --- 2.4 Rol 1: IK calisani (tum veriyi gorebilir/yazabilir)  */
ALTER ROLE db_datareader ADD MEMBER ik_kullanici;
ALTER ROLE db_datawriter ADD MEMBER ik_kullanici;
GO

/* --- 2.5 Rol 2: Rapor calisani (kisitli) --------------------
   Sadece SELECT, ama HASSAS kolonlari (Maas, TCKimlik) GOREMEZ.
   Kolon bazli DENY ile saglanir.                               */
GRANT SELECT ON dbo.Calisanlar TO rapor_kullanici;
DENY SELECT ON dbo.Calisanlar (Maas, TCKimlik) TO rapor_kullanici;
GO

/* --- 2.6 Yetkileri dogrulama -------------------------------- */
SELECT dp.name AS kullanici, p.permission_name AS yetki,
       p.state_desc AS durum, c.name AS kolon
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.columns c ON p.major_id = c.object_id AND p.minor_id = c.column_id
WHERE dp.name IN ('ik_kullanici','rapor_kullanici')
ORDER BY dp.name;
GO

/* --- 2.7 YETKi TESTi -----------------------
   rapor_kullanici tum tabloyu cekmeye calisirsa, hassas
   kolonlar yuzunden hata alir; sadece izinli kolonlari secebilir. */

-- Bu HATA verir (Maas, TCKimlik yasak):
EXECUTE AS USER = 'rapor_kullanici';
    SELECT * FROM dbo.Calisanlar;   -- permission denied bekleniyor
REVERT;
GO

-- Bu CALISIR (sadece izinli kolonlar):
EXECUTE AS USER = 'rapor_kullanici';
    SELECT CalisanID, AdSoyad, Departman, Email FROM dbo.Calisanlar;
REVERT;
GO

PRINT '>> Erisim yonetimi ve rol bazli yetkiler tanimlandi.';
GO
