<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-tags-remove
#>
function Remove-DropboxFileTag {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Tag
    )

    $Headers = @{
        Authorization = 'Bearer ' + $ApiKey
    }

    $Data = @{
        path = $Path
        tag_text = $Tag
    }

    $Body = $Data | ConvertTo-Json
    Write-Debug $Body

    $Uri = 'https://api.dropboxapi.com/2/files/tags/remove'
    Write-Debug "Uri: $Uri"

    $Response = Invoke-WebRequest -Uri $Uri -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

    if ($Response.Content) {

        # convert JSON to Hashtable
        $Content = $Response.Content | ConvertFrom-Json

        # return data
        $Content

    }

}