% controller.erl
% siehe diagramm(Controller)

-module(controller).
-export([start/3]). % Startet den Controller und initialisert die CMEM

start(ServerLogFile,Clientlifetime,HBQ) ->
	CMEM = cmem:initCMEM(Clientlifetime,ServerLogFile), 
	spawn(fun() -> loop(ServerLogFile,CMEM,HBQ) end).   

loop(ServerLogFile,CMEM,HBQ) -> 
	receive 
		{CID, getmessages} -> 
			NNr = cmem:getClientNNr(CMEM,CID),
			
			HBQ ! {self(),{request,deliverMSG,NNr,CID}},
			receive 
				{reply,0} -> 
					tool:l(ServerLogFile,'SERVER',"Dummy Nachricht an  ~p zugestellt, nicht Aktualisiert",[CID]),
					loop(ServerLogFile,CMEM,HBQ);
				{reply,SNNr} ->
					tool:l(ServerLogFile,'SERVER',"Server: Nachricht ~p an ~p zugestellt",[SNNr,CID]),
					NCMEM = cmem:updateClient(CMEM,CID,SNNr+1,hbqLog),
					loop(ServerLogFile,NCMEM,HBQ)
			end;
		{request,kill} ->
			cmem:delCMEM(CMEM),
			HBQ       ! {self(),{request,dellHBQ}},
			receive
				{reply, down} ->
					ok
			end,
			tool:l(ServerLogFile,'SERVER',"Controller DOWN PID ~p.",[self()])
	end. 
