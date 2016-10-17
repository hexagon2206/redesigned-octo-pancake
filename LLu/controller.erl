-module(controller).
-export([start/3]).

start(ServerLogFile,CMEM,HBQ) ->
	spawn(fun() -> loop(ServerLogFile,CMEM,HBQ) end).   

loop(ServerLogFile,CMEM,HBQ) -> 
	receive 
		{CID, getmessages} -> 
			NNr = cmem:getClientNNr(CMEM,CID),
			HBQ ! {self(),{request,deliverMSG,NNr,CID}},
			receive 
				{reply,0} -> 
					log:w(ServerLogFile,'SERVER',"Dummy Nachricht an  ~p zugestellt, nicht Aktualisiert",[CID]),
					loop(ServerLogFile,CMEM,HBQ);
				{reply,SNNr} ->
					log:w(ServerLogFile,'SERVER',"Server: Nachricht ~p an ~p zugestellt",[SNNr,CID]),
					NCMEM = cmem:updateClient(CMEM,CID,SNNr+1,hbqLog),
					loop(ServerLogFile,NCMEM,HBQ)
			end;
		{request,kill} ->
			cmem:delCMEM(CMEM),
			HBQ_PID       ! {self(),{request,dellHBQ}},
			receive
				{ok} ->
				
			ok
	end. 
