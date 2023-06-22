#!/bin/bash

echo -e "\n$ Скачиваем Docker образ PostgresSQL \n"

docker pull postgres:14

echo -e "\n Done \n"

sleep 5

echo -e "\n$ Запускаем контейнер PostgresSQL и заполняем БД demo\n"

# Так же рабочий скрипт для поднятия контейнера
# docker run --name sde_test_db \
# --rm \
# -e POSTGRES_PASSWORD="@sde_password012" \
# -e POSTGRES_USER="test_sde" \
# -e POSTGRES_DB="demo" \
# -e PGDATA=/var/lib/postgresql/data/pgdata \
# -v $(pwd)/sql:/var/lib/postgresql/data \
# -p 5434:5434 \
# -d \
# postgres:14

docker run --name sde_test_db \
--rm \
-it \
-e POSTGRES_USER="test_sde" \
-e POSTGRES_PASSWORD="@sde_password012" \
-e POSTGRES_DB="demo" \
-e PGDATA="/tmp" \
-v $(pwd)/sql/:/var/lib/postgresql/data \
-v $(pwd)/sql/init_db/:/docker-entrypoint-initdb.d \
-p 5434:5434 \
-d \
postgres:14


echo -e "\n$ Контейнер с PostgresSQL запущен и заполнен\n"
sleep 5

echo -e "\n$ Проверим поднятый контейнер\n"

docker ps
sleep 3

# Рабочий скрипт для заполнения контейнера
# echo -e "\n$ Запускаем контейнер для заполнения БД, немного подождите....\n"
# 
# 
# docker exec sde_test_db \
# psql -U \
# test_sde \
# -d demo \
# -f /var/lib/postgresql/data/init_db/demo.sql
# sleep 15


echo -e "\nТаблицы в БД: \n"
sleep 6


docker exec \
sde_test_db psql \
-U test_sde \
-d demo \
-c "SELECT table_name FROM information_schema.tables WHERE table_type='BASE TABLE' AND table_name not like 'pg_%' AND  table_name not like 'sql_%'"

sleep 3


echo -e "\n$ Проверим кол-во записей в таблице bookings, должно быть 262788 \n"

docker exec \
sde_test_db \
psql -U \
test_sde \
-d demo \
-c "SELECT COUNT(*) FROM bookings.bookings"

echo -e "\n$ Done...\n"

