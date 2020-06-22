# vCenter-Server-KKHTA
vCenter Server kasutajakontode haldustegevuste automatiseerimine
 
Lihtsustab kasutajakontode haldustegevuses ressurssipuulide (Resource Pools), virtuaalmasinate ja malli kaustade (VMs and Templates Folders), jagatud kommutaatorisse virtuaalpordigruppide (Virtual Port Groups) tegemises, õiguste jagamises ressursipuulidele, kaustadele, ühisele interneti virtuaalpordigrupile ning saadalolevatele andmehoidlatele.
 
See skript on tehtud ja kujundatud vastavalt Tartu Kutsehariduskeskuse VMware vCenter süsteemi vajadustele. Muutujad ei pruugi olla samad, kui kasutusele võtta teises süsteemis

## Sisukord
* [Paigaldus](#paigaldus)
* [Käivitamine](#kaivitamine)
  * [Käsureal](#kasureal)
* [Parameetrid](#parameetrid)
* [Skripti-sisesed muutujad](#muutujad)

<a name="paigaldus"></a>
### Paigaldus
Skripti saab paigaldada enda süsteemi repositooriumi kloonimisega ZIP-arhiivina või GitHub Desktop rakendusse.

Haldustegevuse automeerimiseks on vaja:
- PowerShell (Windows'iga olemas)
- VMware.PowerCLI moodul

Skript ise automaatselt installeerib PowerCLI mooduli, kui süsteemis veel ei ole paigaldatud. Kuid saab ka seda ise paigaldada läbi PowerShell käsu.

```ps
# Installi VMware.PowerCLI
Install-Module -Name VMware.PowerCLI

# Installi VMware.PowerCLI, kui samas süsteemis on ka olemas Hyper-V
Install-Module -Name VMware.PowerCLI -AllowClobber
```

Kui süsteemis on Hyper-V installitud, siis tuleb lisada käsule juurde `-AllowClobber`. Väldib samanimeliste käskude tõrget (nt. mõlemal moodulil on sama käsk `Get-VM`)

<a name="kaivitamine"></a>
### Käivitamine
Skripti on võimalik avada paaril viisil:
- Parem-klõps, käivita PowerShell'is ('Run with Powershell' ing. k.)
- Avada uus PowerShell aken, liikuda skripti kausta, sisestada käsk (koos või ilma parameetriteta)

<a name="kasureal"></a>
#### Käsureal
Skripti saab avada koos, osaliselt ja ilma ühegi parameetrita. Kui on osaliselt või ilma, küsib skript automaatselt sisestamata andmeid, et käivitada automatsioon. Ilma parameetriteta on käsureal skripti käivitamine selline:

```ps
# Skript peab olema samas kaustas, kus on avatud PowerShell'i aken.
.\KKHTA.ps1
```

Koos parameetritega näeb välja selline:

```ps
# Koos parameetri nimega (järjekord võib olla ka teine)
.\KKHTA.ps1 -vCenterServer <vCenter serveri aadress> -CSVFail <CSV failitee> -DomeeniNimi <vCenter'iga ühildatud domeeninimi (pre-Windows 2000)>

# Ilma parameetri nimeta (järjekord peab olema nagu see on: vCenter'i server, CSV fail, domeeni nimi)
.\KKHTA.ps1 <vCenter serveri aadress> <CSV tabelfaili tee> <domeeninimi>
```

<a name="parameetrid"></a>
### Parameetrid
Skript kasutab järgnevaid parameetrid, mida käsureal saab sisetada

- `-vCenterServer` - sõne, VMware vCenter serveri aadress, millega skript ära ühendada
  - Võib küsida administraatori kasutajanime ja parooli esmakordsel vCenter serveri sisselogimisel läbi PowerCLI mooduli
  - Väljastab tõrke, kui:
    - aadressit pole sisestatud
    - ühendus pole saadaval
    - kasutajanimi ja/või parool on vale
    - mõni muu tõrge
- `-CSVFail` - sõne, CSV tabel, kus on olemas isiku nimi, grupp, VLAN pordi number virtuaalpordigrupi tegemiseks
  - CSV tabel võib asuda:
    - samas kaustas, kus skript ise on: `tabelfail.csv`
    - alamkaustas: `kaust\tabelfail.csv` või `kaust/tabelfail.csv`
    - kuskil mujal väljaspool skripti asukohta: `"C:\Users\Kasutaja\Documents\kaust\tabelfail.csv"`
      - Sellisel juhul tuleb asukoht panna juttumärkidesse
  - Väljastab tõrke, kui:
    - faili nime asukohaga pole sisestatud
    - ei suuda faili leida, või fail ei ole CSV
    - valed tabeli pealdised (peavad olema Nimi, Grupp, VLAN)
- `-DomeeniNimi` - sõne, Active Directory domeeni nimi (pre-Windows 2000)
  - Väljastab tõrke, kui midagi pole sisestatud
  - **TÄHELEPANEK:** puudub tõrkeväljastus osas:
    - kas domeen on vCenter Serveriga ühildatud või mitte
    - kas sisestatud domeeni nimi on õige, mis on ühildatud

Skript kontrollib ka kasutajate ja gruppide olemasolu Active Directory katalooogiteenuses. Väljastab tõrke käsureale, kui kasutajat ja/või grupi ei eksisteeri

<a name="muutujad"></a>
### Skripti-sisesed muutujad
Skriptis on ka muutujaid, mida kasutaja saab ise muuta avades skript tekstiredaktoriga nagu Notepad, Notepad++, Visual Studio Code jne.

```ps
...
# Võtab klustri ja andmekeskuse, mis lõpeb sõnaga "Cluster", "Datacenter"
$kluster = Get-Cluster -Name "*Cluster"
$datacenter = Get-Datacenter -Name "*Datacenter"

# Võtab andmehoidla klustri, mis lõpeb sõnaga "Datastore Cluster"
$dsCluster = Get-DatastoreCluster -Location $datacenter

$esxhosts = Get-VMHost -Location $kluster # hostid
$datastores = Get-Datastore | ? {$_.name -imatch 'datastore'} # Otsib välja kõik andmehoidlad, milles sisaldub 'datastore'
$isoDs = Get-Datastore -Name ISOD # Andmehoidla 'ISOD'
$internetPG = Get-VDPortGroup -Name 000_INTERNET # Jagatud virtuaalportgrupp '000_INTERNET'
$vdswitch = $datacenter | Get-VDSwitch # Võtab andmekeskusest jagatud virtuaalkommutaatori
...
```

Neid saab muuta vastavalt kasutaja vajadustele. Nendel käskudel on olemas parameeter `-Name` (vaata lisaks [PowerCLI dokumentatsiooni](https://pubs.vmware.com/vsphere-51/index.jsp?topic=%2Fcom.vmware.vsphere.doc%2FGUID-1B959D6B-41CA-4E23-A7DB-E9165D5A0E80.html))

#

Ellart Ott, IS118