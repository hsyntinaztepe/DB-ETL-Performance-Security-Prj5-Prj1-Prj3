# DB-Security-AccessControl-Prj3

BLM4522 Ağ Tabanlı Paralel Dağıtım Sistemleri — **Proje 3: Veritabanı Güvenliği ve Erişim Kontrolü**

Bu proje, hassas veri içeren bir veritabanını dört güvenlik ekseninde korur: erişim yönetimi, veri şifreleme, SQL injection'a karşı korunma ve denetim (audit) logları.

## Kullanılan Ortam

- **Veritabanı:** Microsoft SQL Server (MSSQL Management Studio)
- **Test verisi:** Hassas bilgi içeren `Calisanlar` tablosu (TC kimlik, maaş)

## Kapsanan Konular (hocanın 4 alt başlığı)

1. **Erişim Yönetimi** — SQL Server Authentication ile login/kullanıcı; rol bazlı (`db_datareader`/`db_datawriter`) ve kolon bazlı GRANT/DENY yetkilendirme. Windows Authentication açıklaması dahildir.
2. **Veri Şifreleme** — TDE (Transparent Data Encryption) ile tüm veritabanının disk üzerinde şifrelenmesi + kolon bazlı şifreleme (TC kimlik).
3. **SQL Injection Testleri** — Açık olan string-birleştirme yönteminin gösterimi ve parametreli sorgu ile engellenmesi.
4. **Audit Logları** — SQL Server Audit ile tablo üzerindeki SELECT/INSERT/UPDATE/DELETE işlemlerinin kaydedilmesi ve incelenmesi.

## Çalıştırma Sırası

1. `sql/01_setup_database.sql` — Veritabanı ve hassas veri tablosu
2. `sql/02_access_control.sql` — Login, kullanıcı, rol ve yetkiler
3. `sql/03_encryption.sql` — TDE + kolon bazlı şifreleme
4. `sql/04_sql_injection.sql` — Injection açığı gösterimi + korunma
5. `sql/05_audit_logging.sql` — Audit loglama (önce `C:\AuditLogs` klasörünü oluştur)

## Ön Koşullar

- `05` scriptini çalıştırmadan önce `C:\AuditLogs\` klasörünü oluştur (yoksa script `EXEC xp_create_subdir 'C:\AuditLogs';` ile de oluşturabilir).
- TDE ve audit işlemleri sunucu seviyesinde yetki ister; `sysadmin` yetkili bir oturumla çalıştır.

## Dizin Yapısı

```
.
├── sql/
│   ├── 01_setup_database.sql
│   ├── 02_access_control.sql
│   ├── 03_encryption.sql
│   ├── 04_sql_injection.sql
│   └── 05_audit_logging.sql
└── docs/
    ├── Proje3_Rapor.docx
    └── Video_Script.md
```
