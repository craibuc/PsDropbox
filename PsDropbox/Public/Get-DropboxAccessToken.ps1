<#
.SYNOPSIS
Generate a short-lived access_token and long-lived refresh_token.

.DESCRIPTION
Generate a short-lived access_token and long-lived refresh_token.

.PARAMETER client_id
The "App key" from the App console (https://www.dropbox.com/developers/apps/info/{{client_id}}).

.PARAMETER client_secret
The "App secret" from the App console (https://www.dropbox.com/developers/apps/info/{{client_id}}).

.PARAMETER access_code
The one-time-use access_code that is created during the manual authorization process.

.PARAMETER refresh_token
THe long-lived (non-expiring?) refresh_token that is created when using the function with the access_code parameter.

.EXAMPLE
Get-DropboxAccessToken -client_id '123456' -client_secret 'abcdef' -access_code 'abc123' 

access_token  : sl.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
token_type    : bearer
expires_in    : 14400
refresh_token : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
scope         : account_info.read...
uid           : 1234567890
account_id    : dbid:zzzzzzzzzzzzzzzzzzzz

Get an access_token and refresh_token.

.EXAMPLE
Get-DropboxAccessToken -client_id '123456' -client_secret 'abcdef' -refresh_token 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

access_token  : sl.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
token_type    : bearer
expires_in    : 14400
refresh_token : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
scope         : account_info.read...
uid           : 1234567890
account_id    : dbid:zzzzzzzzzzzzzzzzzzzz

Get a new access_token.

.NOTES
Create an access_code:
- Go to https://www.dropbox.com/oauth2/authorize?client_id={{client_id}}&response_type=code&token_access_type=offline'
- Follow prompts
- Save the one-time-use access_code
#>

function Get-DropboxAccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$client_id,

        [Parameter(Mandatory)]
        [string]$client_secret,

        [Parameter(Mandatory,ParameterSetName='Initial')]
        [string]$access_code,

        [Parameter(Mandatory,ParameterSetName='Refresh')]
        [string]$refresh_token

    )

    Write-Debug "client_id: $client_id"
    Write-Debug "client_secret: $client_secret"
    Write-Debug "access_code: $access_code"
    Write-Debug "refresh_token: $refresh_token"

    $Body = switch ($PSCmdlet.ParameterSetName) {
        'Initial' { 
            @{
                code = $access_code
                grant_type = 'authorization_code'
                client_id = $client_id
                client_secret = $client_secret
            }        
        }
        'Refresh' { 
            @{
                refresh_token = $refresh_token
                grant_type = 'refresh_token'
                client_id = $client_id
                client_secret = $client_secret
            }        
        }
    }
    Write-Debug ($Body | ConvertTo-Json)
    
    try {
        $Response = Invoke-WebRequest -Uri 'https://api.dropboxapi.com/oauth2/token' -Method Post -Body $Body -ContentType 'application/x-www-form-urlencoded'
        if ($Response.Content) {
            $Content = $Response.Content | ConvertFrom-Json
            $Content | Add-Member -Type NoteProperty -Name 'expires_at' -Value (Get-Date).AddSeconds($Content.expires_in).ToString('O') -Force
            Write-Debug ($Content | ConvertTo-Json)
            $Content
        }
    }
    catch {
        throw $_
    }

}