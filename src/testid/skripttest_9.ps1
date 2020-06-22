Import-Module ActiveDirectory

$table = Import-Csv inimesed.csv
$groupDuplicate = @()

Write-Host "== GRUPID, MIS PUUDUVAD AD'ST ==" -BackgroundColor black

$table.Grupp | Foreach-Object {

	if (!$groupDuplicate.Contains($_)) {
		$groupExists = [bool](Get-ADGroup -Filter { Name -eq $_ })
		if (-not $groupExists) {
			Write-Warning -Message "Grupp $_ ei eksisteeri"
		}
		$groupDuplicates += ,$_
	}
}

Write-Host "== KASUTAJAD, MIS PUUDUVAD AD'ST ==" -BackgroundColor black

$table.Nimi | Foreach-Object {

	$userExists = [bool](Get-ADUser -Filter { Name -eq $_ })
	if (-not $userExists) {
        Write-Warning -Message "Kasutaja $_ ei eksisteeri"
    }
}

pause