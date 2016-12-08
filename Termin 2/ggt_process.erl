
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
      workPhase(ClientName, false, noTimer, CoordinatorName, NameServiceName, 'LeftNeighbor noch nicht gesetzt', 'RightNeighbor noch nicht gesetzt', WorkTime, Delay, Quota, 'Mi noch nicht gesetzt', LogFile)
    end. 

% ######################################################## Berechnung / Arbeitsphase ########################################################## %

workPhase(ClientName, Consense, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile) ->
  receive
    % Setzt die NAchbarn des ggt - Proezesses
    {setneighbors, Left, Right} ->
      tool:l(LogFile,ClientName,"Setze Rechten und Linken Nachbarn : Links- ~p , Rechts- ~p  ", [Left,Right]),
      workPhase(ClientName,Consense,Timer, Coordinator, NameService, Left, Right, WorkTime, Delay, ProcessCountNeeded,'Mi noch nicht gesetzt', LogFile);

    % Setzt das neue Mi 
    {setpm, NMi} ->
      tool:l(LogFile,ClientName,"Mi erhalten :  ~p ", [NMi]),
      timer:cancel(Timer),
      NewTimer = timer:send_after(round(WorkTime/2*1000), timeout),
      workPhase(ClientName,false,NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NMi, LogFile);

    % Übergibt ein neuen Wert und startet eine neue Berechnung
    {sendy, Y} ->
      tool:l(LogFile,ClientName,"Y erhalten :  ~p ", [Y]),
      timer:cancel(Timer),
      NewMi = calc(Mi, Y, LeftNeighbor, RightNeighbor, Coordinator, Delay, ClientName, NameService, LogFile),
      NewTimer = timer:send_after(round(WorkTime/2*1000), timeout),
      workPhase(ClientName,false,NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NewMi, LogFile);

    % Teilt dem Anfragenden das aktuelle Mi mit
    {From, tellmi} ->
      From ! {mi, Mi},
      tool:l(LogFile,ClientName,"Teile Koordinator Mi mit:  ~p ", [Mi]),
      workPhase(ClientName,Consense,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);

    % Beantwortet die Ping Anfrage
    {From, pingGGT} ->
      From ! {pongGGT, ClientName},
      tool:l(LogFile,ClientName,"Senden Pong an Koordinator "),
      workPhase(ClientName,Consense,Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);

    {TPID, {vote, Name}} ->
      tool:l(LogFile,ClientName,"Erhalte vote Aufforderung von: ~p ", [Name]),
      if
        Consense ->
          tool:l(LogFile,ClientName, "Stimme abbruch der Berechnung zu , ausgelöst durch ~p ", [Name]),

          TPID ! {voteYes, ClientName},
          workPhase(ClientName, true, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);  
        true ->
          workPhase(ClientName, true, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile)
      end;

    timeout -> 
      if 
         Consense == true-> 
          tool:l(LogFile,ClientName,"Starte Abstimmung mit Mi :  ~p ", [Mi]),
          NS = global:whereis_name(NameService),
          VoteHandler = spawn(fun() -> voteHandler(ClientName,self(),Coordinator,NameService,Mi,ProcessCountNeeded,LogFile) end),
          NS ! {VoteHandler, {multicast, vote, ClientName}},
          workPhase(ClientName, true, Timer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);
        true ->
          timer:cancel(Timer),
          NewTimer = timer:send_after(round(WorkTime/2*1000),timeout),
          workPhase(ClientName,true, NewTimer, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile)
      end;

    kill ->
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
    if
        (Y < Mi) ->
          tool:l(LogFile, ClientName,"Starte Berechnung mit Mi: ~p und Y: ~p", [Mi, Y]),
            timer:sleep(timer:seconds(Delay)),
            NewMi = ((Mi - 1) rem Y) + 1,
            tool:send(NeighborLeft,NameService,{sendy, NewMi}),
            tool:send(NeighborRight,NameService,{sendy, NewMi}),
            tool:send(Coordinator,NameService,{briefmi,{ClientName, NewMi, erlang:system_time()}}),
            NewMi;
        true ->
            Mi
    end.

% ########################################################## Abbruch ############################################################## %

voteHandler(ClientName,Parent,Coordinator,NameService,Mi,-1,LogFile) ->
  receive
    {voteYes, _Name} ->
      voteHandler(ClientName,Parent,Coordinator,NameService,Mi,-1,LogFile);
    timeout -> 
      ok
  end;

voteHandler(ClientName,Parent,Coordinator,NameService,Mi,0,LogFile) ->
  tool:l(LogFile,ClientName,"Briefe Koordinator , MI : ~p",[Mi]),
  tool:send(Coordinator, NameService, {Parent,briefterm, {ClientName, Mi, erlang:system_time()}}),
  voteHandler(ClientName,Parent,Coordinator,NameService,Mi,-1,LogFile);
  

voteHandler(ClientName,Parent,Coordinator,NameService,Mi,ProcessCountNeeded,LogFile) ->
  receive
    {voteYes, Name} ->
      tool:l(LogFile,ClientName,"Vote von: ~p erhalten",[Name]),
      tool:l(LogFile,ClientName,"Danach es fehlen noch : ~p ", [ProcessCountNeeded-1]),
      voteHandler(ClientName,Parent,Coordinator,NameService,Mi,ProcessCountNeeded-1,LogFile);
    timeout -> 
      tool:l(LogFile,ClientName,"Vote Timed Out")
  end.
  
