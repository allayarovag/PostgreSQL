## создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в ЯО/Virtual Box/докере
поставьте на нее PostgreSQL 15 через sudo apt
проверьте что кластер запущен через sudo -u postgres pg_lsclusters
зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым

```
postgres=# create table test(c1 text);
postgres=# insert into test values('1');

postgres=# select * from test;
 c1
----
 1
(1 row)

\q
```
	проверяем запущен ли кластер
	заходим из под пользователя postgres в psql
```
sudo -u postgres pg_lsclusters
	
sudo -u postgres psql
```

сам виртуальный диск создал руками. Через управление дисками. Там же присоединил. Далее монтируем диск к WSL.
показываем существующие диски:

```
GET-CimInstance -query "SELECT * from Win32_DiskDrive"
```
Копируем его DeviceID, монтируем...Примечание: сам клиент должен быть выключен!
```
wsl --mount \\.\PHYSICALDRIVE1 --bare
```
далее работаем в WSL:
если parted не установлен - ставим 
```
sudo apt-get install parted
```
Теперь вы можете создать на виртуальном диске таблицу разделов и раздел с файловой системой ext4:
```
$ lsblk
$ sudo parted /dev/sdc print
$ sudo parted /dev/sdc mklabel msdos
$ sudo parted -a optimal /dev/sdc mkpart primary ext4 0% 100%
$ lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT /dev/sdc
$ sudo mkfs.ext4 /dev/sdd1
```
	создаем директорию
```
sudo mkdir /mnt/data
```
	даем права
```
sudo chown -R postgres:postgres /mnt/data
```
	Перемещаем
```
sudo mv /var/lib/postgresql /mnt/data
```

	пробуем запустить 
```
sudo -u postgres pg_ctlcluster 16 main start
Error: /var/lib/postgresql/16/main is not accessible or does not exist
```
	по данному пути его не существует, идем в postgresql.conf
```
sudo nano /etc/postgresql/16/main/postgresql.conf
```
меняем строку, прописываем путь:
```
data_directory = '/mnt/data/postgresql/16/main'
```
запускаем, проверяем:
```
pg_lsclusters
16  main    5432 online postgres /mnt/data/postgresql/16/main /var/log/postgresql/postgresql-16-main.log

postgres=# select * from test;
 c1
----
 1
(1 row)
```
