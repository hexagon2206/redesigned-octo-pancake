%numberService.erl
%siehe diagramm(NumberService)
-module(numberService).
-export([start/1]).

start(LogFile) ->
	spawn(fun() -> loop(LogFile,1) end).
    
loop(LogFile,MsgID) ->
	receive 
		{request,kill} -> 
				tool:l(LogFile,'SERVER',"NumberService DOWN PID ~p.",[self()]);
		{PID} -> 
			PID ! {nid,MsgID},
			tool:l(LogFile,'SERVER',"Nachrichtennummer ~p an ~p gesendet",[MsgID,PID]),
			loop(LogFile,MsgID+1)
	end.