-module(ggt_process_2.0).


% ####################################### init phase ######################################### %
init(ClientName, NameserviceName, CoordinatorName, ProcessCount, Quota, Delay, WorkTime) ->

    % Mit dem Nameservice verbinden
    net_adm:ping(Nameservice),
    % Wichtig damit die Sync funktiniert
    timer:sleep(500),
    % Nameservice PID erfragen und anschließend registrieren
    Nameservice = global:whereis_name(NameserviceName),
    Nameservice ! {self(), {rebind, ClientName, self()}},
    Nameservice ! {self(), {lookup, CoordinatorName}},
    register(ClientName, self());

    ProcessCountNeeded = round(ProcessCount / 100 * Quota),

    receive
        {pin, {Coordinator, Node}} ->
            {Coordinator, Node} ! {hello, ClientName},
    end.
% Wartet auf die Nachbarn vom Koordinator, wenn er diese bekommt, werden die PID's der Nachbarn beim Nameservice abgefragt
waitForNeighbors(ClientName, Nameservice, Coordinator, ProcessCountNeeded, WorkTime, Delay) ->
    receive
        {setneighbors, Left, Right} ->
            Nameservice ! {lookup, Left, self()},
            Nameservice ! {lookup, Right, self()},
            receive
                {pin, {N, Node}} ->
                    LeftNeighbor = {N, Node},
                {pin, {N, Node}} ->
                    RightNeighbor = {N, Node},
            end

    end.

% ####################################### work phase ######################################### %

workPhase(ClientName, Nameservice, Coordinator, LeftNeighbor, RightNeighbor, ProcessCountNeeded, WorkTime, Delay) ->
    receive
        {setpm, NewMi} ->
            Mi = NewMi,

        {sendy, Y} ->
            calc(Mi, Y, LeftNeighbor, RightNeighbor, Delay),
        

        kill ->
            exit("Kill Command"),

        {From, tellmi} ->
            From ! {mi, Mi},

        {From, pngGGT} ->
            From ! {pongGGT, ClientName}
    after
        WorkTime ->
            Nameservice ! {self(), {multicast, vote, ClientName}},
            handleVotes([], ProcessCountNeeded, Coordinator, ClientName, Mi),
            vote(ClientName)
    end,

    workPhase{ClientName, Nameservice, Coordinator, LeftNeighbor, RightNeighbor, ProcessCountNeeded, WorkTime, Delay}.


% ######################################### Other ############################################### %

calc(Mi, Y, LeftNeighbor, RightNeighbor, Delay) ->
    timer:sleep(Delay),
    if
        (Y < Mi) ->
            NewMi = ((Mi - 1) rem Y) + 1,
            if
                NewMi < Mi ->
                    LeftNeighbor ! {sendy, NewMi},
                    RightNeighbor ! {sendy, NewMi}
                    self() ! {setpm, NewMi}    
            end            
    end.

handleVotes(VoteList, ProcessCountNeeded, Coordinator, ClientName, Mi) ->
    Length = length(VoteList),

    if
        Length == ProcessCountNeeded ->
            Coordinator ! {briefmi, {ClientName, Mi, erlang:system_time()}},
        true ->
            receive
                {voteYes, Name} ->
                    handleVotes(lists:append(VoteList, [{voteYes, Name}]), ProcessCountNeeded, Coordinator, ClientName, Mi)
            end
    end.

vote(ClientName) ->
    receive
        {From, {vote, __}} ->
            From ! {voteYes, ClientName}
    end.
