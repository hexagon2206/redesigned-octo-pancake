
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
   % spawn(fun() -> handleKillCommand() end),
   % spawn(fun() -> handlePing(ClientName) end),
   register(ClientName, self()),

    receive
       % ok ->
        {pin, {Coordinator, Node}} ->
          % Beim Koordinator melden und anschließend auf die Namen der Nachbarn warten
          {Coordinator, Node} ! {hello, ClientName},
          workPhase(ClientName, {Coordinator, Node}, NameService, 'LeftNeighbor noch nicht gesetzt', 'RightNeighbor noch nicht gesetzt', WorkTime, Delay, ProcessCountNeeded, 'Mi noch nicht gesetzt')
    end.

% Verarbeitet die Antwort an den NameService von waitForNeighbors ab und fragt anschließend den zweiten / rechten Nachbarn ab und führt dann zur waitForMi - Methode
setRightNeighbor(LeftNeighbor, Right,  NameService, WorkTime, Coordinator, Delay, ClientName, NameService, ProcessCountNeeded) ->
  NameService ! {lookup, Right, self()},
  receive
    {pin, PIDRight} ->
      workPhase(ClientName, Coordinator, NameService, LeftNeighbor, PIDRight, WorkTime, Delay, ProcessCountNeeded, 0)
      %waitForMi(LeftNeighbor, {RightNeighbor, Node}, Coordinator, WorkTime, Delay, ClientName, NameService, ProcessCountNeeded)
  end.

% ######################################################## Berechnung / Arbeitsphase ########################################################## %

workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi) ->
  receive
    {setneighbors, Left, Right} ->
            NameService ! {lookup, Left, self()},
            receive
              {pin, PIDLeft} ->
                setRightNeighbor(PIDLeft, Right, NameService, WorkTime, Coordinator, Delay, ClientName, NameService, ProcessCountNeeded)
            end;

    {setpm, Mi} ->
       %waitForY(Mi, LeftNeighbor, RightNeighbor, Coordinator, WorkTime, Delay, ClientName, NameService, ProcessCountNeeded);
       workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi);
    {sendy, Y} ->
     % calc(Mi, Y, LeftNeighbor, RightNeighbor, Coordinator, WorkTime, Delay, ClientName, NameService, ProcessCountNeeded);
      NewMi = calc(Mi, Y, LeftNeighbor, RightNeighbor, Coordinator, Delay, ClientName, NameService),
      workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, NewMi);

     {From, tellmi} ->
        From ! {mi, Mi},
        workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi);

      {From, pingGGT} ->
        From ! {pongGGT, ClientName},
        workPhase(ClientName, Coordinator, NameService, LeftNeighbor, RightNeighbor, WorkTime, Delay, ProcessCountNeeded, Mi);
      
      kill ->
        %exit("Kill Command"),
        ok

  after WorkTime ->
    initAbort(ClientName, LeftNeighbor, RightNeighbor, Coordinator, WorkTime, Delay, ClientName, NameService, Mi, ProcessCountNeeded)
  end.

% Startet eine neue Berechnung
calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Delay, ClientName, NameService) ->
    timer:sleep(Delay),
    if
        (Y < Mi) ->
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
