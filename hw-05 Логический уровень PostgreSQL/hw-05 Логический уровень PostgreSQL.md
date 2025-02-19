# Логический уровень PostgreSQL 
## зайдите в созданный кластер под пользователем postgres
```
otus_username@PF4TFW5R:~$ sudo -u postgres psql
[sudo] password for otus_username:
psql (16.6 (Ubuntu 16.6-0ubuntu0.24.04.1))
Type "help" for help.

postgres=#
```
##создайте новую базу данных testdb
```
postgres=# CREATE DATABASE testdb_hw5;
CREATE DATABASE
postgres=#
```
##зайдите в созданную базу данных под пользователем postgres
```
postgres=# \c testdb_hw5
You are now connected to database "testdb_hw5" as user "postgres".
testdb_hw5=#
```
##создайте новую схему testnm
```
testdb_hw5=# CREATE SCHEMA hw5_schema;
CREATE SCHEMA
```
##создайте новую таблицу t1 с одной колонкой c1 типа integer
```
testdb_hw5=# CREATE TABLE t1(c1 integer);
CREATE TABLE
```
##вставьте строку со значением c1=1
```
testdb_hw5=# INSERT INTO t1(c1) values(1);
INSERT 0 1
```
##создайте новую роль readonly
```
testdb_hw5=# create role readOnly;
CREATE ROLE
```
## дайте новой роли право на подключение к базе данных testdb
```
testdb_hw5=# grant connect on database testdb_hw5 to readonly;
GRANT
```
## дайте новой роли право на использование схемы testnm
```
testdb_hw5=# grant usage on schema hw5_schema to readonly;
GRANT
```
## дайте новой роли право на select для всех таблиц схемы testnm
```
testdb_hw5=# grant select on all tables in schema hw5_schema to readonly;
GRANT
```
## создайте пользователя testread с паролем test123
```
testdb_hw5=# create user testread with password 'test123';
CREATE ROLE
```
## дайте роль readonly пользователю testread
```
testdb_hw5=grant readonly to testread;
GRANT ROLE
```
## зайдите под пользователем testread в базу данных testdb
Сначала была ошибка Peer authentication failed for user "testread"
Поправил pg_hba.conf...
```
postgres=# \c testdb_hw5 testread
Password for user testread:
You are now connected to database "testdb_hw5" as user "testread".
testdb_hw5=>
```
еще вариант:
```
otus_username@PF4TFW5R:~$ sudo psql -h 127.0.0.1 -U testread -d testdb_hw5 -W
Password:
psql (16.6 (Ubuntu 16.6-0ubuntu0.24.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.
testdb_hw5=>
```
## сделайте select * from t1;
```
testdb_hw5=> select * from t1;
ERROR:  permission denied for table t1
```
##получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)
таблица была создана под пользователем postgres, работали схеме по умолчанию - public, а доступ у нас только к hw5_schema
## посмотрите на список таблиц
```
testdb_hw5=> \dt
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | t1   | table | postgres
```
## вернитесь в базу данных testdb под пользователем postgres, удалите таблицу t1
```
testdb_hw5=# drop table t1;
DROP TABLE
```
##создайте ее заново но уже с явным указанием имени схемы testnm
```
testdb_hw5=# CREATE TABLE hw5_schema.t1(c1 integer);
CREATE TABLE
testdb_hw5=# INSERT INTO hw5_schema.t1(c1) values(1);
INSERT 0 1
testdb_hw5=# select * from hw5_schema.t1;
 c1
----
  1
(1 row)
```
## зайдите под пользователем testread в базу данных testdb
```
testdb_hw5=# \c testdb_hw5 testread
Password for user testread:
You are now connected to database "testdb_hw5" as user "testread".
```
## сделайте select * from testnm.t1;
```
testdb_hw5=> select * from hw5_schema.t1;
ERROR:  permission denied for table t1
```

## получилось? есть идеи почему? если нет - смотрите шпаргалку
Подсмотрел шпаргалку:
потому что grant SELECT on all TABLEs in SCHEMA testnm TO readonly дал доступ только для существующих на тот момент времени таблиц а t1 пересоздавалась

## как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку
```
ALTER default privileges in SCHEMA hw5_schema grant SELECT on TABLES to readonly; 
\c testdb testread;
```

## сделайте select * from testnm.t1; получилось?
```
testdb_hw5=> select * from hw5_schema.t1;
ERROR:  permission denied for table t1
```
## есть идеи почему? если нет - смотрите шпаргалку
Посмотрел в шпаргалку:
*потому что ALTER default будет действовать для новых таблиц а grant SELECT on all TABLEs in SCHEMA testnm TO readonly отработал только для существующих на тот момент времени. надо сделать снова или grant SELECT или пересоздать таблицу*
Таблицу не пересоздаем(на проде вряд ли такое можно), грант grant SELECT
```
testdb_hw5=> \c testdb_hw5 postgres;
You are now connected to database "testdb_hw5" as user "postgres".
testdb_hw5=# grant select on all tables in schema hw5_schema to readonly;
GRANT
testdb_hw5=# \c testdb_hw5 testread;
Password for user testread:
You are now connected to database "testdb_hw5" as user "testread".
testdb_hw5=> select * from hw5_schema.t1
testdb_hw5-> ;
 c1
----
  1
(1 row)
```

но попробовать дропнуть и проверить работут альтер дефалт стоит!
```
testdb_hw5=# DROP TABLE hw5_schema.t1;
DROP TABLE
testdb_hw5=# create table hw5_schema.t1(c1 integer);
CREATE TABLE
testdb_hw5=# \c testdb_hw5 testread;
Password for user testread:
You are now connected to database "testdb_hw5" as user "testread".
testdb_hw5=> select * from hw5_schema.t1
testdb_hw5-> ;
 c1
----
(0 rows)
```

## теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
```
testdb_hw5=>  create table t2(c1 integer);
ERROR:  permission denied for schema public
```
следующие пункты смотрю шпаргалку:

** P.S.S. - у кого не получается создать табличку в public - в 15 версии права на CREATE TABLE по умолчанию отозваны у схемы PUBLIC, только USAGE

у меня версия 16...

## а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
```
testdb_hw5=> show search_path;
   search_path
-----------------
 "$user", public
(1 row)
```
## есть идеи как убрать эти права? если нет - смотрите шпаргалку
*
это все потому что search_path указывает в первую очередь на схему public. 
А схема public создается в каждой базе данных по умолчанию. 
И grant на все действия в этой схеме дается роли public. 
А роль public добавляется всем новым пользователям. 
Соответсвенно каждый пользователь может по умолчанию создавать объекты в схеме public любой базы данных, 
ес-но если у него есть право на подключение к этой базе данных. 
Чтобы раз и навсегда забыть про роль public - а в продакшн базе данных про нее лучше забыть - выполните следующие действия 
\c testdb postgres; 
REVOKE CREATE on SCHEMA public FROM public; 
REVOKE ALL on DATABASE testdb FROM public; 
\c testdb testread; 
*
## теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
расскажите что получилось и почему


t3 создать не получится, пункты выше. Для теста создал под пользователем postgres таблицу т2 в схеме public, т.к. в предыдущем не создалась. под пользователем  testread попытался вставку сделать, ERROR:  relation "t2" does not exist.

Справедливости ради, почитал. Если б создание удалось и отобрать права, то вставка все равно сработает...