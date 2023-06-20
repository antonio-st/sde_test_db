#!/bin/bash

echo -e "\n$ Скачиваем Docker образ PostgreSQL \n"

docker pull postgres

echo -e "\n Done \n"

sleep 5

echo -e "\n$ Запускаем контейнер PostgreSQL \n"


docker run --name sde_test_db \
--rm \
-e POSTGRES_PASSWORD="@sde_password012" \
-e POSTGRES_USER="test_sde" \
-e POSTGRES_DB="demo" \
-e PGDATA=/var/lib/postgresql/data/pgdata \
-v $(pwd)/sql:/var/lib/postgresql/data \
-p 5434:5434 \
-d \
postgres

echo -e "\n$ Контейнер с PostgreSQL запущен\n"
sleep 3

echo -e "\n$ Проверим поднятый контейнер\n"

docker ps
sleep 3

echo -e "\n$ Запускаем контейнер для заполнения БД, немного подождите....\n"


docker exec sde_test_db \
psql -U \
test_sde \
-d demo \
-f /var/lib/postgresql/data/init_db/demo.sql
sleep 15



echo -e "\n$ Проверим кол-во записей в таблице bookings, должно быть 262788 \n"

docker exec sde_test_db psql -U test_sde -d demo -c "SELECT COUNT(*) FROM bookings.bookings"
sleep 3


echo -e "\n$ Done...\n"
