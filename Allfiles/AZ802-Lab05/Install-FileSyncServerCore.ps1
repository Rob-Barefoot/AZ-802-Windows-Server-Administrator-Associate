$srvName = 'SEA-SVR1'
$rgName = 'AZ802-L0501-RG'
$fsName = 'FileSync1'

New-Item -Type Directory -Path "\\$srvName\c$\Temp" -Force
Copy-Item -Path C:\Labfiles\Lab05\StorageSyncAgent_WS2022.msi -Destination "\\$srvName\c$\Temp\" -PassThru

Invoke-Command -ComputerName $srvName -ArgumentList ($rgName, $fsName) {
    param($rgName, $fsName)
    Install-PackageProvider -Name NuGet -Force
    Install-Module az.StorageSync -Force
    Start-Process -FilePath "C:\Temp\StorageSyncAgent_WS2022.msi" -ArgumentList "/quiet" -Wait
    Connect-AzAccount -UseDeviceAuthentication
    Register-AzStorageSyncServer -ResourceGroupName $rgName -StorageSyncServiceName $fsName | Out-Null
    Write-Output "Script finished"
}
