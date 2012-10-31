%% Copyright (C) 2008 Antoine Choppin
%% Description: Execute Slim requests
%% Licensed under the GNU General Public License

-module(slim_executor).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([execute/1]).


-record(executor, {dict=dict:new()}).

%%
%% API Functions
%%

execute(Statements) ->
    io:format("Execute ~p ~n", [Statements]),
    do_execute_statements(Statements, #executor{}, []).

%%
%% Local Functions
%%

do_execute_statements([Statement | Statements], Executor, Results) ->
    case lists:nth(2, Statement) of
        "import" ->
            {Executor2, Result} = add_path(Executor, Statement);
        "make" ->
            {Executor2, Result} = create_instance(Executor, Statement);
        "call" ->
            {Executor2, Result} = call(Executor, Statement);
        "callAndAssign" ->
            {Executor2, Result} = call_and_assign(Executor, Statement);
        _ ->
            {Executor2, Result} = {Executor, invalid_statement}
    end,
    case Result of
        malformed_instruction ->
            Result2 = [lists:nth(1, Statement), lists:flatten(io_lib:format(
                "__EXCEPTION__:message:<<MALFORMED_INSTRUCTION: ~1024p.>>", [Statement]))];
        invalid_statement ->
            Result2 = [lists:nth(1, Statement), 
                "__EXCEPTION__:message:<<INVALID_STATEMENT: invalidOperation.>>"];
        _ ->
            Result2 = Result
    end,
    do_execute_statements(Statements, Executor2, [Result2 | Results]);
do_execute_statements([], _, Results) ->
    lists:reverse(Results).

create_instance(Caller, [Id, _, InstanceName, ClassName | Args]) ->
    #executor{dict=Dict} = Caller,
    FirstLetter = string:substr(ClassName, 1,1),
    StartsWithUppercase = (FirstLetter /= string:to_lower(FirstLetter)),
    if
        StartsWithUppercase ->
            {Caller, [Id, "__EXCEPTION__:message:<<Erlang class name should start with a lowercase!>>"]};
        true ->
            Class = list_to_atom(ClassName),
            DoesConstructorExist = lists:member({new,length(Args)},Class:module_info(exports)),
            if
                DoesConstructorExist ->
                    Instance = apply(Class, new, do_convert_args(Caller, Args)),
                    Caller2 = Caller#executor{dict=dict:store(InstanceName, Instance, Dict)},
                    {Caller2, [Id, "ok"]};
                true ->
                    {Caller, [Id, lists:flatten(io_lib:format(
                        "__EXCEPTION__:message:<<COULD_NOT_INVOKE_CONSTRUCTOR ~s[~B]>>",
                        [Class, length(Args)]))]}
            end
    end;
create_instance(Caller, _) ->
    {Caller, malformed_instruction}.

add_path(Caller, [Id, _, Path]) ->
    code:add_pathz(Path),
    {Caller, [Id, "ok"]};
add_path(Caller, _) ->
    {Caller, malformed_instruction}.

call(Caller, [Id, _, InstanceName, MethodName | Args]) ->
    #executor{dict=Dict} = Caller,
    case dict:find(InstanceName, Dict) of
        {ok, Instance} ->
            Class = element(1, Instance),
            Method = list_to_atom(MethodName),
            DoesMethodExist = lists:member({Method,length(Args)+1},Class:module_info(exports)),
            if
                DoesMethodExist ->
                    case
                        try apply(Class, Method, [Instance | do_convert_args(Caller, Args)])
                        catch
                            _:Exception ->
                                {Instance, lists:flatten(io_lib:format(
                                    "__EXCEPTION__:message:<<~s ~1024p>>", [Exception, erlang:get_stacktrace()]))}
                        end
                    of
                        {Instance2, Result} ->
                            ok;
                        {Instance2} -> % the method can return no value -> void
                            Result = "/__VOID__/"
                    end,
                    Caller2 = Caller#executor{dict=dict:store(InstanceName, Instance2, Dict)};
                true ->
                    Result = lists:flatten(io_lib:format(
                        "__EXCEPTION__:message:<<NO_METHOD_IN_CLASS ~s[~B] ~s.>>",
                         [MethodName, length(Args)+1, Class])),
                    Caller2 = Caller
            end;
        error ->
            Result = lists:flatten(io_lib:format(
                "__EXCEPTION__:message:<<NO_INSTANCE ~s.>>", [InstanceName])),
            Caller2 = Caller
    end,
    {Caller2, [Id, convert_to_string(Result)]};
call(Caller, _) ->
    {Caller, malformed_instruction}.

call_and_assign(Caller, [Id, Operation, VariableName, InstanceName, MethodName | Args]) ->
    {Caller2, [Id, Result]} = call(Caller, [Id, Operation, InstanceName, MethodName | Args]),
    #executor{dict=Dict} = Caller2,
    {Caller2#executor{dict=dict:store(VariableName, Result, Dict)}, [Id, Result]};
call_and_assign(Caller, _) ->
    {Caller, malformed_instruction}.

do_convert_args(Caller, Args) ->
    do_convert_args(Caller, Args, []).

do_convert_args(Caller, [Arg | Args], ConvertedArgs) ->
    do_convert_args(Caller, Args, [convert_arg(Caller, Arg) | ConvertedArgs]);
do_convert_args(_, [], ConvertedArgs) ->
    lists:reverse(ConvertedArgs).

convert_arg(Caller, StringArg) ->
    %% Replace variables
    StringArg2 = do_replace_variables(Caller, StringArg),
    %% Conversion to basic types (now: integer only)
    case io_lib:fread("~d", StringArg2) of
        {ok, IntString, _} ->
            IntStringHead = hd(IntString),
            if
                is_integer(IntStringHead) ->
                    IntStringHead;
                true ->
                    StringArg2
            end;
        {error, _} ->
            StringArg2
    end.

do_replace_variables(Caller, [StringArg]) when is_list(StringArg) ->
    [do_replace_variables(Caller, StringArg)];
do_replace_variables(Caller, StringArg) ->
    case string:str(StringArg, "$") of
        0 ->
            StringArg;
        StartPos ->
            Length = string:span(string:substr(StringArg, StartPos+1), 
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"),
            VariableName = string:substr(StringArg, StartPos+1, Length),
            #executor{dict=Dict} = Caller,
            case dict:find(VariableName, Dict) of
                {ok, VariableValue} ->
                    VariableValue;
                error ->
                    VariableValue = "?"
            end,
            StringArg2 = string:substr(StringArg, 1, StartPos-1)
                ++ VariableValue ++ string:substr(StringArg, StartPos+1+Length),
            do_replace_variables(Caller, StringArg2)
    end.

convert_to_string(Stuff) when is_list(Stuff) or is_atom(Stuff) ->
    Stuff;
convert_to_string(Integer) when is_integer(Integer) ->
    lists:flatten(io_lib:format("~B", [Integer]));
convert_to_string(Float) when is_float(Float) ->
    lists:flatten(io_lib:format("~g", [Float])).

