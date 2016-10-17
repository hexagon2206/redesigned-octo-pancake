-module(dlq).
-export([initDLQ/2]).
-export([delDLQ/1]).
-export([expectedNr/1]).
-export([push2DLQ/3]).
-export([deliverMSG/4]).


% DLQ als eigener Prozess


%/* Initialisieren der DLQ */
initDLQ(Size,Datei) -> 
	log:w(Datei,'DLQ',"Initialisiert mit größe von ~p",[Size]),
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
	log:w(Datei,'DLQ',"Nachricht  ~p ind DLQ eingetragen",[NNr]),
	NewQueue = [{NNr,[NNr,Msg,TSclientout,TShbqin,erlang:now()]}|Queue],
	{S,cutToSize(S,NewQueue)}.

	

deliver(ClientPID,[NNr,Msg,TSclientout,TShbqin,TSdlqin],Terminiert,Datei)->
	log:w(Datei,'DLQ',"Nachricht  ~p an ~p ausgeliefert",[NNr,ClientPID]),
	ClientPID ! {reply,[NNr,Msg,TSclientout,TShbqin,TSdlqin,erlang:now()],Terminiert}.


deliverMSG(MSGNr,ClientPID,{_Size,Queue},Datei) -> 
	deliverMSG(true,MSGNr,ClientPID,Queue,Datei).


%/* Ausliefern einer Nachricht an einen Leser-Client, es wird eine Dummy nachricht gesendet */
deliverMSG(Newest,_NNr,ClientPID,[],Datei) -> 
	log:w(Datei,'DLQ',"Dummy Nachricht an ~p ausgeliefert",[ClientPID]),
	Now = erlang:now(),
	ClientPID ! {reply,[0,"Dummy Nachricht",Now,Now,Now],true},
	0;

deliverMSG(Newest,MSGNr,ClientPID,[{MSGNr,X}|_],Datei)->
	deliver(ClientPID,X,Newest,Datei),
	MSGNr;

deliverMSG(_Newest,MSGNr,ClientPID,[_|X],Datei) ->
	deliverMSG(false,MSGNr,ClientPID,X,Datei).

