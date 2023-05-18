<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-delete
#>
function Remove-DropboxFileFolder {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $Headers = @{
        Authorization = 'Bearer ' + $ApiKey
    }

    $Data = @{
        path = $Path
    }

    $Body = $Data | ConvertTo-Json
    Write-Debug $Body

    $Uri = 'https://api.dropboxapi.com/2/files/delete_v2'
    Write-Debug "Uri: $Uri"

    $Response = Invoke-WebRequest -Uri $Uri -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

    if ($Response.Content) {

        # convert JSON to Hashtable
        $Content = $Response.Content | ConvertFrom-Json

        # return data
        $Content

    }

}