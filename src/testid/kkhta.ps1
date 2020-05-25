<#
TODO:
//////////////
#>

$vcenterServer = ""
do {

	$vcenterServer = Read-Host -Prompt 'Sisesta vCenter serveri aadress'
	
	# kui aadressit pole sisestatud
	if (!$vcenterServer) {
		Write-Host "== Aadress ei tohi olla tühi ==" -BackgroundColor red
	} else {
	
		# Ühendab vCenter serveriga, et järgnevaid toiminguid saaks teha
		$vc = Connect-VIServer -Server $vcenterServer -ErrorAction SilentlyContinue
		
		# Kui on ühendus loodud
		if ($vc.IsConnected) {
			Write-Host "== $vcenterServer ühendatud ==" -ForegroundColor green
			
		# Kui ebaõnnestus, väljastab tõrke
		} else {
			Write-Host "$vcenterServer ei ole ühendatud" -BackgroundColor red
			Write-Host "Ilmnes tõrge: " $Error[0] -BackgroundColor red
			$vcenterServer = ""
		}
	}
	
} until (!$vcenterServer -eq "") # niikaua kuni on sisestatud vCenter serveri aadress

$csvFail = ""
$tabel = ""
do {

	$csvFail = Read-Host -Prompt 'Sisestage CSV fail, kus on olemas nimed, grupid ning VLAN ID-d (faili tee)'
	
	# Kui pole midagi sisestatud
	if (!$csvFail) {
		Write-Host "Faili tee / nimi ei tohi olla tühi" -BackgroundColor red
	} else {
	
		# Kui leiab sisestatud faili nime samast kaustast / teest
		$failOlemas = Test-Path -Path $csvFail
		if ($failOlemas) {
		
			# Impordib CSV faili, kus on tabel andmetega
			$tabel = Import-Csv $csvFail
			
			# Tabeli veeru nimede kontroll
			$tabelVeerg = ($tabel[0].psobject.Properties).name
			
			# Kui tabeli veergude nimed on 'Nimi', 'Grupp', 'VLAN'
			$tabelVeerg = ($tabelVeerg -contains 'Nimi') -and ($tabelVeerg -contains 'Grupp') -and ($tabelVeerg -contains 'VLAN')
			if ($tabelVeerg) {
				Write-Host "== Tabel importitud ==" -ForegroundColor green
			} else {
				Write-Host "Puudub / Puuduvad veerud. Vaadake, kas on tabelis olemas veerud Nimi, Grupp, VLAN (selles järjekorras)" -BackgroundColor red
				$csvFail = ""
			}
		} else {
			Write-Host "== Sellist faili nagu $csvFail ei leitud ==" -BackgroundColor red
			$csvFail = ""
		}
	}

} until (!$csvFail -eq "")

$domeenNimi = ""
do {
	$domeenNimi = Read-Host -Prompt "Sisestage domeeni nimi"
	
	# Kui domeeninime pole antud
	if (!$domeenNimi) {
		Write-Host "Domeeni nimi ei tohi olla tühi"
	} else {
		Write-Host "== $domeenNimi valitud ==" -ForegroundColor green
	}
} until (!$domeenNimi -eq "")

# Võtab klustri ja andmekeskuse, mis lõpeb sõnaga "Cluster", "Datacenter"
$kluster = Get-Cluster -Name "*Cluster"
$datacenter = Get-Datacenter -Name "*Datacenter"

# Võtab andmehoidla klustri, mis lõpeb sõnaga "Datastore Cluster"
$dsCluster = Get-DatastoreCluster -Location $datacenter

$datastores = Get-Datastore | ? {$_.name -imatch 'datastore'} # Otsib välja kõik andmehoidlad, milles sisaldub 'datastore'
$isoDs = Get-Datastore -Name ISOD # Andmehoidla 'ISOD'
$internetPG = Get-VDPortGroup -Name 000_INTERNET # Jagatud virtuaalportgrupp '000_INTERNET'
$vdswitch = $datacenter | Get-VDSwitch # Võtab andmekeskusest jagatud virtuaalkommutaatori

# Kontrollimaks seda, et skript ei käiks läbi
# läbikäidud grupil kõik komponendid uuesti (mõeldud ajavõidu jaoks)
$grupidDuplikaat = @()

