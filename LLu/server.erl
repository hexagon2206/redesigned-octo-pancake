-module(server).
-export([start/0]).

%Autokill muss noch eingebaut werden
start() ->

	ServerLogFile = atom_to_list(node())++".log",

	log:w(ServerLogFile,'SERVER',"server.cfg geöffnet..."),
	{ok, ConfigListe} = file:consult("server.cfg"),
    {ok, Clientlifetime} = werkzeug:get_config_value(clientlifetime, ConfigListe),
	{ok, Servername} = werkzeug:get_config_value(servername, ConfigListe),
	{ok, Hbqname} = werkzeug:get_config_value(hbqname, ConfigListe),
	{ok, Hbqnode} = werkzeug:get_config_value(hbqnode, ConfigListe),
	

	HBQ_PID = {Hbqname,Hbqnode},

	NumberService = numberService:start(ServerLogFile),
	TrashCan 	  = spawn(fun() -> trashCan() end),
    CMEM 	  = cmem:initCMEM(Clientlifetime,ServerLogFile), 
    CTRL      = controller:start(ServerLogFile,CMEM,HBQ_PID),

    ServerPid = spawn(fun() -> init(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan) end),
	
	register(Servername,ServerPid),
	log:w(ServerLogFile,'SERVER',"Started mit PID ~p registerd as '~p' ",[ServerPid,Servername]),
    ServerPid.

trashCan() ->
	receive 
		{request,kill} -> ok;
		_ -> trashCan()
	end.
	
init(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan) ->
	HBQ_PID ! {self(),{request,initHBQ}},
	receive 
		{reply, ok}	-> 
			log:w(ServerLogFile,'SERVER',"HBQ erfolgreich initialisiert"),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,0),

			log:w(ServerLogFile,'SERVER',"shutting Down"),
			CTRL          ! {request,kill},
			NumberService ! {request,kill},
			TrashCan      ! {request,kill},
			log:w(ServerLogFile,'SERVER',"Shutting Down Server with PID ~p.",[self()])
	end.


loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,0) ->
	receive 
		{CID, getmsgid} -> 
			NumberService ! {CID},
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1);
		{dropmessage,[NNR,MSG,TSclientout]} ->
			HBQ_PID ! { TrashCan ,{request,pushHBQ,[NNR,MSG,TSclientout]}},
			log:w(ServerLogFile,'SERVER',"Nachricht: ~p an HBQ gesendet",[NNR]),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1);
        {CID, getmessages} -> 
        	CTRL ! { CID , getmessages},
        	loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1);
		Any -> 
			log:w(ServerLogFile,'SERVER',"Received Something unexpacted :~p", [Any]),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1)
	end;	

loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1) ->
	%reset_timer(killTimer,Latency,{kill}),
	receive 
		{CID, getmsgid} -> 
			NumberService ! {CID},
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1);
		{dropmessage,[NNR,MSG,TSclientout]} ->
			HBQ_PID ! { TrashCan ,{request,pushHBQ,[NNR,MSG,TSclientout]}},
			log:w(ServerLogFile,'SERVER',"Nachricht: ~p an HBQ gesendet",[NNR]),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1);
        {CID, getmessages} -> 
        	CTRL ! { CID , getmessages},
        	loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1);
		Any -> 
			log:w(ServerLogFile,'SERVER',"Received Something unexpacted :~p", [Any]),
			loop(ServerLogFile,HBQ_PID,NumberService,CTRL,TrashCan,1)
	end.	





