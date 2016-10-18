-module(tool).
-export([l/3]).
-export([l/4]).
-export([t/0]).

l(File,Who,Text) ->
	l(File,Who,Text,[]).
l(File,Who,Text,Data) ->
	werkzeug:logging(File,io_lib:format("~p - ~p: "++Text++"~n",[werkzeug:timeMilliSecond(),Who|Data])).

%used for getting a Time Stamp
t() -> erlang:now().