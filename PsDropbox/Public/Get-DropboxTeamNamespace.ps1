<#
.LINK
https://www.dropbox.com/developers/documentation/http/teams#team-namespaces-list

.LINK
https://www.dropbox.com/developers/documentation/http/teams#team-namespaces-list-continue
#>
function Get-DropboxTeamNamespace {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken
    )

    $Headers = @{
        Authorization = 'Bearer ' + $AccessToken
    }

    $Body = @{} | ConvertTo-Json

    $Uri = 'https://api.dropboxapi.com/2/team/namespaces/list'

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
                $Uri = 'https://api.dropboxapi.com/2/team/namespaces/list/continue'
                $Body = @{
                    cursor = $Content.cursor
                } | ConvertTo-Json
                Write-Debug $Body

            }
            else {
                $Continue = $false
            }

            # return array of folders
            $Content.namespaces

        }
    
    } while ( $Continue -eq $true )

}
