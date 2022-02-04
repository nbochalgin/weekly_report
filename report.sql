DROP TABLE IF EXISTS myvar;

SELECT
    ('2022-01-24')::date AS period_start,
    ('2022-01-30')::date AS period_end
INTO
    TEMP TABLE myvar;

/*Поступление, отбраковка. Раскладка по времени доставки.*/
WITH
    temp_table AS (
        SELECT income.nipchi_id
             , income.region
             , CASE 
                WHEN (income.income_date - income.material_take_date) <= 4
                THEN 1
                ELSE 0
               END AS "less_than_4"
             , CASE 
                WHEN (income.income_date - income.material_take_date) >= 5
                 AND (income.income_date - income.material_take_date) <= 7
                THEN 1
                ELSE 0
               END AS "5_7"
             , CASE 
                WHEN (income.income_date - income.material_take_date) > 7
                THEN 1
                ELSE 0
               END AS "more_than_7"
             , CASE
                WHEN supply_qual != 'Удовлетворительно'
                  OR status in ('Отбраковано', 'Отбраковано. Недостаточно материала', 'Отбракован', 'отбраковано')
                THEN 1
                ELSE 0
               END AS "defect"
        FROM myvar
           , income_probes income
   LEFT JOIN wgs_results wres
          ON wres.nipchi_id = income.nipchi_id
   LEFT JOIN frag_seq_results fsr
          ON fsr.nipchi_id = income.nipchi_id        
       WHERE income.income_date BETWEEN myvar.period_start AND myvar.period_end
    )
    SELECT tt.region AS "Регион"
         , count(tt.nipchi_id) AS "Поступило"
         , sum(tt.less_than_4) AS "до 4 дней"
         , sum(tt."5_7") AS "5-7 дней"
         , sum(more_than_7) AS "более 7 дней"
         , sum(tt.defect) AS "отбраковано"
      FROM temp_table tt
  GROUP BY 1
  ORDER BY 1;
  
/*Исследовано до конца. Раскладка по времени, платформе и варианту.*/
WITH
    temp_table AS (
        SELECT income.nipchi_id
             , income.region
             , wres.wgs_status
             , CASE 
                WHEN lower(fsr.variant) ~ 'omicron'
                THEN 1
                ELSE 0
               END AS "omicron"
             , CASE 
                WHEN lower(fsr.variant) ~ 'delta'
                THEN 1
                ELSE 0
               END AS "delta"
             , CASE 
                WHEN lower(fsr.variant) ~ 'иной'
                THEN 1
                ELSE 0
               END AS "other"
             , CASE 
                WHEN (fsr.date_end - income.income_date) <= 4
                THEN 1
                ELSE 0
               END AS "less_than_4"
             , CASE 
                WHEN (fsr.date_end - income.income_date) >= 5
                 AND (fsr.date_end - income.income_date) <= 7
                THEN 1
                ELSE 0
               END AS "5_7"
             , CASE 
                WHEN (fsr.date_end - income.income_date) > 7
                THEN 1
                ELSE 0
               END AS "more_than_7"
             , CASE
                WHEN status = 'Загружено' OR wgs_status = 'Загружено'
                THEN 1
                ELSE 0
               END AS "done"
        FROM myvar
           , income_probes income
   LEFT JOIN wgs_results wres
          ON wres.nipchi_id = income.nipchi_id
   LEFT JOIN frag_seq_results fsr
          ON fsr.nipchi_id = income.nipchi_id        
       WHERE fsr.date_end BETWEEN myvar.period_start AND myvar.period_end
    )
    SELECT tt.region AS "Регион"
         , sum(tt.done) AS "Исследовано до конца"
         , sum(tt.less_than_4) AS "до 4 дней"
         , sum(tt."5_7") AS "5-7 дней"
         , sum(tt.more_than_7) AS "более 7 дней"
         , count(tt.wgs_status) AS "wgs"
         , count(CASE WHEN tt.wgs_status IS NULL THEN 1 END) AS "frag"
         , sum(tt.delta) AS "дельта"
         , sum(tt.omicron) AS "омикрон"
         , sum(tt.other) AS "другой"
      FROM temp_table tt
     WHERE tt.done = 1
  GROUP BY 1
  ORDER BY 1;

DROP TABLE IF EXISTS myvar;
