-module(clientReader).
-author(flo).

% API
-export([init/2]).

init(Server, LogFile) ->
  getMessages(Server, LogFile)

getMessages(Server, LogFile) ->
  Server ! {self(), getmessages},
  receiveReply(Server).

receiveReply(Server, LogFile) ->

  receive
    {reply, Message, Termi} ->
      case Termi of
        true ->
          handleReply(Message, LogFile);
        false ->
          handleReply(Message, LogFile),
          getMessages(Server, LogFile)
      end
  end.


handleReply(Message, LogFile) ->
  [MsgNumber, Message, ClientOut, HBQin, DLQin, DLQout] = Message.
