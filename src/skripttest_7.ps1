Connect-VIServer -Server vcenter.khk.sise

#Get-Datacenter -Name *Datacenter | Get-VirtualSwitch
$internetPG = Get-VirtualPortGroup -Name 000_INTERNET
$internetPGPerms = Get-VIPermission -Entity ($internetPG) -Principal KHK0\IS118 #-ErrorAction SilentlyContinue

if (!$internetPGPerms) {
	New-VIPermission -Role Opilased -Principal KHK0\IS118 -Entity ($internetPG) -Propagate:$false
}

Disconnect-VIServer -Server vcenter.khk.sise -Confirm:$false
pause