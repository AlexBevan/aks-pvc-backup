function Get-Env
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$env
    )
    $var = Get-ChildItem env:$env -ErrorAction SilentlyContinue
    $var.value
}

function Connect-AksEnvironment
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$tenant_id,

        [Parameter(Mandatory=$true)]
        [String]$app_id,

        [Parameter(Mandatory=$true)]
        [String]$app_key,

        [Parameter(Mandatory=$true)]
        [String]$subscription_id,

        [Parameter(Mandatory=$true)]
        [String]$aks_rg,

        [Parameter(Mandatory=$true)]
        [String]$aks_name
    )    
    $passwd = ConvertTo-SecureString $app_key -AsPlainText -Force
    $pscredential = New-Object System.Management.Automation.PSCredential($app_id, $passwd)
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenant_id

    Get-AzSubscription -SubscriptionId $subscription_id -TenantId $tenant_id | Set-AzContext

    Import-AzAksCredential -ResourceGroupName $aks_rg -Name $aks_name -Force
}

function Get-VolumesMatchingAnnotation {
    $volumes = @()
    $pvcs = (kubectl get pvc --all-namespaces -o json | convertfrom-json)
    foreach ($item in $pvcs.items)
    {   
        if ($item.metadata.annotations  | Where-Object "volume.kubernetes.io/backup" -eq "yes"){
            $volumes += $item.spec.volumeName
        }
    }
    return $volumes
}
function Get-AllVolumes {
    $volumes = @()
    $pvcs = (kubectl get pvc --all-namespaces -o json | convertfrom-json)
    foreach ($item in $pvcs.items)
    {   
        $volumes += $item.spec.volumeName
    }
    return $volumes
}

function Backup-Disk
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, 
            HelpMessage="Name of the aks volume to be backed up.")]
        [String]$volumeName
    )
    BEGIN
    {

    }
    PROCESS
    {
        $diskName = "kubernetes-dynamic-$volumeName"
        $azdisk = Get-AzDisk -ResourceGroupName $aks_asset_rg -diskname $diskName

        $ErrorActionPreference = "continue"

        $ssConfig =  New-AzSnapshotConfig -SourceUri $azdisk.Id -Location $azdisk.location -CreateOption copy
        $timestamp = Get-Date -format "dd-MMM-yyyy-HHMM"
        write-output "$(get-date) Creating new snapshot $diskName-$timestamp."
        New-AzSnapshot -Snapshot $ssConfig -SnapshotName $diskName-$timestamp -ResourceGroupName $aks_rg

    }
    END
    {
    }
}

function Delete-OldSnapShots {
    param (
        [Parameter(Mandatory=$true, 
            HelpMessage="Number of days snapshots should be retained for.")]
        [String]$retention_period
    )
    BEGIN
    {

    }
    PROCESS
    {
        $ErrorActionPreference = "SilentlyContinue"
        $snapshots = Get-AzSnapshot -ResourceGroupName $aks_rg
        if ($null -ne $snapshots )
        {
            write-output "$(get-date) Removing snapshot older than $retention_period day(s) old."
            foreach ($snapshot in $snapshots){
                $date_from = (get-date).AddDays( - $retention_period)
                if ($snapshot.TimeCreated -lt $date_from) { 
                    $ErrorActionPreference = "SilentlyContinue"
                    $ss = Get-AzSnapshot -ResourceGroupName $aks_rg -name $($snapshot.Name)
                    if ($null -ne $ss)
                    {
                        write-output "$(get-date) Removing snapshot $($snapshot.Name)"
                        $ss | Remove-AzSnapshot -Force
                    }
                    $ErrorActionPreference = "continue"
                }
            }
        }
    }
}

