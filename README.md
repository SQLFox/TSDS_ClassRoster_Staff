# TSDS_ClassRoster_Staff
These scripts are intended to help you build the Staff records needed for the TSDS ClassRoster 2020 Winter submission. The vast majority of the submission data will be handled by your SIS, but there is just enough Staff data required that many SISs won't be able to build everything you need.

The script here operates on the principle that the TeacherSectionAssociation records created by the SIS control which employees need Staff records. That means you will need the StaffAssociationInterchange file created by your SIS to run this script. If your SIS offers the option to build Staff records, but does not have all of the required information, you probably don't want to include them—duplicate records will just make things more confusing to troubleshoot.

# So how do I use it?
## 1. Figure out which SQL script you need
There are currently two options for getting your raw staff data out of your ERP:
* **eFinance - ClassRoster - Staff (Live).sql**  
Use this one if you want your Staff records based on the current, production eFinance data. This means that you don't need to run any PEIMS data loads for this submission. The only thing it reads from the PEIMS tables is your district's PEIMS id. **IMPORTANT:** This option assumes that all of your employees are employed by the district.
* **eFinance - ClassRoster - Staff (PEIMS).sql**  
Use this one if you want your Staff records based on the eFinance PEIMS tables. This means that you will run the Personnel Load to populate those tables, and make any necessary corrections there.
## 2. Review the code
You (or the appropriate party within your district) **must** review the SQL script you chose above and the main script, ClassRoster_Staff.ps1. You don't necessarily need to verify that it's "right", but you do need to verify that it's "safe". You have no idea what nefarious plans I have for your data—**DO NOT TRUST ME**.  
  
The code is all downloaded together in a zip file using the buttons above:
![download screenshot](/download.PNG)
## 3. Get the raw staff data out of your ERP
* If your district has the ability to run queries against the ERP database, run the SQL script you chose and save the results as a tab delimited text file.
* If you do not have the ability to run queries against the ERP database (e.g. your system is hosted by the vendor), provide the SQL script you chose to the vendor and ask them to return the results to you as a tab delimited text file.
## 4. Run it!
  1. Extract the ClassRoster_Staff.ps1 file (I recommend just putting it on your desktop)
  1. Open PowerShell  
*Hit the Start button, start typing "powershell", and click the app "Windows PowerShell"*
  1. Enter the path & name of the script. If you put it on your desktop, you can use:  
`&([Environment]::GetFolderPath('Desktop') + '\ClassRoster_Staff.ps1')`
  1. First it'll ask you for the StaffAssociationInterchange file created by your SIS
  1. Then it'll ask you for the data file from your ERP
  1. It will create a new StaffAssociationInterchange file, containing only Staff records, on your desktop
## 5. Add the new XML file to the files created by your SIS and load your submission to TSDS
You will now have *two* StaffAssociationInterchange files—one with your TeacherSectionAssociation records and one with your Staff records. That's okay—TSDS knows how to handle it, as long as the Staff file has an earlier datestamp than the TeacherSectionAssociation file. That's why the datestamp on the new file looks like it's from 1920.
## 6. Clean-up
The XML files and the ERP data file have **lots** of tasty PII in them, and you do not want those files laying around on your computer. Archive whatever your district feels is necessary in the appropriate secure network storage, and delete the files from your PC. The script files (the .ps1 and .sql files) don't contain any sensitive information, but you shouldn't need them again after you finish this submission, so you can delete those, too.
# That's it!
I can't promise it'll work for you. I can't promise I'll fix it if it doesn't work. I can't promise that running this code won't burn down your datacenter.  
But I did build it in such a way that I hope it'll work for everyone, and if you do find a problem with it, please let me know and I'll see what I can do. Unless it burns down your datacenter—then don't call me.  
Brought to you by the taxpayers of the state of Texas and Clear Creek ISD.
