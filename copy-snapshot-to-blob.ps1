$storageAccountName = "cptvm"
$storageAccountKey = "L7oKW264eXZ2NPO1NuR1NV2dCNKPLN5AIVWvA78hPcCAckBHLOD30gYS6dJ3+mtX4LJxsyvqDAgSR/MeBkJEBA=="
$absoluteUri = "https://md-qplchggcbqsp.blob.core.windows.net/t3lzk2mcjwpl/abcd?sv=2017-04-17&sr=b&si=89fb4310-6e46-4bed-baf6-b4cbf4cdfbc8&sig=RquwHsZWlVcLpjKEIkDJlsnOpnftUarx6w2A8wGnjZg%3D"
$destContainer = "vms"
$blobName = “wingtipserver.vhd”

$destContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Start-AzureStorageBlobCopy -AbsoluteUri $absoluteUri -DestContainer $destContainer -DestContext $destContext -DestBlob $blobName