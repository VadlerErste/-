----Вадим Лысенков-----
---24.06.2025---
---Задача 1---
--Отфильтруем данные от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats as f
    left join real_estate.advertisement as adv on f.id = adv.id
    ),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT adv.id
    FROM real_estate.flats as f  
    left join real_estate.advertisement as adv on f.id = adv.id
           WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
          ),
 --Разбиваем объявления на категории--
division_id AS(
select  adv.id,count(adv.id)as cnt,--количество объявлений
adv.last_price/f.total_area as one_meter_qu,---стоимость квадратного метра
t.type as type_city,---тип населенного пункта
total_area,---стоимость квадратного метра
rooms,---количество комнат
       case----категории по населенным пунктам
	       		when c.city ='Санкт-Петербург' then 'Санкт-Петербург'
	       		else 'ЛенОбл'
       end region,
		    case ----категории по длительности размещения объявления
		       	when adv.days_exposition <='30' then 'до месяца'
		       	when adv.days_exposition >'30' and  adv.days_exposition <='90' then 'до квартала'
		       	when adv.days_exposition >'90' and  adv.days_exposition <='180' then 'до полугода'
		       	when adv.days_exposition >'180' then 'более полугода'
		       	when adv.days_exposition is null then 'не продано'
		    end activity_info
		       FROM real_estate.flats as f		      
    left join real_estate.advertisement as adv on f.id = adv.id
    left join real_estate.city as c on f.city_id = c.city_id
    left join real_estate.type as t on f.type_id = t.type_id
    where t.type='город'
    group by adv.id,region,activity_info,t.type,one_meter_qu,total_area,rooms
           )   
-- Выведем объявления без выбросов:
SELECT region,activity_info,type_city,
       round((avg(one_meter_qu)::numeric))as avg_one_meter,--средняя стоимость квадратного метра
	   round((avg(total_area)::numeric))as avg_total_area,--средняя площадь квартиры
	   round((avg(rooms)::numeric),1)as cnt_rooms, ---количество комнат
	   count(id)as cnt_id,---количество объявлений,
	   (count(id)::real/sum(count(id))over(partition by region)*100)::numeric(5,2) as parts---доля снятытых объявлений в разрезе количества объявлений по населенным пунктам
	   from division_id as di
where di.id IN (SELECT * FROM filtered_id) 
group by region,type_city,activity_info
order by activity_info,region

---Задача 2---
--Отфильтруем данные от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats as f
    left join real_estate.advertisement as adv on f.id = adv.id
    ),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT adv.id
    FROM real_estate.flats as f  
    left join real_estate.advertisement as adv on f.id = adv.id
           WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
          ),
