Connect-VIServer -Server vcenter.khk.sise

$tabel = Import-Csv '.\inimesed.csv' | Select-Object 'Nimi', 'Grupp'
$kluster = Get-Cluster -Location khk.sise*

foreach ($isik in $tabel) {
	$nimi = $isik.Nimi
	$nimi = [regex]::Replace($nimi, "\s+", ".").ToLower()
	$grupp = $isik.Grupp
	
	$groupExists = Get-ResourcePool -Location $kluster -Name $grupp -ErrorAction SilentlyContinue  
	if (!$groupExists) {
		New-ResourcePool -Location $kluster -Name $grupp
	}
	
	$nameExists = Get-ResourcePool -Location $groupExists -Name $grupp -ErrorAction SilentlyContinue  
	if (!$nameExists) {
		New-ResourcePool -Location $groupExists -Name $nimi
	}
}

Disconnect-VIServer -Server vcenter.khk.sise
pause