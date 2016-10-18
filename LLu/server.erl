-module(server).
-export([start/0]).

%Autokill muss noch eingebaut werden

start() ->

%logfile Namen erstellen und logfile Lesen
	ServerLogFile = atom_to_list(node())++".log",	

	tool:l(ServerLogFile,'SERVER',"server.cfg geöffnet..."),
	{ok, ConfigListe} = file:consult("server.cfg"),
    {ok, ClientlifetimeT} = werkzeug:get_config_value(clientlifetime, ConfigListe),
	Clientlifetime = ClientlifetimeT * 1000,
	{ok, Servername} = werkzeug:get_config_value(servername, ConfigListe),
	{ok, Hbqname} = werkzeug:get_config_value(hbqname, ConfigListe),
	{ok, Hbqnode} = werkzeug:get_config_value(hbqnode, ConfigListe),
	{ok, LatencyT} = werkzeug:get_config_value(latency, ConfigListe),
	Latency = LatencyT * 1000,

	HBQ_PID = {Hbqname,Hbqnode},
	NumberService = numberService:start(ServerLogFile),
	TrashCan 	  = spawn(fun() -> trashCan(ServerLogFile) end),
    CTRL      = controller:start(ServerLogFile,Clientlifetime,HBQ_PID),

    ServerPid = spawn(fun() -> init(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency) end),
	
	register(Servername,ServerPid),
	tool:l(ServerLogFile,'SERVER',"Started mit PID ~p registerd as '~p' ",[ServerPid,Servername]),
    ok.

% kann verwendet werden um antworten andere SErvices zu entsoren, damit Aufrufe nicht Blokierend sind, fals die antwort irelevant ist.
trashCan(ServerLogFile) ->
	receive 
		{request,kill} -> 
			tool:l(ServerLogFile,'SERVER',"TrashCan DOWN PID ~p.",[self()]);
		_ -> trashCan(ServerLogFile)
	end.
	

% initalisiert die HBQ und startet die Haupt schleife, nach verlassen dieser wird die shutdown rotine aufgerufen.
init(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency) ->
	HBQ_PID ! {self(),{request,initHBQ}},
	receive 
		{reply, ok}	-> 
			tool:l(ServerLogFile,'SERVER',"HBQ erfolgreich initialisiert"),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,0,0)
	end.

% sendet an alle relevanten services Shutdown Requests,
% der Controller wiederrum kümmert sich um das beenden der HBQ und der CMEM
shutdown(ServerLogFile,CTRL,NumberService,TrashCan) ->
	tool:l(ServerLogFile,'SERVER',"shutting Down . . "),
	CTRL          ! {request,kill},
	NumberService ! {request,kill},
	TrashCan      ! {request,kill},
	tool:l(ServerLogFile,'SERVER',"Server DOWN PID ~p.",[self()]).




loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,0,KillKey) ->
	receive 

		% Eine Nachrichten Nummern Anfrage wird nicht direkt bearbeitet sondern einfach an den Nummern SErvice Weiter gereicht.
		{CID, getmsgid} -> 
			NumberService ! {CID},
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,1,KillKey);

		% Für das verarbeiten von nachrichten ist die HBQ zuständig
		{dropmessage,[NNR,MSG,TSclientout]} ->
			HBQ_PID ! { TrashCan ,{request,pushHBQ,[NNR,MSG,TSclientout]}},
			tool:l(ServerLogFile,'SERVER',"Nachricht: ~p an HBQ gesendet",[NNR]),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,1,KillKey);

		% Die auslieferung von nachrichten wird von dem Controller übernommen
        {CID, getmessages} -> 
        	CTRL ! { CID , getmessages},
        	loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,1,KillKey);

        %ein Kill request sorgt dafür das das gesamte system beendet wird.
        {request,kill,KillKey} ->
        	shutdown(ServerLogFile,CTRL,NumberService,TrashCan);
		{request,kill,WrongKey} ->
        	tool:l(ServerLogFile,'SERVER',"Kill Request with Wrong Key :~p , curentKeyIs ~p", [WrongKey,KillKey]),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,0,KillKey);
		Any -> 
			tool:l(ServerLogFile,'SERVER',"Received Something unexpacted :~p", [Any]),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,1,KillKey)
	end;	

%hilfs funktion um nach der latency eine Kill Nachricht an den Server zu senden, falls in der Zeit keine Neue anfrage eintraf.
loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,1,OldKillKey) ->
	KillKey = OldKillKey+1,
	timer:send_after(Latency,{request,kill,KillKey}),
	loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,Latency,0,KillKey).




