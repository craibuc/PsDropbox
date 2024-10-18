function Move-DropboxItem {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter()]
        [bool]$AutoRename,

        [Parameter()]
        [bool]$AllowSharedFolder,

        [Parameter()]
        [bool]$AllowOwnershipTransfer
    )
    
    begin {
        $Headers = @{
            Authorization = "Bearer $AccessToken"
        }
    }
    
    process {
        
        $Body = @{
            from_path = $Path
            to_path = $Destination
            autorename = $AutoRename
            allow_shared_folder = $AllowSharedFolder
            allow_ownership_transfer = $AllowOwnershipTransfer
        } | ConvertTo-Json

        if ($PSCmdlet.ShouldProcess("$Path --> $Destination", "Move-DropboxItem")) {

            $Response = Invoke-WebRequest -Uri 'https://api.dropboxapi.com/2/files/move_v2' -Method Post -Body $Body -Headers $Headers -ContentType 'application/json'

            if ($Response.Content) {
                $Response.Content | ConvertFrom-Json
            }

        }

    }

    end {}
}