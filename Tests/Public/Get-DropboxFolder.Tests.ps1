BeforeAll {

    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

    $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}

Describe 'Get-DropboxFolder' {

    BeforeEach {

        # arrange
        $ApiKey = '2134d8d5-d1b4-4a1d-89ac-f44a96514bb5'
        $Path = '/'

    }

    Context "when the request has a single page" {

        BeforeEach {

            Mock Invoke-WebRequest {
                $Fixture = 'Get-DropboxFolder.Response.200.json'
                $Content = Get-Content (Join-Path $FixturesDirectory $Fixture) -Raw

                $Response = New-MockObject -Type  Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject
                $Response | Add-Member -Type NoteProperty -Name 'Content' -Value $Content -Force
                $Response
            }

            # act
            Get-DropboxFolder -ApiKey $Api-ApiKey -Path $Path

        }

        It "uses the correct Uri" {
            # assert
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/files/list_folder' }
        }

        It "uses the correct Method" {
            # assert
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Method -eq 'Post' }
        }

        It "uses the correct ContentType" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $ContentType -eq 'application/json' }
        }

        It "creates the correct Body" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
                $Actual = $Body | ConvertFrom-Json
                $Actual.path -eq $Path
            }
        }

        It "retrieves one page" {
            Should -Invoke -CommandName Invoke-WebRequest -Times 1
        }

        Context "when the Recursive parameter is supplied" {

            BeforeEach {
                # act
                Get-DropboxFolder -ApiKey $Api-ApiKey -Path $Path -Recursive
            }

            It "creates the correct Body" {

                # assert
                Assert-MockCalled Invoke-WebRequest -ParameterFilter { 
                    $Actual = $Body | ConvertFrom-Json
                    $Actual.recursive -eq $true
                }

            }

        }

    }

    Context "when the response includes multiple pages" {

        BeforeEach {

            Mock Invoke-WebRequest {
                Write-Debug "********** Page 1 **********"
                $Fixture = 'Get-DropboxFolder.Response.200.1.json'
                $Content = Get-Content (Join-Path $FixturesDirectory $Fixture) -Raw

                $Response = New-MockObject -Type  Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject
                $Response | Add-Member -Type NoteProperty -Name 'Content' -Value $Content -Force
                $Response
            } # -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/files/list_folder/continue' }

            Mock Invoke-WebRequest {
                Write-Debug "********** Page 0 **********"
                $Fixture = 'Get-DropboxFolder.Response.200.0.json'
                $Content = Get-Content (Join-Path $FixturesDirectory $Fixture) -Raw

                $Response = New-MockObject -Type  Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject
                $Response | Add-Member -Type NoteProperty -Name 'Content' -Value $Content -Force
                $Response
            }  -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/files/list_folder' }

            # act
            Get-DropboxFolder -ApiKey $ApiKey -Path $Path

        }

        It "calls retrieves each page" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -Times 2
        }

    }

}