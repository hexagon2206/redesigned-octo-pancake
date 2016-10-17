-module(client).


% API



% Funtions

init(ConfigFile) ->

  % Liest aus der Config - Datei die Parameter
  {ok, Config} = file:consult(ConfigFile),
  {ok, Lifetime} = werkzeug:get_config_value(lifetime, Config),
  {ok, ServerName} = werkzeug:get_config_value(servername, Config),
  {ok, ServerNode} = werkzeug:get_config_value(servernode, Config),
  {ok, ClientCount} = werkzeug:get_config_value(clients, Config),
  {ok, Interval} = werkzeug:get_config_value(sendeintervall, Config),

  Server = {ServerName, ServerNode},
  LogFile = atom_to_list(node()) ++ ".log",
  getMessageID(Server, 1, Interval * 1000, LogFile).



% ############################################### ClientWriter - Logic ################################################################ %
getMessageID(Server, MessageCounter, SleepTime, LogFile) ->

  Server ! {self(), getmsgid},

  case MessageCounter == 5 of
    % Neue Zufallszahl generieren und die Antwort des Servers ausfiltern
    true ->
      receive
        {nid, ID} -> io:format("~p ~n", [ID])
      end,
    %  getMessageID(Server, 0, (random:uniform(5) * 2000), LogFile);

    werkzeug:logging(LogFile, io:format("Nachrichtnummer: ~p nicht | Zeitstempel:  ~p ~n", [MessageCounter, werkzeug:timeMilliSecond()])),

    % Reader starten
    getMessages(Server, LogFile, MessageCounter, SleepTime);

    % Antwort vom Server verarbeiten und Nachricht an Server vorbereiten
    false ->
      receive
        {nid, ID} -> dropMessage(Server, ID, MessageCounter + 1, SleepTime, LogFile)
      end
  end.

% Eine Zufallszeit "schlafen" und anschlieߟend eine neue Nachricht an den Server schicken
dropMessage(Server, MessageID, MessageCounter, SleepTime, LogFile) ->

  timer:sleep(SleepTime),

  werkzeug:logging(LogFile, io:format("Nachrichtnummer: ~p gesendet | Zeitstempel:  ~p ~n", [MessageCounter, werkzeug:timeMilliSecond()])),

  Server ! {dropmessage, [MessageID, "Hallo Welt", werkzeug:timeMilliSecond()]}, % alternative : erlang:system_time(). -> aktuelle Zeit in Milisekunden
  getMessageID(Server, MessageCounter, SleepTime, LogFile).



% ############################################### ClientReader - Logic ################################################################ %

getMessages(Server, LogFile, MessageCounter, SleepTime) ->
  Server ! {self(), getmessages},
  receiveReply(Server, LogFile, MessageCounter, SleepTime).

receiveReply(Server, LogFile, MessageCounter, SleepTime) ->

  receive
    {reply, Message, Termi} ->
      case Termi of
        true ->
          getMessages(Server, LogFile, MessageCounter, SleepTime);
        false ->
          handleReply(Message, Server ,LogFile, MessageCounter, SleepTime),
          getMessages(Server, LogFile, MessageCounter, SleepTime)
      end
  end.


handleReply(Message, Server, LogFile, MessageCounter, SleepTime) ->
  [MsgNumber, Message, ClientOut, HBQin, DLQin, DLQout] = Message,
  %werkzeug:logging(LogFile, node() ++ ": Nachrichtnummer: " ++  [MsgNumber] ++ " empfangen. Text: " ++ [Message] ++ " ClientOut: " ++ [ClientOut]),

  werkzeug:logging(LogFile, io:format("Nachrichtnummer: ~p empfangen | Zeitstempel:  ~p ~n", [MessageCounter, werkzeug:timeMilliSecond()])),

  receiveReply(Server, LogFile, MessageCounter, SleepTime).
