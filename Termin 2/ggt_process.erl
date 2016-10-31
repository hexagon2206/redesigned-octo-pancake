
-module(ggt_process).
-author("flo").

-export([init/6]).

% Initialisiert den ggt-prozess
init(Delay, TerminationTime, ClientName, NameService, Coordinator, Quota) ->
    NameService ! {self(), {rebind, ClientName, self()}},

    receive
        ok -> 
            register(ClientName, self()),
            waitForNeighbors(TerminationTime, Coordinator, Quota, Delay)
    end.

% Wartet auf die Nachabrn vom Koordinator
waitForNeighbors(TerminationTime, Coordinator, Quota, Delay) ->
    receive
        {setneighbors, Left, Right} -> 
            waitForMi(Left, Right, Coordinator, Quota, TerminationTime, Delay)
    end.

% Wartet auf den Initaliserungswert
waitForMi(NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay) ->
    receive
        {setMi, Mi} -> 
            waitForY(Mi, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay)
    end.

% Wartet auf das Y um eine Berechnung anzustoßen
waitForY(Mi, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay) ->
    receive
        {sendy, Y} -> 
            calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay)
    end.

% Startet eine neue Berechnung
calc(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime, Delay) ->
    timer:sleep(Delay),
    if
        (Y < Mi) ->
            NewMi = ((Mi-1) rem Y) + 1,
            NeighborLeft ! {sendy, NewMi},
            NeighborRight ! {sendy, NewMi},
            waitForY(NewMi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime);
        true ->
            waitForY(Mi, Y, NeighborLeft, NeighborRight, Coordinator, Quota, TerminationTime)
    end.
    
