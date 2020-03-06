<# ================================================================================================
-- Author:		Scott Minar @ Clear Creek ISD
-- Create date:	2020-03-05
-- Description:	When given the Staff Association interchange containing the Teacher Section Associ-
--				ation records, create matching Staff records as a new Staff Association interchange
--				using a data file saved from eFinance.
--
--				For more information, visit https://github.com/SQLFox/TSDS_ClassRoster_Staff
-- ============================================================================================= #>
Add-Type -AssemblyName System.Windows.Forms
$getFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Filter = 'Staff File|*_InterchangeStaffAssociationExtension.xml'
    Title = 'Open ClassRoster Staff File from SIS'
}
$getFile.ShowDialog() | Out-Null
if ($getFile.FileName) {
    [xml]$sis = Get-Content $getFile.FileName
}
if ($sis.InterchangeStaffAssociation.TeacherSectionAssociation.Length -gt 0) {
    Write-Progress -Activity 'Building ClassRoster Staff records...' -Status ('Found ' + $sis.InterchangeStaffAssociation.TeacherSectionAssociation.Length.ToString() + ' TeacherSectionAssociation records.')
} else {
    Write-Host ('  TeacherSectionAssociation records not found. ')
    exit
}
$teachers = $sis.InterchangeStaffAssociation.TeacherSectionAssociation.TeacherReference.StaffIdentity.StaffUniqueStateId | Select -Unique
Write-Progress -Activity 'Building ClassRoster Staff records...' -Status ('Found ' + $teachers.Count.ToString() + ' unique teachers.')
$getFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Filter = 'Employee Data File|*.txt'
    Title = 'Open employee data file from eFinance'
}
$getFile.ShowDialog() | Out-Null
if ($getFile.FileName) {
    $eFin = Import-Csv -Delimiter "`t" -Path $getFile.FileName
}
if ($eFin.UniqueStateId.Count -gt 0) {
    Write-Progress -Activity 'Building ClassRoster Staff records...' -Status ('Found ' + $eFin.Count.ToString() + ' eFinance employee records.')
} else {
    Write-Host ('  eFinance employee records not found. ')
    exit
}
$employee = @{}
$eFin | ForEach-Object {
    $employee[$_.UniqueStateId] = $_
}
[xml]$x = New-Object System.Xml.XmlDocument
$x.AppendChild($x.CreateXmlDeclaration("1.0","UTF-8",$null)) | Out-Null
$isa = $x.AppendChild($x.CreateElement('InterchangeStaffAssociation'))
$xsi = $x.CreateAttribute('xsi','schemaLocation','http://www.w3.org/2001/XMLSchema-instance')
$xsi.InnerText = 'http://www.tea.state.tx.us/tsds InterchangeStaffAssociationExtension.xsd'
$isa.SetAttributeNode($xsi) | Out-Null
$isa.SetAttribute('xmlns','http://www.tea.state.tx.us/tsds')
foreach ($uid in $teachers) {
    $data = $employee[$uid]
    Write-Progress -Activity 'Building ClassRoster Staff records...' -Status ('' + ($teachers.IndexOf($uid) + 1) + ' of ' + $teachers.Count + ' [' + $data.Employee + ']') -PercentComplete ($teachers.IndexOf($uid)/$teachers.Count*100)
    if ($data) {
        $staff = $isa.AppendChild($x.CreateElement('Staff'))
        $staff.AppendChild($x.CreateElement('StaffUniqueStateId')).AppendChild($x.CreateTextNode($data.UniqueStateId)) | Out-Null
        $e = $staff.AppendChild($x.CreateElement('StaffIdentificationCode'))
        $e.SetAttribute('IdentificationSystem','State')
        $e.AppendChild($x.CreateElement('ID')).AppendChild($x.CreateTextNode($data.StateId)) | Out-Null
        $e = $staff.AppendChild($x.CreateElement('Name'))
        $e.AppendChild($x.CreateElement('FirstName')).AppendChild($x.CreateTextNode($data.FirstName)) | Out-Null
        if ($data.MiddleName) {
            $e.AppendChild($x.CreateElement('MiddleName')).AppendChild($x.CreateTextNode($data.MiddleName)) | Out-Null
        }
        $e.AppendChild($x.CreateElement('LastSurname')).AppendChild($x.CreateTextNode($data.LastName)) | Out-Null
        if ($data.GenerationCodeSuffix) {
            $e.AppendChild($x.CreateElement('GenerationCodeSuffix')).AppendChild($x.CreateTextNode($data.GenerationCodeSuffix)) | Out-Null
        }
        $staff.AppendChild($x.CreateElement('Sex')).AppendChild($x.CreateTextNode($data.Sex)) | Out-Null
        $staff.AppendChild($x.CreateElement('BirthDate')).AppendChild($x.CreateTextNode($data.DateOfBirth)) | Out-Null
        $staff.AppendChild($x.CreateElement('HispanicLatinoEthnicity')).AppendChild($x.CreateTextNode($data.HispanicLatinoEthnicity)) | Out-Null
        $e = $staff.AppendChild($x.CreateElement('Race'))
        foreach ($race in $data.Race -split ',') {
            $e.AppendChild($x.CreateElement('RacialCategory')).AppendChild($x.CreateTextNode($race)) | Out-Null
        }
        if ($data.HighestLevelOfEducationCompleted) {
            $staff.AppendChild($x.CreateElement('HighestLevelOfEducationCompleted')).AppendChild($x.CreateTextNode($data.HighestLevelOfEducationCompleted)) | Out-Null
        }
        if ($data.YearsOfPriorTeachingExperience) {
            $staff.AppendChild($x.CreateElement('YearsOfPriorTeachingExperience')).AppendChild($x.CreateTextNode($data.YearsOfPriorTeachingExperience)) | Out-Null
        }
        $staff.AppendChild($x.CreateElement('TX-LEAReference')).AppendChild($x.CreateElement('EducationalOrgIdentity')).AppendChild($x.CreateElement('StateOrganizationId')).AppendChild($x.CreateTextNode($data.DistrictId)) | Out-Null
        $staff.AppendChild($x.CreateElement('TX-StaffTypeCode')).AppendChild($x.CreateTextNode($data.StaffTypeCode)) | Out-Null
    }
}
$filepath = [Environment]::GetFolderPath('Desktop') + '\' + $data.DistrictId + '_000_2020TSDS_' + (Get-Date -Format 'yyyyMMddHHmm') + '_InterchangeStaffAssociationExtension.xml'
$x.Save($filepath)
Write-Host ('  ' + $filepath + ' created. ')