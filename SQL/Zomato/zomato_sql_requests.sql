-- Исследуем данные ETL 
SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

SELECT COUNT(*) FROM customers
WHERE 
	customer_name IS NULL
	OR
	reg_date IS NULL



SELECT COUNT(*) FROM restaurants
WHERE 
	restaurant_name IS NULL
	OR
	city IS NULL
	OR
	opening_hours IS NULL

SELECT * FROM orders
WHERE 
	order_item IS NULL
	OR
	order_date IS NULL
	OR
	order_time IS NULL
	OR
	order_status IS NULL
	OR 
	total_amount IS NULL
--Проверили на наличие null,не обнаружено, а так бы удалили нижеследующим кодом 
--DELETE FROM orders
--WHERE 
	--order_item IS NULL

--Отвечаем на вопросыЖ
--1.Напишите запрос, чтобы найти топ-5 наиболее часто заказываемых клиентом Арджун Мехта блюд за последний 1 год.
--нужен join customers orders
--фильтры-за последний год и Арджун Мехта
	
with tab as (SELECT c.customer_name, o.order_item as dish, count(*) as total_orders, dense_rank() over (ORDER BY count(*) DESC) as rank1
FROM orders as o
join customers as c
on c.customer_id=o.customer_id
where (o.order_date>= current_date-interval '1 Year') and c.customer_name='Arjun Mehta'
group by c.customer_name, o.order_item
--having c.customer_name='Arjun Mehta'
order by total_orders desc)

SELECT *
from tab	
where rank1<=5

--2.Определите временные интервалы, в течение которых размещается наибольшее количество заказов. Исходя из 2-часовых интервалов.
SELECT (CASE
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
	    END) AS time_slot , COUNT(order_id) as order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;

SELECT*
FROM orders
--3.Найдите среднюю стоимость заказа для каждого клиента, который разместил более 750 заказов.
SELECT c.customer_name, COUNT(o.order_id) as total_orders, AVG(o.total_amount) as avg_money
FROM orders o
JOIN customers c
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING  COUNT(order_id) > 750

--4.Перечислите клиентов, которые потратили в общей сложности более 100 тысяч долларов на заказы еды.
SELECT c.customer_name, SUM(o.total_amount) as total_money
FROM orders o
JOIN customers c
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING  SUM(o.total_amount) > 100000

--5.Напишите запрос, чтобы найти заказы, которые были размещены, но не доставлены. Укажите название каждого ресторана, город и количество не доставленных заказов.
SELECT 
	r.restaurant_name,
	r.city,
	COUNT(o.order_id) as cnt_not_delivered_orders
FROM orders as o
LEFT JOIN 
restaurants r
ON r.restaurant_id = o.restaurant_id
LEFT JOIN
deliveries d
ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY r.restaurant_name,r.city
ORDER BY cnt_not_delivered_orders DESC

--6.Проранжируйте рестораны по их общему доходу с клиентов за последний год для каждого города
WITH tab AS (SELECT r.city, r.restaurant_name, SUM (o.total_amount) as revenue,
DENSE_RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) as rank1
FROM orders o
JOIN 
restaurants r
ON r.restaurant_id = o.restaurant_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY r.city, r.restaurant_name )

SELECT *
FROM tab
WHERE rank1 = 1

--7.Определите самое популярное блюдо в каждом городе, основываясь на количестве заказов.
	
WITH cte as (SELECT r.city, o.order_item as dish, COUNT(order_id) as total_orders, RANK() OVER(PARTITION BY r.city ORDER BY COUNT(order_id) DESC) as rank1
FROM orders o
JOIN restaurants r
ON r.restaurant_id = o.restaurant_id
GROUP BY r.city, o.order_item ) 
	
SELECT*
from cte
WHERE rank1 = 1

--8.Найдите клиентов, которые не размещали заказы в 2024 году, но сделали это в 2023 году.
	
