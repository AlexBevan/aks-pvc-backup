# AKS PVC Backup

Creates Snapshots of Azure Disks associated to K8S PVCs.

Required environmental variables:

* AZURE_TENANT_ID 
  * Azure Tenant ID
* AZURE_APP_ID 
  * Azure Service Principle ID
* AZURE_APP_KEY
  * Azure Service Principle Secret
* AZURE_SUBSCRIPTION_ID
  * Azure Subscription where AKS is deployed.

* AKS_RG
  * Resource Group where AKS is deployed
* AKS_ASSET_RG
  * AKS asset RG name ie. MC_myaks_myaks_uksouth
* AKS_NAME
  * Name of AKS deployment ie. myaks
* AKS_BACKUP_TAGS_ONLY
  * leaving blank will backup all PVCs, providing a value will only backup PVCs with the "volume.kubernetes.io/backup" : "yes" annotation.
* AKS_BACKUP_RETENTION
  * Number of days to keep backups for, if blank default value of 30 is used
