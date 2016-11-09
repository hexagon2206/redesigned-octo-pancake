-module(clientList).
-export([report/2]).
-export([destroy/2]).


lf() ->
	koordinator:getLogFileName().


report(NamensDienstName,List) ->
	clientStateReporter(NamensDienstName,List,0).

clientStateReporter(NamensDienstName,[],X) -> 
	timer:send_after(timer:seconds(10),{self(),timeout}),
	clientStateReporter(NamensDienstName,report,X);

clientStateReporter(NamensDienstName,[Name|R],X) ->
	tool:send(Name,NamensDienstName,{self(),pingGGT}),
	clientStateReporter(NamensDienstName,R,X+1);

clientStateReporter(_NamensDienstName,report,0) -> 
	0;

clientStateReporter(NamensDienstName,report,NUM) ->
	MPID = self(),
	receive
		{pongGGT,GGTname} ->  
			tool:l(lf(),'ClientStateReport',"Rueckmeldung von ~p",[GGTname]),
			clientStateReporter(NamensDienstName,report,NUM-1);
		{MPID,timeout}  ->
			tool:l(lf(),'ClientStateReport',"TIEMOUT nach 10 sec : ~p client(s) fehlen",[NUM]),
			NUM
	end.


destroy(_NamensDienstName,[]) -> ok;
destroy(NamensDienstName,[Client|R]) -> 
	tool:send(Client,NamensDienstName,kill),
	destroy(NamensDienstName,R).
