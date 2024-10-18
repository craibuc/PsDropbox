BeforeAll {

    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

    $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}

Describe 'Send-DropboxFile' {

    Context "Parameter validation" {

        BeforeAll {
          $Command = Get-Command "Send-DropboxFile"
        }
    
        $Parameters = @(
            @{Name='AccessToken';Type='string';Mandatory=$true}
            @{Name='Source';Type='string';Mandatory=$true}
            @{Name='Destination';Type='string';Mandatory=$true}
            @{Name='Mode';Type='string';Mandatory=$false}
            @{Name='AutoRename';Type='switch';Mandatory=$false}
            @{Name='Mute';Type='switch';Mandatory=$false}
            @{Name='StrictConflict';Type='switch';Mandatory=$false}
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
            $Source = "~/Prime_Numbers.txt"
            $Destination = "/Homework/math/Prime_Numbers.txt"

            Mock Invoke-WebRequest {}

            # act
            Send-DropboxFile -AccessTo $AccessToken -Source $Source -Destination $Destination

        }

        It "uses the correct Uri" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://content.dropboxapi.com/2/files/upload' }
        }

        It "uses the correct Method" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Method -eq 'Post' }
        }

        It "uses the correct ContentType" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $ContentType -eq 'application/octet-stream' }
        }

        It "uses the correct Authorization header" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                $Headers.Authorization -eq "Bearer $AccessToken"
            }
        }

        It "uses the correct Dropbox-API-Arg header" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                $Headers.'Dropbox-API-Arg' -eq @{path = $Destination} | ConvertTo-Json -Compress
            }
        }

        It "uses the correct InFile" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $InFile -eq $Source }
        }

        Context 'when the SelectUser parameter is supplied' {

            BeforeEach {
                # arrange
                Mock Invoke-WebRequest {}
                # act
                Send-DropboxFile -AccessTo $AccessToken -Source $Source -Destination $Destination -SelectUser 'SelectUser'
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
                Send-DropboxFile -AccessTo $AccessToken -Source $Source -Destination $Destination -RootFolderId 'RootFolderId'
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