-module(ring).
-export([build/2]).
-export([populate/3]).
-export([calculate/3]).


lf() ->
	koordinator:getLogFileName().

build(Nameservicename,ClientList) ->
	tool:l(lf(),'Ring',"buildRing . . ."),
	SClientList=werkzeug:shuffle(ClientList),

	tool:l(lf(),'DBG',"~p",[SClientList]),
	constructRing(Nameservicename,SClientList),
	tool:l(lf(),'Ring',"[DONE]").
	


constructRing(Nameservicename,L)->
	[FName,SName|_] = L,
	[PLName,LName] = constructLine(Nameservicename,L),
	tool:send(FName, Nameservicename,{setneighbors,LName,SName}),
	tool:send(LName, Nameservicename,{setneighbors,PLName,FName}). 


constructLine(_Nameservicename,[X,Y|[]]) -> 
	[X,Y];
constructLine(Nameservicename,[XName,YName,ZName|R]) ->
	tool:send(YName,Nameservicename,{setneighbors,XName,ZName}),
	constructLine(Nameservicename,[YName,ZName|R]). 


populate(_Nameservicename,[],[]) -> 
	ok;

populate(Nameservicename,[N|NR],[C|CR]) ->
	tool:l(lf(),'Ring',"sending ~p to ~p",[N,C]),
	tool:send(C,Nameservicename,{setpm,N}),
	populate(Nameservicename,NR,CR); 

populate(Nameservicename,Wggt,ClientList) -> 
	tool:l(lf(),'Ring',"Populating Ring . . ."),
	Values=werkzeug:bestimme_mis(Wggt,length(ClientList)),
	populate(Nameservicename,Values,ClientList),
	tool:l(lf(),'Ring',"[DONE]"),
	Values.


calculate(Nameservicename,Values,ClientList) -> 
	HowManny = round(length(ClientList)/5),
	CS = werkzeug:shuffle(ClientList),
	if 
		HowManny < 2 ->	
			startCalculation(Nameservicename,Values,CS,2);
		true ->
			startCalculation(Nameservicename,Values,CS,HowManny)
	end.


startCalculation(Nameservicename,Values,ClientList,Num) -> 
	tool:l(lf(),'Ring',"Startin Calulation . . ."),
	startCalculationI(Nameservicename,Values,ClientList,Num).


startCalculationI(_Nameservicename,_Values,_ClientList,0) -> 	
	tool:l(lf(),'Ring',"[DONE]");

startCalculationI(Nameservicename,[Value|VRest],[CNAME|CRest],Num) -> 
	tool:l(lf(),'Ring',"sending ~p to ~p",[Value,CNAME]),
	tool:send(CNAME,Nameservicename,{sendy,Value}),
	startCalculationI(Nameservicename,VRest,CRest,Num-1). 




