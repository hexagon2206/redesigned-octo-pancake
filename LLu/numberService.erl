-module(numberService).
-export([start/1]).

start(Name) ->
	ServerPid = spawn(fun() -> loop(1) end),
    register(Name,ServerPid),
	ServerPid.
	
loop(MsgID) ->
	receive 
		{PID} -> 
			PID ! {nid,MsgID},
			loop(MsgID+1);
		Any -> 
			io:format("Received Something unexpacted :~p\n", [Any]),
			loop(MsgID)
	end.