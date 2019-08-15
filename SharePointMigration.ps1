<######
SharePoint Online Migration Script
Tyler Brabant © 2019
SharePointMigration.ps1

Instructions:

1. Examine the parameters and change if necessary. The script defaults to saving the files to a folder
   that is rooted in the documents folder for easy finding.
2. Examine the script level variables and change them accordingly
3. Run the script by navigating to the folder containing it in powershell
   Then do ".\SharePointMigration4.ps1 -SourceList 'path to the excel file with the list of sites' "
   You can tack on -TempLocation if you want to change the location of the folder to download to or
   or leave it as the Documents folder
4. This script will call UploadFiles.ps1 which is required to be in the same location as SharePointMigration.ps1

#######>

param(
    [string]$SourceList = $(throw "A source list of sites is required."),
    [string]$TempLocation = "$HOME\Documents"
)

#----- Script Level Varaibles ---------
# List of the Libraries to download, these two will cover most, if not all
$script:Libraries = @("Shared Documents", "SiteAssets")
# Folder that will be created
$script:RootFolderName = "YammerSitesFiles"
# Username with access to all of the sites for downloading
$script:UsernameSPO = "** Original Tenant Username **"
# Number of sites to batch out. Up this number if your sites aren't large
# Decrease this number if your sites are large.
$script:NumberOfSitesToBatch = 100
# -----------------------------------------

# Create the temporary folder for downloading
if (!(Test-Path -Path "$TempLocation\$script:RootFolderName")){
    Write-Host -f White "Creating new temporary folder: $TempLocation\$script:RootFolderName"
    $FinalPath = New-Item -Path $TempLocation -ItemType "directory" -Name $script:RootFolderName
} else {
    Write-Host -f Yellow "Deleting existing folder: $TempLocation\$script:RootFolderName"
    Remove-Item -Path "$TempLocation\$script:RootFolderName" -Recurse
    $FinalPath = New-Item -Path $TempLocation -ItemType "directory" -Name $script:RootFolderName
}

# Importing CSV files
Try {
    $Sites = Import-Csv $SourceList
} Catch {
    # Write-Host $_.Exception.Message
    Write-Host -f Yellow "Error importing the CSV File.`nPlease chack the path and file extension."
    exit
}

# Function to recursively go through files and download them in the correct order
# Download all the files in the folder
# Then, find all folders and create a local copy of the folder
# Then, go into the folder and download those files
# Recurse
function ProcessItems($RelativeURL, $FolderToSave){
    foreach($File in (Get-PnPFolderItem -FolderSiteRelativeUrl $RelativeURL -ItemType File)){
        Get-PnPFile -Url $("$RelativeURL/" + $File.Name) -Path $FolderToSave -AsFile  
    }
    foreach($Folder in (Get-PnPFolderItem -FolderSiteRelativeUrl $RelativeURL -ItemType Folder)){
        # Do not include forms folders as they do not contain user data
        if($Folder.Name -ne "Forms"){
            if (!(Test-Path -Path ("$FolderToSave\" + $Folder.Name))) {
                $NewPath =  New-Item -Path $FolderToSave -ItemType "directory" -Name $Folder.Name
            } else {
                $NewPath = "$FolderToSave\" + $Folder.Name
            }
            ProcessItems -RelativeURL $("$RelativeUrl/" + $Folder.Name) -FolderToSave $NewPath
        }
    }
}

# Create the credential variable to login to the sites
$CCreds = Get-Credential -Message "Enter the -c creds for the username that has access to all sites" -UserName $script:UsernameSPO
$CountOfSites = 0

# Goes through each site
Foreach($Site in $Sites){
    # Connects to a $Site in $Sites
    try{
        Connect-PnPOnline -Url $($Site.Sites) -Credentials $CCreds
    } catch {
        write-host -f red "Could not connect to ", $($Site.Sites)
        continue
    }

    # Increase the count AFTER login to only include sites that are active
    $CountOfSites++
    $SiteName = ($Site -split "sites/" -replace ".$")[1]
    Write-Host -f White "$CountOfSites | Downloading site: $SiteName"

    # Creates the local path for the files
    if (!(Test-Path -Path "$FinalPath\$SiteName")){
        $SiteLocation = New-Item -Path $FinalPath -ItemType "directory" -Name $SiteName
    } else {
        Remove-Item -Path "$FinalPath\$SiteName" -Recurse
        $SiteLocation = New-Item -Path $FinalPath -ItemType "directory" -Name $SiteName
    }

    # Goes through the Libraries defined in the array above
    Foreach($Library in $script:Libraries){
        if (!(Test-Path -Path ("$SiteLocation\" + $Library))) {
            $LibraryLocation =  New-Item -Path $SiteLocation -ItemType "directory" -Name $Library
        } else {
            $LibraryLocation = "$SiteLocation\" + $Library
        }
        ProcessItems -RelativeURL $Library -FolderToSave $LibraryLocation
    }

    if((($CountOfSites % $script:NumberOfSitesToBatch) -eq 0) -or ($Site -eq $Sites[-1])){
        write-host -f white "$script:NumberOfSitesToBatch sites completed"
        Start-Process powershell ("$PSScriptRoot\UploadFiles.ps1 -UploadLocation $FinalPath") -Wait
    }   
     
}