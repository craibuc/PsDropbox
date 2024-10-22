<#
.SYNOPSIS

.PARAMETER AccessToken

.PARAMETER Path

.PARAMETER SelectUser

.PARAMETER RootFolderId

.EXAMPLE
Get-DropboxItemMeta -AccessToken '[access_token]' -Path '/path/to/folder'

.tag                    : folder
name                    : FOO Folder
path_lower              : /FOO folder
path_display            : /FOO Folder
parent_shared_folder_id : 2345678901
id                      : id:ABCDEFGHIJKLM
shared_folder_id        : 1234567890
sharing_info            : @{read_only=False; parent_shared_folder_id=2345678901; shared_folder_id=1234567890; traverse_only=False; no_access=False}

Get the Item's metadata.

.EXAMPLE
Get-DropboxItemMeta -AccessToken '[access_token]' -Path '' -SelectUser 'dbmid:XXXXXXXXXX' -RootFolderId '1234567890'

Get the item's metadata when the item has been shared.

.LINK
https://www.dropbox.com/developers/documentation/http/documentation#files-get_metadata
#>
function Get-DropboxItemMeta {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,

        [Parameter(Mandatory)]
        [string]$Path,

        [string]$SelectUser,
        [string]$RootFolderId
    )

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    if ($SelectUser) {$Headers['Dropbox-API-Select-User']=$SelectUser}
    if ($RootFolderId) {$Headers['Dropbox-API-Path-Root']=@{'.tag'='root'; root=$RootFolderId} | ConvertTo-Json -Compress}

    $Content = Send-Request -Path 'files/get_metadata' -Headers $Headers -Data ( @{ path = $Path } )
    $Content

}