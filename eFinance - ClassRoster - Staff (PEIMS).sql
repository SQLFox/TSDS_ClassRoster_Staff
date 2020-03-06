-- ================================================================================================
-- Author:		Scott Minar @ Clear Creek ISD
-- Create date:	2020-03-06
-- Description:	Collects data required by TSDS ClassRoster Staff records using data from the PEIMS
--				tables. You must run the PEIMS Personnel Load in eFinance to populate those tables.
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
		('01','American Indian - Alaskan Native','I','indian')
		,('02','Asian','A','asian')
		,('03','Black - African American','B','black')
		,('04','Native Hawaiian - Pacific Islander','P','hawaiian')
		,('05','White','W','white')
		) x ([Code],[Translation],[race_code],[race])
	)
,DC119 AS (
	SELECT * FROM (VALUES
		('01','Female','F')
		,('02','Male','M')
		) x ([Code],[Translation],[sex])
	)
,DC148 AS (
	SELECT * FROM (VALUES
		('01','Jr','JR','1')
		,('02','Sr','SR','2')
		,('03','II','II','3')
		,('04','III','III','4')
		,('05','IV','IV','5')
		,('06','V','V','6')
		,('07','VI','VI','7')
		,('08','VII','VII','8')
		,('09','VIII','VIII','9')
		,('10','I',NULL,'A')
		,('11','IX',NULL,'B')
		,('12','X',NULL,'C')
		) x ([Code],[Translation],[name_suffix],[gen_code])
	)
SELECT
	Employee = p40.empl_no
	,UniqueStateId = RTRIM(p43.tx_uniq_staff_id)
	,StateId = REPLACE(p40.staff_id,'-','')
	,FirstName = RTRIM(p40.f_name)
	,MiddleName = ISNULL(RTRIM(p40.m_name),'')
	,LastName = RTRIM(p40.l_name)
	,GenerationCodeSuffix = ISNULL(DC148.Translation,'')
	,Sex = DC119.Translation
	,DateOfBirth = CONVERT(DATE,STUFF(STUFF(p43.dob,5,0,'/'),3,0,'/'),101)
	,HispanicLatinoEthnicity = CASE p43.hispanic
		WHEN '1' THEN 'true'
		ELSE 'false' END
	,Race = ISNULL(STUFF((
		SELECT
			',' + DC097.Translation
			FROM (VALUES
				('indian',p43.indian)
				,('asian',p43.asian)
				,('black',p43.black)
				,('hawaiian',p43.hawaiian)
				,('white',p43.white)
				) x ([race],[value])
			INNER JOIN DC097
				ON x.race = DC097.race
			WHERE x.[value] = '1'
			FOR XML PATH('')
		),1,1,''),'')
	,HighestLevelOfEducationCompleted = ISNULL(DC077.Translation,'')
	,YearsOfPriorTeachingExperience = ISNULL(CONVERT(TINYINT,p40.t_years),'')
	,DistrictId = ISNULL((SELECT TOP 1 dist_id FROM dbo.pem_prof),'')
	,StaffTypeCode = '1'
	FROM dbo.pem_040 p40
	INNER JOIN dbo.pem_043 p43
		ON p40.staff_id = p43.staff_id
	LEFT JOIN DC077
		ON p40.high_degree = DC077.dtype
	LEFT JOIN DC119
		ON p40.sex = DC119.sex
	LEFT JOIN DC148
		ON p40.gen_code = DC148.name_suffix
	;
	