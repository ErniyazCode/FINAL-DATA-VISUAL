-- table 1 orders
CREATE TABLE orders (
    order_date DATE NOT NULL,
    order_id INT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    user_id INT NOT NULL
);

-- table 2 products
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product VARCHAR(255) NOT NULL,
    category VARCHAR(255) NOT NULL
);

-- table 3 warehouses
CREATE TABLE warehouses (
    city VARCHAR(255) NOT NULL,
    warehouse_id INT PRIMARY KEY,
    address VARCHAR(255) NOT NULL
);

-- table 4 order_lines
CREATE TABLE order_lines (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

COPY orders 
FROM 'C:\Program Files\PostgreSQL\17\data\myFinalData\cleaned_orders.csv'
DELIMITER ';' 
CSV 
HEADER;

COPY order_lines
FROM 'C:\Program Files\PostgreSQL\17\data\myFinalData\cleaned_order_lines.csv'
DELIMITER ';' 
CSV 
HEADER;

COPY products
FROM 'C:\Program Files\PostgreSQL\17\data\myFinalData\products.csv'
DELIMITER ';' 
CSV 
HEADER;

COPY warehouses
FROM 'C:\Program Files\PostgreSQL\17\data\myFinalData\warehouses.csv'
DELIMITER ';' 
CSV 
HEADER;

SELECT *
FROM warehouses
LIMIT 10;

-- 11-15 августа 2 любых корма для животных, кроме "Корм Kitekat для кошек, с кроликом в соусе, 85 г"
SELECT DISTINCT o.user_id
FROM orders o
JOIN order_lines ol ON o.order_id = ol.order_id
JOIN products p ON ol.product_id = p.product_id
WHERE o.order_date BETWEEN '2017-08-01' AND '2017-08-15'
AND p.category = 'Продукция для животных'
AND p.product != 'Корм Kitekat для кошек, с каоликом в соусе, 85 Б'
GROUP BY o.user_id
HAVING COUNT(DISTINCT ol.product_id) >= 2;


-- топ 5 самых часто встречающихся товаров в заказах пользователей в СПб за период 15-30 августа
SELECT p.product, COUNT(ol.product_id) AS order_count
FROM orders o
JOIN order_lines ol ON o.order_id = ol.order_id
JOIN products p ON ol.product_id = p.product_id
JOIN warehouses w ON o.warehouse_id = w.warehouse_id
WHERE w.city = 'Санкт-Петербург'
AND o.order_date BETWEEN '2017-08-15' AND '2017-08-30'
GROUP BY p.product
ORDER BY order_count DESC
LIMIT 5;
