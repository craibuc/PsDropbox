<#
.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-get_metadata
#>
function Get-DropboxItemMeta {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$Path,

        [string]$SelectUser,
        [string]$RootFolderId
    )

    $Uri = 'https://api.dropboxapi.com/2/files/get_metadata'
    Write-Debug "Uri: $Uri"

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    if ($SelectUser) {$Headers['Dropbox-API-Select-User']=$SelectUser}
    if ($RootFolderId) {$Headers['Dropbox-API-Path-Root']=@{'.tag'='root'; root=$RootFolderId} | ConvertTo-Json -Compress}

    try {

        $Response = Invoke-WebRequest -Uri $Uri -Body ( @{ path = $Path } | ConvertTo-Json ) -Headers $Headers -Method Post -ContentType 'application/json'

        if ($Response.Content) {
            $Response.Content | ConvertFrom-Json
        }

    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {

        <#
        Bad Request [400] - InvalidOperation - TEXT
        Unauthorized [401] - AuthenticationError
        {
            "error": {
                ".tag": "expired_access_token"
            },
            "error_summary": "expired_access_token/"
        }
        Forbidden [403] - PermissionDenied
        NotFound [404] - ObjectNotFound
        MethodNotAllowed [405] - 
        Conflict [409] - 
        {
            "error_summary": "path/not_found/.",
            "error": {
                ".tag": "path",
                "path": {
                    ".tag": "not_found"
                }
            }
        }
        TooManyRequests [429] - 
        #>

        $ErrorDetails = $_.Exception.Response.StatusCode -ne [System.Net.HttpStatusCode]::BadRequest ? ($_.ErrorDetails.Message | ConvertFrom-Json) : $_.ErrorDetails.Message

        # Bad Request [400]
        if (  $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest ) {

            $BadRequestException = [System.Exception]::new($ErrorDetails)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($BadRequestException, $ErrorId, $ErrorCategory, $null)

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
        # Unauthorized [401]
        elseif ( $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized ) {

            $InvalidCredentialException = [System.Security.Authentication.InvalidCredentialException]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::AuthenticationError
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($InvalidCredentialException, $ErrorId, $ErrorCategory, $null)

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
        # Forbidden [403]
        elseif ( $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden ) {

            $InvalidCredentialException = [System.Security.Authentication.]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::PermissionDenied
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($InvalidCredentialException, $ErrorId, $ErrorCategory, $null)

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
        # Conflict [409]
        elseif ( $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Conflict ) {

            $ConflictException = [System.Exception]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::NotSpecified
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) - $( $ErrorDetails.error_summary )"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($ConflictException, $ErrorId, $ErrorCategory, $null)
            
            Write-Error -ErrorRecord $ErrorRecord
        }
        # TooManyRequests [429]
        elseif ( $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::TooManyRequests ) {

            $TooManyRequestsException = [System.Exception]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]:: QuotaExceeded
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($TooManyRequestsException, $ErrorId, $ErrorCategory, $null)

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
        else {

            $ServerException = [System.Exception]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::NotSpecified
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) - $( $_.Exception.Message )"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($ServerException, $ErrorId, $ErrorCategory, $null)
            $ErrorRecord.ErrorDetails = $_.ErrorDetails.Message

            Write-Error -ErrorRecord $ErrorRecord
        }

    }
    catch {
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::NotSpecified
        $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) - $( $_.Exception.Message )"
        $ErrorRecord = [Management.Automation.ErrorRecord]::new($_.Exception, $ErrorId, $ErrorCategory, $null)
        $ErrorRecord.ErrorDetails = $_.ErrorDetails.Message

        Write-Error -ErrorRecord $ErrorRecord
    }

}