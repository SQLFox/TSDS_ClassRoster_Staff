-- ================================================================================================
-- Author:		Scott Minar @ Clear Creek ISD
-- Create date:	2020-02-28
-- Description:	When given the Staff Association interchange containing the Teacher Section Associ-
--				ation records, create matching Staff records as a new Staff Association interchange
--				using data directly from operation eFinance tables (not PEIMS tables).
-- ================================================================================================
-- Usage:		[xml]$in = Get-Content '\\path\084910_000_2020TSDS_202003021822_InterchangeStaffAssociationExtension.xml'
--				$query = "exec ccisd.TSDS_ClassRoster_Staff @in"
--				$filepath = "C:\Users\user\Desktop\084910_000_2020TSDS_202002280000_InterchangeStaffAssociationExtension.xml"
--				[xml]$xml = Invoke-DbaQuery -SqlInstance eFinSQL -Database finplus -Query $query -SqlParameters @{ in = $in.OuterXml } | Select-Object -ExpandProperty xml
--				$xml.Save($filepath)
-- /*==============================================================================================
CREATE PROC [ccisd].[TSDS_ClassRoster_Staff] (
	@in VARCHAR(MAX)
	,@errors BIT = 0
	) AS
--*/
/*
DROP TABLE IF EXISTS #TeacherSectionAssociation;
DROP TABLE IF EXISTS #staff;
DROP TABLE IF EXISTS #race;
DECLARE @in VARCHAR(MAX) = (SELECT BulkColumn FROM OPENROWSET (BULK 'C:\084910_000_2020TSDS_202003021822_InterchangeStaffAssociationExtension.xml', SINGLE_BLOB) x);
DECLARE @errors BIT = 1;
--*/
DECLARE @xmlIn XML = TRY_CONVERT(XML,@in);
DECLARE @xmlOut VARCHAR(MAX);
WITH XMLNAMESPACES(DEFAULT 'http://www.tea.state.tx.us/tsds')
SELECT DISTINCT
	[UniqueStateId] = e.value('(TeacherReference/StaffIdentity/StaffUniqueStateId/text())[1]','VARCHAR(10)')
	INTO #TeacherSectionAssociation
	FROM @xmlIn.nodes('/InterchangeStaffAssociation/TeacherSectionAssociation') AS x(e)
	;
WITH DC077 AS (
	SELECT * FROM (VALUES
		('01','No Degree',0)
		,('02','Bachelor''s',1)
		,('03','Master''s',2)
		,('04','Doctorate',3)
		) x ([Code],[Translation],[dtype])
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
	tsa.UniqueStateId
	,StateId = REPLACE(e.ssn,'-','')
	,FirstName = RTRIM(e.f_name)
	,MiddleName = RTRIM(e.m_name)
	,LastName = RTRIM(e.l_name)
	,GenerationCodeSuffix = DC148.Translation
	,Sex = DC119.Translation
	,DateOfBirth = CONVERT(DATE,e.birthdate)
	,HispanicLatinoEthnicity = CASE p.ethnic_code
		WHEN 'H' THEN 'true'
		ELSE 'false' END
	,HighestLevelOfEducationCompleted = DC077.Translation
	,YearsOfPriorTeachingExperience = TRY_CONVERT(TINYINT,TRY_CONVERT(DECIMAL(3,0),sr2.tcode3))
	,DistrictId = (SELECT TOP 1 dist_id FROM dbo.pem_prof)
	,StaffTypeCode = '1' /*School District Or Charter School Employee*/
	,e.empl_no
	INTO #staff
	FROM #TeacherSectionAssociation tsa
	LEFT JOIN dbo.empuser sr2
		ON sr2.page_no = 32001
		AND tsa.UniqueStateId = sr2.ftext9
	LEFT JOIN dbo.employee e
		ON sr2.empl_no = e.empl_no
	LEFT JOIN dbo.person p
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
	;
WITH DC097 AS (
	SELECT * FROM (VALUES
		('01','American Indian - Alaskan Native','I')
		,('02','Asian','A')
		,('03','Black - African American','B')
		,('04','Native Hawaiian - Pacific Islander','P')
		,('05','White','W')
		) x ([Code],[Translation],[race_code])
	)
SELECT
	er.empl_no
	,RacialCategory = DC097.Translation
	INTO #race
	FROM #staff s
	INNER JOIN dbo.empl_races er
		ON s.empl_no = er.empl_no
	INNER JOIN DC097
		ON er.race_code = DC097.race_code
	;
IF @errors = 0 BEGIN
	SET @xmlOut = (
		SELECT
			[StaffUniqueStateId] = UniqueStateId
			,(SELECT
				[@IdentificationSystem] = 'State'
				,[ID] = StateId
				FOR XML PATH('StaffIdentificationCode'), TYPE
				)
			,[Name/FirstName] = FirstName
			,[Name/MiddleName] = MiddleName
			,[Name/LastSurname] = LastName
			,[Name/GenerationCodeSuffix] = GenerationCodeSuffix
			,[Sex] = Sex
			,[BirthDate] = DateOfBirth
			,[HispanicLatinoEthnicity] = HispanicLatinoEthnicity
			,[Race] = (
				SELECT
					RacialCategory
					FROM #race
					WHERE empl_no = x.empl_no
					FOR XML PATH(''), TYPE
				)
			,[HighestLevelOfEducationCompleted] = HighestLevelOfEducationCompleted
			,[YearsOfPriorTeachingExperience] = YearsOfPriorTeachingExperience
			,[TX-LEAReference/EducationalOrgIdentity/StateOrganizationId] = DistrictId
			,[TX-StaffTypeCode] = StaffTypeCode
			FROM #staff x
			FOR XML PATH('Staff')
		);
	select [xml] = '<?xml version="1.0" encoding="UTF-8"?>'
		+ '<InterchangeStaffAssociation xsi:schemaLocation="http://www.tea.state.tx.us/tsds InterchangeStaffAssociationExtension.xsd" xmlns="http://www.tea.state.tx.us/tsds" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
		+ @xmlOut
		+ '</InterchangeStaffAssociation>
	'	;
	END
ELSE BEGIN
	SELECT
		*
		FROM #staff s
		WHERE StateId IS NULL
			OR FirstName IS NULL
			OR LastName IS NULL
			OR Sex IS NULL
			OR DateOfBirth IS NULL
			OR HighestLevelOfEducationCompleted IS NULL
			OR YearsOfPriorTeachingExperience IS NULL
			OR DistrictId IS NULL
			OR NOT EXISTS (
				SELECT 1 FROM #race
					WHERE empl_no = s.empl_no
				)
	END

