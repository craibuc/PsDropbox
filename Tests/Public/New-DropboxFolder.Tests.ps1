BeforeAll {

    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

    # $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}

Describe 'New-DropboxFolder' {

    Context "Parameter validation" {

        BeforeAll {
          $Command = Get-Command "New-DropboxFolder"
        }
    
        $Parameters = @(
            @{Name='AccessToken';Type='string';Mandatory=$true}
            @{Name='Path';Type='string';Mandatory=$true}
            @{Name='AutoRename';Type='switch';Mandatory=$false}
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
            $Path = "/Homework/math"

            Mock Invoke-WebRequest {}

            # act
            New-DropboxFolder -AccessToken $AccessToken -Path $Path

        }

        It "uses the correct Uri" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/files/create_folder_v2' }
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
                $Actual.path -eq $Path -and
                $Actual.autorename -eq $false
            }
        }

        Context 'when the AutoRename parameter is supplied' {

            BeforeEach {
                # arrange
                Mock Invoke-WebRequest {}
                # act
                New-DropboxFolder -AccessTo $AccessToken -Path $Path -AutoRename
            }

            It "creates the correct Body" {
                # assert
                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Actual = $Body | ConvertFrom-Json
                    $Actual.autorename -eq $true
                }
            }

        }

        Context 'when the SelectUser parameter is supplied' {

            BeforeEach {
                # arrange
                Mock Invoke-WebRequest {}
                # act
                New-DropboxFolder -AccessTo $AccessToken -Path $Path -SelectUser 'SelectUser'
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
                New-DropboxFolder -AccessTo $AccessToken -Path $Path -RootFolderId 'RootFolderId'
            }

            It "adds the Dropbox-API-Path-Root header" {
                # assert
                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Headers.'Dropbox-API-Path-Root' -eq @{root = 'RootFolderId'} | ConvertTo-Json -Compress
                }
            }

        }

    }

}