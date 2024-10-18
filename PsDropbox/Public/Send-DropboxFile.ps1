<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-upload
#>
function Send-DropboxFile {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter()]
        [ValidateSet('add','overwrite','update')]
        [string]$Mode = 'add',

        [Parameter()]
        [switch]$AutoRename,

        [Parameter()]
        [switch]$Mute,

        [Parameter()]
        [switch]$StrictConflict,

        [string]$SelectUser,
        [string]$RootFolderId
    )

    $Headers = @{
        Authorization = 'Bearer ' + $AccessToken
        'Dropbox-API-Arg' = @{
            path = $Destination
            mode = $Mode
            autorename = [bool]$AutoRename
            mute = [bool]$Mute
            strict_conflict = [bool]$StrictConflict
        } | ConvertTo-Json -Compress
    }

    if ($SelectUser) {$Headers['Dropbox-API-Select-User']=$SelectUser}
    if ($RootFolderId) {$Headers['Dropbox-API-Path-Root']=@{'.tag'='root'; root=$RootFolderId} | ConvertTo-Json -Compress}

    Write-Debug $Headers

    $Uri = 'https://content.dropboxapi.com/2/files/upload'
    Write-Debug "Uri: $Uri"

    if ($PSCmdlet.ShouldProcess("$Source --> $Destination", "Send-DropboxFile")) {

        $Response = Invoke-WebRequest -Uri $Uri -Headers $Headers -Method Post -ContentType 'application/octet-stream' -InFile $Source

        if ($Response.Content) {
            $Response.Content | ConvertFrom-Json
        }
    
    }

}