/*Поступило. Время доставки. Брак.*/
    WITH
    temp_table AS (
        SELECT income.nipchi_id
             , income.region
             /*, income.supply_qual 
             , income.status
             , wres.wgs_status
             , fsr.variant*/
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
             , CASE
                WHEN status = 'Загружено' OR wgs_status = 'Загружено'
                THEN 1
                ELSE 0
               END AS "done"
        FROM income_probes income
   LEFT JOIN wgs_results wres
          ON wres.nipchi_id = income.nipchi_id
   LEFT JOIN frag_seq_results fsr
          ON fsr.nipchi_id = income.nipchi_id        
       WHERE income.income_date BETWEEN '2022-01-24' AND '2022-01-30'
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
  
  /*Исследовано до конца.*/
  WITH
    temp_table AS (
                    SELECT income.nipchi_id
                         , income.region
                         , income.supply_qual 
                         , income.status
                         , wres.wgs_status
                         , fsr.variant
                         , CASE
                            WHEN supply_qual != 'Удовлетворительно' OR status = 'Отбраковано' THEN 1
                            ELSE 0
                           END AS "defect"
                         , CASE
                            WHEN status = 'Загружено' OR wgs_status = 'Загружено' THEN 1
                            ELSE 0
                           END AS "done"
                      FROM income_probes income
                 LEFT JOIN wgs_results wres
                        ON wres.nipchi_id = income.nipchi_id
                 LEFT JOIN frag_seq_results fsr
                        ON fsr.nipchi_id = income.nipchi_id        
                     WHERE fsr.date_end BETWEEN '2022-01-24' AND '2022-01-30'
                     )
    SELECT tt.region AS "Регион"
         , sum(tt.done) AS "Исследовано до конца"
      FROM temp_table tt
  GROUP BY 1
  ORDER BY 1;
  
  /*Раскадровка времязатрат по сделанным*/
  WITH
    temp_table AS (
                    SELECT income.nipchi_id
                         , income.region
                         , income.supply_qual 
                         , income.status
                         , wres.wgs_status
                         , fsr.variant
                         , CASE
                            WHEN supply_qual != 'Удовлетворительно' OR status = 'Отбраковано' THEN 1
                            ELSE 0
                           END AS "defect"
                         , CASE
                            WHEN status = 'Загружено' OR wgs_status = 'Загружено' THEN 1
                            ELSE 0
                           END AS "done"
                      FROM income_probes income
                 LEFT JOIN wgs_results wres
                        ON wres.nipchi_id = income.nipchi_id
                 LEFT JOIN frag_seq_results fsr
                        ON fsr.nipchi_id = income.nipchi_id        
                     WHERE fsr.date_end BETWEEN '2022-01-24' AND '2022-01-30'
                     )
      SELECT tt.region AS "Регион"
           , CASE 
                WHEN (fsr.date_end - income.income_date) <= 3 THEN 'до 3-х дней'
                WHEN (fsr.date_end - income.income_date) >= 5
                 AND (fsr.date_end - income.income_date) <= 7 THEN 'от 5 до 7 дней'
                WHEN (fsr.date_end - income.income_date) > 7 THEN 'от 7 дней'
                ELSE '4 ДНЯ!'
             END AS "Дней до выдачи"
           , count(tt.nipchi_id) AS "Количество проб"
        FROM temp_table tt
   LEFT JOIN income_probes AS income
          ON income.nipchi_id = tt.nipchi_id
   LEFT JOIN frag_seq_results AS fsr
          ON fsr.nipchi_id = tt.nipchi_id
       WHERE tt.done = 1
    GROUP BY 1, 2
    ORDER BY 1;
  
/*Раскладка по методу секвенирования*/
WITH 
    temp_table AS (
                    SELECT income.nipchi_id
                         , income.region
                         , income.supply_qual 
                         , income.status
                         , wres.wgs_status
                         , fsr.variant
                         , CASE
                            WHEN supply_qual != 'Удовлетворительно' OR status = 'Отбраковано' THEN 1
                            ELSE 0
                           END AS "defect"
                         , CASE
                            WHEN status = 'Загружено' OR wgs_status = 'Загружено' THEN 1
                            ELSE 0
                           END AS "done"
                      FROM income_probes income
                 LEFT JOIN wgs_results wres
                        ON wres.nipchi_id = income.nipchi_id
                 LEFT JOIN frag_seq_results fsr
                        ON fsr.nipchi_id = income.nipchi_id        
                     WHERE fsr.date_end BETWEEN '2022-01-24' AND '2022-01-30'
                     )
    SELECT tt.region AS "Регион"
         , count(tt.wgs_status) AS "Исследовано по WGS"
         , COUNT(CASE WHEN tt.wgs_status IS NULL THEN 1 END) AS "Исследовано фрагментно"
      FROM temp_table AS tt
     WHERE tt.done = 1
  GROUP BY 1
  ORDER BY 1;

/*Результаты секвенирования*/
    SELECT income.region
         , fsr.variant
         , count(income.nipchi_id)
      FROM income_probes income
 LEFT JOIN frag_seq_results fsr
        ON fsr.nipchi_id = income.nipchi_id  
     WHERE fsr.date_end BETWEEN '2022-01-24' AND '2022-01-30'
       AND fsr.variant NOT IN ('Не определено', 'Не исследовано')
  GROUP BY 1, 2
  ORDER BY 1;
