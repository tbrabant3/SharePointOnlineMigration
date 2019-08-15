# SharePointOnlineMigration Tool
These scripts allow you to transfer data from many SharePoint sites in one tenant, and output the data into a single new site on a different tenant. It keeps all folder structures intact.

### How it works
The tool downloads all of the files (In CSV format) from the specified libraries of the sites on to the local hard drive. It goes through **n** amount of sites then uploads them to the new tenant in a different PowerShell window. The new window is because of the limitations around the SharePoint PnP module. While there is a way to disconnect from the connection, it is unrealiable which is why a new PowerShell window is created to open the new connection to the new tenant. There is an upload limit of 250mb for a single file as well. Any files that have issues or are too large are caught and marked in a log file called logs.txt which will identify the name of the file. Go into the original SharePoint site, download it, and reupload it to the new site manually.  




### Instructions

* Step 1: Download both scripts to the same folder.
* Step 2: Navigate to the folder in which you saved the files to within a PowerShell window
* Step 3: Open the files in your favorite text editor and modify the variables
    * Note: SharePointMigration.ps1 should have the ORIGINAL tenant information
    * Note: UploadFiles.ps1 should have the NEW tenant information
* Step 4. Run SharePointMigration.ps1
NOTE: You do not need to run UploadFiles.ps1, SharePointMigration.ps1 calls it on its own
~~~powershell
.\SharePointMigration.ps1 -SourceList "..\ExcelFiles\listofsites.csv" 
~~~


### Other Notes

Feel free to modify the code to replicate sites file for file. The current script is setup to achieve a specific business purpose but can easily be modified to accomplish many other SharePoint file tasks through the backend/PowerShell.
