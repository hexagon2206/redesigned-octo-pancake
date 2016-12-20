# Readme

Diese Datei beschreibt wie das Ergebnis der 4. aufgabenstellung in VS zu benutzen ist.
Die implementierung ist in mehrer Komponenten aufgeteilt.
Dem inhalt der Jar files kann entnommen werden, das der Client nicht über die implemetations klasse des Servers verfügt,
Beider verfügen lediglich über die selben schnitstellenspezifikations klassen.

Der Name Service ist komplett un abhängig und verfügt nichtmals über die schnittstellenspezifikationen.


# Startprozess
Die Komponenten müssen in Der Richtigen reinfolge gestartet werden :
Diese anweisugnen gehen davon aus das die Aplikation über das loopback interface betrieben wird.

1. Der Name Service muss gestartet werden, auch wen die middleware ohne diesen genutzt werden kann, so benötigen die beiden demo anwendungen diesen doch
	java -jar nameservice.jar 127.0.0.1 1237
	
2. der Server ist zu starten 
	java -jar ServerSimple.jar 127.0.0.1 1237 

3. Die Client anwendung wird gestarte.
	java -jar ClientSimple.jar 127.0.0.1 1237
	
	
Die start befehler werden im folgenden abschnitt aufgeschlüsselt.


## Name service
Der Nameservice unterscheidet sich nur maginal von anderen über die middleware bereitgestellten services.
Er kann mittels 

java -jar nameservice.jar localAddres Port

gestartet werden.
Wobei localAddres die lokale IP addresse des zu benutzenden Interfaces ist, und port den zu verwendenden lokalen port beschreibt.



## Middleware
Wir haben das interface des Object Brokers leicht angepast , dies ist allerdings nur im SpezialObjectBroker 
verfügbar, es ermöglicht die Auswahl der zu verwendenden interfaces.

Die middleware liegt in form von mware_lib.jar vor.
Die schnittstellen lassen sich den Java Doc Komentaren des Quelltextes entnehmen.


### CalcServer
Als demo Liegt ein Server vor, welcher 2 Diesnste zur verfügung stellt, einen einfachen Additions Rechner und einen Stack Basierten Rechner.
dier einfache Taschenrechner wird durch die datei calc.idl beschrieben, der upn rechner durch upnCalc.idl
Durch den UPN rechner wird deutlich gezeigt, das die Objekte status behaftet sind.

Der server ist mittles

java -jar SimpleServer.jar  remoteAddres remotePort 

zu starten.
Wobei remoteAddres die addresse des namensdienstes und remotePort der port des Namensdienstes.



### CalcClient
Wir haben einen einfachen Client geschreiben, welcher beide bereitgestelten Services benutzt.
Dieser ist mittles

java -jar ClientSimple.jar remoteAddres remotePort 

zu starten.
Wobei remoteAddres die addresse des namensdienstes und remotePort der port des Namensdienstes.

Es giebt auch einen weiteren Client, den MultiClientSimple, welcher in 10 threads jewails 100 anfragen an den CalcServer stellt.
Er ist genau so zu starten, mit dem unterschied, das ClientSimple.jar durch MultiClientSimple.jar zu ersetzen ist.



# Benutzung des Compilers 

Der compiler benötigt ein Output Verzeichnis (./out) in welchem er den Generierten java Code ablegt.
Die zu compilierenden Dateien werden In der Komandozeile Übergeben :

java -jar compiler.jar file1.idl file2.idl file3.idl

Es können beliebig viel idl Dateien übergeben werden.
Technisch basiert der Compiler auf dem von freundlicherweise von Herrn Schulz bereitgesteltem Gerüst.

