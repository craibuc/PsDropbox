<#
.LINK
https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-list

.LINK
https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-list-continue
#>
function Get-DropboxTeamFolder {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter()]
        [ValidateRange(1,1000)]
        [int]$Limit = 1000
    )

    $Headers = @{
        Authorization = 'Bearer ' + $AccessToken
    }

    $Data = @{
        limit = $Limit
    }

    $Body = $Data | ConvertTo-Json

    $Uri = 'https://api.dropboxapi.com/2/team/team_folder/list'

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
                $Uri = 'https://api.dropboxapi.com/2/team/team_folder/list/continue'
                $Body = @{
                    cursor = $Content.cursor
                } | ConvertTo-Json
    
            }
            else {
                $Continue = $false
            }

            # return array of folders
            $Content.team_folders

        }
    
    } while ( $Continue -eq $true )

}
