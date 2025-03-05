## Создать БД для тестов: выполнить pgbench -i postgres
```
postgres@PF4TFW5R:/home/allayarovag$ pgbench -i postgres
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.03 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.13 s (drop tables 0.01 s, create tables 0.01 s, client-side generate 0.05 s, vacuum 0.03 s, primary keys 0.03 s).
```
## Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres

```
postgres@PF4TFW5R:/home/allayarovag$  pgbench -c8 -P 6 -T 60 -U postgres postgres
pgbench (16.6 (Ubuntu 16.6-0ubuntu0.24.04.1))
starting vacuum...end.
progress: 6.0 s, 323.2 tps, lat 24.536 ms stddev 18.595, 0 failed
progress: 12.0 s, 331.3 tps, lat 24.133 ms stddev 19.110, 0 failed
progress: 18.0 s, 331.8 tps, lat 24.088 ms stddev 18.512, 0 failed
progress: 24.0 s, 334.7 tps, lat 23.895 ms stddev 17.765, 0 failed
progress: 30.0 s, 335.2 tps, lat 23.848 ms stddev 16.941, 0 failed
progress: 36.0 s, 931.3 tps, lat 8.593 ms stddev 10.050, 0 failed
progress: 42.0 s, 1305.3 tps, lat 6.124 ms stddev 4.769, 0 failed
progress: 48.0 s, 1298.3 tps, lat 6.151 ms stddev 4.557, 0 failed
progress: 54.0 s, 1280.0 tps, lat 6.242 ms stddev 4.672, 0 failed
progress: 60.0 s, 1239.0 tps, lat 6.451 ms stddev 4.826, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 46269
number of failed transactions: 0 (0.000%)
latency average = 10.359 ms
latency stddev = 12.256 ms
initial connection time = 26.221 ms
tps = 771.401901 (without initial connection time)
```
## Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла. Протестировать заново

В задаче указано использование рекомендуемых значений по ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB
Аналогичная задача была в занятии *Настройка PostgreSQL* Использовал рекомендуемые параметры для существующей ВМ 16гб озу

Значения параметров:

max_connections = 40
***
Максимальное количество соединений. Для изменения данного параметра придётся перезапускать сервер. Если планируется использование PostgreSQL как DWH, то большое количество соединений не нужно. Данный параметр тесно связан с **work_mem**.
***
shared_buffers = 1GB
***
Используется для кэширования данных. По умолчанию низкое значение (для поддержки как можно большего кол-ва ОС). Начать стоит с его изменения. Согласно документации, рекомендуемое значение для данного параметра - 25% от общей оперативной памяти на сервере. PostgreSQL использует 2 кэша - свой (изменяется **shared_buffers**) и ОС. Редко значение больше, чем 40% окажет влияние на производительность.
***
effective_cache_size = 3GB
***
Служит подсказкой для планировщика, сколько ОП у него в запасе. Можно определить как **shared_buffers** + ОП системы - ОП используемое самой ОС и другими приложениями. За счёт данного параметра планировщик может чаще использовать индексы, строить hash таблицы. Наиболее часто используемое значение 75% ОП от общей на сервере. 
***
maintenance_work_mem = 512MB
***
Определяет максимальное количество ОП для операций типа VACUUM, CREATE INDEX, CREATE FOREIGN KEY. Увеличение этого параметра позволит быстрее выполнять эти операции. Не связано с **work_mem** поэтому можно ставить в разы больше, чем **work_mem**
***
checkpoint_completion_target = 0.9

wal_buffers = 16MB
***
Объём разделяемой памяти, который будет использоваться для буферизации данных WAL, ещё не записанных на диск. Если у вас большое количество одновременных подключений, увеличение параметра улучшит производительность. По умолчанию -1, определяется автоматически, как 1/32 от **shared_buffers**, но не больше, чем 16 МБ (в ручную можно задавать большие значения). Обычно ставят 16 МБ
***
default_statistics_target = 500
***
параметр в PostgreSQL, который устанавливает значение ориентира статистики по умолчанию для столбцов, для которых командой ALTER TABLE SET STATISTICS не заданы отдельные ограничения. 
По умолчанию значение этого параметра — 100. Чем больше установленное значение, тем больше времени требуется для выполнения ANALYZE, но тем выше может быть качество оценок планировщика
***
random_page_cost = 4 
***
задаёт приблизительную стоимость чтения одной произвольной страницы с диска. Значение по умолчанию равно 4.0. Этот параметр используется планировщиком запросов и влияет на то, как часто система будет предпочитать индексный доступ вместо последовательного сканирования таблицы.
***
effective_io_concurrency = 2 
***
допустимое число параллельных операций ввода/вывода
***
work_mem = 6553kB
***
Используется для сортировок, построения hash таблиц. Это позволяет выполнять данные операции в памяти, что гораздо быстрее обращения к диску. В рамках одного запроса данный параметр может быть использован множество раз. Если ваш запрос содержит 5 операций сортировки, то память, которая потребуется для его выполнения уже как минимум **work_mem** * 5. Т.к. скорее-всего на сервере вы не одни и сессий много, то каждая из них может использовать этот параметр по нескольку раз, поэтому не рекомендуется делать его слишком большим. Можно выставить небольшое значение для глобального параметра в конфиге и потом, в случае сложных запросов, менять этот параметр локально (для текущей сессии)
***
min_wal_size = 4GB
***
параметр в PostgreSQL, который задаёт минимальный размер журнального сегмента, до которого должен «опуститься» WAL перед переиспользованием.
Значение по умолчанию — 80 МБ. Пока WAL занимает на диске меньше этого объёма, старые файлы WAL в контрольных точках всегда перерабатываются, а не удаляются. Это позволяет зарезервировать достаточно места для WAL, чтобы справиться с резкими скачками использования WAL, например, при выполнении больших пакетных заданий.
***
max_wal_size = 16GB
***
Максимальный размер, до которого может вырастать WAL между автоматическими контрольными точками в WAL. Значение по умолчанию — 1 ГБ. Увеличение этого параметра может привести к увеличению времени, которое потребуется для восстановления после сбоя, но позволяет реже выполнять операцию сбрасывания на диск. Так же сбрасывание может выполниться и при достижении нужного времени, определённого параметром 
***

