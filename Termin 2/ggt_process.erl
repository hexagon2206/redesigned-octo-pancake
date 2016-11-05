
-module(ggt_process).
-author("flo").

-export([init/7]).

% ######################################### Initalisierung ################################################## %

% Initialisiert den ggt-prozess
init(Delay, WorkTime, ClientName, NameServiceNode, CoordinatorName, Quota, ProcessCount) ->

    % Den NameService anpingen, beim NameService registrieren und anschließend den Coordinator abfragen
    net_adm:ping(NameServiceNode),
    % Fürs Sync wichtig
    timer:sleep(500),
    NameService = global:whereis_name(nameservice),
    NameService ! {self(), {rebind, ClientName, self()}},
    NameService ! {self(), {lookup, CoordinatorName}},

    ProcessCountNeeded = round((ProcessCount / 100 * Quota)),
    LogFile = ClientName ++ ".log",
    tool:l(LogFile,ClientName,"ggt_process wird gestartet | Zeitstempel:  ~p ", [erlang:system_time()]),

   % spawn(fun() -> handleKillCommand() end),
   % spawn(fun() -> handlePing(ClientName) end),
   register(ClientName, self()),

    receive
       % ok ->
        {pin, {Coordinator, Node}} ->
          % Beim Koordinator melden und anschließend auf die Namen der Nachbarn warten
          {Coordinator, Node} ! {hello, ClientName},
          tool:l(LogFile,ClientName,"Beim Koordinator anmelden | Zeitstempel:  ~p ", [erlang:system_time()]),
          workPhase(ClientName, {Coordinator, Node}, NameService, 'LeftNeighbor noch nicht gesetzt', 'RightNeighbor noch nicht gesetzt', WorkTime, Delay, ProcessCountNeeded, 'Mi noch nicht gesetzt', LogFile)
    end.

% Verarbeitet die Antwort an den NameService von waitForNeighbors ab und fragt anschließend den zweiten / rechten Nachbarn ab und führt dann zur waitForMi - Methode
setRightNeighbor(LeftNeighbor, Right,  NameService, WorkTime, Coordinator, Delay, ClientName, NameService, ProcessCountNeeded, LogFile) ->
  NameService ! {lookup, Right, self()},
  receive
    {pin, PIDRight} ->
      tool:l(LogFile,ClientName,"Setze linken Nachbarn | Zeitstempel:  ~p ", [erlang:system_time()]),
      workPhase(ClientName, Coordinator, NameService, LeftNeighbor, PIDRight, WorkTime, Delay, ProcessCountNeeded,'Mi noch nicht gesetzt' ,LogFile)

  end.

% ######################################################## Berechnung / Arbeitsphase ########################################################## %

workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile) ->
  receive
    {setneighbors, Left, Right} ->
            NameService ! {lookup, Left, self()},
            receive
              {pin, PIDLeft} ->
                tool:l(LogFile,ClientName,"Setze rechten Nachbarn | Zeitstempel:  ~p ", [erlang:system_time()]),
                setRightNeighbor(PIDLeft, Right, NameService, WorkTime, Coordinator, Delay, ClientName, NameService, ProcessCountNeeded, LogFile)
            end;

    {setpm, Mi} ->
      tool:l(LogFile,ClientName,"Mi erhalten | Zeitstempel:  ~p ", [erlang:system_time()]),
       workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);
    {sendy, Y} ->
      tool:l(LogFile,ClientName,"Y erhalten | Zeitstempel:  ~p ", [erlang:system_time()]),
      NewMi = calc(Mi, Y, LeftNeighbor, RightNeighbor, Coordinator, Delay, ClientName, NameService, LogFile),
      workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NewMi, LogFile);

     {From, tellmi} ->
        From ! {mi, Mi},
        tool:l(LogFile,ClientName,"Teile Koordinator Mi mit| Zeitstempel:  ~p ", [erlang:system_time()]),
        workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);

      {From, pingGGT} ->
        From ! {pongGGT, ClientName},
        tool:l(LogFile,ClientName,"Senden Ping an Koordinator | Zeitstempel:  ~p ", [erlang:system_time()]),
        workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile);
      
   %   {From, {vote, Name}} ->
   %     if
   %       Terminator > 0 ->
   %         From ! {voteYes, ClientName}  ;  
   %       true ->
   %         workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi)
   %     end;
        
      kill ->
        %exit("Kill Command"),
        tool:l(LogFile,ClientName,"Beende ggt_process | Zeitstempel:  ~p ", [erlang:system_time()]),
        NameService ! {self(), {unbind, ClientName}},
        ok

  after (WorkTime / 2) ->
    workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi, LogFile)
  end.

% Startet eine neue Berechnung
calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Delay, ClientName, NameService, LogFile) ->
    timer:sleep(Delay),
    if
        (Y < Mi) ->
          tool:l(LogFile,ClientName,"Starte Berechnung mit Mi: ~p und Y: ~p | Zeitstempel:  ~p ", [Mi, Y, erlang:system_time()]),
            NewMi = ((Mi - 1) rem Y) + 1,
            NeighborLeft ! {sendy, NewMi},
            NeighborRight ! {sendy, NewMi},
            Coordinator ! {briefmi,{ClientName, NewMi, erlang:system_time()}},
            NewMi;
        true ->
            Mi
    end.

% ########################################################## Abbruch ############################################################## %

% Startet einen Abbruch der aktuellen Berechnung
initAbort(ClientName, LeftNeighbor, RightNeighbor, Coordinator, WorkTime, Delay, ClientName, NameService, Mi, ProcessCountNeeded) ->
  NameService ! {self(), {multicast, vote, ClientName}},
  spawn(fun() -> handleVotes(ClientName) end),
  spawn(fun() -> handleVoteYes([], ProcessCountNeeded, Coordinator, Mi, ClientName) end).

% Verarbeitet die Vote - Nachrichten
handleVotes(ClientName) ->
  receive
    {From, {vote, _}} ->
      From ! {voteYes, ClientName}
  end.

% Verarbeitet die voteYes - Nachrichten von den anderen ggt_Prozessen
handleVoteYes(VoteList, ProcessCountNeeded, Coordinator, NewMi, ClientName) ->
  Length = length(VoteList),

  if
      Length == ProcessCountNeeded ->
      Coordinator ! {briefmi, {ClientName, NewMi, erlang:system_time()}};
      %handleVoteYes([], ProcessCountNeeded, Coordinator, NewMi, ClientName);
    true ->
      receive
        {voteYes, Name} ->
          handleVoteYes(lists:append(VoteList, [{voteYes, Name}]), ProcessCountNeeded, Coordinator, NewMi, ClientName)
      end
  end.