# Käib läbi iga rea Grupp veerus (nt: IS118)
$tabel.Grupp | Foreach-Object {
	
	# Kui grupp pole veel läbi käidud
	if (!$grupidDuplikaat.Contains($_)) {
	
		<#
			RESSURSIPOOLID:
			Tehakse uued ressursipoolid (Resource Pools) klustrisse
			olemasolevas andmekeskuses (Datacenter)
		#>
		
		Write-Host "**** $_ ****"

		Write-Host "== Ressursipool grupile $_ =="
		Start-Sleep 1 # ootab 1 sekundi
		
		# Kontrollib, kas grupi ressursipool eksisteerib
		$groupExists = Get-ResourcePool -Location $kluster -Name $_ -ErrorAction SilentlyContinue
		
		# Kui pordigruppi ei eksisteeri
		if (!$groupExists) {
			New-ResourcePool -Location $kluster -Name $_
		} else { Write-Host "Ressursipool $_ on juba olemas" -ForegroundColor yellow } # kui ressursipool juba on olemas
		
		# Õiguste kontroll
		$datacentPerms = Get-VIPermission -Entity ($datacenter) -Principal $domeenNimi\$_ -ErrorAction SilentlyContinue
		$klusterPerms = Get-VIPermission -Entity ($kluster) -Principal $domeenNimi\$_ -ErrorAction SilentlyContinue
		$gruppPerms = Get-VIPermission -Entity ($groupExists) -Principal $domeenNimi\$_ -ErrorAction SilentlyContinue
		
		# Kui grupil puuduvad õigused, kas andmekeskuses, klustris või enda grupil
		if ((!$datacentPerms) -or (!$klusterPerms) -or (!$gruppPerms)) {
			
			# Kui grupp ei ole 'Opetajad'
			# Määrab neile ainult lugemis-/vaatamisõiguse
			if ($_ -ne 'Opetajad') {
				New-VIPermission -Role readonly -Principal $domeenNimi\$_ -Entity ($kluster) -Propagate:$false
				New-VIPermission -Role readonly -Principal $domeenNimi\$_ -Entity ($datacenter) -Propagate:$false
				New-VIPermission -Role readonly -Principal $domeenNimi\$_ -Entity ($groupExists) -Propagate:$false
			}
		} else { Write-Host "Grupile $_ on juba õigused määratud" -ForegroundColor yellow } # Kui grupil on juba õigused olemas
		
		<#
			KAUSTAD:
			Luuakse grupile uued virtuaalmasinate ja mallide kaustad
			(VMs and Templates Folder), kui neid ei ole loodud
		#>
		
		Write-Host "== VMs and Templates kaust grupile $_ =="
		Start-Sleep 1
		
		$newFolder = Get-View (Get-View -viewtype datacenter).vmfolder
		if ($newFolder) {
			Write-Host $newFolder

			# Üritab tekitada kausta
			try {
				$newFolder.CreateFolder("$_")
				New-VIPermission -Role readonly -Principal $domeenNimi\$_ -Entity (Get-Folder -Name $_) -Propagate:$false
				New-VIPermission -Role Opilased -Principal $domeenNimi\Opetajad -Entity (Get-Folder -Name $_)
			} catch {}
		}
		
		<#
		See viis ei toimi, tekitab kausta ressursipoolide alla
		
		$kaustExists = Get-Folder -Location $datacenter -Name $_ -ErrorAction SilentlyContinue
		if (!$kaustExists) { New-Folder -Name $_ -Location $datacenter }
		else { Write-Host "Kaust $_ juba on loodud" }
		#>
		
		Write-Host "== Andmehoidlate kasutusõigus grupile $_ =="
		Start-Sleep 1
		
		<#
			ANDMEHOIDLAD (ÕIGUSED):
			Kontrollitakse andmehoidlate kasutusõiguseid.
			Kui puuduvad, määratakse grupile vastav roll kasutusõiguseks
		#>
		
		# Kui grupil puudub andmehoidla klustril vastavad õigused
		$dsClusterPerms = Get-VIPermission -Entity ($dsCluster) -Principal $domeenNimi\$_ -ErrorAction SilentlyContinue
		if (!$dsClusterPerms) {
			New-VIPermission -Role Opilased -Principal $domeenNimi\$_ -Entity ($dsCluster)
		}
		
		<#
		# Käib läbi iga andmehoidla
		ForEach ($datastore in $datastores) {
			
			# Kui grupil puudub andmehoidlal õigused
			$datastorePerms = Get-VIPermission -Entity ($datastore) -Principal $domeenNimi\$_
			if (!$datastorePerms) {
				New-VIPermission -Role Opilased -Principal $domeenNimi\$_ -Entity ($datastore)
			} else {
				Write-Host "Grupile $_ juba määratud andmekogule $datastore"
			}
		}
		#>
		
		# ISOD kasutusõiguse jagamine
		$isoDsPerms = Get-VIPermission -Entity ($isoDs) -Principal $domeenNimi\$_ -ErrorAction SilentlyContinue
		if (!$isoDsPerms) {
			New-VIPermission -Role Opilased -Principal $domeenNimi\$_ -Entity ($isoDs)
		}
		
		Write-Host "== 000_INTERNET virtuaalpordigrupi kasutusõigus grupile $_ =="
		Start-Sleep 1
		
		<#
			PORDIGRUPPID:
			Grupide alal ühise internet jagatud virtuaalpordigrupi kasutusõiguse
			määramine grupile
		#>
		
		$internetPGPerms = Get-VIPermission -Entity ($internetPG) -Principal $domeenNimi\$_ -ErrorAction SilentlyContinue
		
		# Kui grupil puudub internet pordigrupil õigused
		if (!$internetPGPerms) {
			New-VIPermission -Role Opilased -Principal $domeenNimi\$_ -Entity ($internetPG) -Propagate:$false
		} else {
			Write-Host "Grupile $_ on juba 000_INTERNET õigused määratud" -ForegroundColor yellow
		}
		
		# Vältimaks seda, et sama grupp uuesti läbi ei käiks
		# lisab grupi massiivi
		$grupidDuplikaat += ,$_
	}
}

