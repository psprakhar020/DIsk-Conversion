<#
#          Script: Managed to Unmanaged disk conversion                                          
#            Date: December 2, 2018                                                                     
#          Author: Prakhar Sharma
#

DESCRIPTION:
This script is used to convert datadisk from managed to unmanaged 
#>


Param(
[Parameter(Mandatory = $true)][String]$ResourceGroupName,
[Parameter(Mandatory = $true)][String]$Storageaccount,
[Parameter(Mandatory = $true)][String]$Key,
[Parameter(Mandatory = $true)][String]$Diskname
)

#Sign into Azure Portal
login-azurermaccount

#Getting context for access to storage account
$context = New-AzureStorageContext -StorageAccountName $Storageaccount -StorageAccountKey $Key

#Creating new storage container
New-AzureStorageContainer -Name "vhds" -Context $context -Permission Off

#Getting access URI for the managed disk 
$sas = Grant-AzureRmDiskAccess -ResourceGroupName $ResourceGroupName -DiskName $Diskname -Access Read -DurationInSecond (60*60*24)

#Starting the copy of disk from the manged disk to storage account
$Blobcopyresult = Start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestinationContainer "vhds" -DestinationBlob  "$Diskname+vhd" -DestinationContext $context


while(($Blobcopyresult | Get-AzureStorageBlobCopyState).Status -eq "Pending")
{
Write-Host $($Blobcopyresult | Get-AzureStorageBlobCopyState).BytesCopied "out of" $($Blobcopyresult | Get-AzureStorageBlobCopyState).TotalBytes 
}