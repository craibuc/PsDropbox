BeforeAll {

  $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
  $PublicPath = Join-Path $ProjectDirectory "/PsDropbox/Public/"

  $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
  . (Join-Path $PublicPath $SUT)

}

Describe 'Test-DropboxApp' {

  Context "Parameter validation" {

    BeforeAll {
      $Command = Get-Command "Test-DropboxApp"
    }

    $Parameters = @(
        @{Name='AppKey';Type='string';Mandatory=$true}
        @{Name='AppSecret';Type='string';Mandatory=$true}
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

        $AppKey = New-Guid | Select-Object -ExpandProperty Guid
        $AppSecret = New-Guid | Select-Object -ExpandProperty Guid

        Mock Invoke-WebRequest {}

        # act
        Test-DropboxApp -AppKey $AppKey -AppSecret $AppSecret

    }

    It "uses the correct Uri" {
        # assert
        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://api.dropboxapi.com/2/check/app' }
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
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes("$AppKey`:$AppSecret")
        $Token = [Convert]::ToBase64String($Bytes)
  
        # assert
        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
            $Headers.Authorization -eq "Basic $Token"
        }
    }

    It "creates the correct Body" {
        # assert
        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { 
            $Actual = $Body | ConvertFrom-Json
            $Actual.query -eq 'Ping'
        }
    }

  }
}