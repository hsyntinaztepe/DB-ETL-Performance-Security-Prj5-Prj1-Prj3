
USE AdventureWorks2022;
GO

/* --- 4.1 Login ve kullanici olusturma ------------------------ */
-- Tekrar calistirilabilirlik icin once temizle
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rapor_kullanici')
    DROP USER rapor_kullanici;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'veri_yonetici')
    DROP USER veri_yonetici;
GO
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'rapor_login')
    DROP LOGIN rapor_login;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'yonetici_login')
    DROP LOGIN yonetici_login;
GO

-- SQL Server Authentication ile login'ler
CREATE LOGIN rapor_login    WITH PASSWORD = 'Rapor!2024Pass';
CREATE LOGIN yonetici_login WITH PASSWORD = 'Yonetici!2024Pass';
GO

-- Veritabani kullanicilari
CREATE USER rapor_kullanici FOR LOGIN rapor_login;
CREATE USER veri_yonetici   FOR LOGIN yonetici_login;
GO

/* --- 4.2 Rol 1: Sadece okuma (rapor calisani) ----------------
   Sadece SELECT yapabilir, veri degistiremez.                  */
ALTER ROLE db_datareader ADD MEMBER rapor_kullanici;
GO
-- Ek olarak sadece belirli tabloya GRANT da yapilabilir:
GRANT SELECT ON dbo.SalesOrdersBig TO rapor_kullanici;
-- Acikca veri degistirmeyi YASAKLA
DENY INSERT, UPDATE, DELETE ON dbo.SalesOrdersBig TO rapor_kullanici;
GO

/* --- 4.3 Rol 2: Veri yoneticisi (okuma + yazma + indeks) ----- */
ALTER ROLE db_datareader ADD MEMBER veri_yonetici;
ALTER ROLE db_datawriter ADD MEMBER veri_yonetici;
GO
-- Indeks olusturma/degistirme yetkisi (performans yonetimi icin)
GRANT ALTER ON dbo.SalesOrdersBig TO veri_yonetici;
GO

/* --- 4.4 Yetkileri dogrulama ---------------------------------
   Hangi kullanicinin hangi yetkisi var?                        */
SELECT
    dp.name              AS kullanici,
    dp.type_desc         AS tip,
    p.permission_name    AS yetki,
    p.state_desc         AS durum,
    OBJECT_NAME(p.major_id) AS nesne
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE dp.name IN ('rapor_kullanici', 'veri_yonetici')
ORDER BY dp.name, p.permission_name;
GO

-- Rol uyeliklerini gosterme
SELECT
    r.name AS rol,
    m.name AS uye
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE m.name IN ('rapor_kullanici', 'veri_yonetici')
ORDER BY r.name;
GO

/* --- 4.5 Yetki testi (EXECUTE AS ile) ------------------------
   rapor_kullanici olarak UPDATE denersek reddedilmeli.         */
-- EXECUTE AS USER = 'rapor_kullanici';
--   UPDATE dbo.SalesOrdersBig SET Quantity = 1 WHERE OrderID = 1;  -- HATA vermeli
-- REVERT;
-- (Videoda bunu acip calistir; "permission denied" hatasini goster.)
GO

PRINT '>> Roller ve erisim yetkileri tanimlandi.';
GO
