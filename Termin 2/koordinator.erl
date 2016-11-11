-module(koordinator).
-export([start/0]).

-export([getLogFileName/0]).

%2016-11-01 8h


%%%%% ALL PHASES %%%%%

% reset:
% Der Koordinator sendet allen ggT-Prozessen das kill-Kommando und bringt sich selbst in den initialen Zustand, indem sich Starter wieder melden können.

% Nameservicename,nudge:
% Der Koordinator erfragt bei allen ggT-Prozessen per pingGGT deren Lebenszustand ab und zeigt dies im log an.

% toggle:
% Der Koordinator verändert den Flag zur Korrektur bei falschen Terminierungsmeldungen.

% kill:
% Der Koordinator wird beendet und sendet allen ggT-Prozessen das kill-Kommando.


%%%%% INIT PHASE %%%%%

% {From,getsteeringval}
% Die Anfrage nach den steuernden Werten durch den Starter Prozess (From ist seine PID).

% {hello,ClientName}:
% Ein ggT-Prozess meldet sich beim Koordinator mit Namen ClientName an (Name ist der lokal registrierte Name, keine PID!).

% step:
% Der Koordinator beendet die Initialphase und bildet den Ring. Er wartet nun auf den Start einer ggT-Berechnung.


%%%%% CALC PHASE %%%%%

% {calc,WggT}:
% Der Koordinator startet eine neue ggT-Berechnung mit Wunsch-ggT WggT.

% {briefmi,{ClientName,CMi,CZeit}}:
% Ein ggT-Prozess mit Namen ClientName (keine PID!) informiert über sein neues Mi CMi um CZeit Uhr. 

% {From,briefterm,{ClientName,CMi,CZeit}}:
% Ein ggT-Prozess mit Namen ClientName (keine PID!) und Absender From (ist PID) informiert über über die Terminierung der Berechnung mit Ergebnis CMi um CZeit Uhr.

% prompt:
% Der Koordinator erfragt bei allen ggT-Prozessen per tellmi deren aktuelles Mi ab und zeigt dies im log an.


lf() -> getLogFileName().
getLogFileName() -> 'Koordinator_log.log'.


start() ->
	start('koordinator.cfg').

start(ConfigFile) -> 
	  % Liest aus der Config - Datei die Parameter
	tool:l(lf(),'Startup',"Startup . . "),
	tool:l(lf(),'Startup',"Lese Config file . . ."),
	{ok, Config} = file:consult(ConfigFile),
	{ok, Arbeitszeit} = werkzeug:get_config_value(arbeitszeit, Config),			%in  StrVal
	{ok, Termzeit} = werkzeug:get_config_value(termzeit, Config),				%in  StrVal
	{ok, Ggtprozessnummer} = werkzeug:get_config_value(ggtprozessnummer, Config),%in  StrVal
	{ok, Nameservicenode} = werkzeug:get_config_value(nameservicenode, Config),	%in NSPID
	{ok, Nameservicename} = werkzeug:get_config_value(nameservicename, Config),	%in NSPID
	{ok, Koordinatorname} = werkzeug:get_config_value(koordinatorname, Config),	
	{ok, Quote} = werkzeug:get_config_value(quote, Config),						%in  StrVal
	{ok, Korrigieren} = werkzeug:get_config_value(korrigieren, Config),			

	tool:l(lf(),'Startup',"[OK]"),


	tool:l(lf(),'Startup',"Pinge NS Node . . ."),
	net_adm:ping(Nameservicenode),
	timer:sleep(500),
	tool:l(lf(),'Startup',"[OK]"),


	StrVal = {steeringval,Arbeitszeit,Termzeit,Quote,Ggtprozessnummer},

	KOPID = spawn(fun() -> initPhase(Koordinatorname,StrVal,Nameservicename,Korrigieren) end),

	tool:l(lf(),'Startup',"Registrien des Dienstes . . ."),
	register(Koordinatorname,KOPID),
	NSPID = global:whereis_name(Nameservicename),
	NSPID ! {self(),{rebind,Koordinatorname,node()}},
	tool:l(lf(),'Startup',"[OK]"),
	tool:l(lf(),'Startup',"[DONE]").



reset(_Phase,Nameservicename,ClientList) ->
	tool:l(lf(),'Koordinator',"Resetting . . ."),
	clientList:destroy(Nameservicename,ClientList),
	spawn( fun() -> start() end ),
	tool:l(lf(),'Koordinator',"[GONE]").
	
initPhase(Koordinatorname,StrVal,Nameservicename,Korrigieren) ->  
	tool:l(lf(),'Koordinator',"Betrete init Phase"),
	initPhase(Koordinatorname,StrVal,1,[],Nameservicename,Korrigieren,0). 

