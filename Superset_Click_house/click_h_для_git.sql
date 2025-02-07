--1)DAU — это число уникальных пользователей, использовавших продукт в течение календарных суток.
--Всего пользователей
SELECT toMonth(log_date) as month,  COUNT(DISTINCT user_id) AS uniques
FROM events_log
WHERE name = 'pageOpen'
GROUP BY toMonth(log_date)
ORDER by toMonth(log_date)

--2)Расчитайте DAU только для НОВЫХ пользователей 
SELECT toMonth(log_date),  COUNT(DISTINCT user_id) AS uniques
FROM events_log
WHERE name = 'pageOpen' AND install_date=log_date AND install_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY toMonth(log_date)
ORDER by toMonth(log_date)

--DAU НОВЫХ пользователей по дням
SELECT log_date,  COUNT(DISTINCT user_id) AS uniques
FROM events_log
WHERE name = 'pageOpen' AND install_date=log_date AND install_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY log_date
ORDER by log_date

-- Какой процент Android-пользователей по месяцам?
WITH cte as 
(
	SELECT
	month1,
	SUM(CASE WHEN app_id = 'Android' THEN uniques ELSE 0 END) AS dau_Android,
	SUM(uniques) AS dau
	--SUM(uniques) filter( where app_id='Android') over(PARTITION by month1) as dau_Android,
	--SUM(uniques) over(PARTITION by month1)as dau
	from 
		(SELECT 
		toMonth(log_date) as month1,
		app_id,
    	COUNT(DISTINCT user_id) AS uniques
    	FROM events_log
    	WHERE name = 'pageOpen' AND log_date  BETWEEN '2024-01-01' AND '2024-12-31'
    	GROUP BY month1, app_id
    	ORDER BY month1 ASC
    	)
    GROUP BY month1
    ORDER BY month1 ASC
)
    	
SELECT 
	month1,
	dau_Android,
	dau,
	ROUND(dau_Android*100/dau, 2) as dau_part_Android
from cte 
ORDER BY month1 ASC	

--Какой процент Android-пользователей по датам?
WITH cte as 
(
	SELECT
	log_date,
	SUMIf(uniques, app_id = 'Android') OVER (PARTITION BY log_date) AS dau_day_Android,
	--SUM(uniques) filter( where app_id='Android') over(PARTITION by log_date) as dau_day_Android,
	SUM(uniques) over(PARTITION by log_date)as dau_day,
	
	SUMIf(uniques, app_id = 'Android') OVER () AS dau_all_Android,
	--SUM(uniques) filter( where app_id='Android') over() as dau_all_Android,
	SUM(uniques) over() as dau_all
	from 
		(SELECT 
		log_date,
		app_id,
    	COUNT(DISTINCT user_id) AS uniques
    	FROM events_log
    	WHERE name = 'pageOpen' AND log_date  BETWEEN '2024-01-01' AND '2024-12-31'
    	GROUP BY log_date, app_id
    	ORDER BY log_date ASC
    	)
)
    	
SELECT 
	log_date,
	ROUND(dau_day_Android*100/dau_day, 2) as Android_doll_by_day,
	
	ROUND(dau_all_Android*100/dau_all, 2) as Android_doll_all
from cte 
ORDER BY log_date ASC	









--Число пользователей посмотревший хотябы один фильм
SELECT toMonth(log_date) as month1, count(DISTINCT user_id) as movie_watchers
FROM events_log
WHERE name = 'startMovie'
GROUP BY month1
ORDER BY month1

--Число подписок в месяц
SELECT toMonth(log_date) as month1, count(DISTINCT user_id)
FROM events_log
WHERE name = 'subs'
GROUP BY month1
ORDER BY  month1


	   
--Удержание рассчитывается как доля новых пользователей, вернувшихся в продукт через N дней после первого использования
--Возьмем пользователей которые начали пользоваться продуктом в период с '2024-01-01' по '2024-01-15' 
--Видно, что если нужно проанализировать удержание 7-го дня, то нужно брать активность новых пользователей в промежутке с 2024-01-01' AND '2024-01-22' 
--Шаг 1. Расчёт числа удержанных пользователей для каждого лайфтайма
--Шаг 2. Расчёт доли удержания


