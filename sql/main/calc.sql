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


--1--  Вывести максимальное количество человек в одном бронировании

INSERT INTO results

SELECT 01  as id
        ,COUNT(book_ref) as "count_br"
FROM tickets
GROUP BY book_ref
ORDER BY count_br DESC
LIMIT 1;


--2--  Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование

WITH cbrf as (
                SELECT COUNT(*) as "count_book_ref"
                FROM tickets
                GROUP BY book_ref
                )

INSERT INTO results

SELECT 02 as id
    ,COUNT(*)
FROM cbrf
WHERE count_book_ref > (SELECT AVG(count_book_ref) FROM cbrf);


---3---  Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза,
        -- среди бронирований с максимальным количеством людей (п.1)

WITH pg as (SELECT book_ref
                 , string_agg(passenger_id, ',' ORDER BY passenger_id) as passenger_group
                 , rank() OVER (ORDER BY count(passenger_id) DESC) AS rnk
            FROM bookings.tickets
            GROUP BY book_ref
            ORDER BY count(passenger_id) DESC)

INSERT INTO results

SELECT 3 as id, count(book_ref)
FROM pg
WHERE rnk = 1
GROUP BY passenger_group
HAVING count(passenger_group) > 1;


---4---  Вывести номера брони и контактную информацию по пассажирам в брони
        -- (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3

INSERT INTO results

SELECT  4 as id, concat_ws('|', t.book_ref, string_agg(t.passenger_info, '|'))
FROM (
         SELECT book_ref
              , concat_ws('|', passenger_id, passenger_name, contact_data) AS passenger_info
         FROM bookings.tickets
         WHERE book_ref IN (
             SELECT book_ref
             FROM bookings.tickets
             GROUP BY book_ref
             HAVING count(passenger_id) = 3
         )
     ) t
GROUP BY t.book_ref
ORDER BY 2;



---5---  Вывести максимальное количество перелётов на бронь

INSERT INTO results

SELECT 5 as id
        ,COUNT(b.book_ref) as "count_brf"
FROM bookings b
JOIN tickets t ON b.book_ref = t.book_ref
JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
GROUP BY b.book_ref
ORDER BY count_brf DESC
LIMIT 1;


---6---  Вывести максимальное количество перелётов на пассажира в одной брони

INSERT INTO results

SELECT 6 as id
     ,COUNT(t.passenger_id) as "count_ps"
FROM bookings b
JOIN tickets t ON b.book_ref = t.book_ref
JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
GROUP BY b.book_ref, t.passenger_id
ORDER BY count_ps DESC
LIMIT 1;



---7---  Вывести максимальное количество перелётов на пассажира

WITH cpid as (SELECT t.passenger_id
     ,COUNT(t.passenger_id) as "cpid"
FROM tickets t
JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
GROUP BY t.passenger_id
ORDER BY cpid DESC)

INSERT INTO results

SELECT 7 as id
    ,MAX(cpid)
FROM cpid;


---8--- Вывести контактную информацию по пассажиру(ам)
        -- (passenger_id, passenger_name, contact_data) и общие траты на билеты,
        -- для пассажира потратившему минимальное количество денег на перелеты

INSERT INTO results

SELECT 8 as id
     ,CONCAT(passenger_id, '|', passenger_name, '|', contact_data, '|', rank_sum)
from (
        SELECT passenger_id
                   , passenger_name
                   , contact_data
                   , rank() over (order by sum(amount)) as "rank_sum"
              FROM tickets t
                       JOIN ticket_flights tf on t.ticket_no = tf.ticket_no
              WHERE amount is not null
              GROUP BY t.ticket_no
      ) t
WHERE rank_sum = 1
ORDER BY passenger_id, passenger_name, contact_data;



---9--- Вывести контактную информацию по пассажиру(ам)
    -- (passenger_id, passenger_name, contact_data)
    -- и общее время в полётах, для пассажира, который провёл максимальное время в полётах


WITH w_time as (SELECT t.passenger_id
                     ,t.passenger_name
                     ,t.contact_data
                   , SUM(fv.actual_duration) as "sum_time_duration"
                    ,RANK() OVER(ORDER BY SUM(fv.actual_duration) DESC) rank_sum_duration
                FROM tickets t
                JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
                JOIN flights_v fv on tf.flight_id = fv.flight_id
                WHERE fv.actual_duration IS NOT NULL
                GROUP BY t.ticket_no
                )

INSERT INTO results

SELECT 9 as id
       ,CONCAT(passenger_id, '|', passenger_name, '|', contact_data, '|', sum_time_duration)
FROM w_time
WHERE rank_sum_duration = 1
ORDER BY sum_time_duration DESC;




---10--- Вывести город(а) с количеством аэропортов больше одного


INSERT INTO results

SELECT 10 as id
       ,city
FROM airports
GROUP BY city
HAVING COUNT(airport_name) > 1
ORDER BY city;



---11--- Вывести город(а), у которого самое меньшее количество городов прямого сообщения

WITH comm_beetwen_city as (
                            SELECT departure_city
                                    ,arrival_city
                                    ,COUNT(*) OVER(PARTITION BY departure_city ORDER BY departure_city) as "count_city"
                            FROM routes
                            GROUP BY departure_city, arrival_city
                            )
INSERT INTO results

SELECT 11 as id
    ,departure_city
FROM comm_beetwen_city
WHERE count_city = (SELECT MIN(count_city) FROM comm_beetwen_city);




---12---  Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты

WITH comm_beetwen_city as(
    SELECT distinct departure_city, arrival_city
    FROM routes),
comm_beetwen_city_res as (SELECT t1.departure_city dc
                               ,t2.arrival_city ac
                          FROM comm_beetwen_city t1,
                               comm_beetwen_city t2
                        --удаляем реверсивные дубликаты
                          WHERE t1.departure_city < t2.arrival_city
                          EXCEPT
                          SELECT *
                          FROM comm_beetwen_city)

INSERT INTO results

SELECT 12 as id
        ,CONCAT(dc, '|', ac)
FROM comm_beetwen_city_res
ORDER BY dc, ac;




---13---  Вывести города, до которых нельзя добраться без пересадок из Москвы?



INSERT INTO results

SELECT DISTINCT 13 as id
                ,departure_city
FROM routes
WHERE departure_city != 'Москва'
AND departure_city not in (SELECT arrival_city
                           FROM routes
                           WHERE departure_city = 'Москва')
ORDER BY 2;


---14---  Вывести модель самолета, который выполнил больше всего рейсов


WITH model_dep_max as (SELECT a.model
                             ,COUNT(f.flight_no) as "count_fly"
                        FROM aircrafts a
                        JOIN flights f on a.aircraft_code = f.aircraft_code
                        WHERE f.actual_departure IS NOT NULL
                        GROUP BY a.model)

INSERT INTO results

SELECT 14 as id
        ,model
FROM model_dep_max
WHERE count_fly =  (SELECT MAX(count_fly) FROM model_dep_max);


---15--- Вывести модель самолета, который перевез больше всего пассажиров

WITH model_max_pass as (
                        SELECT a.model
                        ,COUNT(tf.ticket_no) as "count_ticket"
                        FROM aircrafts a
                        JOIN flights f on a.aircraft_code = f.aircraft_code
                        JOIN ticket_flights tf on f.flight_id = tf.flight_id
                        WHERE f.actual_departure IS NOT NULL
                        GROUP BY a.model
                        )

INSERT INTO results

SELECT 15 as id
    ,model
FROM model_max_pass
WHERE count_ticket = (SELECT MAX(count_ticket) FROM model_max_pass);

---16--- Вывести отклонение в минутах суммы запланированного времени перелета от
     -- фактического по всем перелётам

INSERT INTO results

SELECT 16 as id, ABS(extract(epoch from sum(scheduled_duration) - sum(actual_duration)) / 60)::int as difference
FROM bookings.flights_v
WHERE status = 'Arrived';


---17--- Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13


INSERT INTO results

SELECT DISTINCT
    17 as id,
    arrival_city as response
FROM flights_v f
WHERE departure_city = 'Санкт-Петербург'
AND date_trunc('day',actual_departure_local) = '2016-09-13'
ORDER BY 1,2;


---18--- Вывести перелёт(ы) с максимальной стоимостью всех билетов

INSERT INTO results

WITH flight_amount as
         (
             SELECT
                 flight_id ,
                 SUM(amount) as sum_amnt
             FROM ticket_flights tf
             GROUP BY flight_id
         )
SELECT
    18 as id,
    flight_id as response
FROM flight_amount
WHERE sum_amnt = (SELECT MAX(sum_amnt) from flight_amount);



---19--- Выбрать дни в которых было осуществлено минимальное количество перелётов


INSERT INTO results

SELECT 19 as id
     ,tmp.actual_departure
FROM (
         SELECT COUNT(actual_departure::date)
              , actual_departure::date as actual_departure
              , RANK() OVER (ORDER BY COUNT(actual_departure::date)) AS rnk
         FROM flights
         WHERE status != 'Cancelled'
           AND actual_departure IS NOT NULL
         GROUP BY actual_departure::date
         ORDER BY COUNT(actual_departure::date)
     ) tmp
WHERE tmp.rnk = 1
ORDER BY tmp.actual_departure;



---20--- Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года


INSERT INTO results

SELECT 20, AVG(count_flights) avg_departure
FROM
    (SELECT COUNT(flight_id) as "count_flights"
     FROM flights
     WHERE actual_departure IS NOT NULL
       AND date_trunc('month', actual_departure) = '2016-09-01'
     GROUP BY actual_departure::date) t;


---21--- Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов

INSERT INTO results

SELECT 21 as id
     ,departure_city
FROM bookings.flights_v
WHERE status = 'Arrived'
GROUP BY departure_city
HAVING AVG(actual_duration) > INTERVAL '3 hours'
ORDER BY AVG(actual_duration) DESC
LIMIT 5;