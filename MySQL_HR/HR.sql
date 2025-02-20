CREATE  DATABASE PROJECTS;
USE PROJECTS;
SELECT * from hr;
SHOW COLUMNS FROM hr;
ALTER TABLE HR
change column п»їid emp_id varchar(20) Null;

SET sql_safe_updates=0;

UPDATE hr
set birthdate = case 
	when birthdate like '%/%/%' then date_format(str_to_date (birthdate,'%m/%d/%Y'),'%Y-%m-%d')
	when birthdate like '%-%-%' then date_format(str_to_date (birthdate,'%m-%d-%Y'),'%Y-%m-%d')
end;
ALTER TABLE HR
modify column birthdate Date;

UPDATE hr
set hire_date = case 
	when hire_date like '%/%/%' then date_format(str_to_date (hire_date,'%m/%d/%Y'),'%Y-%m-%d')
	when hire_date like '%-%-%' then date_format(hire_date,'%Y-%m-%d') 
	else null
end;
UPDATE hr
SET hire_date = CASE 
    WHEN MONTH(hire_date) = 0 OR DAY(hire_date) = 0 THEN NULL
    ELSE hire_date
END
ALTER TABLE HR
modify column hire_date Date;

UPDATE hr
SET termdate = CASE
    WHEN termdate IS NOT NULL AND termdate != '' THEN DATE(STR_TO_DATE(termdate, '%Y-%m-%d %H:%i:%s UTC'))
    ELSE NULL
END;
ALTER TABLE hr
MODIFY COLUMN termdate DATE;

select count(age) from hr;

alter table hr add column age int;
select age from hr;
update hr
set age=timestampdiff(year, birthdate, curdate()); --curdate текущая дата


--Какое соотношение между мужчинами и женщинами в компании?
select gender, count(*)
from hr 
where age>=18 and termdate is null
group by gender;

--Какое рассовое/этническое распределение в компании? 
select race, count(*) as count
from hr
where age>=18 and termdate is null
group by race
order by count(*) desc;

--Каково возрастное распределение в компании?
--Если в колонки termdate стоит null мы считаем, что сотрудник не собирается нас покидать.
select
	min(age) as youngest,
	max(age) as oldest
from hr
where age>=18 and termdate is null

select 
	case
		when age>=20 and age<=29 then "20-29"
        when age>=30 and age<=40 then "30-40"
        when age>=41 and age<=50 then "41-50"
        when age>=51 and age<=60 then "51-60"
        when age>=61 and age<=65 then "61-65"
        else "65+"
    end as age_group, gender, count(*) as count
from hr
where age>=18 and termdate is null
group by age_group, gender
order by age_group, gender;

--Сколько сотрудников работает в головном офисе и сколько в филиале?
select Location, count(*) as count
from hr
where age>=18 and termdate is null
group by location;

--Сколько сотрудники проработали в компании перед увольнением?
select avg(datediff(termdate, hire_date))/365 as avg_length_employment
from hr
where termdate<=curdate() and termdate is not null and age >=18;

--Какое половое распределение по отлелам и должностям?
select department, gender, count(*) as count
from hr 
where age>=18 and termdate is null
group by department, gender
order by department

--Есть ли лишние должности в компании?
select jobtitle, count(*) as count
from hr 
where age>=18 and termdate is null
group by jobtitle
order by jobtitle desc

--Какой уровень текучести кадров?
select department, total_count,terminated_count, terminated_count/total_count as termination_rate
from (select department, count(*) as total_count,
		sum(case when termdate is not null and termdate<=curdate() then 1 else 0 end) as terminated_count
      from hr  
	  where age>=18
      group by department
     ) as subquery
order by termination_rate DESC;

--Какое распределение сотрудников по штатам?
select location_state, count(*) as count
from hr 
where age>=18 and termdate is null
group by location_state
order by count desc

select year(hire_date) 
from hr
--Какое % cотрудников остался в компании по сегодняшний день?
select year1, hires, terminations, (hires-terminations) as net_change,
	   round(((hires-terminations)/hires)*100,2) as net_change_percent
from(select year(hire_date) as year1,
			count(*) as hires,
            sum(case when termdate is not null and termdate<=curdate() then 1 else 0 end) as terminations
            from hr
            where age>=18 and hire_date is not null
            group by year(hire_date)
	) as subquery
    order by year1 asc
          
--Какой средний срок работы для каждого отдела?
SELECT department, avg(datediff(termdate, hire_date)/365) as avg_tenure
from hr
where termdate <=curdate() and termdate is not null and age>=18
group by department;
