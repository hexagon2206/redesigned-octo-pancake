-module(koordinator).
-export([start/0]).
-export([start/1]).

% {From,getsteeringval} Die Anfrage nach den steuernden Werten durch den Starter Prozess (From ist seine PID).

% {hello,Clientname}:
% Ein ggT-Prozess meldet sich beim Koordinator mit Namen Clientname an (Name ist der lokal registrierte Name, keine PID!).
% OK

% {briefmi,{Clientname,CMi,CZeit}}:
% Ein ggT-Prozess mit Namen Clientname (keine PID!) informiert über sein neues Mi CMi um CZeit Uhr. 
%

% {From,briefterm,{Clientname,CMi,CZeit}}:
% Ein ggT-Prozess mit Namen Clientname (keine PID!) und Absender From (ist PID) informiert über über die Terminierung der Berechnung mit Ergebnis CMi um CZeit Uhr.
%

% reset:
% Der Koordinator sendet allen ggT-Prozessen das kill-Kommando und bringt sich selbst in den initialen Zustand, indem sich Starter wieder melden können.
% -> im init
% -> 
% ->

% step:
% Der Koordinator beendet die Initialphase und bildet den Ring. Er wartet nun auf den Start einer ggT-Berechnung.
%

% prompt:
% Der Koordinator erfragt bei allen ggT-Prozessen per tellmi deren aktuelles Mi ab und zeigt dies im log an.
%

% nudge:
% Der Koordinator erfragt bei allen ggT-Prozessen per pingGGT deren Lebenszustand ab und zeigt dies im log an.
%

% toggle:
% Der Koordinator verändert den Flag zur Korrektur bei falschen Terminierungsmeldungen.
% -> im init
%

% {calc,WggT}:
% Der Koordinator startet eine neue ggT-Berechnung mit Wunsch-ggT WggT.
%


% kill:
% Der Koordinator wird beendet und sendet allen ggT-Prozessen das kill-Kommando.
% -> im init
% 

start() ->
	start('koordinator.cfg').

start(ConfigFile) -> 
	  % Liest aus der Config - Datei die Parameter
	{ok, Config} = file:consult(ConfigFile),

	{ok, Arbeitszeit} = werkzeug:get_config_value(arbeitszeit, Config),			%in  StrVal
	{ok, Termzeit} = werkzeug:get_config_value(termzeit, Config),				%in  StrVal
	{ok, Nameservicenode} = werkzeug:get_config_value(nameservicenode, Config),	%in NSPID
	{ok, Nameservicename} = werkzeug:get_config_value(nameservicename, Config),	%in NSPID
	{ok, Koordinatorname} = werkzeug:get_config_value(koordinatorname, Config),	
	{ok, Quote} = werkzeug:get_config_value(quote, Config),						%in  StrVal
	{ok, Korrigieren} = werkzeug:get_config_value(korrigieren, Config),			

	NSPID = {Nameservicename,Nameservicenode},

	StrVal = {steeringval,Arbeitszeit,Termzeit,Quote},
	CLC = spawn( fun() -> clientListConstructor([])end ),
														%Stewuer werte für starter = erlang:insert_element(5, StrVal, Nummer).
	KOPID = spawn(fun() -> init(Koordinatorname,NSPID,StrVal,1,CLC,Korrigieren) end),
	register(Koordinatorname,KOPID).


clientListConstructor(List) ->
	receive 
		{pin,X} -> 
			clientListConstructor([X|List]);
		{get,From} -> 
			From ! {self(),list,List};
		{command, kill} -> 
			destroyClientList(List);
		_ -> 
			clientListConstructor(List)
	end.

destroyClientList([]) -> ok;
destroyClientList([PID|R]) -> 
	PID ! kill,
	destroyClientList(R).


reset(Koordinatorname,NSPID,StrVal,_StarterNummer,_,Korrigieren) -> 
	CLC = spawn( fun() -> clientListConstructor([])end ),  						%Stewuer werte für starter = erlang:insert_element(5, StrVal, Nummer).
	init(Koordinatorname,NSPID,StrVal,1,CLC,Korrigieren).
	

init(Koordinatorname,NSPID,StrVal,StarterNummer,CLC,Korrigieren) ->
	receive 
		{From,getsteeringval} -> 
			From ! erlang:insert_element(5, StrVal, StarterNummer),
			init(Koordinatorname,NSPID,StrVal,StarterNummer+1,CLC,Korrigieren);
		{hello,Clientname} -> 
			NSPID ! {CLC,{lookup,Clientname}},
			init(Koordinatorname,NSPID,StrVal,StarterNummer,CLC,Korrigieren);
		toggle -> 
			init(Koordinatorname,NSPID,StrVal,StarterNummer,CLC,not(Korrigieren));
		step   ->
			CLC ! {get,self()},
			receive
				{CLC,list,Clients}
			end.
			stepp(Koordinatorname,NSPID,StrVal,Korrigieren,Clients);
		kill   -> 
			CLC ! {command,kill};
		reset  -> 
			CLC ! {command,kill},
			reset(Koordinatorname,NSPID,StrVal,StarterNummer,CLC,Korrigieren)
		
	end.
