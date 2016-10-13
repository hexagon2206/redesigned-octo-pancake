-module(dlq).
-export([initDLQ/2]).
-export([delDLQ/1]).
-export([expectedNr/1]).
-export([push2DLQ/3]).
-export([deliverMSG/4]).


%/* Initialisieren der DLQ */
initDLQ(Size,Datei) -> 
	{Size,[]}.

%/* Löschen der DLQ */
delDLQ(Queue) -> Queue.
	

%/* Abfrage welche Nachrichtennummer in der DLQ gespeichert werden kann */
expectedNr({_,[{NR,_}|_]}) -> NR+1;
expectedNr(_) -> 1.
	

cutToSize(_,[]) -> [];
cutToSize(0,_) -> [];
cutToSize(N,[E|X]) -> [E|cutToSize(N-1,X)].

%/* Speichern einer Nachricht in der DLQ */
push2DLQ([NNr,Msg,TSclientout,TShbqin],{S,Queue},Datei) ->
	NewQueue = [{NNr,[NNr,Msg,TSclientout,TShbqin]}|Queue],
	{S,cutToSize(S,NewQueue)}.

	

deliver(ClientPID,Msg,Datei)->
	ClientPID ! Msg.


deliverMSG(MSGNr,ClientPID,{_,Queue},Datei) -> 
	deliverMSG(MSGNr,ClientPID,Queue,Datei);

%/* Ausliefern einer Nachricht an einen Leser-Client */
deliverMSG(_,_,[],Datei) -> 
	-1;
deliverMSG(_	,ClientPID,[{N,X}|[]],Datei)->
	deliver(ClientPID,X,Datei),
	N;
deliverMSG(MSGNr,ClientPID,[{MSGNr,X}|_],Datei)->
	deliver(ClientPID,X,Datei),
	MSGNr;
deliverMSG(MSGNr,ClientPID,[_|X],Datei) ->
	deliverMSG(MSGNr,ClientPID,X,Datei).