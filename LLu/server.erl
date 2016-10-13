-module(server).
-export([start/0]).
-export([requestMsgNumber/0]).
-export([requestMsgNumber/1]).


start() ->

	numberService:start(numberS),
	ServerPid = spawn(fun() -> loop() end),
	TCS 	  = spawn(fun() -> trashCan() end),
    
    register(server,ServerPid),
    register(trashCanService,TCS),
	
	ServerPid.

trashCan() ->
	receive 
		_ -> trashCan()
	end.
	
loop() ->
	receive 
		{CID, getmsgid} -> 
			numberS ! {CID},
			loop();
		{dropmessage,[NNR,MSG,TSclientout]} ->
			hbqS ! {trashCanService,{request,pushHBQ,[NNR,MSG,TSclientout]}};	
		Any -> 
			io:format("Received Something unexpacted :~p\n", [Any]),
			loop()
	end.
	
	
requestMsgNumber() ->
	requestMsgNumber(server).
	
requestMsgNumber(Server) ->
	Server ! {self(), getmsgid},
	receive
		{nid,Num} -> 
			Num;
		_ -> 
			io:format("unerwarteteAntwort") ,
			-1
	end.
	