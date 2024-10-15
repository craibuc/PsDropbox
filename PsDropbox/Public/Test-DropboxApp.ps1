<#
.SYNOPSIS
Validates the app key and secret.

.DESCRIPTION
This endpoint performs App Authentication, validating the supplied app key and secret, and returns the supplied string, to allow you to test your code and connection to the Dropbox API. It has no other effect. If you receive an HTTP 200 response with the supplied query, it indicates at least part of the Dropbox API infrastructure is working and that the app key and secret valid.

.PARAMETER AppKey
AKA client_id

.PARAMETER AppSecret
AKA client_secret

.EXAMPLE
Test-DropboxApp -AppKey $Env:DROPBOX_CLIENT_ID -AppSecret $Env:DROPBOX_CLIENT_SECRET

true

.LINK
https://www.dropbox.com/developers/documentation/http/documentation#check-app
#>
function Test-DropboxApp {
  [CmdletBinding()]
  param (
      [parameter(Mandatory)]
      [Alias('client_id')]
      [string]$AppKey,

      [parameter(Mandatory)]
      [Alias('client_secret')]
      [string]$AppSecret
  )
  
  try {
      $Bytes = [System.Text.Encoding]::UTF8.GetBytes("$AppKey`:$AppSecret")
      $Token = [Convert]::ToBase64String($Bytes)

      Invoke-WebRequest -Method Post -Uri 'https://api.dropboxapi.com/2/check/app' -Body ( @{query='Ping'}|ConvertTo-Json ) -Headers @{Authorization = "Basic $Token"} -ContentType 'application/json' | Out-Null
      return $true
  }
  catch {
      return $false
  }

}