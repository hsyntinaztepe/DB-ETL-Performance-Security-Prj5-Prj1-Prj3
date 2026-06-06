# DB-Performance-Optimization-Monitoring-Prj1

BLM4522 Ağ Tabanlı Paralel Dağıtım Sistemleri — **Proje 1: Veritabanı Performans Optimizasyonu ve İzleme**

Bu proje, büyük bir veritabanı tablosu üzerinde performans analizi yapar; indeksleme, sorgu iyileştirme ve izleme teknikleriyle sorgu sürelerini ölçülebilir biçimde düşürür. Ayrıca farklı kullanıcı rolleri için erişim yönetimi tanımlar.

## Kullanılan Ortam

- **Veritabanı:** Microsoft SQL Server (MSSQL Management Studio)
- **Temel veri:** AdventureWorks2022 + içine üretilen 500.000 satırlık `SalesOrdersBig` test tablosu

## Kapsanan Konular (hocanın 4 alt başlığı)

1. **Veritabanı İzleme** — DMV'ler (`sys.dm_exec_query_stats`, `dm_os_wait_stats`, `dm_db_missing_index_details`) ile sorgu performansı ve eksik indeks tespiti.
2. **İndeks Yönetimi** — Clustered/nonclustered/covering indeksler; gereksiz indeksin tespiti ve kaldırılması.
3. **Sorgu İyileştirme** — Aynı sorgunun indeksli/indekssiz karşılaştırması; SARGability (fonksiyon kullanımının indeksi devre dışı bırakması).
4. **Veri Yöneticisi Rolleri** — `db_datareader`/`db_datawriter` rolleri, GRANT/DENY ile erişim kontrolü.

## Çalıştırma Sırası

1. `sql/01_create_big_table.sql` — 500.000 satırlık test tablosunu oluşturur (indekssiz)
2. `sql/02_monitoring_dmv.sql` — DMV'lerle izleme sorguları
3. `sql/03_index_optimization.sql` — İndeksleme + önce/sonra performans ölçümü (projenin kalbi)
4. `sql/04_roles_access.sql` — Kullanıcı rolleri ve erişim yetkileri

## Ölçüm Yöntemi

`03` scriptinde performans şu araçlarla ölçülür:
- `SET STATISTICS IO ON` → mantıksal okuma sayısı (logical reads)
- `SET STATISTICS TIME ON` → geçen süre (ms)
- **Actual Execution Plan** (Ctrl+M) → Table Scan mı Index Seek mi

İndeks eklendikten sonra aynı sorguda logical reads değeri binlerden birkaç sayfaya düşer; çalıştırma planı Table Scan'den Index Seek'e geçer.

## Dizin Yapısı

```
.
├── sql/
│   ├── 01_create_big_table.sql
│   ├── 02_monitoring_dmv.sql
│   ├── 03_index_optimization.sql
│   └── 04_roles_access.sql
└── docs/
    ├── Proje1_Rapor.docx
    └── Video_Script.md
```
