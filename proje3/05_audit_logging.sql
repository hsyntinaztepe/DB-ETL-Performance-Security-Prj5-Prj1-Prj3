/* ============================================================
   05 - AUDIT LOGLARI (SQL Server Audit)
   ------------------------------------------------------------
   Kim, ne zaman, hangi tabloya eristi/degistirdi? SQL Server
   Audit ile kullanici aktiviteleri kaydedilir. Guvenlik
   olaylarinin sonradan incelenmesi (forensic) icin sarttir.
   ============================================================ */

USE master;
GO

/* --- 5.1 Temizlik (tekrar calistirilabilirlik) -------------- */
IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'Guvenlik_Audit')
BEGIN
    IF EXISTS (SELECT 1 FROM sys.dm_server_audit_status WHERE audit_id =
               (SELECT audit_id FROM sys.server_audits WHERE name='Guvenlik_Audit'))
        ALTER SERVER AUDIT Guvenlik_Audit WITH (STATE = OFF);
    DROP SERVER AUDIT Guvenlik_Audit;
END
GO

/* --- 5.2 Server Audit olustur -------------------------------
   Loglarin nereye yazilacagini belirler. Burada dosyaya yaziyoruz.
   C:\AuditLogs klasoru ONCEDEN olusturulmali (yoksa hata verir). */
CREATE SERVER AUDIT Guvenlik_Audit
    TO FILE (FILEPATH = 'C:\AuditLogs\',
             MAXSIZE = 10 MB,
             MAX_ROLLOVER_FILES = 5);
GO

-- Audit'i etkinlestir
ALTER SERVER AUDIT Guvenlik_Audit WITH (STATE = ON);
GO

USE Guvenlik_Proje3;
GO

/* --- 5.3 Database Audit Specification -----------------------
   Hangi olaylar loglanacak? Burada Calisanlar tablosundaki
   SELECT, INSERT, UPDATE, DELETE islemlerini logluyoruz.        */
IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name='Calisanlar_Audit_Spec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION Calisanlar_Audit_Spec WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION Calisanlar_Audit_Spec;
END
GO

CREATE DATABASE AUDIT SPECIFICATION Calisanlar_Audit_Spec
    FOR SERVER AUDIT Guvenlik_Audit
    ADD (SELECT, INSERT, UPDATE, DELETE
         ON dbo.Calisanlar BY public)
    WITH (STATE = ON);
GO

/* --- 5.4 Test: birkac islem yap (loglanacaklar) ------------- */
SELECT * FROM dbo.Calisanlar;                         -- loglanir
UPDATE dbo.Calisanlar SET Maas = Maas + 1000 WHERE CalisanID = 1;  -- loglanir
GO

/* --- 5.5 Audit loglarini oku --------------------------------
   Kim, ne zaman, hangi islemi yapti?                           */
SELECT
    event_time          AS zaman,
    server_principal_name AS kullanici,
    action_id           AS islem_kodu,
    statement           AS calistirilan_sorgu
FROM sys.fn_get_audit_file('C:\AuditLogs\*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
GO

PRINT '>> Audit loglama etkinlestirildi ve test islemleri kaydedildi.';
GO

/* NOT: C:\AuditLogs klasorunu olusturmayi UNUTMA. SSMS ile:
   - Bilgisayarda C:\AuditLogs klasoru ac, ya da
   - Komutla:  EXEC xp_create_subdir 'C:\AuditLogs';            */
