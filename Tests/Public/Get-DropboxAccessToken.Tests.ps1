BeforeAll {

  $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
  $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

  # $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

  $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
  . (Join-Path $PublicPath $SUT)

}

Describe 'Get-DropboxAccessToken' {

  Context "Parameter validation" {

    BeforeAll {
      $Command = Get-Command "Get-DropboxAccessToken"
    }

    $Parameters = @(
        @{Name='client_id';Type='string';Mandatory=$true}
        @{Name='client_secret';Type='string';Mandatory=$true}
        @{Name='access_code';Type='string';Mandatory=$true}
        @{Name='refresh_token';Type='string';Mandatory=$true}
    )

    Context 'Type' {
        it '<Name> is a <Type>' -TestCases $Parameters {
            param($Name, $Type, $Mandatory)
          
            $Command | Should -HaveParameter $Name -Type $type
        }    
    }

    Context 'Type' {
        it '<Name> mandatory is <Mandatory>' -TestCases $Parameters {
            param($Name, $Type, $Mandatory)
          
            if ($Mandatory) { $Command | Should -HaveParameter $Name -Mandatory }
            else { $Command | Should -HaveParameter $Name -Not -Mandatory }
        }    
    }

  }

  Context "Request" {

    Context "When valid credentials are supplied" {

      BeforeEach {

        $access_token = (New-Guid).Guid

        Mock Invoke-WebRequest {

          @{
            StatusCode = 200
            Content = @{
              access_token = $access_token
              token_type = "bearer"
              expires_in = 14400
            } | ConvertTo-Json
          }

        }

        $Actual = Get-DropboxAccessToken -client_id 'client_id' -client_secret 'client_secret' -refresh_token 'refresh_token' #-Debug

      }

      It "uses the correct Uri" {
        # assert
        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/oauth2/token' }
      }

      It "uses the correct Method" {
          # assert
          Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Method -eq 'Post' }
      }

      It "uses the correct ContentType" {
          # assert
          Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $ContentType -eq 'application/x-www-form-urlencoded' }
      }

      It "creates the correct Body" {
        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
          $Body.client_id -eq 'client_id' -and
          $Body.client_secret -eq 'client_secret' -and
          $Body.refresh_token -eq 'refresh_token' -and
          $Body.grant_type -eq 'refresh_token'
        }
      }

      It "returns an access_token" {
        $Actual.access_token | Should -Be $access_token
      }


    }

    Context "When an invalid client_id or client_secret is supplied" {

      BeforeEach {

        Mock Invoke-WebRequest {
          $Content = @{
            error = "invalid_client: Invalid client_id or client_secret"
          } | ConvertTo-Json

          $HttpResponseMessage = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::BadRequest)

          $Phrase = 'Response status code does not indicate success: 400 (Bad Request).'
          $HttpResponseException = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase, $HttpResponseMessage)
      
          $errorID = 'PsDropbox.Get-DropboxAccessToken.Bad Request [400]'
          $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
          $targetObject = $null
          
          $errorRecord = New-Object Management.Automation.ErrorRecord $HttpResponseException, $errorID, $errorCategory, $targetObject
          $errorRecord.ErrorDetails = $Content

          Throw $errorRecord
        }

        
      }
      It "throws an error" {
        { Get-DropboxAccessToken -client_id 'invalid' -client_secret 'invalid' -refresh_token 'valid' } | Should -Throw
      }

    }

    Context "When an invalid refresh_token is supplied" {

      BeforeEach {

        Mock Invoke-WebRequest {
          $Content = @{
            error = "invalid_client: Invalid client_id or client_secret"
          } | ConvertTo-Json

          $HttpResponseMessage = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::BadRequest)

          $Phrase = 'Response status code does not indicate success: 400 (Bad Request).'
          $HttpResponseException = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase, $HttpResponseMessage)
      
          $errorID = 'PsDropbox.Get-DropboxAccessToken.Bad Request [400]'
          $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
          $targetObject = $null
          
          $errorRecord = New-Object Management.Automation.ErrorRecord $HttpResponseException, $errorID, $errorCategory, $targetObject
          $errorRecord.ErrorDetails = $Content

          Throw $errorRecord
        }

        
      }
      It "throws an error" {
        { Get-DropboxAccessToken -client_id 'valid' -client_secret 'valid' -refresh_token 'invalid' } | Should -Throw
      }

    }

  }
}