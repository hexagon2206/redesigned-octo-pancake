
-module(ggt_process).
-author("flo").

-export([init/7]).

% ####################################### Initalisierung und Berechnung ################################################# %

% Initialisiert den ggt-prozess
init(Delay, TerminationTime, ClientName, NameService, CoordinatorName, Quota, ProcessCount) ->

    % Den NameService anpingen, beim NameService registrieren und anschließend den Coordinator abfragen
    net_adm:ping(NameService),
    NameService = global:whereis_name(nameservice),
    NameService ! {self(), {rebind, ClientName, self()}},
    NameService ! {self(), {lookup, CoordinatorName}},

    ProcessCountNeeded = round((ProcessCount / 100 * Quota)),

    receive
        ok ->
          register(ClientName, self());

        {pin, {Coordinator, Node}} ->

          % Beim Koordinator melden und anschließend auf die Nachabarn warten
          {Coordinator, Node} ! {hello, ClientName},
          waitForNeighbors(TerminationTime, {Coordinator, Node}, Quota, Delay, NameService, ClientName)
    end.

% Wartet auf die Nachbarn vom Koordinator und fragt den linken Nachbarn beim NameService ab
waitForNeighbors(TerminationTime, Coordinator, Quota, Delay, NameService, ClientName) ->
    receive
        {setneighbors, Left, Right} ->
            NameService ! {lookup, Left, self()},
            receive
              {pin, {LeftNeighbor, Node}} ->
                setRightNeighbor({LeftNeighbor, Node}, Right, NameService, TerminationTime, Coordinator, Quota, Delay, ClientName)
            end
    end.

% Verarbeitet die Antwort an den NameService von waitForNeighbors ab und fragt anschließend den zweiten / rechten Nachbarn ab und führt dann zur waitForMi - Methode
setRightNeighbor(LeftNeighbor, Right,  NameService, TerminationTime, Coordinator, Quota, Delay, ClientName) ->
  NameService ! {lookup, Right, self()},
  receive
    {pin, {RightNeighbor, Node}} ->
      waitForMi(LeftNeighbor, {RightNeighbor, Node}, Coordinator, Quota, TerminationTime, Delay, ClientName)
  end.

% Wartet auf den Initaliserungswert
waitForMi(NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay, ClientName) ->
    receive
        {setpm, Mi} ->
            waitForY(Mi, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay, ClientName)
    end.

% Wartet auf das Y um eine Berechnung anzustoßen
waitForY(Mi, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay, ClientName) ->
    receive
        {sendy, Y} ->
            calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay, ClientName)
    end.

% Startet eine neue Berechnung
calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay, ClientName) ->
    timer:sleep(Delay),
    if
        (Y < Mi) ->
            NewMi = ((Mi-1) rem Y) + 1,
            NeighborLeft ! {sendy, NewMi},
            NeighborRight ! {sendy, NewMi},
            waitForY(NewMi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, ClientName);
        true ->
            waitForY(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, ClientName)
    end.

% ################################################ Abbruch ##################################################### %

% Startet einen Abbruch der aktuellen Berechnung
initAbort(ClientName, LeftNeighbor, RightNeighbor, Coordinator, Quota, TerminationTime, Delay, ClientName, NameService, Mi) ->
  NameService ! {self(), {multicast, vote, ClientName}},
  waitForY(Mi, LeftNeighbor, RightNeighbor, Coordinator, Quota, TerminationTime, Delay, ClientName).

% Verarbeitet die Vote - Nachrichten
handleVotes(Coordinator, VoteList, ProcessCountNeeded, ClientName) ->
  receive
    {From, {vote, Name}} ->
      if
        true ->
          From ! {voteYes, ClientName}
      end
  end.

% Verarbeitet die voteYes - Nachrichten von den anderen ggt_Prozessen
handleVoteYes(VoteList) ->
  Length = length(VoteList),

  if
     guard Length == ProcessCountNeeded ->
      Coordinator ! {briefmi, {ClientName, NewMi, erlang:system_time()}};
    true ->
      receive
        {voteYes, Name} ->
          handleVoteYes(lists:append(VoteList, [{voteYes, Name}]))
      end
  end.