WITH installs AS (
    -- Количество уникальных пользователей в день установки (Day 0)
    SELECT 
        install_date, 
        COUNT(DISTINCT user_id) AS day_0_users
    FROM events_log 
    WHERE install_date BETWEEN '2024-01-01' AND '2024-01-15' 
    GROUP BY install_date
),
retention AS (
    -- Определение последней активности пользователя
    SELECT 
        user_id,
        install_date,
        MAX(log_date) AS last_log_date,  -- Последняя активность пользователя
        dateDiff('day', install_date, MAX(log_date)) AS retention_day  -- Разница в днях
    FROM events_log
    WHERE install_date BETWEEN '2024-01-01' AND '2024-01-15' 
      AND log_date BETWEEN '2024-01-01' AND '2024-01-22' 
    GROUP BY user_id, install_date
)
-- Итоговый расчет удержания
SELECT 
    r.install_date,
    r.retention_day,--Livetime Лайфтайм
    COUNT(DISTINCT r.user_id) AS retained_users, --Считаем уникальных пользователей с с данным конкретным retantion_rate
    i.day_0_users,
    ROUND(COUNT(DISTINCT r.user_id) * 100.0 / NULLIF(i.day_0_users, 0),2) AS retention_rate,  -- Retention per day
    ROUND(SUM(COUNT(DISTINCT r.user_id)) OVER () * 100.0 / NULLIF(SUM(i.day_0_users) OVER (), 0),2) AS avg_retention_rate  -- Средний retention за период
FROM retention r
JOIN installs i 
ON r.install_date = i.install_date
WHERE r.retention_day<=7
GROUP BY r.install_date, r.retention_day, i.day_0_users
ORDER BY r.install_date, r.retention_day


--Считаем 
-- Шаг 1. Получаем и группируем результаты опросов во FROM ()
-- Шаг 2. Рассчитываем число ответов по группам и NPS Промоутерами считем людей, которые поставили оценку 3 и выше
WITH nps AS (

    -- Шаг 1. Получаем и группируем результаты опросов

    SELECT object_value AS nps_score,
           COUNT(DISTINCT user_id) AS votes
    FROM events_log 
    WHERE name = 'npsDialogVote'
    GROUP BY object_value
    
)

-- Шаг 2. Рассчитываем число ответов по группам и NPS
SELECT SUM(CASE WHEN nps_score < 4 THEN votes ELSE 0 END) AS detractors,
       SUM(CASE WHEN nps_score >=4 THEN votes ELSE 0 END) AS promoters, 
       SUM(votes) AS total,
       ROUND(SUM(CASE WHEN nps_score >= 4 THEN votes ELSE 0 END) / SUM(votes) - SUM(CASE WHEN nps_score <4 THEN votes ELSE 0 END) / SUM(votes),2) AS nps
FROM nps 
 




--Конверсия в целевое действие
--Число новых пользователей совершивших целевое действие/число новых пользователей

WITH n1 AS (  
    -- Определяем новых пользователей
    SELECT user_id, 
           MIN(install_date) AS install_date_min
    FROM events_log 
    WHERE log_date = install_date 
          AND install_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-28')
    GROUP BY user_id
),
m1 AS (
    -- Количество просмотров фильмов пользователем
    SELECT 
           user_id,  
           install_date,
           COUNTIf(name = 'startMovie') AS count_movie -- Используем COUNTIf для ClickHouse
    FROM events_log
    WHERE install_date BETWEEN '2024-02-01' AND toDate('2024-02-28') 
          AND name = 'startMovie' AND log_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-28')
    GROUP BY user_id, install_date
),
conversion AS (
    -- Вычисляем конверсию в просмотры фильмов
    SELECT 
        n1.install_date_min,
        SUM(IF(m1.count_movie > 1, 1, 0)) AS watched_movie_users,  -- Считаем пользователей, которые посмотрели более 1 фильма
        COUNT(DISTINCT n1.user_id) AS total_users  -- Считаем общее число новых пользователей
    FROM n1
    FULL JOIN m1 ON n1.user_id = m1.user_id  
    GROUP BY n1.install_date_min
)

