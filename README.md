# sde_test_db
<hr>
Репозиторий для проверки практического задания учеников Школы Инженерии Данных

<hr>

* Запуск заполнения БД: 
    - `./bash/run_init_db.sh` из корневого каталога

* в файле demo.sql закомментирован код:
    - DROP DATABASE...
    - CREATE DATABASE \
так как БД demo создаем в скрипте bash выше

* Заполнение таблицы results:

  docker exec sde_test_db \
  psql -U \
  test_sde \
  -d demo \
  -f /var/lib/postgresql/data/main/calc.sql
