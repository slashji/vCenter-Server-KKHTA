# Yhendab vCenter serveriga k6igepealt
Connect-VIServer -Server vcenter.khk.sise

# Impordib CSV faili (hetkel staatiline, teen l2hiajal dynaamilisemaks)
# Otsib / saab k2tte klusteri, mille alguseks on khk.sise
$tabel = Import-Csv '.\inimesed.csv'
$kluster = Get-Cluster -Location khk.sise*

$filter = 'datastore'

$datastores = Get-Datastore | ? {$_.name -imatch 'datastore'}

$tabel.Grupp | Foreach-Object {
	
	ForEach ($datastore in $datastores) {
		Write-Host $datastore -BackgroundColor Blue
		$datastorePerms = Get-VIPermission -Entity ($datastore) -Principal KHK0\$_
		if (!$datastorePerms) {
			New-VIPermission -Role Opilased -Principal KHK0\$_ -Entity ($datastore) -Propagate:$false
		} else {
			Write-Host "$_ lol"
		}
	}
}