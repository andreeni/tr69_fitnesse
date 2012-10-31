%% Copyright (C) 2008 Antoine Choppin
%% Description: Serialize and deserialize strings following the Slim protocol.
%% Licensed under the GNU General Public License

-module(slim_serializer).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([serialize/1,deserialize/1]).

%%
%% API Functions
%%

deserialize(Serialized) ->
    check_serialization_valid(Serialized),
    deserialize_string(Serialized).

serialize(Results) ->
    io:format("Results = ~p ~n", [Results]),
    S = serialize_list(Results),
    io:format("String = ~p ~n", [S]),
    S.


%%
%% Local Functions
%%

check_serialization_valid(Serialized) ->
    if
        is_list(Serialized) == false ->
            throw(not_a_string);
        Serialized == [] ->
            throw(empty_string);
        true ->
            ok
    end.

deserialize_string(S1) ->
    S2 = check_for_open_bracket(S1),
    {S3, Result} = deserialize_list(S2),
    check_for_closed_bracket(S3),
    Result.

check_for_open_bracket([H | T]) ->
    if
        [H | ""] /= "[" ->
            throw(no_open_bracket);
        true ->
            ok
    end,
    T;
check_for_open_bracket([]) ->
    throw(no_open_bracket).

check_for_closed_bracket([H | T]) ->
    if
        [H | ""] /= "]" ->
            throw(no_closed_bracket);
        true ->
            ok
    end,
    T;
check_for_closed_bracket([]) ->
    throw(no_closed_bracket).

deserialize_list(S1) ->
    {S2, Length} = get_length(S1),
    do_deserialize_item(S2, Length, []).

do_deserialize_item(S1, 0, Result) ->
    {S1, Result};
do_deserialize_item(S1, Length, Result) ->
    {S2, Item} = deserialize_item(S1),
    do_deserialize_item(S2, Length-1, lists:reverse([Item | lists:reverse(Result)])).

deserialize_item(S1) ->
    {S2, Length} = get_length(S1),
    {S3, Item} = get_string(S2, Length),
    try deserialize(Item) of
        Result ->
            {S3, Result}
    catch
        _ ->
            {S3, Item}
    end.

get_length(S1) ->
    LengthString = string:substr(S1, 1, 6),
    {Length, _} = string:to_integer(LengthString),
    S2 = check_for_colon(string:substr(S1, 7)),
    {S2, Length}.

get_string(S1, Length) ->
    SubString = string:substr(S1, 1, Length),
    S2 = check_for_colon(string:substr(S1, Length+1)),
    {S2, SubString}.

check_for_colon([H | T]) ->
    if
        [H | ""] /= ":" ->
            throw(no_colon);
        true ->
            ok
    end,
    T.
    
serialize_list(List) ->
    do_serialize_list(List, lists:flatten(io_lib:format("[~6..0B:", [length(List)]))).

do_serialize_list([Item | List], Serialized) ->
    SerializedItem = serialize_item(Item),
    do_serialize_list(List, lists:flatten(io_lib:format("~s~6..0B:~s:", [Serialized, string:len(SerializedItem), SerializedItem])));
do_serialize_list([], Serialized) ->
    Serialized ++ "]".

serialize_item(Item) ->
    IsString = is_string(Item),
    if
        is_integer(Item) ->
            lists:flatten(io_lib:format("~B", [Item]));
        is_float(Item) ->
            lists:flatten(io_lib:format("~g", [Item]));
        IsString -> % this must be tested before is_list
            Item;
        is_list(Item) ->
            serialize_list(Item);
        Item == null ->
            "null";
        true -> % everything else is ignored (including atoms)
            "/__VOID__/"
    end.

is_string(S) ->
    IsPrintable = fun(X) ->
        if X < 0 -> false;
           X > 255 -> false;
           true -> true
        end
    end,
    case is_list(S) of
        false -> false;
        true -> lists:all(IsPrintable, S)
    end.

