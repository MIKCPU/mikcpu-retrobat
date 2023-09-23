# VMAN gamelist generator for systems that can't be scrap 
# Produced by Mikcpu 1.0
# Instructions: Simply add your "list-games.txt" and it will generate gamelist_temp.xml that you can append to your existing gamelist.xml 

$xmlsettings = New-Object System.Xml.XmlWriterSettings
$xmlsettings.Indent = $true
$xmlsettings.IndentChars = "    "

$XmlWriter = [System.XML.XmlWriter]::Create("V:\gamelist_temp.xml", $xmlsettings)
$xmlWriter.WriteStartDocument()
$xmlWriter.WriteStartElement("gameList")

function AddGame {
    Param($gamename)
	$xmlWriter.WriteStartElement("game") 
		$xmlWriter.WriteElementString("path","./$($gamename).vpx")
		$xmlWriter.WriteElementString("name","$($gamename)")
		$xmlWriter.WriteElementString("desc","Flipper $($gamename)")
		$xmlWriter.WriteElementString("image","./mixart/$($gamename).png")
		$xmlWriter.WriteElementString("video","./snap/$($gamename).mp4")
		$xmlWriter.WriteElementString("marquee","./wheel/$($gamename).png")
		$xmlWriter.WriteElementString("rating","3")
		$xmlWriter.WriteElementString("releasedate","unknown")
		$xmlWriter.WriteElementString("developer","FanMade")
		$xmlWriter.WriteElementString("publisher","VisualPinball")
		$xmlWriter.WriteElementString("genre","Pinball")
		$xmlWriter.WriteElementString("players","2")
		$xmlWriter.WriteElementString("favorite","true")
		$xmlWriter.WriteElementString("lang","en")		
	$xmlWriter.WriteEndElement()    
}

$games = Get-Content 'V:\list-games.txt' 
$games | ForEach-Object { AddGame($_) }

$xmlWriter.WriteEndElement() 
$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()