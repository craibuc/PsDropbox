function Move-DropboxItem {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [Alias('Source')]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter()]
        [bool]$AutoRename,

        [Parameter()]
        [bool]$AllowSharedFolder,

        [Parameter()]
        [bool]$AllowOwnershipTransfer,

        [string]$SelectUser,
        [string]$RootFolderId
    )

    begin {
        $Headers = @{
            Authorization = "Bearer $AccessToken"
        }
    }

    process {

        $Data = @{
            from_path = $Path
            to_path = $Destination
            autorename = $AutoRename
            allow_shared_folder = $AllowSharedFolder
            allow_ownership_transfer = $AllowOwnershipTransfer
        }

        if ($SelectUser) {$Headers['Dropbox-API-Select-User']=$SelectUser}
        if ($RootFolderId) {$Headers['Dropbox-API-Path-Root']=@{'.tag'='root'; root=$RootFolderId} | ConvertTo-Json -Compress}

        if ($PSCmdlet.ShouldProcess("$Path --> $Destination", "Move-DropboxItem")) {
            Send-Request -Path 'files/move_v2' -Headers $Headers -Data $Data
        }

    }

    end {}
}