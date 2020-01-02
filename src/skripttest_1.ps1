# VCenter serverisse yhendamine
connect-viserver -server vcenter.khk.sise

# Datacenterisse ei ole voimalik luua Resource Pooli
# $Datacent = Get-Datacenter -Name *Datacenter
# new-resourcepool -location $Datacent -name TestResPool

# Valib/Otsib klusteri, mis lopeb sonaga Cluster
$Cluster = Get-Cluster -Location khk.sise*
New-ResourcePool -Location $Cluster -Name TestNr2

# Enne, kui PowerShell aken kinni laheb
pause