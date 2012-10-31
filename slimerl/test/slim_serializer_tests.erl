%% Copyright (C) 2008 Antoine Choppin
%% Description: Tests for Slim Serializer
%% Licensed under the GNU General Public License

%% Note: according to EUnit convention, this module is named
%% <module_name>_tests

-module(slim_serializer_tests).

%%
%% Include files
%%
-include_lib("eunit/include/eunit.hrl").
-import(slim_serializer, [serialize/1, deserialize/1]).

%%
%% Test cases
%%

slim_serializer_test_() -> [
  canSerializeNullList(),
  canSerializeOneItemList(),
  canSerializeTwoItemsList(),
  canSerializeNestedList(),
  canSerializeListWithNonString(),
  canSerializeNullElement(),
  cantDeserializeNonString(),
  cantDeserializeEmptyString(),
  cantDeserializeStringThatDoesntStartWithBracket(),
  cantDeserializeStringThatDoesntEndWithBracket(),
  canDeserializeEmptyList(),
  canDeserializeListWithOneElement(),
  canDeserializeListWithTwoElements(),
  canDeserializeListWithSubList()
].

%%
%% Test functions
%%

canSerializeNullList() ->
    ?_assertMatch("[000000:]", serialize([])).

canSerializeOneItemList() ->
    ?_assertMatch("[000001:000005:hello:]", serialize(["hello"])).

canSerializeTwoItemsList() ->
    ?_assertMatch("[000002:000005:hello:000005:world:]", serialize(["hello", "world"])).

canSerializeNestedList() ->
    ?_assertMatch("[000001:000024:[000001:000007:element:]:]", serialize([["element"]])).

canSerializeListWithNonString() ->
    fun() ->
        [First | _] = deserialize(serialize([1])),
        ?assertMatch("1", First)
    end.

canSerializeNullElement() ->
    ?_assertMatch("[000001:000004:null:]",serialize([null])).

cantDeserializeNonString() ->
    ?_assertException(throw, not_a_string, deserialize(abc)).

cantDeserializeEmptyString() ->
    ?_assertException(throw, empty_string, deserialize("")).

cantDeserializeStringThatDoesntStartWithBracket() ->
    ?_assertException(throw, no_open_bracket, deserialize("hello")).

cantDeserializeStringThatDoesntEndWithBracket() ->
    ?_assertException(throw, no_closed_bracket, deserialize("[000000:")).

canDeserializeEmptyList() ->
    check([]).

canDeserializeListWithOneElement() ->
    check(["hello"]).

canDeserializeListWithTwoElements() ->
    check(["hello", "world"]).

canDeserializeListWithSubList() ->
    check([["hello", "world"], "single"]).

%%
%% Helper functions
%%

check(List) ->
    ?_assertEqual(List, deserialize(serialize(List))).

