-module(reciver).
-export([start/0]).

%initialisiert den CMEM. RemTime gibt dabei die Zeit an, nach der die Clients vergessen werden Bei Erfolg wird ein leeres CMEM zurück geliefert. Datei kann für ein logging genutzt werden.
start() ->
	spawn( fun() -> loop() end ).

loop() -> 
	receive
		D -> io:format("~p~n",[D]),
			loop()
	end.
