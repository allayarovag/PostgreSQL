В этот ВМ поднял в яндекс облаке. Установил Pg:

```
otus@compute-vm-2-2-20-ssd-1742454247239:~$ sudo apt update && sudo apt upgrade -y && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql
```
Проверяем:
ВМ1
```
otus@compute-vm-2-2-20-ssd-1742454247239:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```
ВМ2
```
otus@compute-vm-2-2-20-ssd-1742454195835:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```
ВМ3
```
otus@compute-vm-2-2-20-ssd-1742454271817:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
```
Далее на всех настраиваем доступность и перезапускаем сервис:
```
otus@compute-vm-2-2-20-ssd-1742454271817:~$ sudo pg_conftool 17 main set listen_address
es '*'
otus@compute-vm-2-2-20-ssd-1742454271817:~$ sudo nano /etc/postgresql/17/main/pg_hba.co
nf
otus@compute-vm-2-2-20-ssd-1742454271817:~$ sudo service postgresql restart
otus@compute-vm-2-2-20-ssd-1742454271817:~$ sudo -u postgres psql
psql (17.4 (Ubuntu 17.4-1.pgdg24.04+2))
Type "help" for help.

postgres=#
```
Проверяем wal_level на всех ВМ, меняем на logical и перезапускаем кластер
```
postgres=# show wal_level;
 wal_level
-----------
 replica
(1 row)

postgres=# alter system set wal_level = logical;
ALTER SYSTEM
postgres=#
\q
otus@compute-vm-2-2-20-ssd-1742454247239:~$ sudo service postgresql restart
otus@compute-vm-2-2-20-ssd-1742454247239:~$
postgres=# show wal_level;
 wal_level
-----------
 logical
(1 row)

postgres=#
```
На всех ВМ создаем таблицы test и test2
```
postgres=# create table test (i int);
CREATE TABLE
postgres=# create table test2 (i int);
CREATE TABLE
postgres=# \dt
         List of relations
 Schema | Name  | Type  |  Owner
--------+-------+-------+----------
 public | test  | table | postgres
 public | test2 | table | postgres
(2 rows)
```
Создаем публикации на ВМ1.test и ВМ2.test2:
```
postgres=# create publication test_PUBLICATION for table test;
CREATE PUBLICATION
```
Создаем подписки: 
	ВМ2 на ВМ1.тест, ВМ1 на ВМ.тест2
	ВМ3 на ВМ1.тест и  ВМ.тест2
ВМ1
```
postgres=# create subscription test_SUBSCRIPTION
connection 'host=158.160.90.136 port=5432 user=postgres dbname=postgres'
publication test_PUBLICATION with (copy_data = false);
NOTICE:  created replication slot "test_subscription" on publisher
CREATE SUBSCRIPTION
```
ВМ2
```
postgres=# create subscription test_SUBSCRIPTION
connection 'host=158.160.70.166 port=5432 user=postgres dbname=postgres'
publication test_PUBLICATION with (copy_data = false);
NOTICE:  created replication slot "test_subscription" on publisher
CREATE SUBSCRIPTION
```
ВМ3
```
postgres=# create subscription test_SUBSCRIPTION_vm1
connection 'host=158.160.90.136 port=5432 user=postgres dbname=postgres'
publication test_PUBLICATION with (copy_data = false);
NOTICE:  created replication slot "test_subscription_vm1" on publisher
CREATE SUBSCRIPTION
postgres=# create subscription test_SUBSCRIPTION_vm2
connection 'host=158.160.70.166 port=5432 user=postgres dbname=postgres'
publication test_PUBLICATION with (copy_data = false);
NOTICE:  created replication slot "test_subscription_vm2" on publisher
CREATE SUBSCRIPTION
postgres=# \dRs+
       Name          |  Owner   | Enabled |    Publication     | Binary | Streaming | Two-phase commit | Disable on error | Origin | Password required | Run as owner? | Failover | Synchronous commit |                          Conninfo                           | Skip LSN
-----------------------+----------+---------+--------------------+--------+-----------+------------------+------------------+--------+-------------------+---------------+----------+--------------------+-------------------------------------------------------------+----------
 test_subscription_vm1 | postgres | t       | {test_publication} | f      | off       | d                | f                | any    | t                 | f             | f        | off                | host=158.160.90.136 port=5432 user=postgres dbname=postgres | 0/0
 test_subscription_vm2 | postgres | t       | {test_publication} | f      | off       | d                | f                | any    | t                 | f             | f        | off                | host=158.160.70.166 port=5432 user=postgres dbname=postgres | 0/0
```

Проверяем что получилось:
ВМ1 добавляем данные:
```
postgres=#  INSERT INTO test(i) SELECT random() FROM generate_series(1, 10);
INSERT 0 10
postgres=# select * from test;
 i
---
 0
 1
 0
 1
 0
 1
 0
 1
 0
 0
(10 rows)
```
ВМ2 добавляем данные, заодно проверяем что получилось в реплике вм1 - работает
```
postgres=# INSERT INTO test2(i) SELECT generate_series(11, 20);
INSERT 0 10
postgres=# select * from test;
 i
---
 0
 1
 0
 1
 0
 1
 0
 1
 0
 0
(10 rows)
```
Проверяем подписку на ВМ1 с ВМ2 - работает
```
postgres=# select * from test2;
 i
----
 11
 12
 13
 14
 15
 16
 17
 18
 19
 20
(10 rows)
```
Проверяем ВМ3 - работает:
```
postgres=# select * from test;
 i
---
 0
 1
 0
 1
 0
 1
 0
 1
 0
 0
(10 rows)

postgres=# select * from test2;
 i
----
 11
 12
 13
 14
 15
 16
 17
 18
 19
 20
(10 rows)
```
Все работает.