SELECT DISTINCT customer_id FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2023
AND customer_id NOT IN (SELECT DISTINCT customer_id FROM orders WHERE EXTRACT(YEAR FROM order_date) = 2024)

--9.Рассчитайте и сравните частоту отмены заказов в каждом ресторане за текущий и предыдущий годы.

WITH cte_2023 AS (
    SELECT 
        o.restaurant_id, 
        COUNT(o.order_id) AS total_orders, 
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS count_not_delivered2023
    FROM orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM order_date) = 2023
    GROUP BY o.restaurant_id
),
cte_2024 AS (
    SELECT 
        o.restaurant_id, 
        COUNT(o.order_id) AS total_orders, 
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS count_not_delivered2024
    FROM orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM order_date) = 2024
    GROUP BY o.restaurant_id
),
Rat_2024 AS (
    SELECT 
        restaurant_id, 
        total_orders,
        count_not_delivered2024,
        ROUND((count_not_delivered2024::numeric / total_orders::numeric) * 100, 2) AS cancel_rat24
    FROM cte_2024
),
Rat_2023 AS (
    SELECT 
        restaurant_id, 
        total_orders, 
        count_not_delivered2023,
        ROUND((count_not_delivered2023::numeric / total_orders::numeric) * 100, 2) AS cancel_rat23
    FROM cte_2023
)
SELECT 
    Rat_2024.restaurant_id, 
    Rat_2023.cancel_rat23, 
    Rat_2024.cancel_rat24
FROM Rat_2023
JOIN Rat_2024 ON Rat_2023.restaurant_id = Rat_2024.restaurant_id;

--10.Определите время доставки каждого доставщика.
SELECT d.rider_id, o.order_id,o.order_time,d.delivery_time,
d.delivery_time - o.order_time AS time_difference,
ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
	CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
	INTERVAL '0 day' END))/60,2) as time_difference_minutes
FROM orders o
JOIN deliveries d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'

-11-- Рассчитайте коэффициент роста каждого ресторана на основе общего количества доставленных заказов с момента его присоединения
WITH tab AS
(SELECT o.restaurant_id,
	EXTRACT(YEAR FROM o.order_date) as year1,
	EXTRACT(MONTH FROM o.order_date) as month1,
	COUNT(o.order_id) as month_orders,
	LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)) as prev_month_orders
FROM orders o
JOIN deliveries d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY o.restaurant_id, EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
ORDER BY o.restaurant_id, year1, month1
)
SELECT restaurant_id, year1, month1, month_orders, prev_month_orders,
ROUND((month_orders::numeric -prev_month_orders::numeric)/prev_month_orders::numeric * 100,2) as growth_rat
FROM tab;

--12.Сегментация клиентов: Разделите клиентов на "Золотые" или "Серебряные" группы на основе их общих расходов.
-- в сравнении со средней стоимостью заказа (AOV). Если общие расходы клиента превышают AOV, 
-- обозначьте их как "Золотые", в противном случае - как "Серебряные". Напишите SQL-запрос, чтобы определить 
-- общее количество заказов в каждом сегменте и общий доход.
WITH tab AS
	(SELECT customer_id,
	 SUM(total_amount) as total_spent,
	 COUNT(order_id) as total_orders,
	 CASE WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold' ELSE 'silver' END as category
	 FROM orders
	 GROUP BY customer_id
	 )
SELECT category, SUM(total_orders), SUM (total_spent)
FROM tab
GROUP BY category


--13. Рассчитайте общий ежемесячный заработок каждого доставщика, предполагая, что он зарабатывает 8% от суммы заказа.
SELECT 
	d.rider_id,
	TO_CHAR(o.order_date, 'mm-yy') as month1,
	SUM(total_amount) as revenue,
	SUM(total_amount)* 0.08 as riders_earning
FROM orders as o
JOIN deliveries as d
ON o.order_id = d.order_id
GROUP BY d.rider_id,TO_CHAR(o.order_date, 'mm-yy')
ORDER BY d.rider_id,month1

