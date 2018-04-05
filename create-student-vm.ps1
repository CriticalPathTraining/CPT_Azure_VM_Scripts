cls
$tenantName = "sharepointconfessions"
$tenantAdminAccountName = "tedp"
$tenantDomain = $tenantName + ".onMicrosoft.com"
$tenantAdminSPN = $tenantAdminAccountName + "@" + $tenantDomain

$vmlabel = "student01"

$location = "eastus2" 
$resourceGroupName = $vmlabel + "-vm"

$storageAccountName = $vmlabel + "storage"
$subnetName = $vmlabel + "-subnet"
$virtualNetworkName = $vmlabel + "-vnet"
$networkInterfaceName = $vmlabel + "-nic"
$publicIpAddressName = $vmlabel + "-publicIP"
$domainNameLabel = $vmlabel + "vm"

$vmName = $vmlabel + "-vm"

$osDiskName = $vmlabel + "-OSDisk"
$osDiskUri = "https://cptvm.blob.core.windows.net/backup/wingtipserver.vhd"

$credential = Get-Credential -UserName $tenantAdminSPN -Message "Enter password"
Login-AzureRmAccount -Credential $credential | Out-Null

Set-AzureRmContext -Subscription 9c8547bc-0a61-4cf0-bfd5-b08c7fe353cb

# Create group if it does't exist
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction Ignore
if(!$resourceGroup){
  Write-Host "Resource group named" $resourceGroupName "does not exist - now creating it"
  $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}

# Process for creating web app
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Ignore
if(!$storageAccount){
    # ensure web app name is not in use
    $originalName = $storageAccountName
    $counter = 0

    while( (Get-AzureRmStorageAccountNameAvailability -Name $storageAccountName).NameAvailable -eq $false ){
        Write-Host "Storage account name $storageAccountName already in use"
        $counter += 1
        $storageAccountName = $originalName + $counter
    }

    Write-Host "Calling New-AzureRmStorageAccount to create a storage account named $storageAccountName"
    $storageAccount = New-AzureRmStorageAccount `
                        -Location $location `
                        -ResourceGroupName $resourceGroupName `
                        -Name $storageAccountName `
                        -SkuName Premium_LRS `
                        -Kind Storage                        
}

Write-Host "Calling New-AzureRmVirtualNetworkSubnetConfig to create subnet named $subnetName"
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24


Write-Host "Calling New-AzureRmVirtualNetwork to create Virtual network name $virtualNetworkName"
$virtualNetwork = New-AzureRmVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -Name $virtualNetworkName `
                      -Subnet $subnet `
                      -AddressPrefix 10.0.0.0/16 `
                      -WarningAction SilentlyContinue


$counter = 0
$originalName = $domainNameLabel
while( (Test-AzureRmDnsAvailability -Location $location -DomainNameLabel $domainNameLabel) -eq $false ){
    Write-Host "domain label name $domainNameLabel already in use"
    $counter += 1
    $domainNameLabel = $originalName + $counter
}

Write-Host "Calling New-AzureRmPublicIpAddress to create static public IP address with domain label name of $domainNameLabel"
$publicIpAddress = New-AzureRmPublicIpAddress `
                        -Name $publicIpAddressName `
                        -ResourceGroupName $resourceGroupName `
                        -Location $location `
                        -AllocationMethod Static `
                        -DomainNameLabel $domainNameLabel `
                        -WarningAction SilentlyContinue

Write-Host "Calling New-AzureRmNetworkInterface to create network interface named $networkInterfaceName"
$networkInterface = New-AzureRmNetworkInterface `
                        -Name $networkInterfaceName `
                        -ResourceGroupName $resourceGroupName `
                        -Location $location `
                        -SubnetId $virtualNetwork.Subnets[0].Id `
                        -PublicIpAddressId $publicIpAddress.Id `
                        -WarningAction SilentlyContinue


Write-Host "Calling New-AzureRmVMConfig to create new VM configuration with name of $vmName and size of $vmSize"
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

Write-Host "Calling Add-AzureRmVMNetworkInterface"
$vmNic = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $networkInterface.Id

Write-Host "Calling New-AzureRmDiskConfig"
$diskConfig = New-AzureRmDiskConfig -AccountType PremiumLRS -Location $location -CreateOption Import -SourceUri $osDiskUri 

Write-Host "Calling New-AzureRmDisk"
$osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk $diskConfig  -ResourceGroupName $resourceGroupName

Write-Host "Calling Set-AzureRmVMOSDisk"
$vmOSDisk = Set-AzureRmVMOSDisk -VM $vmNic -ManagedDiskId $osDisk.Id -StorageAccountType PremiumLRS -DiskSizeInGB 128 -CreateOption Attach -Windows

Write-Host "Calling Set-AzureRmVMBootDiagnostics"
$vmDiag = Set-AzureRmVMBootDiagnostics -VM $vmOSDisk -disable

Write-Host "Calling New-AzureRmVM to create the VM"
$vm = New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmDiag

Write-Host "The script has completed successfully"

$vm | select *