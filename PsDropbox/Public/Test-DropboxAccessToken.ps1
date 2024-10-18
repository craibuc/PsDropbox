function Test-DropboxAccessToken {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$AccessToken,

        [string]$SelectUser,
        [string]$RootFolderId
    )

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    if ($SelectUser) {$Headers['Dropbox-API-Select-User']=$SelectUser}
    if ($RootFolderId) {$Headers['Dropbox-API-Path-Root']=@{'.tag'='root'; root=$RootFolderId} | ConvertTo-Json -Compress}

    try {
        Invoke-WebRequest -Method Post -Uri 'https://api.dropboxapi.com/2/users/get_current_account' -Body ( $null | ConvertTo-Json ) -Headers $Headers -ContentType 'application/json' | Out-Null
        $true
    }
    catch {
        $false
    }
    
}