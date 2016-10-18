-module(dlq).
-export([initDLQ/2]).
-export([delDLQ/1]).
-export([expectedNr/1]).
-export([push2DLQ/3]).
-export([deliverMSG/4]).


% DLQ als eigener Prozess


%/* Initialisieren der DLQ */
initDLQ(Size,Datei) -> 
	tool:l(Datei,'DLQ',"Initialisiert mit größe von ~p",[Size]),
	{Size,[]}.

%/* Löschen der DLQ */
delDLQ(_Queue) -> ok.
	

%/* Abfrage welche Nachrichtennummer in der DLQ gespeichert werden kann */
expectedNr({_,[{NR,_}|_]}) -> NR+1;
expectedNr({_,[]}) -> 1.
	

cutToSize(_,[]) -> [];
cutToSize(0,_) -> [];
cutToSize(N,[E|X]) -> [E|cutToSize(N-1,X)].

%/* Speichern einer Nachricht in der DLQ */
push2DLQ([NNr,Msg,TSclientout,TShbqin],{S,Queue},Datei) ->
	tool:l(Datei,'DLQ',"Nachricht  ~p ind DLQ eingetragen",[NNr]),
	NewQueue = [{NNr,[NNr,Msg,TSclientout,TShbqin,tool:t()]}|Queue],
	{S,cutToSize(S,NewQueue)}.

	

deliver(ClientPID,[NNr,Msg,TSclientout,TShbqin,TSdlqin],Terminiert,Datei)->
	tool:l(Datei,'DLQ',"Nachricht  ~p an ~p ausgeliefert",[NNr,ClientPID]),
	ClientPID ! {reply,[NNr,Msg,TSclientout,TShbqin,TSdlqin,tool:t()],Terminiert}.


deliverMSG(MSGNr,ClientPID,DLQ,Datei) ->
	Max = expectedNr(DLQ),
	if 
		MSGNr < Max ->	
			{_,Queue}=DLQ,
			deliverMSG(true,MSGNr,ClientPID,Queue,Datei);
		true ->
			deliverMSG(true,MSGNr,ClientPID,[],Datei)	% einfach so tun als ob die Queue Lehr ist ;-)	
	end.



%/* Es liegen Noch keine Nachrichten vor, dummy Nachricht senden*/
deliverMSG(_Newest,_NNr,ClientPID,[],Datei) -> 
	tool:l(Datei,'DLQ',"Dummy Nachricht an ~p ausgeliefert",[ClientPID]),
	Now = tool:t(),
	ClientPID ! {reply,[0,"Dummy Nachricht",Now,Now,Now],true},
	0;


% angefragte nachricht wurde gefunden
deliverMSG(Newest,MSGNr,ClientPID,[{MSGNr,X}|_],Datei)->
	deliver(ClientPID,X,Newest,Datei),
	MSGNr;

% es wurde eine Nachricht mit kleinere ID als die kleinste in der Liste vorhandene Angefragt, die Kleinste wird gesendet
deliverMSG(Newest,_RequestedNum,ClientPID,[{MSGNr,X}|[]],Datei)->
	deliver(ClientPID,X,Newest,Datei),
	MSGNr;

% fürs durchlaufen der liste	
deliverMSG(_Newest,MSGNr,ClientPID,[_|X],Datei) ->
	deliverMSG(false,MSGNr,ClientPID,X,Datei).

