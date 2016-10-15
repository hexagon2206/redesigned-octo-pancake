-module(numberService).
-export([start/1]).

start(LogFile) ->
	spawn(fun() -> loop(LogFile,1) end).
    
loop(LogFile,MsgID) ->
	receive 
		{request,kill} -> ok;
		{PID} -> 
			PID ! {nid,MsgID},
			log:w(LogFile,'SERVER',"Nachrichtennummer ~p an ~p gesendet",[MsgID,PID]),
			loop(LogFile,MsgID+1)
	end.