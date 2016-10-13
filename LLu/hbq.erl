-module(hbq).
-export([start/0]).
-export([pushMSG/1]).
-export([deliverMSG/2]).



start() ->
	HBQPid = spawn(fun() -> startup() end),
	register(hbqS,HBQPid).

startup() -> 
	receive 
		%/* Initialisieren der HBQ */
		%HBQ ! {self(), {request,initHBQ}}
		%receive {reply, ok} 
		{PID,{request,initHBQ}} -> 
			init(PID);
		_ -> start()
	end.

init(PID) -> 
	PID ! {reply, ok},
	loop().


pushMSG(Msg) ->
	hbqS ! {trashS,{request,pushHBQ,Msg}}.

deliverMSG(NNr,ToClient) ->
	hbqS ! {self(),{request,deliverMSG,NNr,ToClient}}.
	receive
		{reply, NNr} -> NNr 
	end.
	

loop() ->
	receive
		%/* Speichern einer Nachricht in der HBQ */
		%HBQ ! {self(), {request,pushHBQ,[NNr,Msg,TSclientout]}}
		%receive {reply, ok} 
		{PID,{request,pushHBQ,[NNr,Msg,TSclientout]}} ->
			
			PID ! {reply, ok},
			loop();

		%/* Abfrage einer Nachricht */
		%HBQ ! {self(), {request,deliverMSG,NNr,ToClient}}
		%receive {reply, SendNNr}
		{PID,{request,deliverMSG,NNr,ToClient}} ->
			
			PID ! {reply, NNr+1},
			loop();
		
		%/* Terminierung der HBQ */
		%HBQ ! {self(), {request,dellHBQ}}
		%receive {reply, ok} 
		{PID,{request,dellHBQ}} ->
			PID ! {reply, ok},
			true
	end.