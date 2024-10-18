<#
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

        $Response = Invoke-WebRequest -Uri 'https://api.dropboxapi.com/2/files/create_folder_v2' -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

        if ($Response.Content) {
            $Response.Content | ConvertFrom-Json
        }
    
    }

}