/* Финальный расчет конверсии */
SELECT 
    install_date_min,
    ROUND(watched_movie_users*100 / NULLIF(total_users, 0),2) AS conv_by_date_pr  -- Избегаем деления на 0
FROM conversion
ORDER BY install_date_min





--Конверсия в SQL, на примере конверсии 60-го дня
--Мы зарабатываем только на оплате подписки и просмотре обьявлений,
--первая подписка может произойти спустя 30-60 дней после установки так как первый месяц 
--юзеры пользуются  приложением бесплатно

--Подзапрос installs позволяет определить число пользователей которые начали пользоваться приложением в каждый из дней наблюдений.
--В этом подзапросе с помощью оператора BETWEEN нужно задать временной интервал наблюдений 
--log_date BETWEEN '2024-02-01' AND '2024-02-15' и с помощью условия install_date = log_date 
--отобрать только тех клиентов, которые начали пользоваться продуктом внутри интервала наблюдений '2024-02-01' AND '2024-02-15' 
WITH installs  AS (
    /* Шаг 1. Расчёт числа новых пользователей */
    SELECT install_date,  
           COUNT(DISTINCT user_id) AS new_dau 
    FROM events_log
    WHERE log_date BETWEEN '2024-02-01' AND '2024-02-15'
          AND install_date = log_date
    GROUP BY install_date
),
--Отбираем только тех клиентов, которые начали пользоваться продуктом с '2024-02-01' по '2024-02-15' 
--Затем с помощью условия log_date BETWEEN '2024-02-01' AND ('2024-02-15' + toIntervalDay(60)) отбираются покупки этих пользователей за первые 10 дней.
--После этого для каждого покупателя определяется лайфтайм совершения первой покупки по формуле  dateDiff('day', MIN(install_date), MIN(log_date))

orders  AS (
    /* Шаг 2. Расчёт числа конверсий в покупку */
	--
    SELECT install_date_min,  -- Переименовываем для JOIN
       lifetime,
       COUNT(DISTINCT user_id) AS conversions
	FROM (
    SELECT user_id,
           MIN(install_date) AS install_date_min,  
           MIN(log_date) AS log_date_min,
           dateDiff('day', MIN(install_date), MIN(log_date)) AS lifetime
    FROM events_log
    WHERE name = 'purchase' 
          AND install_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-15')
          AND log_date >= toDate('2024-02-01')  
          AND log_date <= toDate('2024-02-15') + toIntervalDay(60)
    GROUP BY user_id
	) AS subquery  
	GROUP BY install_date_min, lifetime
),

/* Шаг 3. Третий шаг — объединение конверсий и числа новых пользователей */

conv  AS (
 		   SELECT i.install_date,
           i.new_dau,
           o.lifetime,
           COALESCE(o.conversions, 0) AS conversions
    FROM installs i 
    FULL JOIN orders o ON i.install_date = o.install_date_min
)



   /* Шаг 4. Расчёт накопительных конверсий */
    SELECT install_date,
           SUM(conversions) OVER (PARTITION BY install_date ORDER BY lifetime) AS cumulative_conversions,
           new_dau,
           ROUND(CAST(cumulative_conversions AS FLOAT) / CAST(new_dau AS FLOAT),2) AS conversion
    FROM conv
    ORDER BY install_date

--1Сначала выполняется подзапрос revenue
--Он проходит по таблице events_log и подсчитывает уникальных пользователей, 
--покупателей и выручку в день. Обратите внимание, как с помощью оператора 
--CASE считаются уникальные покупатели: CASE WHEN name = 'purchase' THEN user_id ELSE NULL END.
--В том случае, когда тип события — покупка, CASE возвращает user_id, 
--а для всех остальных типов ивентов он возвращает NULL (то есть пропуск). 
--Это позволяет оператору COUNT(DISTINCT) посчитать уникальные идентификаторы только тех пользователей, которые совершили покупку.


