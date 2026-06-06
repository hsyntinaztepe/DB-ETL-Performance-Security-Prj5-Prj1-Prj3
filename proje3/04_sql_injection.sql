/* ============================================================
   04 - SQL INJECTION TESTLERi ve KORUNMA
   ------------------------------------------------------------
   SQL injection: kullanici girdisinin sorguya dogrudan
   yapistirilmasiyla olusan en yaygin guvenlik acigi.
   Bu script ACIGI gosterir ve KORUNMA yontemini uygular.
   (Egitim amaclidir; kendi test DB'nde calistir.)
   ============================================================ */

USE Guvenlik_Proje3;
GO

/* ============================================================
   A) ACIK OLAN (KOTU) YONTEM: Dinamik SQL + string birlestirme
   ------------------------------------------------------------
   Bir giris ekrani dusunelim: kullanici email girip kendi
   bilgisini sorguluyor. Girdi dogrudan sorguya ekleniyor.
   ============================================================ */

-- Normal kullanim (durust girdi)
DECLARE @email NVARCHAR(100) = 'ahmet@firma.com';
DECLARE @sql NVARCHAR(MAX) =
    N'SELECT CalisanID, AdSoyad, Departman FROM dbo.Calisanlar WHERE Email = ''' + @email + '''';
PRINT '--- Normal girdi ile uretilen sorgu: ---';
PRINT @sql;
EXEC sp_executesql @sql;
GO

-- KOTU NIYETLI girdi (injection saldirisi)
-- Saldirgan email yerine: ' OR '1'='1  yaziyor.
-- Boylece WHERE kosulu hep DOGRU olur -> TUM kayitlar dokulur!
DECLARE @email NVARCHAR(100) = ''' OR ''1''=''1';
DECLARE @sql NVARCHAR(MAX) =
    N'SELECT CalisanID, AdSoyad, Departman FROM dbo.Calisanlar WHERE Email = ''' + @email + '''';
PRINT '--- Injection girdisi ile uretilen sorgu: ---';
PRINT @sql;   -- Bakin WHERE Email = '' OR '1'='1' oldu
EXEC sp_executesql @sql;   -- TUM tablo dondu = ACIK!
GO


/* ============================================================
   B) GUVENLi (iYi) YONTEM: Parametreli sorgu
   ------------------------------------------------------------
   Girdi sorgu metnine yapistirilmaz; PARAMETRE olarak gecer.
   Boylece girdi "veri" olarak islenir, "kod" olarak degil.
   Ayni saldiri girdisi artik ise yaramaz.
   ============================================================ */

-- Ayni kotu niyetli girdi, ama parametreli:
DECLARE @email NVARCHAR(100) = ''' OR ''1''=''1';
EXEC sp_executesql
    N'SELECT CalisanID, AdSoyad, Departman FROM dbo.Calisanlar WHERE Email = @p_email',
    N'@p_email NVARCHAR(100)',
    @p_email = @email;
-- Sonuc: HIC kayit donmez, cunku boyle bir email yok.
-- Saldiri etkisiz hale geldi.
GO

PRINT '>> SQL injection: acik gosterildi ve parametreli sorgu ile engellendi.';
GO

/* --- KORUNMA OZETi (rapora yaz) -----------------------------
   1) String birlestirme ile sorgu KURMA.
   2) Her zaman parametreli sorgu (sp_executesql / stored proc)
      ya da ORM kullan.
   3) Girdi dogrulama (input validation) yap.
   4) En az yetki ilkesi: uygulama kullanicisi sadece gereken
      yetkiye sahip olsun (bkz. 02_access_control).
   ------------------------------------------------------------ */
