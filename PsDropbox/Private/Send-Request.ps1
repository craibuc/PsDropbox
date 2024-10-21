function Send-Request {

  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [hashtable]$Headers,

    [Parameter(Mandatory)]
    [hashtable]$Data,

    [int]$Retries = 3
  )

  begin {
    
    Write-Debug "Path: $Path"

    $BaseUri = 'https://api.dropboxapi.com/2'
  
    $Uri = "$BaseUri/$Path"
    Write-Debug "Uri: $Uri"

    $Body = $Data | ConvertTo-Json
    Write-Debug $Body

  }

  process {

    [int]$Retry = 1

    while ($Retry -le $Retries) {

      try {

        Write-Debug "Retry: $Retry"

        $Response = Invoke-WebRequest -Method Post -Uri $Uri -Body $Body -Headers $Headers -ContentType 'application/json'

        if ($Response.Content) {
          $Response.Content | ConvertFrom-Json
          Break
        }

      }
      catch [Microsoft.PowerShell.Commands.HttpResponseException] {

        Write-Debug $_.Exception.Message
        $ErrorDetails = $_.Exception.StatusCode -ne [System.Net.HttpStatusCode]::BadRequest ? ($_.ErrorDetails.Message | ConvertFrom-Json) : $_.ErrorDetails.Message

        switch ($_.Exception.StatusCode) {

          # "Bad Request [400]"
          {$_ -eq [System.Net.HttpStatusCode]::BadRequest} {

            $InvalidCredentialException = [System.Security.Authentication.InvalidCredentialException]::new($ErrorDetails)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($InvalidCredentialException, $ErrorId, $ErrorCategory, $null)

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)

          }

          # "Unauthorized [401]"
          {$_ -eq [System.Net.HttpStatusCode]::Unauthorized} {

            $InvalidCredentialException = [System.Security.Authentication.InvalidCredentialException]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::AuthenticationError
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($InvalidCredentialException, $ErrorId, $ErrorCategory, $null)

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)

          }

          # "Forbidden [403]"
          {$_ -eq [System.Net.HttpStatusCode]::Forbidden} {

            $InvalidCredentialException = [System.Security.Authentication.InvalidCredentialException]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::PermissionDenied
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($InvalidCredentialException, $ErrorId, $ErrorCategory, $null)

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)

          }

          # Conflict [409]
          {$_ -eq [System.Net.HttpStatusCode]::Conflict} {

            $InvalidCredentialException = [System.Security.Authentication.InvalidCredentialException]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.Response.StatusCode )]"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($InvalidCredentialException, $ErrorId, $ErrorCategory, $null)
            $ErrorRecord.ErrorDetails = $ErrorDetails | ConvertTo-Json

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)

          }

          # "When Too Many Requests [429]"
          {$_ -eq [System.Net.HttpStatusCode]::TooManyRequests} {

            $Delay = [int]$ErrorDetails.error.retry_after

            if ($Retry -lt $Retries) {

              Write-Debug "Received Too Many Requests [429]. Retrying in $Delay seconds..."
              Start-Sleep -Seconds $Delay
              $Retry++

            } 
            else {

              $InvalidCredentialException = [System.Security.Authentication.InvalidCredentialException]::new($ErrorDetails.error_summary)
              $ErrorCategory = [System.Management.Automation.ErrorCategory]::QuotaExceeded
              $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) [$( $_.Exception.StatusCode )]"
              $ErrorRecord = [Management.Automation.ErrorRecord]::new($InvalidCredentialException, $ErrorId, $ErrorCategory, $null)
              $ErrorRecord.ErrorDetails = $ErrorDetails | ConvertTo-Json

              $PSCmdlet.ThrowTerminatingError($ErrorRecord)
  
            }

          }

          # other 4XX/5XX errors
          Default { 
            $ServerException = [System.Exception]::new($ErrorDetails.error_summary)
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::NotSpecified
            $ErrorId = "$($MyInvocation.MyCommand.Module.Name).$($MyInvocation.MyCommand.Name) - $( $_.Exception.Message )"
            $ErrorRecord = [Management.Automation.ErrorRecord]::new($ServerException, $ErrorId, $ErrorCategory, $null)
            $ErrorRecord.ErrorDetails = $_.ErrorDetails.Message

            Write-Error -ErrorRecord $ErrorRecord
          }

        } # /switch

      }
      catch {
        Write-Error $_.Exception.Message
      }

    } # while

  }

  end {}

}