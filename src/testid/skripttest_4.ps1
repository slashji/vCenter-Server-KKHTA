# Õiguste info saamiseks koostatud mini-skript
# Testimiseks
Connect-VIServer -Server vcenter.khk.sise

$kluster = Get-Cluster -Location khk.sise*

Get-VIPermission -Entity (Get-ResourcePool -Location $kluster -Name ILU19) -Principal KHK0\Users