-- ================================================================================================
-- Author:		Scott Minar @ Clear Creek ISD
-- Create date:	2020-03-05
-- Description:	Collects data required by TSDS ClassRoster Staff records using data directly from
--				operation eFinance tables (not PEIMS tables).
--
--				Designed for use with Clear Creek's ClassRoster Staff generator at 
--				https://github.com/SQLFox/TSDS_ClassRoster_Staff
-- /*==============================================================================================
WITH DC077 AS (
	SELECT * FROM (VALUES
		('01','No Degree','0')
		,('02','Bachelor''s','1')
		,('03','Master''s','2')
		,('04','Doctorate','3')
		) x ([Code],[Translation],[dtype])
	)
,DC097 AS (
	SELECT * FROM (VALUES
		('01','American Indian - Alaskan Native','I')
		,('02','Asian','A')
		,('03','Black - African American','B')
		,('04','Native Hawaiian - Pacific Islander','P')
		,('05','White','W')
		) x ([Code],[Translation],[race_code])
	)
,DC119 AS (
	SELECT * FROM (VALUES
		('01','Female','F')
		,('02','Male','M')
		) x ([Code],[Translation],[sex])
	)
,DC148 AS (
	SELECT * FROM (VALUES
		('01','Jr','JR')
		,('02','Sr','SR')
		,('03','II','II')
		,('04','III','III')
		,('05','IV','IV')
		,('06','V','V')
		,('07','VI','VI')
		,('08','VII','VII')
		,('09','VIII','VIII')
		,('10','I',NULL)
		,('11','IX',NULL)
		,('12','X',NULL)
		) x ([Code],[Translation],[name_suffix])
	)
SELECT
	Employee = e.empl_no
	,UniqueStateId = RTRIM(sr2.ftext9)
	,StateId = REPLACE(e.ssn,'-','')
	,FirstName = RTRIM(e.f_name)
	,MiddleName = ISNULL(RTRIM(e.m_name),'')
	,LastName = RTRIM(e.l_name)
	,GenerationCodeSuffix = ISNULL(DC148.Translation,'')
	,Sex = DC119.Translation
	,DateOfBirth = CONVERT(DATE,e.birthdate)
	,HispanicLatinoEthnicity = CASE p.ethnic_code
		WHEN 'H' THEN 'true'
		ELSE 'false' END
	,Race = ISNULL(STUFF((
		SELECT
			',' + DC097.Translation
			FROM dbo.empl_races er
			INNER JOIN DC097
				ON er.race_code = DC097.race_code
			WHERE er.empl_no = e.empl_no
			FOR XML PATH('')
		),1,1,''),'')
	,HighestLevelOfEducationCompleted = ISNULL(DC077.Translation,'')
	,YearsOfPriorTeachingExperience = ISNULL(CONVERT(TINYINT,CONVERT(DECIMAL(3,0),sr2.tcode3)),'')
	,DistrictId = ISNULL((SELECT TOP 1 dist_id FROM dbo.pem_prof),'')
	,StaffTypeCode = '1' /*School District Or Charter School Employee*/
	FROM dbo.employee e
	INNER JOIN dbo.empuser sr2
		ON e.empl_no = sr2.empl_no
		AND sr2.page_no = 32001
	INNER JOIN dbo.person p
		ON e.empl_no = p.empl_no
	LEFT JOIN (
		SELECT
			empl_no
			,dtype = MAX(dtype)
			FROM dbo.emp_degree
			WHERE highest = '*'
			GROUP BY empl_no
			HAVING COUNT(*) = 1
		) ed
		ON e.empl_no = ed.empl_no
	LEFT JOIN DC077
		ON ed.dtype = DC077.dtype
	LEFT JOIN DC119
		ON p.sex = DC119.sex
	LEFT JOIN DC148
		ON e.name_suffix = DC148.name_suffix
	WHERE sr2.ftext9 IS NOT NULL
	;


