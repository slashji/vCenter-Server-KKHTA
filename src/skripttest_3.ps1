<#
TODO:
//////////////
1 (tehtud). Kui nimes on t2pit2hti, v6iks need asendada tavaliste ladinat2htedega

https://www.lieben.nu/liebensraum/2018/12/removing-special-characters-from-utf8-input-for-use-in-email-addresses-or-login-names/

2. Resource Pool 6iguste jagamine (pooleli)
3. V2ljundi k2sureal v2hendamine
4. Dynaamilisus
#>

# Yhendab vCenter serveriga k6igepealt
Connect-VIServer -Server vcenter.khk.sise

# Impordib CSV faili (hetkel staatiline, teen l2hiajal dynaamilisemaks)
# Otsib / saab k2tte klusteri, mille alguseks on khk.sise
$tabel = Import-Csv '.\inimesed.csv'
$kluster = Get-Cluster -Location khk.sise*
$datacenter = Get-Datacenter -Name khk.sise*

# Vaatab iga rida, mida oli ette soodetud
$tabel.Grupp | Foreach-Object {
	
	# Kontrollib, kas grupi Resource Pool eksisteerib. Kui ei, siis teeb uue klustrisse.
	$groupExists = Get-ResourcePool -Location $kluster -Name $_ -ErrorAction SilentlyContinue
	if (!$groupExists) {
		New-ResourcePool -Location $kluster -Name $_
	} else { Write-Host "Resource Pool $_ juba eksisteerib" -ForegroundColor Red }
	
	$datacentPerms = Get-VIPermission -Entity ($datacenter) -Principal KHK0\$_ -ErrorAction SilentlyContinue
	$klusterPerms = Get-VIPermission -Entity ($kluster) -Principal KHK0\$_ -ErrorAction SilentlyContinue
	$gruppPerms = Get-VIPermission -Entity ($groupExists) -Principal KHK0\$_ -ErrorAction SilentlyContinue
	
	if ((!$datacentPerms) -or (!$klusterPerms) -or (!$gruppPerms)) {
		if ($_ -ne 'Opetajad') {
			New-VIPermission -Role readonly -Principal KHK0\$_ -Entity ($kluster) -Propagate:$false
			New-VIPermission -Role readonly -Principal KHK0\$_ -Entity ($datacenter) -Propagate:$false
			New-VIPermission -Role readonly -Principal KHK0\$_ -Entity ($groupExists) -Propagate:$false
		}
	} else { Write-Host "Grupile $_ on juba õigused määratud" }
	
	$newFolder = Get-View (Get-View -viewtype datacenter).vmfolder
	if ($newFolder) {
		$newFolder.CreateFolder("$_")
		New-VIPermission -Role readonly -Principal KHK0\$_ -Entity (Get-Folder -Name $_) -Propagate:$false
		New-VIPermission -Role Opilased -Principal KHK0\Opetajad -Entity (Get-Folder -Name $_)
	}
	
	# $kaustExists = Get-Folder -Location $datacenter -Name $_ -ErrorAction SilentlyContinue
	# if (!$kaustExists) { New-Folder -Name $_ -Location $datacenter }
	# else { Write-Host "Kaust $_ juba on loodud" }
}

$tabel | Foreach-Object {

	# Kuna nimed on CSV arvatavsti ette soodetud kui "Aadu Tamm" formaadis,
	# Asendab all olev muutuja tyhiku punktiga ning teeb suurt2hed v2ikesteks.
	$nimi = [regex]::Replace($_.Nimi, "\s+", ".").ToLower()
	
	# Samuti asendab k6ik t2pit2hed tavalisteks ladinat2htedeks
	$nimi = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($nimi))
	
	# Kontrollib, kas persooni Resource Pool eksisteerib, Kui ei, siis teeb uue vastavasse grupi
	# Resource Pool'i
	$nameExists = Get-ResourcePool -Location $_.Grupp -Name $nimi -ErrorAction SilentlyContinue
	if (!$nameExists) {
		New-ResourcePool -Location $_.Grupp -Name $nimi
	} else { Write-Host "Resource Pool $nimi juba eksisteerib" -ForegroundColor red }
	
	# Peale individuaalsete Resource Pool'ide tegemist, määratakse ära nendele Opilase roll
	# Kui õigust kasutajale ei eksisteeri, antakse talle roll oma Resource Pool'ile
	$permsExist = Get-VIPermission -Entity (Get-ResourcePool -Location $_.Grupp -Name $nimi) -Principal KHK0\$nimi -ErrorAction SilentlyContinue
	if (!$permsExist) {
		New-VIPermission -Role Opilased -Principal KHK0\$nimi -Entity (Get-ResourcePool -Location $_.Grupp -Name $nimi)
	} else { Write-Host "Õigused on juba $nimi'le määratud" -ForegroundColor yellow }
	
	$folderExists = Get-Folder -Location $_.Grupp -Name $nimi -ErrorAction SilentlyContinue
	if (!$folderExists) {
		(Get-View -viewtype folder -filter @{"name"=$_.Grupp}).CreateFolder("$nimi")
	} else { Write-Host "Kaust $nimi juba olemas" }
	
	$folderPerms = Get-VIPermission -Entity (Get-Folder -Location $_.Grupp -Name $nimi) -Principal KHK0\$nimi -ErrorAction SilentlyContinue
	if (!$folderPerms) {
		New-VIPermission -Role Opilased -Principal KHK0\$nimi -Entity (Get-Folder -Location $_.Grupp -Name $nimi)
	}
}

# Yhendab lahti vCenter serveri yhenduse, enne skripti v2ljumist.
Disconnect-VIServer -Server vcenter.khk.sise -Confirm:$false
pause