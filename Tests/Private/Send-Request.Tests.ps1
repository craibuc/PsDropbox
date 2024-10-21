BeforeAll {

  $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
  $PrivatePath = Join-Path $ProjectDirectory "/PsDropbox/Private/"

  # $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

  $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
  . (Join-Path $PrivatePath $SUT)

}

Describe 'Send-Request' {

    Context "Parameter validation" {

        BeforeAll {
            $Command = Get-Command "Send-Request"
        }

        $Parameters = @(
            @{Name='Path';Type='string';Mandatory=$true}
            @{Name='Headers';Type='hashtable';Mandatory=$true}
            @{Name='Data';Type='hashtable';Mandatory=$true}
        )

        Context 'Type' {
            it '<Name> is a <Type>' -TestCases $Parameters {
                param($Name, $Type, $Mandatory)
            
                $Command | Should -HaveParameter $Name -Type $type
            }    
        }
  
        Context 'Mandatory' {
            it '<Name> mandatory is <Mandatory>' -TestCases $Parameters {
                param($Name, $Type, $Mandatory)
            
                if ($Mandatory) { $Command | Should -HaveParameter $Name -Mandatory }
                else { $Command | Should -HaveParameter $Name -Not -Mandatory }
            }    
        }
      
    }

    Context "Request" {
  
        BeforeEach {

            $AccessToken = (New-Guid).Guid
            $Expected = @{
                Path = "path/to/resource"
                Headers = @{ Authorization = "Bearer $AccessToken" }
                Data = @{key = 'value'}
            }

            Mock Invoke-WebRequest {
                @{
                    StatusCode = 200
                    Content = $Expected.Data | ConvertTo-Json
                }
            }

            # act
            Send-Request @Expected

        }

        It "uses the correct Method" {
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
                $Method -eq 'Post' 
            }
        }

        It "uses the correct ContentType" {
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
                $ContentType -eq 'application/json' 
            }
        }

        It "uses the correct Uri" {
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
                $Uri -eq "https://api.dropboxapi.com/2/$($Expected.Path)" 
            }
        }

        It "uses the correct Authorization header" {
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                $Headers.Authorization -eq "Bearer $AccessToken"
            }
        }

        It "creates the correct Body" {
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
                $Actual = $Body | ConvertFrom-Json
                $Actual.key -eq $Expected.Data.key
            }
        }

    }

    Context "Response" {

        BeforeEach {
            $AccessToken = (New-Guid).Guid
            $Expected = @{
                Path = "path/to/resource"
                Headers = @{ Authorization = "Bearer $AccessToken" }
                Data = @{ key = 'value' }
            }
        }

        Context "When OK [200]" {

            BeforeEach {

                Mock Invoke-WebRequest {
                    @{
                        StatusCode = 200
                        StatusDescription = "OK"
                        Content = $Expected.Data | ConvertTo-Json
                    }
                }

                $Actual = Send-Request @Expected

            }

            It 'return the expected data' {
                $Actual.key | Should -Be $Expected.Data.key
            }

        }

        Context "When Bad Request [400]" {

            BeforeEach {

                Mock Invoke-WebRequest { 

                    $Content = "lorem ipsum"

                    $HttpResponseMessage = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::BadRequest)

                    $Phrase = 'Response status code does not indicate success: 400 (Bad Request).'
                    $HttpResponseException = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase, $HttpResponseMessage)
                
                    $errorID = 'PsDropbox.Send-Request.Bad Request [400]'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $targetObject = $null
                    
                    $errorRecord = New-Object Management.Automation.ErrorRecord $HttpResponseException, $errorID, $errorCategory, $targetObject
                    $errorRecord.ErrorDetails = $Content
        
                    Throw $errorRecord
                }

            }

            It 'throws an error' {
                { Send-Request @Expected } | Should -Throw -ExceptionType ([System.Security.Authentication.InvalidCredentialException]) -ExpectedMessage $Content
            }

        }

        Context "When Unauthorized [401]" {

            BeforeEach {

                Mock Invoke-WebRequest { 

                    $Content = @{
                        error_summary = "invalid_access_token/..."
                        error = @{
                          ".tag" = "invalid_access_token"
                        }
                    }

                    $HttpResponseMessage = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::Unauthorized)

                    $Phrase = 'Response status code does not indicate success: 401 (Unauthorized).'
                    $HttpResponseException = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase, $HttpResponseMessage)
                
                    $errorID = 'PsDropbox.Send-Request.Unauthorized [401]'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::AuthenticationError
                    $targetObject = $null
                    
                    $errorRecord = New-Object Management.Automation.ErrorRecord $HttpResponseException, $errorID, $errorCategory, $targetObject
                    $errorRecord.ErrorDetails = $Content | ConvertTo-Json
        
                    Throw $errorRecord
                }

            }

            It 'throws an error' {
                { Send-Request @Expected } | Should -Throw -ExceptionType ([System.Security.Authentication.InvalidCredentialException]) -ExpectedMessage $Content.error_summary
            }

        }

        Context "When Forbidden [403]" {

            BeforeEach {

                Mock Invoke-WebRequest { 

                    $Content = @{
                        error_summary = "no_permission" 
                    }

                    $HttpResponseMessage = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::Forbidden)

                    $Phrase = 'Response status code does not indicate success: 403 (Forbidden).'
                    $HttpResponseException = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase, $HttpResponseMessage)
                
                    $errorID = 'PsDropbox.Send-Request.Forbidden [403]'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::PermissionDenied
                    $targetObject = $null
                    
                    $errorRecord = New-Object Management.Automation.ErrorRecord $HttpResponseException, $errorID, $errorCategory, $targetObject
                    $errorRecord.ErrorDetails = $Content | ConvertTo-Json
        
                    Throw $errorRecord
                }

            }

            It 'throws an error' {
                { Send-Request @Expected } | Should -Throw -ExceptionType ([System.Security.Authentication.InvalidCredentialException]) -ExpectedMessage $Content.error_summary
            }

        }

        Context "Conflict [409]" {

            BeforeEach {

                Mock Invoke-WebRequest { 

                    $Content = @{
                        error_summary = "lorem ipsum" 
                    }

                    $HttpResponseMessage = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::Conflict)

                    $Phrase = 'Response status code does not indicate success: 409 (Conflict).'
                    $HttpResponseException = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase, $HttpResponseMessage)
                
                    $errorID = 'PsDropbox.Send-Request.Conflict [409]'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $targetObject = $null
                    
                    $errorRecord = New-Object Management.Automation.ErrorRecord $HttpResponseException, $errorID, $errorCategory, $targetObject
                    $errorRecord.ErrorDetails = $Content | ConvertTo-Json
        
                    Throw $errorRecord
                }

            }

            It 'throws an error' {
                { Send-Request @Expected } | Should -Throw -ExceptionType ([System.Security.Authentication.InvalidCredentialException]) -ExpectedMessage $Content.error_summary
            }

        }

        Context "When Too Many Requests [429]" {

            BeforeEach {

                Mock Invoke-WebRequest { 

                    $Content = @{
                        error_summary = "too_many_requests" 
                        error = @{
                            reason = @{
                                ".tag" = "too_many_requests"
                            }
                            retry_after = 1
                        }
                    }

                    $HttpResponseMessage = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::TooManyRequests)

                    $Phrase = 'Response status code does not indicate success: 429 (Too Many Requests).'
                    $HttpResponseException = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase, $HttpResponseMessage)
                
                    $errorID = 'PsDropbox.Send-Request'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded
                    $targetObject = $null
                    
                    $errorRecord = New-Object Management.Automation.ErrorRecord $HttpResponseException, $errorID, $errorCategory, $targetObject
                    $errorRecord.ErrorDetails = $Content | ConvertTo-Json
        
                    Throw $errorRecord
                }

            }

            It 'return the expected data' {
                { Send-Request @Expected } | Should -Throw -ExceptionType ([System.Security.Authentication.InvalidCredentialException]) -ExpectedMessage $Content.error_summary
            }

        }

    }

}