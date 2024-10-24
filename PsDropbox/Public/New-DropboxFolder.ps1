<#
.SYNOPSIS

.PARAMETER AccessToken
Generated by Get-DropboxAccessToken.

.PARAMETER Path
Path of the folder to be created.

.PARAMETER AutoRename
Rename the folder if it already exists.

.PARAMETER SelectUser

.PARAMETER RootFolderId

.EXAMPLE
New-DropboxFolder -AccessToken ACCESS_TOKEN -Path '/path/to/folder'

.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder

#>
function New-DropboxFolder {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [switch]$AutoRename,

        [string]$SelectUser,
        [string]$RootFolderId
    )

    Write-Debug "AccessToken: $AccessToken"
    Write-Debug "Path: $Path"
    Write-Debug "AutoRename: $AutoRename"
    Write-Debug "SelectUser: $SelectUser"
    Write-Debug "RootFolderId: $RootFolderId"

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    if ($SelectUser) {$Headers['Dropbox-API-Select-User']=$SelectUser}
    if ($RootFolderId) {$Headers['Dropbox-API-Path-Root']=@{'.tag'='root'; root=$RootFolderId} | ConvertTo-Json -Compress}

    $Body = @{
        path = $Path
        autorename = [bool]$AutoRename
    } | ConvertTo-Json
    Write-Debug $Body

    if ($PSCmdlet.ShouldProcess($Path, "New-DropboxFolder")) {
        Send-Request -Path 'files/create_folder_v2' -Headers $Headers -Body $Body
    }

}