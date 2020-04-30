Connect-VIServer -Server vcenter.khk.sise

$datacenter = Get-Datacenter -Name *Datacenter
$internetPG = Get-VDPortGroup -Name 000_INTERNET
$tabel = Import-Csv '.\inimesed.csv'

$tabel.Grupp | Foreach-Object {
	$internetPGPerms = Get-VIPermission -Entity ($internetPG) -Principal KHK0\$_ -ErrorAction SilentlyContinue
	if (!$internetPGPerms) {
		New-VIPermission -Role Opilased -Principal KHK0\$_ -Entity ($internetPG) -Propagate:$false
	} else {
		Write-Host "Grupile $_ on juba 000_INTERNET õigused määratud"
	}
}

$vdswitch = Get-VDSwitch -Location $datacenter

$tabel | Foreach-Object {

	$nimi = [regex]::Replace($_.Nimi, "\s+", ".").ToLower()
	$nimi = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($nimi))

	$portGroupExists = Get-VirtualPortGroup -Name $nimi -ErrorAction SilentlyContinue
	if (!$portGroupExists) {
		New-VDPortGroup -VDSwitch $vdswitch -Name $nimi -NumPorts 8 -VLanId $_.VLAN
		Get-VDPortGroup -Name $nimi | New-VIPermission -Role Opilased -Principal KHK0\$nimi -Propagate:$false
	} else {
		Write-Host "$nimi juba olemas"
	}
}

Disconnect-VIServer -Server vcenter.khk.sise -Confirm:$false
pause