--ARPDAU с помощью SQL
WITH revenue AS (
    -- Шаг 1. Расчёт DAU, уникальных плательщиков и дневной выручки
    SELECT log_date, 
           SUM(CASE WHEN name = 'purchase' THEN CAST(object_value AS FLOAT) ELSE 0 END) as revenue,
           COUNT(DISTINCT user_id) AS dau, -- считаем DAU 
           COUNT(DISTINCT CASE WHEN name = 'purchase' THEN user_id ELSE NULL END) AS paying_dau -- считаем платящий DAU
    FROM events_log 
    WHERE log_date BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY log_date
   
)
-- Шаг 2. Расчёт ARPDAU и ARPPDAU
SELECT log_date,
       revenue,
       dau,
       paying_dau,
       ROUND(revenue / CAST(dau AS FLOAT),2) AS arpdau,
       revenue / CAST(paying_dau AS FLOAT) AS arppdau
FROM revenue
ORDER BY log_date






--LTV--выручку за время жизни пользователя
--Подзапрос installs определяет число клиентов, которые начали пользоваться 
--приложением в каждый из дней наблюдений. Если выполнить этот подзапрос 
--отдельно То получится таблица, в которой для каждой даты указано число новых пользователей
WITH installs AS (
    /* Шаг 1. Расчёт числа новых пользователей */
    SELECT 
        install_date,  
        COUNT(DISTINCT user_id) AS new_dau 
    FROM events_log
    WHERE install_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-15')
          AND install_date = log_date
    GROUP BY install_date
),

orders AS (
    /* Шаг 2. Расчёт числа конверсий в покупку */
    SELECT install_date,  
           COUNT(DISTINCT user_id) AS paying_dau,
           SUM(CAST(object_value AS FLOAT)) AS rev
    FROM (
        SELECT user_id,
               install_date,  
               log_date,
               dateDiff('day', install_date, log_date) AS lifetime,
               object_value
        FROM events_log
        WHERE name = 'purchase' 
              AND install_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-15')
              AND log_date BETWEEN toDate('2024-02-01') AND toDate('2024-07-31')
        GROUP BY user_id, install_date, log_date, object_value
    ) AS subquery  
    GROUP BY install_date
),

cumulative_revenue AS (
    /* Шаг 3. Расчёт накопительной выручки */
    SELECT 
        COALESCE(i.install_date, o.install_date) AS install_date, 
        i.new_dau,
        o.rev,
        SUM(o.rev) OVER (PARTITION BY o.install_date ORDER BY o.install_date ASC) AS cumulative_rev
    FROM orders o
    LEFT JOIN installs i 
    ON o.install_date = i.install_date
)

/* Финальный запрос */
SELECT 
    install_date,
    new_dau,
    cumulative_rev,
    ROUND(cumulative_rev / NULLIF(new_dau, 0),2) AS ltv,  
    SUM(cumulative_rev) OVER () AS total_cumulative_revenue
FROM cumulative_revenue
GROUP BY install_date, new_dau, cumulative_rev  
ORDER BY install_date


--CAC
WITH installs AS (

    /* Шаг 1. Расчёт числа новых пользователей */
    SELECT toDate(install_date) as install_date1,
           COUNT(DISTINCT user_id) AS new_dau
    FROM events_log
    WHERE install_date = log_date
          AND utm_source != 'organic'  -- Убираем органический трафик
          AND install_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-15')
          AND log_date BETWEEN toDate('2024-02-01') AND toDate('2024-07-31')
    GROUP BY install_date
    
),
ad_costs AS (

    /* Шаг 2. Расчёт затрат на рекламу */
    SELECT toDate(cost_date) AS cost_date,  -- Исправлено: заменили Date() на toDate()
           SUM(cost_per_user) AS costs
    FROM ads_costs
    GROUP BY cost_date
    
)

