/* Написать и протестировать скрипт (sql запросы) на локальной базе:
Создать таблицу results c атрибутами id (INT), response (TEXT), где
    • id – номер запроса из списка ниже
    • response – результат запроса

Если запись содержит несколько атрибутов, то их значения должны объединяться в одно, через конкатенацию с разделителем “|” 
Если результат возвращает несколько записей, то все записи записываются в результирующую таблицу, с id номера запроса и отсортированные 
по возрастанию по всем выводимым атрибутам.
*/

SET search_path = bookings, public;
--создадим таблицу results
CREATE TABLE results
(
    id int,
    response text
);


--1--


-- Вывести максимальное количество человек в одном бронировании
INSERT INTO results

SELECT 01::int
        ,COUNT(book_ref) as "count_br"
FROM tickets
GROUP BY book_ref
ORDER BY count_br DESC
LIMIT 1;


--2--


-- Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование

WITH cbrf as (
                SELECT COUNT(*) as "count_book_ref"
                FROM tickets
                GROUP BY book_ref
                )

INSERT INTO results

SELECT 02::int
    ,COUNT(*)
FROM cbrf
WHERE count_book_ref > (SELECT AVG(count_book_ref) FROM cbrf);



---3---


-- Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза,
-- среди бронирований с максимальным количеством людей (п.1)

-- бронирования и количество пасажиров в каждом из них
WITH cte_3 as (
    SELECT book_ref
         ,COUNT(*) c
    FROM tickets
    GROUP BY book_ref
                ),
-- бронирования и id пассажира среди тех бронирований,
-- где max число пассажиров в бронировании
     cte_3_1 as (
         SELECT book_ref
              ,passenger_id
         FROM tickets
         WHERE book_ref in (
                            SELECT book_ref
                            FROM cte_3
                            WHERE c = (SELECT MAX(c) FROM cte_3)
                            )
                )

INSERT INTO results
-- в окошках посчитаем кол-во пассажиров в бронированиях, отсеим те , что не повторяются
-- среди бронирований с максимальным количеством людей
SELECT 3::int
     ,COUNT(distinct book_ref)
FROM (
        SELECT t1.book_ref,
                ROW_NUMBER() OVER(PARTITION BY t1.book_ref, t2.book_ref
                         ORDER BY t1.book_ref, t2.book_ref) pass_num
        FROM cte_3_1 t1
        JOIN cte_3_1 t2 ON t1.passenger_id = t2.passenger_id AND t1.book_ref != t2.book_ref
    ) t
WHERE t.pass_num = (SELECT MAX(c) FROM cte_3);



---4---


-- Вывести номера брони и контактную информацию по пассажирам в брони
-- (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3
WITH count_pi as (SELECT book_ref
                  FROM tickets
                  GROUP BY book_ref
                  HAVING COUNT(*) = 3
                  )

INSERT INTO results

SELECT 4::int
    ,CONCAT(book_ref, '|', passenger_id, '|',passenger_name,'|', contact_data)
FROM tickets
WHERE book_ref in (SELECT book_ref FROM count_pi)


---5---


-- Вывести максимальное количество перелётов на бронь

INSERT INTO results

SELECT 5::int
        ,COUNT(b.book_ref) as "count_brf"
FROM bookings b
JOIN tickets t ON b.book_ref = t.book_ref
JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
GROUP BY b.book_ref
ORDER BY count_brf DESC
LIMIT 1;


---6---


-- Вывести максимальное количество перелётов на пассажира в одной брони

INSERT INTO results

SELECT 6::int
     ,COUNT(t.passenger_id) as "count_ps"
FROM bookings b
         JOIN tickets t ON b.book_ref = t.book_ref
         JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
GROUP BY b.book_ref, t.passenger_id
ORDER BY count_ps DESC
LIMIT 1;
