#
# Script to implement Storage Spaces Direct
#

#
# Step 0. Install management tools on management server
#
Install-WindowsFeature RSAT -IncludeAllSubFeature
Restart-computer

#
# Step 1. Install the Windows Server roles and features
#
Invoke-Command -ComputerName SEA-SVR1,SEA-SVR2,SEA-SVR3 -ScriptBlock {Install-WindowsFeature -Name File-Services, Failover-Clustering -IncludeManagementTools}
Invoke-Command -ComputerName SEA-SVR1,SEA-SVR2,SEA-SVR3 -ScriptBlock {Restart-Computer -Force}
Install-WindowsFeature RSAT-Clustering-MGMT 
#
# Step 2. Validate cluster
#
Test-Cluster -Node SEA-SVR1,SEA-SVR2,SEA-SVR3 -Include 'Storage Spaces Direct',Inventory,Network,'System Configuration'

#
#Step 3. Create cluster
#
New-Cluster -Name S2DCluster -Node SEA-SVR1,SEA-SVR2,SEA-SVR3 -NoStorage -StaticAddress 172.16.0.40

#
# Step 4. Enable Storage Spaces Direct
#
Invoke-Command -ComputerName SEA-SVR1 -ScriptBlock {Enable-ClusterS2D -CacheState Disabled -AutoConfig:0 -SkipEligibilityChecks -Confirm:$false}

#
# Step 5. Create storage pools
#
Invoke-Command -ComputerName SEA-SVR1 -ScriptBlock {New-StoragePool  -StorageSubSystemName S2DCluster.Contoso.com -FriendlyName S2DStoragePool -ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault Mirror -PhysicalDisk (Get-StorageSubSystem  -Name S2DCluster.Contoso.com | Get-PhysicalDisk)}

#
# Step 6. Create virtual disks
#
Invoke-Command -ComputerName SEA-SVR1 -ScriptBlock {New-Volume -StoragePoolFriendlyName S2DStoragePool -FriendlyName "CSV" -FileSystem CSVFS_ReFS -Size 5GB}

#
# Step 7. Create File Server
#
Invoke-Command -ComputerName SEA-SVR1 -ScriptBlock {New-StorageFileServer -StorageSubSystemName S2DCluster.Contoso.com -FriendlyName S2D-SOFS -HostName S2D-SOFS -Protocols SMB}

#
# Step 8. Create file shares
#Administrator: Windows PowerShell ISE 
Invoke-Command -ComputerName SEA-SVR3 -ScriptBlock {md "C:\ClusterStorage\CSV\VM01" }
Invoke-Command -ComputerName SEA-SVR1 -ScriptBlock {New-SmbShare -Name VM01 -Path "C:\ClusterStorage\CSV\VM01" -FullAccess "Contoso\Administrator"}
Invoke-Command -ComputerName SEA-SVR1 -ScriptBlock {Set-SmbPathAcl -ShareName VM01}