initPhase(Koordinatorname,StrVal,StarterNummer,ClientList,Nameservicename,Korrigieren,ClientCount) ->
	receive 
		% STATE SPEZIFIC
		{From,getsteeringval} ->
			{steeringval,Arbeitszeit,Termzeit,Quote,Ggtprozessnummer} = StrVal,

			SV = {steeringval,Arbeitszeit,Termzeit,round((Ggtprozessnummer+ClientCount)*Quote/100),Ggtprozessnummer},
			
			tool:l(lf(),'Koordinator',"Steuerwerte ~p an ~p",[SV,From]),
			From ! SV,
			initPhase(Koordinatorname,StrVal,StarterNummer+1,ClientList,Nameservicename,Korrigieren,Ggtprozessnummer+ClientCount);
		{hello,ClientName} -> 
			tool:l(lf(),'Koordinator',"Hallo von ~p",[ClientName]),
			initPhase(Koordinatorname,StrVal,StarterNummer,[ClientName|ClientList],Nameservicename,Korrigieren,ClientCount);
		step  ->
			stepp(Koordinatorname,ClientList,Nameservicename,Korrigieren);

		%ALL STATES
		toggle -> 
			initPhase(Koordinatorname,StrVal,StarterNummer,ClientList,Nameservicename,not(Korrigieren),ClientCount);
		kill   -> 
			clientList:destroy(Nameservicename,ClientList),
			tool:l(lf(),'Koordinator',"Unbinding . . . "),
			NSPID = global:whereis_name(Nameservicename),
			NSPID ! {self(),{unbind,Koordinatorname}},
			receive 
				ok -> 	tool:l(lf(),'Koordinator',"Unbind Done"),
						tool:l(lf(),'Koordinator',"Shutting Down")
			end;
		reset  -> 
			reset(Nameservicename,init,ClientList);
		nudge  ->
			spawn( fun() -> clientList:report(Nameservicename,ClientList)end),
			initPhase(Koordinatorname,StrVal,StarterNummer,ClientList,Nameservicename,Korrigieren,ClientCount);
		%OTHER
		V -> 
			tool:l(lf(),'Koordinator',"Recived unexpcted in init : ~p",[V]),
			initPhase(Koordinatorname,StrVal,StarterNummer,ClientList,Nameservicename,Korrigieren,ClientCount)
	end.

stepp(Koordinatorname,ClientList,Nameservicename,Korrigieren) -> 
	tool:l(lf(),'Koordinator',"stepping to Calculation, Clients :  ~p",[ClientList]),
	MinMi = ring:build(Nameservicename,ClientList,lf()),
	calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren).


calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren) -> 
	% ALL STATES
	receive
		toggle ->
			calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,not(Korrigieren)) ;
		kill   -> 
			clientList:destroy(Nameservicename,ClientList),
			tool:l(lf(),'Koordinator',"Unbinding . . . "),
			NSPID = global:whereis_name(Nameservicename),
			NSPID ! {self(),{unbind,Koordinatorname}},
			receive 
				ok -> 	tool:l(lf(),'Koordinator',"Unbind Done"),
						tool:l(lf(),'Koordinator',"Shutting Down")
			end;
		reset  -> 
			reset(calculate,Nameservicename,ClientList);
		nudge  ->
			spawn( fun() -> Nameservicename,clientList:report(Nameservicename,ClientList)end),
			calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren);
		% CALC STATE

		{calc,WggT} -> 
			Values=ring:populate(Nameservicename,WggT,ClientList,lf()),
			ring:calculate(Nameservicename,Values,ClientList,lf()),
			[NMINIMI|_]=tool:sort(Values),
			calcPhase(Koordinatorname,NMINIMI,ClientList,Nameservicename,Korrigieren);	
		
		

		%Wird verwendet um das bis jetzt beste MI zu bekommen, für korektur notwendig
		{briefmi,{ClientName,CMi,CZeit}} -> 
			tool:l(lf(),'Koordinator',"Meldung von ~p um ~p wert : ~p",[ClientName,CZeit,CMi]),
			if 
				MinMi > CMi -> 
					calcPhase(Koordinatorname,CMi,ClientList,Nameservicename,Korrigieren);
				true ->
					calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren)	
			end;

		{_From,briefterm,{ClientName,CMi,CZeit}} ->
			tool:l(lf(),'Koordinator',"Terminierung von ~p um ~p Ergebnis : ~p",[ClientName,CZeit,CMi]),
			
			%TODO Korektur senden

			calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren);	

		{_PID,{vote,ClientName}} -> 
			tool:l(lf(),'Koordinator',"Aufruf zur umfrage von  : ~p",[ClientName]),
			calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren);	
		prompt -> 
			tool:l(lf(),'Koordinator',"prompt"),
			calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren);	
			% prompt:
			% Der Koordinator erfragt bei allen ggT-Prozessen per tellmi deren aktuelles Mi ab und zeigt dies im log an.
			%
			% CALC Phase

		V -> 
			tool:l(lf(),'Koordinator',"Recived unexpcted in calc : ~p",[V]),
			calcPhase(Koordinatorname,MinMi,ClientList,Nameservicename,Korrigieren)
	end.




