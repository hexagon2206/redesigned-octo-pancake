-module(ring).
-export([build/3]).
-export([populate/4]).
-export([calculate/4]).


build(Nameservicename,ClientList,LogFile) ->
	tool:l(LogFile,'Ring',"buildRing . . ."),
	SClientList=werkzeug:shuffle(ClientList),

	tool:l(LogFile,'DBG',"~p",[SClientList]),
	constructRing(Nameservicename,SClientList),
	tool:l(LogFile,'Ring',"[DONE]").
	


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


populate(_Nameservicename,[],[],_LogFile) -> 
	ok;

populate(Nameservicename,[N|NR],[C|CR],LogFile) ->
	tool:l(LogFile,'Ring',"sending ~p to ~p",[N,C]),
	tool:send(C,Nameservicename,{setpm,N}),
	populate(Nameservicename,NR,CR,LogFile); 

populate(Nameservicename,Wggt,ClientList,LogFile) -> 
	tool:l(LogFile,'Ring',"Populating Ring . . ."),
	Values=werkzeug:bestimme_mis(Wggt,length(ClientList)),
	populate(Nameservicename,Values,ClientList,LogFile),
	tool:l(LogFile,'Ring',"[DONE]"),
	Values.


calculate(Nameservicename,Values,ClientList,LogFile) -> 
	HowManny = round(length(ClientList)/5),
	CS = werkzeug:shuffle(ClientList),
	if 
		HowManny < 2 ->	
			startCalculation(Nameservicename,Values,CS,2,LogFile);
		true ->
			startCalculation(Nameservicename,Values,CS,HowManny,LogFile)
	end.


startCalculation(Nameservicename,Values,ClientList,Num,LogFile) -> 
	tool:l(LogFile,'Ring',"Startin Calulation . . ."),
	startCalculationI(Nameservicename,Values,ClientList,Num,LogFile).


startCalculationI(_Nameservicename,_Values,_ClientList,0,LogFile) -> 	
	tool:l(LogFile,'Ring',"[DONE]");

startCalculationI(Nameservicename,[Value|VRest],[CNAME|CRest],Num,LogFile) -> 
	tool:l(LogFile,'Ring',"sending ~p to ~p",[Value,CNAME]),
	tool:send(CNAME,Nameservicename,{sendy,Value}),
	startCalculationI(Nameservicename,VRest,CRest,Num-1,LogFile). 