--Активность публикации объявлений о продаже недвижимости по месяцам
exposition_info as(
	select  
		case 
       	   when EXTRACT(MONTH FROM (first_day_exposition))='01' then 'Январь'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='02' then 'Февраль'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='03' then 'Март'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='04' then 'Апрель'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='05' then 'Май'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='06' then 'Июнь'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='07' then 'Июль'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='08' then 'Август'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='09' then 'Сентябрь'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='10' then 'Октябрь'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='11' then 'Ноябрь'
       	   when EXTRACT(MONTH FROM (first_day_exposition))='12' then 'Декабрь'
       end period_month_exp,
       count(first_day_exposition) as cnt_exp_id,---количество размещенных объвлений по месяцам
       round(avg((total_area)::numeric),2) as avg_area,---средняя площадь квартиры
       round(avg((last_price/total_area)::numeric),2) as avg_qmeter---средняя стоимость квадратного метра
       from real_estate.advertisement as adv
       left join real_estate.flats as f on adv.id = f.id
       where adv.id IN (SELECT * FROM filtered_id) 
       group by period_month_exp
       order by cnt_exp_id
       ),
       ----информация по снятым объявлениям
       finish_info as(
      select  
       		case 
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='01' then 'Январь'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='02' then 'Февраль'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='03' then 'Март'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='04' then 'Апрель'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='05' then 'Май'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='06' then 'Июнь'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='07' then 'Июль'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='08' then 'Август'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='09' then 'Сентябрь'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='10' then 'Октябрь'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='11' then 'Ноябрь'
       	   when EXTRACT(MONTH FROM (first_day_exposition + INTERVAL '1 day' *days_exposition))='12' then 'Декабрь'
      end period_month_final,
       count(*) as cnt_final_id---количеcтво снятых объвлений по месяцам
       from real_estate.advertisement
       where days_exposition is not NULL
       group by period_month_final
       order by cnt_final_id desc
       )
       select period_month_exp,cnt_exp_id,
       NTILE(12) OVER(ORDER BY cnt_exp_id DESC) as rank_exp,---активность по месяцам размещения объявлений
       period_month_final,cnt_final_id,
       NTILE(12) OVER(ORDER BY cnt_final_id DESC) as rank_exp,---активность по месяцам снятия объявлени
       avg_area,avg_qmeter
       from finish_info as fi
       left join exposition_info as exi on fi.period_month_final=exi.period_month_exp      
       
       ---Задача 3
       ---ТОП-10 рейтинг населённых пунктов Ленинградской области по публикацим и продажам,cредняя стоимость одного квадратного метра и средняя площадь продаваемых квартир,
       ---продолжительностm публикации объявлений
	   WITH limits AS (
	    SELECT  
	        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
	        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
	        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
	        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
	        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
	    FROM real_estate.flats as f
	    left join real_estate.advertisement as adv on f.id = adv.id
	    ),
	-- Найдём id объявлений, которые не содержат выбросы:
		filtered_id AS(
	    SELECT adv.id
	    FROM real_estate.flats as f  
	    left join real_estate.advertisement as adv on f.id = adv.id
	           WHERE 
	        total_area < (SELECT total_area_limit FROM limits)
	        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
	              AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
	          ),
      start_id as( 
       select city,
       		COUNT(adv.id)as cnt_exp,----количество объявлений
       		round(avg((total_area)::numeric),2) as avg_area,---средняя площадь квартиры
            round(avg((last_price/total_area)::numeric),2) as avg_qmeter,---средняя стоимость квадратного метра
            round(avg((days_exposition)::numeric),2)as long_time_id,---средняя длительность размещения объявления
            round(avg((rooms)::numeric),2)as avg_cnt_rooms,---среднее количсетво комнат в квартирах
            round(avg((floor)::numeric),2)as avg_floor,---средний показатель этажа продаваемых квартир
            (count(adv.id)::real/sum(count(adv.id))over(partition by c.city)*100)::numeric(5,2) as parts---доля снятых объявлений в разрезе количества объявлений по населенным пунктам
       		from real_estate.advertisement as adv
       		left join real_estate.flats as f on adv.id = f.id
       		left join real_estate.city as c on f.city_id = c.city_id
       		left join real_estate.type as t on f.type_id = t.type_id
       where c.city !='Санкт-Петербург'and adv.id IN (SELECT * FROM filtered_id) 
       		group by c.city
       		order by cnt_exp desc
       limit 15
       ),
       final_id as(
       select city,COUNT(adv.id)as cnt_final----количество снятых объявлений
        	from real_estate.advertisement as adv
      		left join real_estate.flats as f on adv.id = f.id
      		left join real_estate.city as c on f.city_id = c.city_id
       where c.city !='Санкт-Петербург'and days_exposition is not NULL and adv.id IN (SELECT * FROM filtered_id)  
       group by city
       order by cnt_final desc
       limit 15
       )  
        select sid.city,sid.cnt_exp,fid.cnt_final,         
        	round((fid.cnt_final::numeric/sid.cnt_exp),4)*100 as parts,---процент снятых объявлений от размещенных в разрезе населенных пунктов
       		NTILE(15) OVER(ORDER BY cnt_exp DESC) as rank_exp,---активность по месяцам размещения объявлений
       		NTILE(15) OVER(ORDER BY cnt_final DESC) as rank_fin,---активность по месяцам снятия объявлений
       		avg_area,avg_qmeter,long_time_id,avg_cnt_rooms,avg_floor,
       		NTILE(15) OVER(ORDER BY long_time_id DESC) as rank_long---длительность активности объявления
       		from start_id as sid 
       		left join final_id as fid on sid.city = fid.city       		
       		  AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
	        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
	    
       		