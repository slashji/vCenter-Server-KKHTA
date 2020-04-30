# T2pit2htede asendamiseks m6eldud test

$tahed = 'Õunad on želatiinist ja šampoonist. Ärge sööge ÜHTEGI mürgist mõtetut ainet. Söö Šokolaadi!'
$tahed
Write '----------------------------------------------------------------------'

$tahed = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($tahed))

$tahed