
Connect-VIServer -Server vcenter.khk.sise

$kluster = Get-Cluster -Location khk.sise*

Get-ResourcePool -Location $kluster -Name Opilased -ErrorAction SilentlyContinue

$nameExists = Get-ResourcePool -Location IS118 -Name ellart.ott -ErrorAction SilentlyContinue
if (!$nameExists) {
	New-ResourcePool -Location $grupp -Name $nimi
} else {
	Write-Host "$_ juba eksisteerib" -ForegroundColor Red
}