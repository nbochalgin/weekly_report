DROP TABLE IF EXISTS myvar;

SELECT
    ('2022-01-31')::date AS period_start,
    ('2022-02-06')::date AS period_end
INTO
    TEMP TABLE myvar;

/*�����������, ����������. ��������� �� ������� ��������.*/
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
                WHEN supply_qual != '�����������������'
                  OR status in ('�����������', '�����������. ������������ ���������', '����������', '�����������')
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
    SELECT tt.region AS "������"
         , count(tt.nipchi_id) AS "���������"
         , sum(tt.less_than_4) AS "�� 4 ����"
         , sum(tt."5_7") AS "5-7 ����"
         , sum(more_than_7) AS "����� 7 ����"
         , sum(tt.defect) AS "�����������"
      FROM temp_table tt
  GROUP BY 1
  ORDER BY 1;
  
/*����������� �� �����. ��������� �� �������, ��������� � ��������.*/
WITH
    temp_table AS (
        SELECT income.nipchi_id
             , income.region
             , wres.wgs_status
             , income.status
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
                WHEN lower(fsr.variant) ~ '����'
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
                WHEN status IN ('���������', '��������') OR wgs_status = '���������'
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
    SELECT tt.region AS "������"
         , sum(tt.done) AS "����������� �� �����"
         , sum(tt.less_than_4) AS "�� 4 ����"
         , sum(tt."5_7") AS "5-7 ����"
         , sum(tt.more_than_7) AS "����� 7 ����"
         , count(tt.wgs_status) AS "wgs"
         , count(CASE WHEN tt.wgs_status IS NULL THEN 1 END) AS "frag"
         , sum(tt.delta) AS "������"
         , sum(tt.omicron) AS "�������"
         , sum(tt.other) AS "������"
      FROM temp_table tt
     WHERE tt.done = 1
  GROUP BY 1
  ORDER BY 1;
  
/*������������� ���� � 2022-01-01. ���������, �����������, ����������� �� �����. ��������� �� ��������.*/
WITH
    temp_table AS (
        SELECT income.nipchi_id
             , income.region
             , wres.wgs_status
             , income.income_date
             , fsr.date_end
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
                WHEN lower(fsr.variant) ~ '����'
                THEN 1
                ELSE 0
               END AS "other"
             , CASE
                WHEN supply_qual != '�����������������'
                  OR status in ('�����������', '�����������. ������������ ���������', '����������', '�����������')
                THEN 1
                ELSE 0
               END AS "defect"
             , CASE
                WHEN status IN ('���������', '��������') OR wgs_status = '���������'
                THEN 1
                ELSE 0
               END AS "done"
        FROM myvar
           , income_probes income
   LEFT JOIN wgs_results wres
          ON wres.nipchi_id = income.nipchi_id
   LEFT JOIN frag_seq_results fsr
          ON fsr.nipchi_id = income.nipchi_id        
       WHERE income.income_date BETWEEN '2022-01-01' AND myvar.period_end
          OR fsr.date_end BETWEEN '2022-01-01' AND myvar.period_end
    )
    SELECT tt.region AS "������"
         , count(CASE
                  WHEN tt.income_date BETWEEN '2022-01-01' AND myvar.period_end
                  THEN 1
                 END) AS "���������"
         , count(CASE
                  WHEN tt.income_date BETWEEN '2022-01-01' AND myvar.period_end 
                   AND tt.defect = 1
                  THEN 1
                 END) AS "�����������"
         , count(CASE
                  WHEN tt.date_end BETWEEN '2022-01-01' AND myvar.period_end 
                   AND tt.done = 1
                  THEN 1
                 END) AS "����������� �� �����"
         , sum(CASE
                WHEN tt.date_end BETWEEN '2022-01-01' AND myvar.period_end 
                THEN tt.delta
               END) AS "������"
         , sum(CASE
                WHEN tt.date_end BETWEEN '2022-01-01' AND myvar.period_end 
                THEN tt.omicron
               END) AS "�������"
         , sum(CASE
                WHEN tt.date_end BETWEEN '2022-01-01' AND myvar.period_end 
                THEN tt.other
               END) AS "������"
      FROM myvar
         , temp_table tt
  GROUP BY 1
  ORDER BY 1; 

DROP TABLE IF EXISTS myvar;
