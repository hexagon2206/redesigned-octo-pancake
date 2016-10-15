-module(hbq).
-export([start/0]).
-export([pushMSG/1]).
-export([deliverMSG/2]).

-export([nmsg/1]).

nmsg(Nummer) -> [Nummer,test,10].



start() ->
	HbqLogFile = 'hbqLog.log',

	{ok, ConfigListe} = file:consult("server.cfg"),
	low:w(HbqLogFile,'HBQ',"server.cfg datei geöfnet . . ."),
    
    {ok, DLQSize} = werkzeug:get_config_value(dlqlimit, ConfigListe),
	{ok, Hbqname} = werkzeug:get_config_value(hbqname, ConfigListe),

	HBQPid = spawn(fun() -> startup(DLQSize) end),
	register(Hbqname,HBQPid).

startup(DLQSize) -> 
	receive 
		%/* Initialisieren der HBQ */
		%HBQ ! {self(), {request,initHBQ}}
		%receive {reply, ok} 
		{PID,{request,initHBQ}} -> 
			init(PID,DLQSize);
		_ -> start()
	end.

init(PID,DLQSize) -> 
	
	DLQ= dlq:initDLQ(DLQSize,hbqLog),
	PID ! {reply, ok},
	loop({0,[]},DLQ,DLQSize,hbqLog,dlq:expectedNr(DLQ)).

pushMSG(Msg) ->
	hbqS ! {self(),{request,pushHBQ,Msg}}.

deliverMSG(NNr,ToClient) ->
	hbqS ! {self(),{request,deliverMSG,NNr,ToClient}},
	receive
		{reply, NNr} -> NNr 
	end.
	


% Struktur der HBQ {Size,[ {ID,Nachricht} , ... ]}
tryToAppend(E,DLQ,{S,[{E,Nachricht}|R]},Datei) ->
	NDLQ = dlq:push2DLQ(Nachricht,DLQ,Datei),
	tryToAppend(E+1,NDLQ,{S-1,R},Datei);

tryToAppend(E,DLQ,HBQ,_) ->
	{E,DLQ,HBQ}.


tryToCloseGap(E,DLQ,{0,[]}, _,_)  -> {E,DLQ,{0,[]}}; 

tryToCloseGap(E,DLQ,{S,List}, DLQSize,Datei)  when S < DLQSize/3 -> 
	{E,DLQ,{S,List}};

tryToCloseGap(_E,DLQ,HBQ,_DLQSize,Datei)  -> 
	{_,[{Next,_}|_]} = HBQ,
	Now = erlang:now(),
	NDLQ = dlq:push2DLQ( [Next-1, lueckeGeschlossen , Now,Now],DLQ,Datei),
	tryToAppend(Next,NDLQ,HBQ,Datei).


pushToHBQ({X,L},M) -> {X+1,pushToHBQ(L,M)};		% fürs einfachere benutzung
pushToHBQ([],[N|Content]) -> [{N,[N|Content]}]; % Die HBQ ist lehr oder es kommt nach hinten
pushToHBQ([{N,M}|R],[M|_Content]) -> [{N,M}|R];	% Das Element ist bereits in der HBQ enthalten :( es wird ignoriert
pushToHBQ([{N,M}|R],[MN|Content]) when N > MN -> [{MN,[MN|Content]}|[{N,M}|R]]; % und einfügen
pushToHBQ([E|R],MSG) -> 	% weiter nach der richtigen position suchen 
	[E|pushToHBQ(R,MSG)].




loop(HBQ,DLQ,DLQSize,Datei,Expected) ->
	io:format("~p~n~p~n~n",[HBQ,DLQ]),
	receive
		%/* Speichern einer Nachricht in der HBQ */
		%HBQ ! {self(), {request,pushHBQ,[NNr,Msg,TSclientout]}}
		%receive {reply, ok} 
		{PID,{request,pushHBQ,[NNr,_Msg,_TSclientout]}} when NNr < Expected  ->	% Nachrichten nummer kleiner als die erwartete, nachricht verwerfen
			PID ! {reply, nok},
			loop(HBQ,DLQ,DLQSize,Datei,Expected);							

		{PID,{request,pushHBQ,[Expected,Msg,TSclientout]}} ->					% die erwartete nachricht wurde erhalten
			TDLQ = dlq:push2DLQ([Expected,Msg,TSclientout,erlang:now()],DLQ,Datei),
			PID ! {reply, ok},
			{NE,NDLQ,NHBQ} = tryToAppend(Expected+1,TDLQ,HBQ,Datei),
			loop(NHBQ,NDLQ,DLQSize,Datei,NE);

		{PID,{request,pushHBQ,[Num,Msg,TSclientout]}} ->						% und ab in die sortierte HBQ
			{NE,NDLQ,NHBQ} = tryToCloseGap(Expected,DLQ, pushToHBQ(HBQ,[Num,Msg,TSclientout,erlang:now()]) ,DLQSize,Datei),
			PID ! {reply, ok},
			loop(NHBQ,NDLQ,DLQSize,Datei,NE);


		%/* Abfrage einer Nachricht */
		%HBQ ! {self(), {request,deliverMSG,NNr,ToClient}}
		%receive {reply, SendNNr}
		{PID,{request,deliverMSG,NNr,ToClient}} ->
			PID ! {reply,dlq:deliverMSG(NNr,ToClient,DLQ,Datei)},
			loop(HBQ,DLQ,DLQSize,Datei,Expected);
		
		%/* Terminierung der HBQ */
		%HBQ ! {self(), {request,dellHBQ}}
		%receive {reply, ok} 
		{PID,{request,dellHBQ}} ->
			PID ! {reply, ok},
			true
	end.