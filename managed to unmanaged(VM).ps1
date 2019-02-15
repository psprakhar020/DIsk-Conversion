<#
          Script: Managed to Unmanaged disk conversion                                          
          Date: December 2, 2018                                                                     
          Author: Prakhar Sharma


DESCRIPTION:
This script is used to convert OS disk from managed to unmanaged
#>

Param(
[Parameter(Mandatory = $true)][String]$ResourceGroupName,
[Parameter(Mandatory = $true)][String]$VMname,
[Parameter(Mandatory = $true)][String]$Storageaccount,
[Parameter(Mandatory = $true)][String]$Key
)

#Sign into Azure Portal
login-azurermaccount

$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMname

#Get name of OS disk
$OSdisk= $vm.StorageProfile.OsDisk | Where-Object {$_.ManagedDisk -ne $null} | Select-Object Name

#Getting context for access to storage account
$context = New-AzureStorageContext -StorageAccountName $Storageaccount -StorageAccountKey $Key

#Creating new storage container
New-AzureStorageContainer -Name "vhds" -Context $context -Permission Off

#Getting access URI for the managed disk 
$sas = Grant-AzureRmDiskAccess -ResourceGroupName $ResourceGroupName -DiskName $OSdisk.Name -Access Read -DurationInSecond (60*60*24)

#Starting the copy of disk from the manged disk to storage account
$Blobcopyresult = Start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestinationContainer "vhds" -DestinationBlob '$OSdisk.name +"vhd"' -DestinationContext $context



while(($Blobcopyresult | Get-AzureStorageBlobCopyState).Status -eq "Pending")
{
Write-Host $($Blobcopyresult | Get-AzureStorageBlobCopyState).BytesCopied "out of" $($Blobcopyresult | Get-AzureStorageBlobCopyState).TotalBytes 
} 
