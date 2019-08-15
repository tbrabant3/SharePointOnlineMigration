<#####
SharePoint Online Migration Script
Tyler Brabant © 2019
UploadFiles.ps1

Instructions: 
1. Examine the varibles below and update them accordingly
2. Everything else should be setup and ready to go

#####>
param(
    [string]$UploadLocation = "$HOME\Documents\YammerSitesFiles"
)

# Your username for the new tenant
$UsernameNewTenant = "** Username for new Tenant"
# This is the URL of the new site that will serve as the repository
$UrlNewTenant = "** Full Site URL in the same Tenant **"
# This is the library that the folder structure will be replicated in
$DocumentLibraryName = "Shared Documents"

# Creating the credential variable
$UploadCreds = Get-Credential -Message "Enter the new tenant ID and Password" -UserName $UsernameNewTenant

# Connect to the new Tenant
Connect-PnPOnline -Url $UrlNewTenant -CreateDrive -Credentials $UploadCreds
write-host -f yellow "Conncected. Please wait."

# Upload the files recursively
(Get-ChildItem $UploadLocation -Recurse) | ForEach-Object{
    Try { 
        if($_.GetType().Name -eq "FileInfo"){
            $SPFolderName = $DocumentLibraryName + $_.DirectoryName.Substring($UploadLocation.Length)
            Add-PnPFile -Path $_.FullName -Folder $SPFolderName
            # Checks for Errors on the files that are being uploaded 
            if(!($?)){
                Write-Output "File too large, or other issue. Mannualy upload " $_.FullName $SPFolderName | 
                                Out-File "$UploadLocation\..\logs.txt" -Append 
            }
        }        
    } Catch { 
        Write-Host $_.Exception.Message
        Write-Host -f Yellow "Issue with uploading file"
    }
}

# Delete Files in the folder to save space
Get-ChildItem -Path $UploadLocation -Recurse |
    Foreach-object { Remove-item -Recurse -path $_.FullName }

# Disconect from the site
Disconnect-PnPOnline