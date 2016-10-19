# README
## Start
Um unsere Implementation der ersten Aufgabe zu starten, sind die folgenden Befehle in der dargestellten Reihenfolge auszuführen. Vorher sind noch die 'client.cfg' und die 'server.cfg' entsprechend anzupassen.
- hbq:start().                      % Starten der HBQ
- server:start().                   % Starten des Servers
- client:init('client.cfg').        % Starten der Clients

## Logging
In der node().log - Datei sind die Logs von allen Clients und dem Server zu finden

### Log - Dateiaufbau
Der Aufbau der Logdateien ist wie folgt: 
    "Timestamp|"  - "Servicename:" Logtext
Die Clients sind in der Logdatei durchnummeriert, um zu sehen welcher Client was ausgibt bzw. loggt.