
BeforeAll {

    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

    $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}

Describe 'Get-DropboxItemMeta' {

    Context "Parameter validation" {

        BeforeAll {
          $Command = Get-Command "Get-DropboxItemMeta"
        }
    
        $Parameters = @(
            @{Name='AccessToken';Type='string';Mandatory=$true}
            @{Name='Path';Type='string';Mandatory=$true}
            @{Name='SelectUser';Type='string';Mandatory=$false}
            @{Name='RootFolderId';Type='string';Mandatory=$false}
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
        
    } # /context
    
    Context "Request" {

        BeforeEach {
            # arrange
            $AccessToken = '2134d8d5-d1b4-4a1d-89ac-f44a96514bb5'
            $Path = "/Homework/math/Prime_Numbers.txt"

            Mock Invoke-WebRequest {}

            # act
            Get-DropboxItemMeta -AccessToken $AccessToken -Path $Path

        }

        It "uses the correct Uri" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/files/get_metadata' }
        }

        It "uses the correct Method" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Method -eq 'Post' }
        }

        It "uses the correct ContentType" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $ContentType -eq 'application/json' }
        }

        It "uses the correct Authorization header" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                $Headers.Authorization -eq "Bearer $AccessToken"
            }
        }

        It "creates the correct Body" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
                $Actual = $Body | ConvertFrom-Json
                $Actual.path -eq $Path
            }
        }

        Context 'when the SelectUser parameter is supplied' {

            BeforeEach {
                # arrange
                Mock Invoke-WebRequest {}
                # act
                Get-DropboxItemMeta -AccessToken $AccessToken -Path $Path -SelectUser 'SelectUser'
            }

            It "adds the Dropbox-API-Select-User header" {
                # assert
                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Headers.'Dropbox-API-Select-User' -eq 'SelectUser'
                }
            }

        }

        Context 'when the RootFolderId parameter is supplied' {

            BeforeEach {
                # arrange
                Mock Invoke-WebRequest {}
                # act
                Get-DropboxItemMeta -AccessToken $AccessToken -Path $Path -RootFolderId 'RootFolderId'
            }

            It "adds the Dropbox-API-Path-Root header" {
                # assert
                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Headers.'Dropbox-API-Path-Root' -eq @{root = 'RootFolderId'} | ConvertTo-Json -Compress
                }
            }

        }

    }

    Context "Response" {

        BeforeEach {
            # arrange
            $AccessToken = '2134d8d5-d1b4-4a1d-89ac-f44a96514bb5'
        }

        Context "when a path exists" {

            BeforeEach {
                # arrange
                Mock Invoke-WebRequest {
                    $Fixture = 'Get-DropboxFileMeta.Response.200.json'
                    $Content = Get-Content (Join-Path $FixturesDirectory $Fixture) -Raw
    
                    $Response = New-MockObject -Type  Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject
                    $Response | Add-Member -Type NoteProperty -Name 'Content' -Value $Content -Force
                    $Response
                }
            }

            It "returns data" {
                # arrange
                $Path = "/Homework/math/Prime_Numbers.txt"

                # act
                $Actual = Get-DropboxItemMeta -AccessToken $AccessToken -Path $Path

                # assert
                $Actual | Should -Not -BeNullOrEmpty
            }
        }

        Context "when a path doesn't exist" -skip {

            BeforeEach {
                # arrange
                Mock Invoke-WebRequest {
                    $ConflictResponse = New-Object System.Net.Http.HttpResponseMessage 409
                    $Phrase = 'Response status code does not indicate success: 409 ().'
        
                    $Exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Phrase,$ConflictResponse)

                    $ErrorId = "PsDropbox.Get-DropboxMeta - [$( $ConflictResponse.StatusCode )]"
                    $ErrorRecord = [Management.Automation.ErrorRecord]::new($Exception, $ErrorId, [System.Management.Automation.ErrorCategory]::AuthenticationError, $null)

                    $Message = @{
                        "error_summary" = "path/not_found/"
                        "error" = @{
                            ".tag" = "path"
                            "path" = @{
                                ".tag" = "not_found"
                            }
                        }
                    }
                    $ErrorDetails = [System.Management.Automation.ErrorDetails]::new($Message)
                    $ErrorRecord.ErrorDetails = $ErrorDetails

                    Write-Error $ErrorRecord
                }
            }

            It "throws an exception" {
                # act / assert
                { Get-DropboxItemMeta -AccessToken $AccessToken -Path "/path/not/exists/file.txt" -ErrorAction Stop } | Should -Throw "Not found"
            }

        }

    }

}