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
        [bool]$AutoRename
    )

    $Uri = 'https://api.dropboxapi.com/2/files/create_folder_v2'

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    $Body = @{
        path = $Path
        autorename = $AutoRename
    } | ConvertTo-Json

    if ($PSCmdlet.ShouldProcess($Path, "New-DropboxFolder")) {

        $Response = Invoke-WebRequest -Uri $Uri -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

        if ($Response.Content) {
    
            # convert JSON to Hashtable
            $Content = $Response.Content | ConvertFrom-Json
    
            # return data
            $Content
    
        }
    
    }

}