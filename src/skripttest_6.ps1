# Yhendab vCenter serveriga k6igepealt
Connect-VIServer -Server vcenter.khk.sise

# Impordib CSV faili (hetkel staatiline, teen l2hiajal dynaamilisemaks)
# Otsib / saab k2tte klusteri, mille alguseks on khk.sise
$tabel = Import-Csv '.\inimesed.csv'
$kluster = Get-Cluster -Location *Datacenter
$dsCluster = Get-DatastoreCluster -Name "*Datastore Cluster"

# $filter = 'datastore'

$datastores = Get-Datastore | ? {$_.name -imatch 'datastore'}
$isoDs = Get-Datastore -Name ISOD

$tabel.Grupp | Foreach-Object {
	
	$dsClusterPerms = Get-VIPermission -Entity ($dsCluster) -Principal KHK0\$_
	if (!$dsClusterPerms) {
		New-VIPermission -Role Opilased -Principal KHK0\$_ -Entity ($dsCluster)
	}
	
	ForEach ($datastore in $datastores) {
		# Write-Host $datastore -BackgroundColor Blue
		$datastorePerms = Get-VIPermission -Entity ($datastore) -Principal KHK0\$_
		if (!$datastorePerms) {
			New-VIPermission -Role Opilased -Principal KHK0\$_ -Entity ($datastore)
		} else {
			Write-Host "Grupile $_ juba määratud andmekogule $datastore"
		}
	}
	
	$isoDsPerms = Get-VIPermission -Entity ($isoDs) -Principal KHK0\$_
	if (!$isoDsPerms) {
		New-VIPermission -Role Opilased -Principal KHK0\$_ -Entity ($isoDs)
	}
	
}

Disconnect-VIServer -Server vcenter.khk.sise -Confirm:$false
pause