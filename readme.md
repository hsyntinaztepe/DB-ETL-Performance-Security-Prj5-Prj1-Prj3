# BLM4522 – Ağ Tabanlı Paralel Dağıtım Sistemleri

Bu repo, BLM4522 dersi kapsamında hazırlanan proje çalışmalarını içermektedir.  
Projeler **AdventureWorks2022**, **ETL_Proje5** ve **Guvenlik_Proje3** veritabanları kullanılarak gerçekleştirilmiştir.

VİZE VİDEO LİNKİ (Proje 2 & 7): https://youtu.be/saMLoJvcOxU  
FİNAL VİDEO LİNKİ (Proje 5, 1 & 3): https://youtu.be/6GHcj0e-f3w

https://learn.microsoft.com/tr-tr/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms

---

## 📁 Proje Dizinleri

### [📂 proje2](./proje2)
**Veritabanı Yedekleme ve Felaketten Kurtarma Planı**

AdventureWorks2022 veritabanı üzerinde kapsamlı bir yedekleme stratejisi oluşturulmuş ve felaketten kurtarma senaryoları uygulanmıştır.

- Full, Differential ve Transaction Log yedeklemeleri
- Felaket simülasyonu (DROP DATABASE) ve geri yükleme
- Point-in-Time Restore ile belirli bir zamana geri dönme
- RESTORE VERIFYONLY ile yedek doğrulama
- msdb üzerinden yedekleme geçmişi raporlama

---

### [📂 proje7](./proje7)
**Veritabanı Yedekleme ve Otomasyon Çalışması**

Yedekleme işlemleri T-SQL ile otomatikleştirilmiş, SQL Server Agent ile zamanlanmış ve sonuçlar raporlanmıştır.

- `BackupLog` tablosu ile yedekleme geçmişi takibi
- `sp_AutoBackup` stored procedure (Full / Differential)
- SQL Server Agent Job ile günlük 02:00 otomatik yedekleme
- Hata senaryosu testi ve log kaydı
- Günlük özet ve msdb raporlama sorguları

---

### [📂 proje5](./proje5)
**Veri Temizleme ve ETL Süreçleri Tasarımı**

1050 satırlık kirli müşteri veri seti, üç katmanlı bir ETL (Extract–Transform–Load) süreciyle temizlenmiş, standartlaştırılmış ve hedef tabloya yüklenmiştir.

- Üç katmanlı mimari: `staging_customers` → `clean_customers` / `etl_error_log`
- BULK INSERT ile ham verinin staging'e alınması (Extract)
- Boşluk temizliği, şehir/e-posta standartlaştırma, TRY_CONVERT ile tarih doğrulama (Transform)
- Geçerli kayıtların yüklenmesi, reddedilenlerin sebebiyle loglanması (Load)
- Veri kalitesi raporu (1050 → 759 temiz kayıt, %72.29 başarı)

---

### [📂 proje1](./proje1)
**Veritabanı Performans Optimizasyonu ve İzleme**

AdventureWorks2022 içinde üretilen 500.000 satırlık tablo üzerinde performans analizi yapılmış; indeksleme ve sorgu iyileştirmeyle sorgu süreleri ölçülebilir biçimde düşürülmüştür.

- 500.000 satırlık `SalesOrdersBig` test tablosu
- DMV'lerle izleme (en pahalı sorgular, eksik indeks önerileri)
- Clustered / covering / composite indeksler
- Önce/sonra ölçüm: Table Scan → Index Seek, logical reads karşılaştırması
- SARGability (sorgu yazımının performansa etkisi)
- Rol bazlı erişim yönetimi (db_datareader / db_datawriter)

---

### [📂 proje3](./proje3)
**Veritabanı Güvenliği ve Erişim Kontrolü**

Hassas veri içeren bir veritabanı dört güvenlik ekseninde korunmuştur: erişim, şifreleme, injection koruması ve denetim.

- Rol ve kolon bazlı yetkilendirme (GRANT / DENY, hassas kolon gizleme)
- TDE (Transparent Data Encryption) ile tüm veritabanının şifrelenmesi
- Kolon bazlı şifreleme (ENCRYPTBYKEY ile TC kimlik)
- SQL injection açığının gösterimi ve parametreli sorgu ile engellenmesi
- SQL Server Audit ile kullanıcı aktivitelerinin loglanması

---

## 🛠️ Kullanılan Teknolojiler

| Araç | Versiyon |
|------|----------|
| SQL Server | 2022 Developer Edition |
| SSMS | 20 |
| Veritabanları | AdventureWorks2022, ETL_Proje5, Guvenlik_Proje3 |

---

## 📄 Rapor

Projelere ait detaylı final raporu `BLM4522_21290360_HuseyinTinaztepe_FinalRaporu.pdf` dosyasında bulunmaktadır.
