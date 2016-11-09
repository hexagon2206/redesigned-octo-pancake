
-module(ggt_process).
-author("flo").

-export([init/6]).

% ######################################### Initalisierung ################################################## %

% Initialisiert den ggt-prozess
init(Delay, WorkTime, ClientName, NameServiceName, CoordinatorName, Quota) ->
    % Den NameService anpingen, beim NameService registrieren und anschließend den Coordinator abfragen
%    net_adm:ping(NameServiceNode),
    % Fürs Sync wichtig
%    timer:sleep(500),

    NameService = global:whereis_name(NameServiceName),
    NameService ! {self(), {rebind, ClientName, node()}},

    receive 
      ok  -> 

      LogFile = tool:format("~p.log",[ClientName]),
      tool:l(LogFile,ClientName,"ggt_process wird gestartet "),

     % spawn(fun() -> handleKillCommand() end),
     % spawn(fun() -> handlePing(ClientName) end),
     register(ClientName, self()),

      tool:send(CoordinatorName,NameServiceName,{hello, ClientName}),
      tool:l(LogFile,ClientName,"Beim Koordinator anmelden "),
      workPhase(ClientName,false,noTimer_xD, CoordinatorName, NameServiceName,
                 'LeftNeighbor noch nicht gesetzt',
                 'RightNeighbor noch nicht gesetzt',
                  WorkTime, Delay, Quota,
                  'Mi noch nicht gesetzt',
                  LogFile)
    end. 

% ######################################################## Berechnung / Arbeitsphase ########################################################## %

workPhase(ClientName,Consense,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile) ->
  receive
    {setneighbors, Left, Right} ->
      tool:l(LogFile,ClientName,"Setze Rechten und Linken Nachbarn : Links- ~p , Rechts- ~p  ", [Left,Right]),
      workPhase(ClientName,Consense,Timer, Coordinator, NameService, Left, Right, WorkTime, Delay, ProcessCountNeeded,'Mi noch nicht gesetzt' ,LogFile);
    {setpm, NMi} ->
      tool:l(LogFile,ClientName,"Mi erhalten | Zeitstempel:  ~p ", [erlang:system_time()]),
      timer:cancel(Timer),
      NewTimer = timer:send_after(round(WorkTime/2*1000)),{self(),timeout}),
      workPhase(ClientName,false,NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NMi, LogFile);
    {sendy, Y} ->
      tool:l(LogFile,ClientName,"Y erhalten | Zeitstempel:  ~p ", [erlang:system_time()]),
      NewMi = calc(Mi, Y, LeftNeighbor, RightNeighbor, Coordinator, Delay, ClientName, NameService, LogFile),
      timer:cancel(Timer),
      NewTimer = timer:send_after(round(WorkTime/2*1000)),{self(),timeout}),
      workPhase(ClientName,false,NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NewMi, LogFile);

     {From, tellmi} ->
        From ! {mi, Mi},
        tool:l(LogFile,ClientName,"Teile Koordinator Mi mit| Zeitstempel:  ~p ", [erlang:system_time()]),
        workPhase(ClientName,Consense,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);

      {From, pingGGT} ->
        From ! {pongGGT, ClientName},
        tool:l(LogFile,ClientName,"Senden Ping an Koordinator | Zeitstempel:  ~p ", [erlang:system_time()]),
        workPhase(ClientName,Consense,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);
      
   

      {From, {vote, Name}} ->
        if
          Consense ->
            From ! {voteYes, ClientName}  ;  
          true ->
            workPhase(ClientName,true,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);
        end;


      timeout -> 
        if 
          Consense -> 
            timer:send_after(Delay*4000,{spawn(fun() -> startVote(ClientName,Koordinator,NameService,Mi,Quota) end),timeout});
            workPhase(ClientName,true,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);
          true -> 
            workPhase(ClientName,true,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);
        end;

        
      kill ->
        %exit("Kill Command"),
        timer:cancel(Timer),
        tool:l(LogFile,ClientName,"Beende ggt_process "),
        NameServicePID = global:whereis_name(NameService),
        NameServicePID ! {self(), {unbind, ClientName}},
        ok;
      O ->
        tool:l(LogFile,ClientName,"Unerwartete Nachricht :  ~p ", [O])
  end.

% Startet eine neue Berechnung
calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Delay, ClientName, NameService, LogFile) ->
    timer:sleep(Delay),
    if
        (Y < Mi) ->
          tool:l(LogFile,ClientName,"Starte Berechnung mit Mi: ~p und Y: ~p | Zeitstempel:  ~p ", [Mi, Y, erlang:system_time()]),
            NewMi = ((Mi - 1) rem Y) + 1,
            tool:send(NeighborLeft,NameService,{sendy, NewMi}),
            tool:send(NeighborRight,NameService,{sendy, NewMi}),
            tool:send(Coordinator,NameService,{briefmi,{ClientName, NewMi, erlang:system_time()}}),
            NewMi;
        true ->
            Mi
    end.

% ########################################################## Abbruch ############################################################## %

startVote(ClientName,Koordinator,NameService,Mi,0) -> 
  %bief den Koordinatoooooor.
  ok;
startVote(ClientName,Koordinator,NameService,Mi,Quota) -> 
  receive
    {From, {voteYes, _}} ->
      startVote(ClientName,Koordinator,NameService,Mi,Quota-1);
      %looooging
    timeout -> 
      %loging
      ok
  end.