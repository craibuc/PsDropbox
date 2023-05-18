BeforeAll {

    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

    # $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}

Describe 'Remove-DropboxFileTag' {

    BeforeEach {

        # arrange
        $ApiKey = '2134d8d5-d1b4-4a1d-89ac-f44a96514bb5'
        $Path = "/Homework/math/Prime_Numbers.txt"
        $Tag = 'lorem'

    }

    Context "Request" {

        BeforeEach {

            Mock Invoke-WebRequest {}

            # act
            Remove-DropboxFileTag -ApiKey $ApiKey -Path $Path -Tag $Tag

        }

        It "uses the correct Uri" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/files/tags/remove' }
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
                $Headers.Authorization -eq "Bearer $ApiKey"
            }
        }

        It "creates the correct Body" {
            # assert
            Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
                $Actual = $Body | ConvertFrom-Json
                $Actual.path -eq $Path -and
                $Actual.tag_text -eq $Tag
            }
        }

    }

}