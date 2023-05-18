BeforeAll {

    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

    $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}

Describe 'Send-DropboxFile' {

    BeforeEach {

        # arrange
        $ApiKey = '2134d8d5-d1b4-4a1d-89ac-f44a96514bb5'
        $Source = "~/Prime_Numbers.txt"
        $Destination = "/Homework/math/Prime_Numbers.txt"

    }

    Context "Request" {

        BeforeEach {

            Mock Invoke-WebRequest {}

            # act
            Send-DropboxFile -ApiKey $ApiKey -Source $Source -Destination $Destination

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
                $Headers.Authorization -eq "Bearer $ApiKey"
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

    }

}