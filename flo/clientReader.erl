-module(clientReader).
-author(flo).

% API
-export([init/3]).

init(Server, LogFile, ConfigFile) ->
  getMessages(Server, LogFile),
  
  % Liest aus der Config - Datei die Parameter
  {ok, Config} = file:consult(ConfigFile),
  {ok, Lifetime} = werkzeug:get_config_value(lifetime, Config),
  {ok, ServerName} = werkzeug:get_config_value(servername, Config),
  {ok, ServerNode} = werkzeug:get_config_value(servernode, Config),
  {ok, ClientCount} = werkzeug:get_config_value(clients, Config),
  {ok, Interval} = werkzeug:get_config_value(sendeintervall, Config).

getMessages(Server, LogFile) ->
  Server ! {self(), getmessages},
  receiveReply(Server, LogFile).

receiveReply(Server, LogFile) ->

  receive
    {reply, Message, Termi} ->
      case Termi of
        true ->
          handleReply(Message, Server , LogFile);
        false ->
          handleReply(Message, Server ,LogFile),
          getMessages(Server, LogFile)
      end
  end.


handleReply(Message, Server, LogFile) ->
  [MsgNumber, Message, ClientOut, HBQin, DLQin, DLQout] = Message,

  werkzeug:logging(LogFile, node() ++ ": Nachrichtnummer: " ++  [MsgNumber] ++ " empfangen. Text: " ++ [Message] ++ " ClientOut: " ++ [ClientOut]),

  receiveReply(Server, LogFile).
