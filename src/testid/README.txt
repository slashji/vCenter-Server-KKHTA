VMware vCenter Server kasutajakontode haldustegevuste automatiseerimine
================================================================================================
Enamus skriptid siin on PowerShell'is kirjutatud
================================================================================================
skripttest_1 	- Clusterisse Resource Pooli loomine
skripttest_2 	- Esimene versioon eraldi gruppide ja isikute Resource Poolide tegemine (ilma õigusteta)
kkhta 		- Töökorras prototüüp, suudab:
			1. luua Resource Poole Clusterisse (gruppid, isikud grupi klustrisse, koos õigustega)
			2. luua VMs and Templates sektsiooni kaustasid (grupiti, isikutele eraldi, koos õigustega)
			3. jagada andmeklusteri vastavad õigused kasutajatele, koos ISOD andmehoidlaga
			4. luua jagatud virtuaalpordigrupid kasutajatele, 000_INTERNET kasutusõiguse jagamine
skripttest_4 	- Resource Pooli õiguste info kättesaamine
skripttest_5 	- Resource Pooli tegemine, kui juba ei eksisteeri
skripttest_6 	- Datastore'ide õiguste jagamine
skripttest_7	- 000_INTERNET pordi kasutusõiguse jagamine seatud grupile
skripttest_8	- 000_INTERNET pordi kasutusõiguse ning kasutajatele individuaalsete portide tekitamine.
t2hed		- Täpitähtede asendaja tavaliste ladina tähtedega