show transaction isolation level;
--read committed

/*create table 
persons
	(id serial, 
	first_name text,
	second_name text); 
insert into persons(first_name, second_name) values('ivan', 'ivanov');
insert into persons(first_name, second_name) values('petr', 'petrov'); 
commit;
*/

--Скрипт 1

begin transaction;
	insert into persons(first_name, second_name) values('sergey', 'sergeev');
	select * from persons;
--Добавил запись, до коммита, во втором запросе не видна запись.
commit;
--После коммита, во втором запросе запись появилась.




BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE read;
insert into persons(first_name, second_name) values('sveta', 'svetova');
select * from persons;
commit;
select * from persons;
/*
До коммита запись добавили, во второй не видно. 
После коммита первой транзакции все равно не видно.
	видны только те данные, которые были зафиксированы до начала транзакции,
	но не видны незафиксированные данные и изменения, произведённые другими
	транзакциями в процессе выполнения данной транзакции.
После коммита второй транзакции запись появилась.
*/

--Скрипт 2
begin transaction;
 select * from persons;
/*Запись видим, т.к. уровень изоляции транзакции read committed
который позволяет видеть изменения, внесённые успешно завершёнными транзакциями, 
в оставшихся параллельно открытых транзакциях.
*/
commit;



BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE read;
select * from persons;
/*
 видны только те данные, которые были зафиксированы до начала транзакции,
 но не видны незафиксированные данные и изменения, произведённые другими
 транзакциями в процессе выполнения данной транзакции.
*/
commit;
--rollback



