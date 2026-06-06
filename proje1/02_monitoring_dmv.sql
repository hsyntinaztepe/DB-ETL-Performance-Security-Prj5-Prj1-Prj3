
USE AdventureWorks2022;
GO

/* --- 2.1 En cok kaynak tuketen sorgular ----------------------
   sys.dm_exec_query_stats: calismis sorgularin istatistikleri  */
SELECT TOP 10
    qs.execution_count                              AS calisma_sayisi,
    qs.total_worker_time / 1000                     AS toplam_cpu_ms,
    qs.total_elapsed_time / 1000                    AS toplam_sure_ms,
    (qs.total_elapsed_time / qs.execution_count)/1000 AS ort_sure_ms,
    qs.total_logical_reads                          AS toplam_okuma,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)+1) AS sorgu_metni
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_elapsed_time DESC;
GO

/* --- 2.2 Bekleme istatistikleri (wait stats) -----------------
   Sistemin nerede bekledigini gosterir (CPU, disk, kilit...).  */
SELECT TOP 10
    wait_type                          AS bekleme_tipi,
    waiting_tasks_count                AS bekleyen_gorev,
    wait_time_ms                       AS toplam_bekleme_ms,
    wait_time_ms / NULLIF(waiting_tasks_count,0) AS ort_bekleme_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%'        -- sistem beklemelerini ele
  AND wait_type NOT LIKE '%IDLE%'
  AND waiting_tasks_count > 0
ORDER BY wait_time_ms DESC;
GO

/* --- 2.3 Eksik indeks onerileri ------------------------------
   SQL Server'in "burada indeks olsa iyiydi" dedigi yerler.     */
SELECT TOP 10
    mid.statement                       AS tablo,
    migs.avg_user_impact                AS tahmini_iyilesme_yuzde,
    migs.user_seeks + migs.user_scans   AS talep_sayisi,
    mid.equality_columns                AS esitlik_kolonlari,
    mid.inequality_columns              AS aralik_kolonlari,
    mid.included_columns                AS dahil_kolonlar
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
ORDER BY migs.avg_user_impact DESC;
GO

/* --- 2.4 Tablo bazinda indeks kullanimi ----------------------
   Hangi indeks ne kadar kullaniliyor / hic kullanilmiyor mu?   */
SELECT
    OBJECT_NAME(ius.object_id)  AS tablo,
    i.name                      AS indeks_adi,
    ius.user_seeks              AS arama,
    ius.user_scans              AS tarama,
    ius.user_lookups            AS lookup,
    ius.user_updates            AS guncelleme
FROM sys.dm_db_index_usage_stats ius
JOIN sys.indexes i ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE ius.database_id = DB_ID()
  AND OBJECT_NAME(ius.object_id) = 'SalesOrdersBig'
ORDER BY ius.user_seeks + ius.user_scans DESC;
GO

PRINT '>> Izleme sorgulari calistirildi. Sonuclari incele.';
GO
