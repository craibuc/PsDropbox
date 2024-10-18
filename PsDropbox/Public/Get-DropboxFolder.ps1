<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder
#>
function Get-DropboxFolder {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('access_token')]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [switch]$Recursive,

        [string]$SelectUser,
        [string]$RootFolderId
    )

    $Headers = @{
        Authorization = 'Bearer ' + $AccessToken
    }

    if ($SelectUser) {$Headers['Dropbox-API-Select-User']=$SelectUser}
    if ($RootFolderId) {$Headers['Dropbox-API-Path-Root']=@{'.tag'='root'; root=$RootFolderId} | ConvertTo-Json -Compress}
    
    $Data = @{
        path = $Path
    }

    if ( $Recursive.IsPresent ) { $Data.recursive =  $true }

    $Body = $Data | ConvertTo-Json

    $Uri = 'https://api.dropboxapi.com/2/files/list_folder'

    $Continue = $false

    do {

        Write-Debug $Body

        Write-Debug "Uri: $Uri"
        $Response = Invoke-WebRequest -Uri $Uri -Body $Body -Headers $Headers -Method Post -ContentType 'application/json'

        if ($Response.Content) {

            # convert JSON to Hashtable
            $Content = $Response.Content | ConvertFrom-Json
    
            # has more?
            if ( $Content.has_more ) {

                $Continue = $true
                $Uri = 'https://api.dropboxapi.com/2/files/list_folder/continue'    
                $Body = @{
                    cursor = $Content.cursor
                } | ConvertTo-Json
    
            }
            else {
                $Continue = $false
            }

            # return array of folders
            $Content.entries

        }
    
    } while ( $Continue -eq $true )

}
