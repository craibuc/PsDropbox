<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-tags-add
#>
function Get-DropboxFileTag {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string[]]$Path
    )

    $Headers = @{
        Authorization = 'Bearer ' + $AccessToken
    }

    $Response = Invoke-WebRequest -Uri 'https://api.dropboxapi.com/2/files/tags/get' -Body ( @{paths = $Path} | ConvertTo-Json ) -Headers $Headers -Method Post -ContentType 'application/json'

    if ($Response.Content) {
        $Response.Content | ConvertFrom-Json
    }

}