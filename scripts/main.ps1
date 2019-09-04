# make the functions available to main
Import-Module  $PSScriptRoot/functions.ps1 -Force

# Get variables

$tenant_id = Get-Env "AZURE_TENANT_ID"
$app_id = Get-Env "AZURE_APP_ID"
$app_key = Get-Env "AZURE_APP_KEY"
$subscription_id = Get-Env "AZURE_SUBSCRIPTION_ID"

$aks_rg = Get-Env "AKS_RG"
$aks_asset_rg = Get-Env "AKS_ASSET_RG"
$aks_name = Get-Env "AKS_NAME"
$aks_backup_tags_only = Get-Env "AKS_BACKUP_TAGS_ONLY"
$aks_backup_retention = Get-Env "AKS_BACKUP_RETENTION"

# Do 
# The
# Thing

# Login

Connect-AksEnvironment -tenant_id $tenant_id -app_id $app_id -app_key $app_key `
-subscription_id $subscription_id -aks_rg $aks_rg -aks_name $aks_name


# Create snapshots
if ($aks_backup_tags_only){ # Backup only volumes tagged with "volume.kubernetes.io/backup" : "yes"
    write-output "$(get-date) Backing up all volumes matching volume.kubernetes.io/backup annotation."
    Foreach ($volume in Get-VolumesMatchingAnnotation){
        Backup-Disk -volumeName $volume 
    }
} else { # backup all pvc volumes
    write-output "$(get-date) Backing up all volumes."
    Foreach ($volume in Get-AllVolumes){
        Backup-Disk -volumeName $volume 
    }
}

# Delete old snapshots, default = 30 days
if ($aks_backup_retention) {
    Delete-OldSnapshots -retention_period $aks_backup_retention
} else {
    Delete-OldSnapshots -retention_period 30
}

# leave
write-output "$(get-date) Finished, exiting."
exit
