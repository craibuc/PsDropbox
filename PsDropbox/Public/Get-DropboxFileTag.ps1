<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-tags-add
#>
function Get-DropboxFileTag {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter(Mandatory)]
        [string[]]$Path
    )

    $Headers = @{
        Authorization = 'Bearer ' + $ApiKey
    }

    $Data = @{
        paths = $Path
    }

    $Body = $Data | ConvertTo-Json
    Write-Debug $Body

    $Uri = 'https://api.dropboxapi.com/2/files/tags/get'
    Write-Debug "Uri: $Uri"

    $Response = Invoke-WebRequest -Uri $Uri -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

    if ($Response.Content) {

        # convert JSON to Hashtable
        $Content = $Response.Content | ConvertFrom-Json

        # return data
        $Content

    }

}