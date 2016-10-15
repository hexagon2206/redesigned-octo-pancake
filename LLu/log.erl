-module(log).
-export([w/3]).
-export([w/4]).

w(File,Who,Text) ->
	w(File,Who,Text,[]).
w(File,Who,Text,Data) ->
	werkzeug:logging(File,io_lib:format("~p - ~p: "++Text++"~n",[werkzeug:timeMilliSecond(),Who|Data])).