Меняю параметры, перезапускаю:
```
ALTER SYSTEM SET shared_buffers TO '4GB';
ALTER SYSTEM SET effective_cache_size TO '12GB';
ALTER SYSTEM SET maintenance_work_mem TO '819MB';
ALTER SYSTEM SET min_wal_size TO '2GB';
ALTER SYSTEM SET max_wal_size TO '16GB';
ALTER SYSTEM SET checkpoint_completion_target TO '0.9';
ALTER SYSTEM SET wal_buffers TO '16MB';
ALTER SYSTEM SET listen_addresses TO '*';
ALTER SYSTEM SET max_connections TO '100';
ALTER SYSTEM SET random_page_cost TO '1.1';
ALTER SYSTEM SET effective_io_concurrency TO '200';
ALTER SYSTEM SET max_worker_processes TO '8';
ALTER SYSTEM SET max_parallel_workers_per_gather TO '2';
ALTER SYSTEM SET max_parallel_workers TO '2';
```
Бенч:
```
postgres@PF4TFW5R:/home/allayarovag$  pgbench -c8 -P 6 -T 60 -U postgres postgres
pgbench (16.6 (Ubuntu 16.6-0ubuntu0.24.04.1))
starting vacuum...end.
progress: 6.0 s, 400.2 tps, lat 19.901 ms stddev 15.576, 0 failed
progress: 12.0 s, 438.5 tps, lat 18.214 ms stddev 14.437, 0 failed
progress: 18.0 s, 1452.3 tps, lat 5.514 ms stddev 4.766, 0 failed
progress: 24.0 s, 1532.3 tps, lat 5.212 ms stddev 4.022, 0 failed
progress: 30.0 s, 1506.7 tps, lat 5.301 ms stddev 4.041, 0 failed
progress: 36.0 s, 1431.0 tps, lat 5.578 ms stddev 4.430, 0 failed
progress: 42.0 s, 1207.5 tps, lat 6.622 ms stddev 5.388, 0 failed
progress: 48.0 s, 467.0 tps, lat 17.070 ms stddev 18.146, 0 failed
progress: 54.0 s, 340.2 tps, lat 23.447 ms stddev 19.678, 0 failed
progress: 60.0 s, 303.3 tps, lat 26.388 ms stddev 20.743, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 54482
number of failed transactions: 0 (0.000%)
latency average = 8.801 ms
latency stddev = 11.073 ms
initial connection time = 10.370 ms
tps = 907.749193 (without initial connection time)
```
tps увеличился с 771.401901 до 907.749193. С дефолтными параметрами обработано 46269 транзакций против 54482 рекомендуемых.
при одновременных 8 соединениях. Благодаря установке "рекомендуемых" настроек. Основной прирост получил благодаря shared_buffers,wal_buffers,effective_cache_size

## Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
```
postgres=# create table hw8 (c0 text);
```
Заполняем
```
postgres=# INSERT INTO hw8 (c0) SELECT 'name' FROM generate_series(1,1000000);
INSERT 0 1000000
```
## Посмотреть размер файла с таблицей

```
postgres=# SELECT pg_size_pretty(pg_TABLE_size('hw8'));
-[ RECORD 1 ]--+------
pg_size_pretty | 35 MB
```
## 5 раз обновить все строчки и добавить к каждой строчке любой символ
```
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000```
## Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум

```
postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs  WHERE relname = 'hw8';
-[ RECORD 1 ]---+------------------------------
relname         | hw8
n_live_tup      | 1000000
n_dead_tup      | 4999851
ratio%          | 499
last_autovacuum | 2025-03-05 12:50:54.642345+05

postgres=# SELECT pg_size_pretty(pg_TABLE_size('hw8'));
-[ RECORD 1 ]--+-------
pg_size_pretty | 223 MB
```
Ждем, автовакуум:
```
postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs  WHERE relname = 'hw8';
-[ RECORD 1 ]---+------------------------------
relname         | hw8
n_live_tup      | 1000000
n_dead_tup      | 0
ratio%          | 0
last_autovacuum | 2025-03-05 12:51:55.520803+05

```
Еще раз обновляем данные
```
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000

postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs  WHERE relname = 'hw8';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 hw8     |     996883 |          0 |      0 | 2025-03-05 13:16:11.915542+05
(1 row)

postgres=# SELECT pg_size_pretty(pg_TABLE_size('hw8'));
 pg_size_pretty
----------------
 253 MB
(1 row)
Размер таблицы почти не изменился. Т.к. автовакуум = вакуум, т.е. место уже было зарезервировано.

## Отключить Автовакуум на конкретной таблице
```
postgres=# ALTER TABLE hw8 SET (autovacuum_enabled = off);
ALTER TABLE
```
## 10 раз обновить все строчки и добавить к каждой строчке любой символ
```
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
postgres=# update hw8 set c0 = CONCAT(c0, 'a');
UPDATE 1000000
```
## Посмотреть размер файла с таблицей
```
postgres=# SELECT pg_size_pretty(pg_TABLE_size('hw8'));
 pg_size_pretty
----------------
 540 MB
(1 row)
```
Размер увеличился в 2 раза. Т.к. данные под 5 апдейтов уже были зарезервированы + мы добавили сверху 5. 