/* Шаг 3. Расчёт CAC */
SELECT 
       i.install_date1,
       i.new_dau,
       ROUND(COALESCE(a.costs, 0),2) AS costs,  -- Если нет затрат, ставим 0
       ROUND(COALESCE(a.costs, 0) / NULLIF(CAST(i.new_dau AS FLOAT), 0),2) AS cac  -- Защита от NULL и деления на 0
FROM installs i
LEFT JOIN ad_costs a ON i.install_date1 = a.cost_date  -- Исправлено: теперь `cost_date` совпадает
ORDER BY install_date1








--ROI

--всё начинается с подсчёта числа новых пользователей для каждого из дней привлечения. 
--Отличие от расчёта LTV в том, что в этот раз запрос отсекает органических пользователей 
--с помощью условия utm_source != 'organic'.
    /* Шаг 1. Расчёт числа новых пользователей */
WITH installs AS (
    /* Шаг 1. Расчёт числа новых пользователей */
    SELECT 
        install_date,  
        COUNT(DISTINCT user_id) AS new_dau 
    FROM events_log
    WHERE install_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-15')
          AND install_date = log_date
    GROUP BY install_date
),

orders AS (
    /* Шаг 2. Расчёт числа конверсий в покупку */
    SELECT install_date,  
           COUNT(DISTINCT user_id) AS paying_dau,
           SUM(CAST(object_value AS FLOAT)) AS rev
    FROM (
        SELECT user_id,
               install_date,  
               log_date,
               dateDiff('day', install_date, log_date) AS lifetime,
               object_value
        FROM events_log
        WHERE name = 'purchase' 
              AND install_date BETWEEN toDate('2024-02-01') AND toDate('2024-02-15')
              AND log_date BETWEEN toDate('2024-02-01') AND toDate('2024-07-31')
        GROUP BY user_id, install_date, log_date, object_value
    ) AS subquery  
    GROUP BY install_date
),

cumulative_revenue AS (
    /* Шаг 3. Расчёт накопительной выручки */
    SELECT 
        COALESCE(i.install_date, o.install_date) AS install_date, 
        i.new_dau,
        o.rev,
        SUM(o.rev) OVER (PARTITION BY COALESCE(i.install_date, o.install_date) ORDER BY COALESCE(i.install_date, o.install_date) ASC) AS cumulative_rev
    FROM orders o
    LEFT JOIN installs i 
    ON o.install_date = i.install_date
),

ad_costs AS (
    /* Шаг 4. Расчёт затрат на рекламу */
    SELECT 
        toDate(cost_date) AS cost_date,  
        SUM(cost_per_user) AS costs
    FROM ads_costs
    GROUP BY cost_date
)

/* Финальный запрос */
SELECT 
    cr.install_date,
    cr.new_dau,
    cr.cumulative_rev,
    ROUND(cr.cumulative_rev / NULLIF(cr.new_dau, 0), 2) AS ltv,  
    SUM(cr.cumulative_rev) OVER () AS total_cumulative_revenue,
    ROUND(COALESCE(a.costs, 0), 2) AS costs,  -- ✅ Добавлена запятая перед costs
    ROUND(COALESCE(a.costs, 0) / NULLIF(CAST(cr.new_dau AS FLOAT), 0), 2) AS cac,
    ROUND(ROUND(cr.cumulative_rev / NULLIF(cr.new_dau, 0), 2) / NULLIF(ROUND(COALESCE(a.costs, 0) / NULLIF(CAST(cr.new_dau AS FLOAT), 0), 2), 0), 2) AS roi
FROM cumulative_revenue cr
LEFT JOIN ad_costs a ON cr.install_date = a.cost_date  -- ✅ Добавлен `JOIN` для затрат на рекламу
GROUP BY cr.install_date, cr.new_dau, cr.cumulative_rev, a.costs  
ORDER BY cr.install_date


