<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-upload
#>
function Send-DropboxFile {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $Headers = @{
        Authorization = 'Bearer ' + $ApiKey
        'Dropbox-API-Arg' = @{path = $Destination} | ConvertTo-Json -Compress
    }
    Write-Debug $Headers

    $Uri = 'https://content.dropboxapi.com/2/files/upload'
    Write-Debug "Uri: $Uri"

    $Response = Invoke-WebRequest -Uri $Uri -Headers $Headers -Method Post -ContentType 'application/octet-stream' -InFile $Source

    if ($Response.Content) {

        # convert JSON to Hashtable
        $Content = $Response.Content | ConvertFrom-Json

        # return data
        $Content

    }

}