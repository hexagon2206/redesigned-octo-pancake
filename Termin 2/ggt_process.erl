
-module(ggt_process).
-author("flo").

-export([init/6]).

% ######################################### Initalisierung ################################################## %

% Initialisiert den ggt-prozess
init(Delay, WorkTime, ClientName, NameServiceName, CoordinatorName, Quota) ->

    NameService = global:whereis_name(NameServiceName),
    NameService ! {self(), {rebind, ClientName, node()}},
    
    receive 
      ok  -> 
        LogFile = tool:format("~p.log",[ClientName]),
        tool:l(LogFile,ClientName,"ggt_process wird gestartet "),
        tool:l(LogFile,ClientName,"Start - Quota: ~p | Zeitstempel:  ~p ", [Quota, erlang:system_time()]),
        register(ClientName, self()),

      tool:send(CoordinatorName, NameServiceName, {hello, ClientName}),
      tool:l(LogFile,ClientName,"Beim Koordinator anmelden "),
      workPhase(ClientName, false, noTimer_xD, CoordinatorName, NameServiceName, 'LeftNeighbor noch nicht gesetzt', 'RightNeighbor noch nicht gesetzt', WorkTime, Delay, Quota, 'Mi noch nicht gesetzt', LogFile, false)
    end. 

% ######################################################## Berechnung / Arbeitsphase ########################################################## %

workPhase(ClientName, Consense, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, ActiveVote) ->
  %tool:l(LogFile,ClientName,"Starte workPhase | Zeitstempel:  ~p ", [erlang:system_time()]),
  receive
    {setneighbors, Left, Right} ->
      tool:l(LogFile,ClientName,"Setze Rechten und Linken Nachbarn : Links- ~p , Rechts- ~p  ", [Left,Right]),
      workPhase(ClientName,Consense,Timer, Coordinator, NameService, Left, Right, WorkTime, Delay, ProcessCountNeeded,'Mi noch nicht gesetzt', LogFile, ActiveVote);
    {setpm, NMi} ->
      tool:l(LogFile,ClientName,"Mi erhalten | Zeitstempel:  ~p ", [erlang:system_time()]),
      timer:cancel(Timer),
      NewTimer = timer:send_after(round(WorkTime/2*1000), timeout),
      workPhase(ClientName,false,NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NMi, LogFile, ActiveVote);

    {sendy, Y} ->
      tool:l(LogFile,ClientName,"Y erhalten | Zeitstempel:  ~p ", [erlang:system_time()]),
      NewMi = calc(Mi, Y, LeftNeighbor, RightNeighbor, Coordinator, Delay, ClientName, NameService, LogFile),
      timer:cancel(Timer),
      NewTimer = timer:send_after(round(WorkTime/2*1000), timeout),
      workPhase(ClientName,false,NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NewMi, LogFile, ActiveVote);

     {From, tellmi} ->
        From ! {mi, Mi},
        tool:l(LogFile,ClientName,"Teile Koordinator Mi mit| Zeitstempel:  ~p ", [erlang:system_time()]),
        workPhase(ClientName,Consense,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, ActiveVote);

     {From, pingGGT} ->
        From ! {pongGGT, ClientName},
        tool:l(LogFile,ClientName,"Senden Ping an Koordinator | Zeitstempel:  ~p ", [erlang:system_time()]),
        workPhase(ClientName,Consense,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, ActiveVote);
      
    {_, {vote, Name}} ->
      tool:l(LogFile,ClientName,"Erhalte vote Aufforderung von: ~p | Zeitstempel:  ~p ", [Name, erlang:system_time()]),
        if
          Consense ->
            tool:l(LogFile,ClientName, "Stimme abbruch der Berechnung zu | Zeitstempel:  ~p ", [erlang:system_time()]),

            tool:send(Name, NameService, {voteYes, ClientName}),
            workPhase(ClientName, true, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, ActiveVote);  
          true ->
            workPhase(ClientName, true, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, ActiveVote)
        end;

      timeout -> 
        if 
           Consense == true, ActiveVote == false -> 
            tool:l(LogFile,ClientName,"Starte Abstimmung | Zeitstempel:  ~p ", [erlang:system_time()]),
            % timer:send_after(Delay*4000,spawn(fun() -> startVote(ClientName, Coordinator, NameService, Mi, ProcessCountNeeded) end), timeout),
            %Vote = spawn(fun() -> startVote(self(), ClientName, NameService, Coordinator, Mi, ProcessCountNeeded, LogFile) end),
           % NameService ! {self(), {multicast, vote, ClientName}},
            TMP = global:whereis_name(NameService),
            TMP ! {self(), {multicast, vote, ClientName}},
            %tool:send(NameService, NameService, {self(), {multicast, vote, ClientName}}),
            workPhase(ClientName, true, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, true);
          true ->
            timer:cancel(Timer),

            NewTimer = timer:send_after(round(WorkTime/2*1000),timeout),
            workPhase(ClientName,true, NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, false)
        end;

      kill ->
        timer:cancel(Timer),
        tool:l(LogFile,ClientName,"Beende ggt_process "),
        NameServicePID = global:whereis_name(NameService),
        NameServicePID ! {self(), {unbind, ClientName}},
        ok;

      {voteYes, Name} ->
        tool:l(LogFile,ClientName,"Vote von: ~p erhalten | Zeitstempel:  ~p ", [Name, erlang:system_time()]),
        startVote(ClientName, NameService, Coordinator, Mi, ProcessCountNeeded, LogFile);
        %workPhase(ClientName, false, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, false);
      O ->
        tool:l(LogFile,ClientName,"Unerwartete Nachricht :  ~p ", [O])
        %timer:cancel(Timer),
        %NewTimer = timer:send_after(round(WorkTime/2*1000),timeout),
        %workPhase(ClientName, false, NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile)
  end.

% Startet eine neue Berechnung
calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Delay, ClientName, NameService, LogFile) ->
    timer:sleep(Delay),
    if
        (Y < Mi) ->
          tool:l(LogFile, ClientName,"Starte Berechnung mit Mi: ~p und Y: ~p | Zeitstempel:  ~p ", [Mi, Y, erlang:system_time()]),
            NewMi = ((Mi - 1) rem Y) + 1,
            tool:send(NeighborLeft,NameService,{sendy, NewMi}),
            tool:send(NeighborRight,NameService,{sendy, NewMi}),
            tool:send(Coordinator,NameService,{briefmi,{ClientName, NewMi, erlang:system_time()}}),
            NewMi;
        true ->
            Mi
    end.

% ########################################################## Abbruch ############################################################## %

startVote(ClientName, NameService, Coordinator, Mi, 0, LogFile) -> 
  tool:l(LogFile,ClientName,"Briefe Koordinator | Zeitstempel:  ~p ", [erlang:system_time()]),
  tool:send(Coordinator, NameService, {briefterm, {ClientName, Mi, erlang:system_time()}});
  %workPhase(ClientName, false, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile, true);

startVote(ClientName, NameService ,Coordinator, Mi, Quota, LogFile) -> 
  tool:l(LogFile,ClientName,"Davor Quota: ~p | Zeitstempel:  ~p ", [Quota, erlang:system_time()]),
  Q = Quota - 1,
  receive
    {voteYes, Name} ->
      tool:l(LogFile,ClientName,"Vote von: ~p erhalten | Zeitstempel:  ~p ", [Name, erlang:system_time()]),
      tool:l(LogFile,ClientName,"Danach Quota: ~p | Zeitstempel:  ~p ", [Q, erlang:system_time()]),
      startVote(ClientName, NameService, Coordinator, Mi, Q, LogFile)
  end.
  
