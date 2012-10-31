%% Copyright (C) 2008 Antoine Choppin
%% Description: Slim server
%%
%% This is an implementation of Slim for Erlang.
%% Slim is a communication protocol for the Fitnesse acceptance test framework
%% (see http://fitnesse.org/ for details).

%%
%% Overview:
%%    slimserver.erl            - Slim server
%%    slim_serializer.erl       - Deserializes Slim requests and serializes results
%%    slim_executor.erl         - Execute Slim requests
%%    slim_serializer_tests.erl - Unit tests form slim_serializer.erl
%%    slim_executor_tests.erl   - Unit tests form slim_executor.erl
%%    test_slim.erl             - Module used by slim_executor_tests.erl
%%

%%
%% How to use:
%%
%% 1. Compile the code
%%      erlc slimserver.erl slim_serializer.erl slim_executor.erl
%%
%% 2. Compile the tests
%%      erlc slim_serializer_tests.erl slim_executor_tests.erl test_slim.erl
%%
%% 3. Run the tests
%%      erl
%%      1> eunit:test(slim_serializer).
%%        All 14 tests successful.
%%      ok
%%      2> eunit:test(slim_executor).
%%        All 17 tests successful.
%%      ok
%%
%% 4. Create a module to test and compile it.
%%    Note: you should follow the conventions illustrated by test_slim.erl
%%
%% 5. In your Fitnesse page, insert the following lines:
%%      !define TEST_SYSTEM {slim}
%%      !define COMMAND_PATTERN {erl -noshell -pa "path_to_slim" -run slimserver listen}
%%    where path_to_slim is the path where you extracted the above files.
%%
%% 6. Run your tests!
%%

%%
%%    This program is free software: you can redistribute it and/or modify
%%    it under the terms of the GNU General Public License as published by
%%    the Free Software Foundation, either version 3 of the License, or
%%    (at your option) any later version.
%%
%%    This program is distributed in the hope that it will be useful,
%%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%    GNU General Public License for more details.
%%
%%    You should have received a copy of the GNU General Public License
%%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%

-module(slimserver).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([listen/1]).

%% TCP options for our listening socket.  The initial list atom
%% specifies that we should receive data as lists of bytes (ie
%% strings) rather than binary objects and the rest are explained
%% better in the Erlang docs than I can do here.

-define(TCP_OPTIONS,[list, {packet, 0}, {active, false}, {reuseaddr, true}]).

%%
%% API Functions
%%

%% Listen on the given port, accept the first incoming connection and
%% launch the echo loop on it.
%% Note: This function accepts either string or int argument
listen(SPort) when is_list(SPort) ->
    [H|_] = SPort,
    io:format("String is ~p ~n", [H]),
    {Port, _} = string:to_integer(H),
    io:format("Port is ~p ~n", [Port]),
    listen(Port);
listen(Port) ->
    io:format("Listening...~n"),
    {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
    do_accept(LSocket).

%%
%% Local Functions
%%

do_accept(LSocket) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    io:format("Accepted ~p ~n", [Socket]),
    gen_tcp:send(Socket, "Slim -- V0.0\n"),
    do_process_set_of_instruction(Socket),
    exit(ok). % only accepts one connection and exits

%% Sit in a loop, echoing everything that comes in on the socket.
%% Exits cleanly on client disconnect.

do_process_set_of_instruction(Socket) ->
    case get_instructions(Socket) of
        error ->
            ok;
        Instructions ->
            case process_instructions(Instructions, Socket) of
                bye ->
                    ok;
                _ ->
                    do_process_set_of_instruction(Socket)
            end
    end.

get_instructions(Socket) ->
    case gen_tcp:recv(Socket, 6) of
        {ok, Data} ->
            {Length, _} = string:to_integer(Data),
            io:format("Length = ~p ~n", [Length]),
            case gen_tcp:recv(Socket, 1) of
                {ok, _} ->
                    case gen_tcp:recv(Socket, Length) of
                        {ok, Instructions} ->
                            io:format("Instructions = ~p ~n", [Instructions]),
                            Instructions;
                        {error, closed} -> error
                    end;
                {error, closed} -> error
            end;
        {error, closed} -> error
    end.

process_instructions(Instructions, Socket) ->
    case string:to_lower(Instructions) of
        "bye" ->
            bye;
        _ ->
            try
                Results = execute_instructions(Instructions),
                send_results_to_client(Results, Socket)
            catch
                _ ->
                    bye
            end
    end.

execute_instructions(Instructions) ->
    Statements = slim_serializer:deserialize(Instructions),
    slim_executor:execute(Statements).

send_results_to_client(Results, Socket) ->
    ResultString = slim_serializer:serialize(Results),
    gen_tcp:send(Socket, io_lib:format("~6..0B:~s", [string:len(ResultString), ResultString])).

