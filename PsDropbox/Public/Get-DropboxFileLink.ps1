<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-get_temporary_link

#>
function Get-DropboxFileLink {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter()]
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

    $Uri = 'https://api.dropboxapi.com/2/files/get_temporary_link'
    Write-Debug "Uri: $Uri"

    $Response = Invoke-WebRequest -Uri $Uri -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

    if ($Response.Content) {

        # convert JSON to Hashtable
        $Content = $Response.Content | ConvertFrom-Json

        # return data
        $Content

    }
    
}
