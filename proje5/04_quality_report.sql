

USE ETL_Proje5;
GO

-- 4.1 Genel ozet: ham / temiz / reddedilen / basari orani
SELECT
    (SELECT COUNT(*) FROM dbo.staging_customers) AS toplam_ham_kayit,
    (SELECT COUNT(*) FROM dbo.clean_customers)   AS temiz_kayit,
    (SELECT COUNT(*) FROM dbo.staging_customers)
      - (SELECT COUNT(*) FROM dbo.clean_customers) AS reddedilen_kayit,
    CAST(100.0 * (SELECT COUNT(*) FROM dbo.clean_customers)
         / (SELECT COUNT(*) FROM dbo.staging_customers) AS DECIMAL(5,2)) AS basari_orani_yuzde;
GO

-- 4.2 Hata tipine gore dagilim
SELECT error_type AS hata_tipi,
       COUNT(*)   AS adet
FROM dbo.etl_error_log
GROUP BY error_type
ORDER BY adet DESC;
GO

-- 4.3 Temizlik sonrasi sehir dagilimi (standartlasmis)
SELECT city AS sehir, COUNT(*) AS musteri_sayisi
FROM dbo.clean_customers
GROUP BY city
ORDER BY musteri_sayisi DESC;
GO

-- 4.4 Yillara gore kayit (tarih temizliginin ise yaradiginin kaniti)
SELECT YEAR(signup_date) AS yil, COUNT(*) AS kayit
FROM dbo.clean_customers
GROUP BY YEAR(signup_date)
ORDER BY yil;
GO

-- 4.5 Ornek reddedilen kayitlar (her tipten birkac ornek)
SELECT TOP 20 source_id, error_type, error_detail
FROM dbo.etl_error_log
ORDER BY error_type, source_id;
GO

-- 4.6 Veri kalitesi: temiz tabloda artik hic problem kalmadiginin dogrulamasi
SELECT
    SUM(CASE WHEN email NOT LIKE '%_@_%.__%' THEN 1 ELSE 0 END) AS hala_bozuk_email,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END)        AS hala_null_tarih,
    SUM(CASE WHEN full_name = '' THEN 1 ELSE 0 END)             AS hala_bos_isim,
    COUNT(*) - COUNT(DISTINCT email)                            AS hala_duplicate_email
FROM dbo.clean_customers;
GO
