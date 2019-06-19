
-- ȯ�� ������ ��ü ��ȸ
SELECT *
FROM patients;

-- ȯ�ڼ�
SELECT COUNT(*) 
FROM patients;

-- ������ � ������ ���� �Ǵ��� Ȯ��
SELECT DISTINCT(gender)
FROM patients;

-- ���� ȯ���� ��
SELECT COUNT(*)
FROM patients
WHERE gender = 'F';

-- ���� ȯ�ڼ� Ȯ��
SELECT gender, COUNT(*)
FROM patients
GROUP BY gender;

-- expire_flag�� ȯ�ڰ� �������� ��� ����
-- �������� ��� �����.
SELECT expire_flag, COUNT(*)
FROM patients
GROUP BY expire_flag;


----------------------------------------------------------------
-- ���� ����� ���
----------------------------------------------------------------

-- 1. ���� ȯ�� ���� : ������ ù �Կ��Ͽ� 15�� �̻��� ȯ�ڷ� ����

-- ȯ�� ���̺�� �Կ� ���̺� ����
SELECT p.subject_id, p.dob, a.hadm_id,
    a.admittime, p.expire_flag
FROM admissions a
INNER JOIN patients p
ON p.subject_id = a.subject_id;


-- ȯ�ں��� ���� ���� �Է��� ���
-- MIN�Լ��� PARTITION BY Ȱ��
SELECT p.subject_id, p.dob, a.hadm_id,
    a.admittime, p.expire_flag,
    MIN (a.admittime) OVER (PARTITION BY p.subject_id) AS first_admittime
FROM admissions a
INNER JOIN patients p
ON p.subject_id = a.subject_id
ORDER BY a.hadm_id, p.subject_id;

-- ȯ���� ���̴� ������ϰ� ó�� �Կ� �� ��¥�� ���̿� ���� ����
WITH first_admission_time AS
(
  SELECT
      p.subject_id, p.dob, p.gender
      , MIN (a.admittime) AS first_admittime
      , MIN( ROUND( (cast(admittime as date) - cast(dob as date)) / 365.242,2) )
          AS first_admit_age
  FROM patients p
  INNER JOIN admissions a
  ON p.subject_id = a.subject_id
  GROUP BY p.subject_id, p.dob, p.gender
  ORDER BY p.subject_id
)
SELECT
    subject_id, dob, gender
    , first_admittime, first_admit_age
    , CASE
        -- all ages > 89 in the database were replaced with 300
        WHEN first_admit_age > 89
            then '>89'
        WHEN first_admit_age >= 14
            THEN 'adult'
        WHEN first_admit_age <= 1
            THEN 'neonate'
        ELSE 'middle'
        END AS age_group
FROM first_admission_time
ORDER BY subject_id



-- WHERE �� COUNT �Լ��� ����Ͽ� ������� ���
WITH first_admission_time AS
(
  SELECT
      p.subject_id, p.dob, p.gender
      , MIN (a.admittime) AS first_admittime
      , MIN( ROUND( (cast(admittime as date) - cast(dob as date)) / 365.242,2) )
          AS first_admit_age
  FROM patients p
  INNER JOIN admissions a
  ON p.subject_id = a.subject_id
  GROUP BY p.subject_id, p.dob, p.gender
  ORDER BY p.subject_id
)
, age as
(
  SELECT
      subject_id, dob, gender
      , first_admittime, first_admit_age
      , CASE
          -- all ages > 89 in the database were replaced with 300
          -- we check using > 100 as a conservative threshold to ensure we capture all these patients
          WHEN first_admit_age > 100
              then '>89'
          WHEN first_admit_age >= 14
              THEN 'adult'
          WHEN first_admit_age <= 1
              THEN 'neonate'
          ELSE 'middle'
          END AS age_group
  FROM first_admission_time
)
select age_group, gender
  , count(subject_id) as NumberOfPatients
from age
group by age_group, gender;



----------------------------------------------------------------
-- ICU stays
----------------------------------------------------------------

-- ȯ�� ICU �̵��� transfers�� ��ϵ�.
SELECT *
FROM transfers;

-- prev_careunit'�� 'curr_careunit'���� ���� �� ���� �������� �̸�
--  'prev_wardid'�� 'curr_wardid�� ���� �� ���� �ɾ� ������ ID
-- ICU�� �Կ� �� ȯ���� ���� ���̺��ִ� ù ��° �׸��� 'prev_careunit'���� �ƹ��͵� ǥ�õ��� ����.
-- ȯ���� ������ �׸��� 'curr_careunit'�� �ƹ��͵� ����.
-- ���� �� ���� ������ ���� �ƹ��͵����� �׸��� ȯ�ڰ� �� ���� ġ�� �μ����� ����
SELECT *
FROM transfers
where hadm_id = 177678;



