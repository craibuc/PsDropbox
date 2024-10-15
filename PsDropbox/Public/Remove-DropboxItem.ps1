<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-delete
#>
function Remove-DropboxItem {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $Uri = 'https://api.dropboxapi.com/2/files/delete_v2'

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    $Body = @{
        path = $Path
    } | ConvertTo-Json

    if ($PSCmdlet.ShouldProcess($Path, "Remove-DropboxItem")) {

        $Response = Invoke-WebRequest -Uri $Uri -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

        if ($Response.Content) {
    
            # convert JSON to Hashtable
            $Content = $Response.Content | ConvertFrom-Json
    
            # return data
            $Content
    
        }
    
    }

}