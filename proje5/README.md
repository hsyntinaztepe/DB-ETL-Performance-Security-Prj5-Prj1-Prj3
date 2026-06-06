# DB-DataCleaning-ETL-Prj5

BLM4522 Ağ Tabanlı Paralel Dağıtım Sistemleri — **Proje 5: Veri Temizleme ve ETL Süreçleri Tasarımı**

Bu proje, kirli bir müşteri veri setini **Extract → Transform → Load (ETL)** süreçlerinden geçirerek temizler, standartlaştırır ve bir hedef veritabanına yükler. Reddedilen kayıtlar sebepleriyle birlikte loglanır ve sonunda bir veri kalitesi raporu üretilir.

## Kullanılan Ortam

- **Veritabanı:** Microsoft SQL Server (MSSQL Management Studio)
- **Veri seti:** 1050 satırlık müşteri verisi (`data/customers_raw.csv`), kasıtlı bozukluklar içerir.

## Mimari (3 Katmanlı ETL)

```
CSV (ham)  ──Extract──►  staging_customers  ──Transform/Load──►  clean_customers
                                  │
                                  └──reddedilen──►  etl_error_log
```

| Katman | Tablo | Açıklama |
|--------|-------|----------|
| Staging | `staging_customers` | Ham veri, tüm kolonlar NVARCHAR |
| Clean | `clean_customers` | Temizlenmiş veri, doğru tipler |
| Error | `etl_error_log` | Reddedilen kayıtlar + sebep |

## Veri Setindeki Kasıtlı Bozukluklar

- Geçersiz/eksik e-posta adresleri
- Tutarsız tarih formatları (gg/aa/yyyy, ABD formatı, "bilinmiyor", boş)
- Boş/null isimler
- Baş-son boşluklu metinler
- Tutarsız şehir yazımı (istanbul / ISTANBUL / " Istanbul ")
- Sayısal olmayan id değerleri
- Tekrar eden kayıtlar (aynı e-posta)
- Karışık telefon formatları

## Çalıştırma Sırası

1. `sql/01_create_tables.sql` — Veritabanı ve tabloları oluşturur
2. `sql/02_extract.sql` — CSV'yi staging'e yükler (BULK INSERT)
3. `sql/03_transform_load.sql` — Temizler, standartlaştırır, hedefe yükler, hataları loglar
4. `sql/04_quality_report.sql` — Veri kalitesi raporlarını üretir

> Not: `02_extract.sql` içindeki dosya yolunu (`C:\etl\customers_raw.csv`) kendi ortamına göre değiştir.

## Sonuçlar (örnek çalıştırma)

| Metrik | Değer |
|--------|-------|
| Toplam ham kayıt | 1050 |
| Temiz tabloya yüklenen | 734 |
| Reddedilen | 316 |
| Başarı oranı | %69.90 |

## Dizin Yapısı

```
.
├── data/
│   ├── customers_raw.csv         # ham (kirli) veri
│   └── generate_dirty_data.py    # veriyi üreten script
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_extract.sql
│   ├── 03_transform_load.sql
│   └── 04_quality_report.sql
└── docs/
    └── Proje5_Rapor.docx
```
