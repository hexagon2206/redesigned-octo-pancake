-module(koordinator).
%-export([start/0]).

%{setneighbors,LeftN,RightN}:
% die (lokal auf deren Node registrieten und im Namensdienst registrierten) Namen (keine PID!) des linken und rechten Nachbarn werden gesetzt.
%

%{setpm,MiNeu}:
% die von diesem Prozess zu berabeitenden Zahl für eine neue Berechnung wird gesetzt.
%

%{sendy,Y}:
% der rekursive Aufruf der ggT Berechnung.
%

%{From,{vote,Initiator}}:
% Wahlnachricht für die Terminierung der aktuellen Berechnung; Initiator ist der Initiator dieser Wahl (Name des ggT-Prozesses, keine PID!) und From (ist PID) ist sein Absender.
%

%{voteYes,Name}:
% erhaltenes Abstimmungsergebnis, wobei Name der Name des Absenders ist (keine PID!).
%

%{From,tellmi}:
% Sendet das aktuelle Mi an From (ist PID): From ! {mi,Mi}. Wird vom Koordinator z.B. genutzt, um bei einem Berechnungsstillstand die Mi-Situation im Ring anzuzeigen.
%

%{From,pingGGT}:
% Sendet ein pongGGT an From (ist PID): From ! {pongGGT,GGTname}. Wird vom Koordinator z.B. genutzt, um auf manuelle Anforderung hin die Lebendigkeit des Rings zu prüfen.
%


%kill:
% der ggT-Prozess wird beendet.
%