----------------------------------------------------------------
-- ICU �Կ� ȯ�ڿ� ���� ������ ���� ���
----------------------------------------------------------------
-- icustays ���̺�


--  'subject_id', 'hadm_id', 'icustay_id', 'intime'�� 'outtime'�� 'icustays'���̺��� �˻�
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime
FROM icustays ie;


-- ȯ�� ���̺��� ����Ͽ� ��� �� ȯ�� ������ �˻�
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime,
    ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) AS age
FROM icustays ie
INNER JOIN patients pat
ON ie.subject_id = pat.subject_id;


-- ���� ȯ�ڿ� �Ż��Ƹ� ����
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime,
    ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) AS age,
    CASE
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 1
            THEN 'neonate'
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 14
            THEN 'middle'
        -- all ages > 89 in the database were replaced with 300
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) > 100
            then '>89'
        ELSE 'adult'
        END AS ICUSTAY_AGE_GROUP
FROM icustays ie
INNER JOIN patients pat
ON ie.subject_id = pat.subject_id;


-- �Կ� ǥ�� ���������ν� ȯ�ڰ� ICU�� �����ϱ� ���� �� ü�� �Ⱓ �� Ȯ��
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime,
    ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) as age,
    ROUND((cast(ie.intime as date) - cast(adm.admittime as date))/365.242, 2) as preiculos,
    CASE
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 1
            THEN 'neonate'
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 14
            THEN 'middle'
        -- all ages > 89 in the database were replaced with 300
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) > 100
            THEN '>89'
        ELSE 'adult'
        END AS ICUSTAY_AGE_GROUP
FROM icustays ie
INNER JOIN patients pat
ON ie.subject_id = pat.subject_id
INNER JOIN admissions adm
ON ie.hadm_id = adm.hadm_id;


-- ������ �ش�Ǵ� ��� ȯ���� ��� ����
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime, adm.deathtime,
    ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) as age,
    ROUND((cast(ie.intime as date) - cast(adm.admittime as date))/365.242, 2) AS preiculos,
    CASE
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 1
            THEN 'neonate'
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 14
            THEN 'middle'
        -- all ages > 89 in the database were replaced with 300
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) > 100
            THEN '>89'
        ELSE 'adult'
        END AS ICUSTAY_AGE_GROUP
FROM icustays ie
INNER JOIN patients pat
ON ie.subject_id = pat.subject_id
INNER JOIN admissions adm
ON ie.hadm_id = adm.hadm_id;


-- �׷� ���� ȯ�ڰ� �������ִ� ���� �߻��� ����ڸ� �˻�
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime, adm.deathtime,
    ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) AS age,
    ROUND((cast(ie.intime as date) - cast(adm.admittime as date))/365.242, 2) AS preiculos,
    CASE
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 1
            THEN 'neonate'
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 14
            THEN 'middle'
        -- all ages > 89 in the database were replaced with 300
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) > 100
            THEN '>89'
        ELSE 'adult'
        END AS ICUSTAY_AGE_GROUP,
    -- note that there is already a "hospital_expire_flag" field in the admissions table which you could use
    CASE
        WHEN adm.hospital_expire_flag = 1 then 'Y'
    ELSE 'N'
    END AS hospital_expire_flag
FROM icustays ie
INNER JOIN patients pat
ON ie.subject_id = pat.subject_id
INNER JOIN admissions adm
ON ie.hadm_id = adm.hadm_id;

-- ICU ������ �󸶳� ���� ����ڰ� �߻��ߴ��� Ȯ��
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime, adm.deathtime,
    ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) AS age,
    ROUND((cast(ie.intime as date) - cast(adm.admittime as date))/365.242, 2) AS preiculos,
    CASE
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 1
            THEN 'neonate'
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 14
            THEN 'middle'
        -- all ages > 89 in the database were replaced with 300
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) > 100
            THEN '>89'
        ELSE 'adult'
        END AS ICUSTAY_AGE_GROUP,
    -- note that there is already a "hospital_expire_flag" field in the admissions table which you could use
    CASE
        WHEN adm.hospital_expire_flag = 1 then 'Y'           
    ELSE 'N'
    END AS hospital_expire_flag,
    -- note also that hospital_expire_flag is equivalent to "Is adm.deathtime not null?"
    CASE
        WHEN adm.deathtime BETWEEN ie.intime and ie.outtime
            THEN 'Y'
        -- sometimes there are typographical errors in the death date, so check before intime
        WHEN adm.deathtime <= ie.intime
            THEN 'Y'
        WHEN adm.dischtime <= ie.outtime
            AND adm.discharge_location = 'DEAD/EXPIRED'
            THEN 'Y'
        ELSE 'N'
        END AS ICUSTAY_EXPIRE_FLAG
FROM icustays ie
INNER JOIN patients pat
ON ie.subject_id = pat.subject_id
INNER JOIN admissions adm
ON ie.hadm_id = adm.hadm_id;