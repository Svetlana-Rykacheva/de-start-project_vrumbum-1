
--Создаем схему

CREATE SCHEMA car_shop;



--Создаем таблицу стран

CREATE TABLE car_shop.countries (    
country_id SERIAL PRIMARY KEY,  
  name VARCHAR(50) UNIQUE
);



--Создаем таблицу цветов

CREATE TABLE car_shop.colors (   
 color_id SERIAL PRIMARY KEY,   
 name VARCHAR(30) NOT NULL UNIQUE
);



--Таблица брендов автомобилей 

CREATE TABLE car_shop.brands (   
 brand_id SERIAL PRIMARY KEY,    
brand_name VARCHAR(50) NOT NULL UNIQUE,  
 country_id INTEGER REFERENCES car_shop.countries(country_id),
 gasoline_consumption NUMERIC(4,1), 
 UNIQUE(brand_name) 
);






--Создаем таблицу клиентов

CREATE TABLE car_shop.customers (  
   customer_id SERIAL PRIMARY KEY,   
   full_name VARCHAR(100) NOT NULL,
   phone VARCHAR(50));



-- Таблица автомобилей (объединяет модель и цвет)

CREATE TABLE car_shop.cars (  
     car_id SERIAL PRIMARY KEY,
    brand_id INTEGER NOT NULL REFERENCES car_shop.brands(brand_id),   
     color_id INTEGER NOT NULL REFERENCES car_shop.colors(color_id) );





-- Основная таблица продаж (соответствует исходным данным)

CREATE TABLE car_shop.sales (   
   sale_id SERIAL PRIMARY KEY,  
  car_id INTEGER NOT NULL REFERENCES car_shop.cars(car_id),  
  customer_id INTEGER NOT NULL REFERENCES car_shop.customers(customer_id),
  price NUMERIC(10,2) NOT NULL CHECK (price > 0),   
  sale_date DATE NOT NULL,  
  discount INTEGER NOT NULL CHECK (discount BETWEEN 0 AND 100) );





-- Заполняем страны

INSERT INTO car_shop.countries (name)
SELECT DISTINCT brand_origin 
FROM raw_data.sales;



-- Заполняем цвета

INSERT INTO car_shop.colors (name)
SELECT DISTINCT split_part(auto, ', ', 2) 
FROM raw_data.sales;



-- Заполняем бренды

INSERT INTO car_shop.brands (brand_name, country_id, gasoline_consumption)
SELECT DISTINCT  
    SPLIT_PART(auto, ', ', 1) AS brand_name,
    c.country_id,
    gasoline_consumption
FROM raw_data.sales s
JOIN car_shop.countries c ON s.brand_origin = c.name
ON CONFLICT (brand_name) DO NOTHING;





-- Заполняем cars

INSERT INTO car_shop.cars (brand_id, color_id)
SELECT
 b.brand_id,
 c.color_id
FROM raw_data.sales s
JOIN car_shop.brands b ON
 TRIM(SPLIT_PART(s.auto, ', ', 1)) = b.brand_name
JOIN car_shop.colors c ON
 TRIM(SPLIT_PART(s.auto, ',', 2)) = c.name;





--Заполнение таблицы customers

INSERT INTO car_shop.customers (full_name, phone)
SELECT
  person_name,
  phone
FROM raw_data.sales;



-- Заполнение таблицы sales

INSERT INTO car_shop.sales (car_id, customer_id, price, sale_date, discount)
SELECT
  c.car_id,
  cust.customer_id,
  s.price,
  s.date::date,
  s.discount
FROM raw_data.sales s
JOIN car_shop.customers cust
  ON s.person_name = cust.full_name AND s.phone = cust.phone
JOIN car_shop.cars c
  ON c.car_id = s.id;




-- Этап 2. Создание выборок

---- Задание 1. Напишите запрос, который выведет процент моделей машин, у которых нет параметра `gasoline_consumption`.
SELECT 
  ROUND(100.0 * COUNT(*) FILTER (WHERE gasoline_consumption IS NULL) / COUNT(*), 2) 
  AS nulls_percentage_gasoline_consumption
FROM car_shop.brands;


---- Задание 2. Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки.
SELECT
      b.brand_name,
      EXTRACT(YEAR FROM s.sale_date) AS year,
      ROUND(AVG(s.price * (1 - s.discount/100)), 2) AS price_avg
FROM car_shop.sales s
JOIN car_shop.cars c USING (car_id)
JOIN car_shop.brands b USING (brand_id)
GROUP BY
      b.brand_name,
     EXTRACT(YEAR FROM s.sale_date)
ORDER BY
    b.brand_name ASC,
    year ASC;


---- Задание 3. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки.
SELECT
    EXTRACT(MONTH FROM s.sale_date) AS month,  -- Получаем номер месяца (1-12)
    2022 AS year,                              --  указываем год
    ROUND(AVG(s.price * (1 - s.discount/100.0)), 2) AS price_avg  -- Средняя цена со скидкой
FROM
    car_shop.sales s
WHERE
    EXTRACT(YEAR FROM s.sale_date) = 2022      -- Только 2022 год
GROUP BY
    EXTRACT(MONTH FROM s.sale_date)            -- Группируем по месяцам
ORDER BY
    month;

---- Задание 4. напишите запрос, который выведет список купленных машин у каждого пользователя через запятую.

SELECT
    c.full_name AS person,
    b.brand_name AS cars
FROM
    car_shop.customers c
JOIN    car_shop.sales s USING (customer_id)
JOIN    car_shop.cars ca USING (car_id)
JOIN    car_shop.brands b USING (brand_id) 
GROUP BY
    c.full_name, b.brand_name
ORDER BY
    person;



---- Задание 5. Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки.

SELECT
    co.name AS brand_origin,
    MAX(s.price) AS price_max,
    MIN(s.price) AS price_min
FROM car_shop.sales s
JOIN car_shop.cars c USING (car_id) 
JOIN car_shop.brands b  USING (brand_id )
JOIN car_shop.countries co using (country_id)
WHERE s.discount = 0
GROUP BY co.name;

---- Задание 6. Напишите запрос, который покажет количество всех пользователей из США.
SELECT
  COUNT(*) AS persons_from_usa_count
FROM car_shop.customers
WHERE phone LIKE '+1%';

