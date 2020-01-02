<#
TODO:
//////////////
1 (tehtud). Kui nimes on t2pit2hti, v6iks need asendada tavaliste ladinat2htedega

https://www.lieben.nu/liebensraum/2018/12/removing-special-characters-from-utf8-input-for-use-in-email-addresses-or-login-names/

2. Resource Pool 6iguste jagamine
3. V2ljundi k2sureal v2hendamine
4. Dynaamilisus
#>

# Yhendab vCenter serveriga k6igepealt
Connect-VIServer -Server vcenter.khk.sise

# Impordib CSV faili (hetkel staatiline, teen l2hiajal dynaamilisemaks)
# Otsib / saab k2tte klusteri, mille alguseks on khk.sise
$tabel = Import-Csv '.\inimesed.csv'
$kluster = Get-Cluster -Location khk.sise*

# Vaatab iga rida, mida oli ette soodetud
$tabel.Grupp | Foreach-Object {
	
	# Kontrollib, kas grupi Resource Pool eksisteerib. Kui ei, siis teeb uue klustrisse.
	$groupExists = Get-ResourcePool -Location $kluster -Name $_ -ErrorAction SilentlyContinue
	if (!$groupExists) {
		New-ResourcePool -Location $kluster -Name $_
	}

}

$tabel | Foreach-Object {

	# Kuna nimed on CSV arvatavsti ette soodetud kui "Aadu Tamm" formaadis,
	# Asendab all olev muutuja tyhiku punktiga ning teeb suurt2hed v2ikesteks.
	$nimi = [regex]::Replace($_.Nimi, "\s+", ".").ToLower()
	
	# Samuti asendab k6ik t2pit2hed tavalisteks ladinat2htedeks
	$nimi = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($nimi))
	$grupp = $_.Grupp
	
	# Kontrollib, kas persooni Resource Pool eksisteerib, Kui ei, siis teeb uue vastavasse grupi
	# Resource Pool'i
	$nameExists = Get-ResourcePool -Location $_.Grupp -Name $grupp -ErrorAction SilentlyContinue
	if (!$nameExists) {
		New-ResourcePool -Location $grupp -Name $nimi
	}
}

# Yhendab lahti vCenter serveri yhenduse, enne skripti v2ljumist.
Disconnect-VIServer -Server vcenter.khk.sise
pause