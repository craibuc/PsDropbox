BeforeAll {

  $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
  $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

  $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
  . (Join-Path $PublicPath $SUT)

}

Describe 'Test-DropboxAccessToken' {

  Context "Parameter validation" {

    BeforeAll {
      $Command = Get-Command "Test-DropboxAccessToken"
    }

    $Parameters = @(
        @{Name='AccessToken';Type='string';Mandatory=$true}
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
    
  } # /context

  Context "Request" {

    BeforeEach {
        # arrange
        $AccessToken = New-Guid | Select-Object -ExpandProperty Guid

        Mock Invoke-WebRequest {}

        # act
        Test-DropboxAccessToken -AccessToken $AccessToken

    }

    It "uses the correct Uri" {
        # assert
        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/users/get_current_account' }
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
            $Actual.query -eq $null
        }
    }

  }
}