%% Copyright (C) 2008 Antoine Choppin
%% Description: Class for Slim test
%% Licensed under the GNU General Public License

-module(test_slim).

%%
%% Record definition
%%

-record(test_slim, {constructor_arg=0}).

%%
%% Exported Functions
%%

-export([new/0,new/1,returnString/1,returnConstructorArg/1,addTo/3,echoString/2,echoInt/2,echoList/2,voidFunction/1,nullString/1,execute/1,throwException/1]).

%%
%% API Functions
%%

new() ->
    #test_slim{}.

new(ConstructorArg) ->
    #test_slim{constructor_arg=ConstructorArg}.

returnString(Record) ->
    {Record, "string"}.

returnConstructorArg(Record) ->
    #test_slim{constructor_arg=ConstructorArg} = Record,
    {Record, ConstructorArg}.

addTo(Record, A, B) ->
    {Record, A+B}.

echoString(Record, String) ->
    {Record, String}.

echoInt(Record, Integer) ->
    {Record, Integer}.

echoList(Record, List) ->
    {Record, List}.

voidFunction(Record) ->
    {Record}.

nullString(Record) ->
    {Record, null}.

execute(Record) ->
    {Record}.

throwException(_) ->
    throw(hahaha).

%%
%% Local Functions
%%

