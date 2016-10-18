-module(cmem).
-export([initCMEM/2]).
-export([delCMEM/1]).
-export([updateClient/4]).
-export([getClientNNr/2]).

%initialisiert den CMEM. RemTime gibt dabei die Zeit an, nach der die Clients vergessen werden Bei Erfolg wird ein leeres CMEM zurück geliefert. Datei kann für ein logging genutzt werden.
% Die übergebene Datei wird ignoriert, die mit welche die Cmem inmitialisiert wurde wird verwendet
initCMEM(RemTime,Datei) ->
	spawn( fun() -> init(RemTime,Datei) end ).


%löscht den CMEM. Bei Erfolg wird ok zurück geliefert.
delCMEM(CMEM) -> 
	CMEM ! {request,kill,self()},
	receive
		{cmem,ok} -> ok
	end.

%speichert bzw. aktualisiert im CMEM den Client ClientID und die an ihn gesendete Nachrichtenummer NNr. Datei kann für ein logging genutzt werden.
% Die übergebene Datei wird ignoriert, die mit welche die Cmem inmitialisiert wurde wird verwendet
updateClient(CMEM,ClientID,NNr,Datei) ->
	CMEM ! {request,update,ClientID,NNr,self(),Datei},
	receive
		{cmem,ok}    -> CMEM
	end.


%gibt die als nächstes vom Client erwartete Nachrichtennummer des Clients ClientID aus CMEM zurück. Ist der Client unbekannt wird 1 zurück gegeben.
getClientNNr(CMEM,ClientID) ->
	CMEM ! {request,get,ClientID,self()},
	receive
		{cmem,N} -> N
	end.

findCNum(_,_,_,[]) -> 
	1;
findCNum(Now,RemTime,Client,[{Client,T,Number}|_]) when T > Now-RemTime -> 
	Number;
findCNum(_,_,Client,[{Client,_,_}|_]) -> 
	1;
findCNum(Now,RemTime,Client,[_|Rest]) -> 
	findCNum(Now,RemTime,Client,Rest).




%es war noch nicht eingetragen, daher wird es jetzt eingetragen
updateCNum(Datei,Time,ClientID,NewNum,[],NewCmem) ->
	tool:l(Datei,'CMEM',"Client ~p neu angelegt mit ~p",[ClientID,NewNum]),
	[{ClientID,Time,NewNum}|NewCmem];

%gefunden
updateCNum(Datei,Time,ClientID,NewNum,[{ClientID,_,_}|Rest],NewChnem) -> 
	tool:l(Datei,'CMEM',"Client ~p aktualisiert mit ~p",[ClientID,NewNum]),
	lists:append([{ClientID,Time,NewNum}|Rest],NewChnem);

%nicht gefunden
updateCNum(Datei,Time,ClientID,NewNum,[X|Rest],NewChnem) -> 
	updateCNum(Datei,Time,ClientID,NewNum,Rest,[X|NewChnem]).


init(RemTime,Datei) ->
	tool:l(Datei,'CMEM',"initialisierung mit Lebenszeit ~p",[RemTime]),
	loop(RemTime,Datei,[]).

loop(RemTime,Datei,CMEM) ->
	receive
		{request,get,ClientID,PID} ->
			PID ! {cmem,findCNum(werkzeug:getUTC(),RemTime,ClientID,CMEM)},
			loop(RemTime,Datei,CMEM);
		{request,update,ClientID,NewNum,PID,_File} ->
			NewCmem=updateCNum(Datei,werkzeug:getUTC(),ClientID,NewNum,CMEM,[]),
			PID ! {cmem,ok},
			loop(RemTime,Datei,NewCmem);
		{request,kill,PID} ->
			PID ! {cmem,ok},
			tool:l(Datei,'CMEM',"CMEM DOWN PID ~p.",[self()]);
		X ->
			tool:l(Datei,'CMEM',"Unknown Request ~p",[X]),
			loop(RemTime,Datei,CMEM)
	end.
