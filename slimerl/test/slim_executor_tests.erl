%% Copyright (C) 2008 Antoine Choppin
%% Description: Tests for Slim Executor
%% Licensed under the GNU General Public License

%% Note: according to EUnit convention, this module is named
%% <module_name>_tests

-module(slim_executor_tests).

%%
%% Include files
%%
-include_lib("eunit/include/eunit.hrl").
-import(slim_executor, [execute/1]).

%%
%% Test cases
%%

slim_executor_test_() -> [
  cantExecuteInvalidOperation(),
  cantExecuteMalformedInstruction(),
  cantExecuteInexistentInstance(),
  emptyListReturnsNicely(),
  createWithFullyQualifiedNameWorks(),
  cantCallInexistentMethod(),
  canExecuteOneFunctionCall(),
  canPassArgumentsToConstructor(),
  canExecuteMultiFunctionCall(),
  canCallAndAssign(),
  canReplaceMultipleVariablesInAnArgument(),
  canPassAndReturnList(),
  canPassAndReturnListWithVariable(),
  callToVoidFunctionReturnsVoidValue(),
  callToFunctionReturningNull(),
  cantExecuteInexistantConstructor(),
  catchException()
].

%%
%% Test functions
%%

cantExecuteInvalidOperation() ->
    ?_assert(
        exceptionThrown(execute([["inv1", "invalidOperation"]]),
        "inv1","message:<<INVALID_STATEMENT: invalidOperation.>>")).

cantExecuteMalformedInstruction() ->
    ?_assert(
        exceptionThrown(execute([["id", "call", "notEnoughArguments"]]),
        "id","message:<<MALFORMED_INSTRUCTION: [\"id\",\"call\",\"notEnoughArguments\"].>>")).

cantExecuteInexistentInstance() ->
    ?_assert(
        exceptionThrown(execute([["id", "call", "noSuchInstance", "noSuchInstance"]]),
        "id","message:<<NO_INSTANCE noSuchInstance.>>")).

emptyListReturnsNicely() ->
    ?_assertMatch([], execute([])).

createWithFullyQualifiedNameWorks() ->
    ?_assertMatch([["m1", "ok"]],
        execute([["m1", "make", "test_slim1", "test_slim"]])).

cantCallInexistentMethod() ->
    ?_assert(exceptionThrown(
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "call", "test_slim1", "noSuchMethod"]]),
        "id1","message:<<NO_METHOD_IN_CLASS noSuchMethod[1] test_slim.>>")).

canExecuteOneFunctionCall() ->
    ?_assertMatch([["m1", "ok"], ["id", "string"]],
        execute([["m1", "make", "test_slim1", "test_slim"],
                 ["id", "call", "test_slim1", "returnString"]])).

canPassArgumentsToConstructor() ->
    ?_assertMatch([["m2", "ok"], ["c1", "3"]],
        execute([["m2", "make", "test_slim1", "test_slim", "3"],
                 ["c1", "call", "test_slim1", "returnConstructorArg"]])).

canExecuteMultiFunctionCall() ->
    ?_assertMatch([["id", "ok"], ["id1", "3"], ["id2", "7"]],
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "call", "test_slim1", "addTo", "1", "2"],
                 ["id2", "call", "test_slim1", "addTo", "3", "4"]])).

canCallAndAssign() ->
    ?_assertMatch([["id", "ok"], ["id1","11"], ["id2","11"]],
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "callAndAssign", "v", "test_slim1", "addTo", "5", "6"],
                 ["id2", "call", "test_slim1", "echoInt", "$v"]])).

canReplaceMultipleVariablesInAnArgument() ->
    ?_assertMatch([["id", "ok"], ["id1", "Bob"], ["id2", "Martin"], ["id3", "name: Bob Martin"]],
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "callAndAssign", "v1", "test_slim1", "echoString", "Bob"],
                 ["id2", "callAndAssign", "v2", "test_slim1", "echoString", "Martin"],
                 ["id3", "call", "test_slim1", "echoString", "name: $v1 $v2"]])).

canPassAndReturnList() ->
    ?_assertMatch([["id", "ok"], ["id1",["one", "two"]]],
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "call", "test_slim1", "echoList", ["one", "two"]]])).

canPassAndReturnListWithVariable() ->
    ?_assertMatch([["id", "ok"], ["id1","7"], ["id2", ["7"]]],
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "callAndAssign", "v", "test_slim1", "addTo", "3", "4"],
                 ["id2", "call", "test_slim1", "echoList", ["$v"]]])).

callToVoidFunctionReturnsVoidValue() ->
    ?_assertMatch([["id", "ok"], ["id1","/__VOID__/"]],
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "call", "test_slim1", "voidFunction"]])).

callToFunctionReturningNull() ->
    ?_assertMatch([["id", "ok"], ["id1",null]],
        execute([["id", "make", "test_slim1", "test_slim"],
                 ["id1", "call", "test_slim1", "nullString"]])).

cantExecuteInexistantConstructor() ->
    ?_assert(
        exceptionThrown(execute([["id", "make", "test_slim1", "test_slim", "1", "2", "3"]]),
        "id","message:<<COULD_NOT_INVOKE_CONSTRUCTOR test_slim[3]>>")).

catchException() ->
	EXE = execute([["id", "make", "test_slim1", "test_slim"],
		       ["id1", "call", "test_slim1", "throwException"]]),
	io:format(user, ">> ~p~n", [EXE]),
	?_assert(exceptionThrown(EXE, "id1","message:<<hahaha [{test_slim,throwException,1")).

%%
%% Helper functions
%%

exceptionThrown(Results, Id, Message) ->
    FirstElemMatchesId = fun([X | _]) ->
        X == Id
    end,
    [[_ | [Result | _]] | _] = lists:filter(FirstElemMatchesId, Results),
    (0 /= string:str(Result, "__EXCEPTION__:")) and (0 /= string:str(Result, Message)).