# Käib iga rea igas veerus läbi
$tabel | Foreach-Object {

	# Kuna nimed on CSV arvatavsti ette söödetud kui "Eesnimi Perenimi" formaadis,
	# asendab all olev muutuja tühiku punktiga ning teeb suurtähed väikesteks.
	$nimi = [regex]::Replace($_.Nimi, "\s+", ".").ToLower()
	
	# Muudab ka kõik täpitähed, spetsiaalsed tähed tavalisteks ladinatähtedeks
	$nimi = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($nimi))
	
	Write-Host "**** $nimi ****"
	
	<#
		RESSURSIPOOLID:
		Tehakse uued ressursipoolid (Resource Pools) klustrisse
		olemasolevas andmekeskuses (Datacenter)
	#>
	
	Write-Host "== Ressursipool kasutajale $nimi =="
	Start-Sleep 1
	
	# Kui kasutaja ressursipool ei ole olemas
	$nameExists = Get-ResourcePool -Location $_.Grupp -Name $nimi -ErrorAction SilentlyContinue
	if (!$nameExists) {
		New-ResourcePool -Location $_.Grupp -Name $nimi
	} else { Write-Host "Ressursipool $nimi juba eksisteerib" -ForegroundColor yellow }
	
	# Peale individuaalsete Resource Pool'ide tegemist, määratakse ära nendele roll Opilased
	# Kui õigust kasutajale ei eksisteeri, antakse talle roll oma Resource Pool'ile
	$permsExist = Get-VIPermission -Entity (Get-ResourcePool -Location $_.Grupp -Name $nimi) -Principal $domeenNimi\$nimi -ErrorAction SilentlyContinue
	if (!$permsExist) {
		New-VIPermission -Role Opilased -Principal $domeenNimi\$nimi -Entity (Get-ResourcePool -Location $_.Grupp -Name $nimi)
	} else { Write-Host "Õigused on juba $nimi ressursipoolile määratud" -ForegroundColor yellow }
	
	<#
		KAUSTAD:
		Luuakse uued virtuaalmasinate ja mallide kaustad (VMs and Templates Folder),
		kui neid ei ole loodud
	#>
	
	Write-Host "== VMs and Templates kaust kasutajale $nimi =="
	Start-Sleep 1
	
	# Kontrollitakse kausta olemasolekut
	$folderExists = Get-Folder -Location $_.Grupp -Name $nimi -ErrorAction SilentlyContinue
	
	# Kui kausta ei eksisteeri
	if (!$folderExists) {
		
		# Läbi vaate saamisega ning filtreerimisega saab vCenter serverisse luua
		# virtuaalmasinate ja mallide kaustasid. Tavalise
		# New-Folder käsuga loob kausta hoopis ressursipoolide
		# sektsiooni.
		try {
			(Get-View -viewtype folder -filter @{"name"=$_.Grupp}).CreateFolder("$nimi")
		} catch {}
		
	} else { Write-Host "Kaust $nimi juba olemas" -ForegroundColor yellow } # kui kaust on juba olemas
	
	# Kausta õigused
	$folderPerms = Get-VIPermission -Entity (Get-Folder -Location $_.Grupp -Name $nimi) -Principal $domeenNimi\$nimi -ErrorAction SilentlyContinue
	if (!$folderPerms) {
		New-VIPermission -Role Opilased -Principal $domeenNimi\$nimi -Entity (Get-Folder -Location $_.Grupp -Name $nimi)
	}
	
	<#
		PORDIGRUPID:
		Jagatud virtuaalpordigrupi (Virtual Port Groups) tekitamine igale kasutajale
		oma VLAN ID-ga
	#>
	
	Write-Host "== Virtuaalpordigrupp kasutajale $nimi =="
	Start-Sleep 1
	
	$portGroupExists = Get-VirtualPortGroup -Name $nimi -ErrorAction SilentlyContinue
	
	# Kui pordigruppi ei eksisteeri
	if (!$portGroupExists) {
		
		# Tekitab uue pordigrupi, ning annab Opilased rolli kasutajale
		New-VDPortGroup -VDSwitch $vdswitch -Name $nimi -NumPorts 8 -VLanId $_.VLAN
		Get-VDPortGroup -Name $nimi | New-VIPermission -Role Opilased -Principal $domeenNimi\$nimi -Propagate:$false
	} else {
		Write-Host "Pordigrupp $nimi on juba olemas" -ForegroundColor yellow
	}
}

# Ühendab lahti vCenter serveri peale tegevuste lõpetamist
Write-Host "== $vcenterServer serveri lahtiühendamine =="

Disconnect-VIServer -Server $vcenterServer -Confirm:$false
Read-Host -Prompt "Vajutage Enter klahvi, et sulgeda..."
