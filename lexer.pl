:- module(lexer, [tokenize/2]).
:- use_module(library(lists)).

% Main entry point
tokenize(Input, Tokens) :-
    (   string(Input) -> string_codes(Input, Codes) 
    ;   atom(Input)   -> atom_codes(Input, Codes)
    ;   is_list(Input) -> Codes = Input
    ;   string_codes(Input, Codes)
    ),
    phrase(tokens(Tokens), Codes).

% DCG Engine
tokens([T|Ts]) --> token(T), !, tokens(Ts).
tokens([]) --> [].

% --- Token Definitions ---

% 1. Layout & Comments
token(layout(L)) --> whitespace(Codes), { Codes \= [], atom_codes(L, Codes) }.
% In the token definitions
token(comment(C)) --> line_comment(C), !.
token(comment(C)) --> block_comment(C), !.

% 2. Multi-char Symbols
token(symbol(S)) --> symbol_multi(S), !.

% 3. Numbers
token(number(N)) --> [C], { code_type(C, digit) }, !, digits_rest(Rest), { number_codes(N, [C|Rest]) }.

% 4. Structural
token(bracket(B)) --> [C], { member(C, [40, 41, 91, 93, 123, 125, 124]), atom_codes(B, [C]) }. % ()[]{}|
token(symbol(',')) --> ",", !.
token(symbol(';')) --> ";", !.
token(symbol('.')) --> ".", !.

% 5. Variables
token(var(V)) --> [C], { is_var_start(C) }, !, at_codes(Rest), { atom_codes(V, [C|Rest]) }.

% 6. Atoms
token(atom(A)) --> [C], { code_type(C, lower) }, !, at_codes(Rest), { atom_codes(A, [C|Rest]) }.
token(atom(A)) --> "'", !, quoted_codes(Codes), "'", { atom_codes(A, Codes) }.

% 7. General Graphic Symbols
token(symbol(S)) --> [C], { is_graphic(C) }, !, symbol_sequence(Rest), { atom_codes(S, [C|Rest]) }.

% Only matches if nothing else did.
token(unknown(U)) --> [C], { atom_codes(U, [C]) }.

% --- Helper Predicates (Fixed Visibility) ---

is_var_start(C) :- code_type(C, upper) ; C == 95. % 95 is '_'

is_graphic(C) :- 
    member(C, [35, 36, 38, 42, 43, 45, 46, 47, 58, 60, 61, 62, 63, 64, 94, 126, 92]), % #$&*+-./:<=>?@^~\
    \+ member(C, [40, 41, 91, 93, 123, 125, 44, 59]). % ()[]{},;

% --- Helper DCGs ---

symbol_multi('=..')   --> "=..".
symbol_multi('=@=')   --> "=@=".
symbol_multi('\\=@=') --> "\\=@=".
symbol_multi('=:=')   --> "=:=".
symbol_multi('=\\=')  --> "=\\=".
symbol_multi('@=<')   --> "@=<".
symbol_multi('@>=')   --> "@>=".
symbol_multi('==')    --> "==".
symbol_multi('\\==')  --> "\\==".
symbol_multi(':-')    --> ":-".
symbol_multi('->')    --> "->".
symbol_multi('\\=')   --> "\\=".
symbol_multi('>=')    --> ">=".
symbol_multi('=<')    --> "=<".
symbol_multi('@<')    --> "@<".
symbol_multi('@>')    --> "@>".
symbol_multi('**')    --> "**".

whitespace([C|Cs]) --> [C], { code_type(C, space) }, !, whitespace(Cs).
whitespace([]) --> [].

digits_rest([C|Cs]) --> [C], { code_type(C, digit) }, !, digits_rest(Cs).
digits_rest([]) --> [].

at_codes([C|Cs]) --> [C], { code_type(C, alnum) ; C == 95 }, !, at_codes(Cs).
at_codes([]) --> [].

symbol_sequence([C|Cs]) --> [C], { is_graphic(C) }, !, symbol_sequence(Cs).
symbol_sequence([]) --> [].

quoted_codes(Codes) --> "''", !, { Codes = [39|Rest] }, quoted_codes(Rest).
quoted_codes([C|Cs]) --> [C], { C \= 39 }, !, quoted_codes(Cs).
quoted_codes([]) --> [].

% In the helper section (remove the 'comment()' wrapper here)
line_comment(A)  --> "%", rest_of_line(C), { atom_codes(A, [37|C]) }.
block_comment(A) --> "/*", rest_of_block(C), { atom_codes(A, [47, 42|C]) }.

rest_of_line([]) --> "\n", !.
rest_of_line([C|Cs]) --> [C], rest_of_line(Cs).
rest_of_line([]) --> [].

rest_of_block(Codes) --> "*/", !, { Codes = [42, 47] }.
rest_of_block([C|Cs]) --> [C], rest_of_block(Cs).

:- begin_tests(lexer).

% --- 1. Basic Terminology ---
test(atoms_and_vars) :-
    tokenize("cat Dog _variable", [atom(cat), layout(' '), var('Dog'), layout(' '), var('_variable')]).

% --- 2. Multi-character Operators (The Rigaux List) ---
test(comparison_ops) :-
    tokenize("X @< Y, A @>= B", Tokens),
    assertion(Tokens = [var('X'), layout(' '), symbol('@<'), layout(' '), var('Y'), symbol(','), layout(' '), var('A'), layout(' '), symbol('@>='), layout(' '), var('B')]).

test(arithmetic_equality) :-
    tokenize("1 =:= 1, 2 =\\= 3", Tokens),
    assertion(Tokens = [number(1), layout(' '), symbol('=:='), layout(' '), number(1), symbol(','), layout(' '), number(2), layout(' '), symbol('=\\='), layout(' '), number(3)]).

test(univ_operator) :-
    tokenize("Term =.. List", [var('Term'), layout(' '), symbol('=..'), layout(' '), var('List')]).

% --- 3. Quotes and Escaping ---
test(quoted_atoms) :-
    tokenize("'hello world' 'can''t'", [atom('hello world'), layout(' '), atom('can\'t')]).

% --- 4. Comments and Layout (Formatter Essentials) ---
test(comments_preservation) :-
    tokenize("X = 1. % set x", [var('X'), layout(' '), symbol('='), layout(' '), number(1), symbol('.'), layout(' '), comment('% set x')]).

test(block_comments) :-
    tokenize("/* start */ f(X).", [comment('/* start */'), layout(' '), atom(f), bracket('('), var('X'), bracket(')'), symbol('.')]).

% --- 5. Tricky Symbol Clusters ---
test(symbol_blobs) :-
    % Ensure period isn't swallowed by a greedy symbol blob
    tokenize("X=1.", [var('X'), symbol('='), number(1), symbol('.')]).

test(implied_operators) :-
    % :- and -> should be atomic symbols
    tokenize("a :- b -> c.", [atom(a), layout(' '), symbol(':-'), layout(' '), atom(b), layout(' '), symbol('->'), layout(' '), atom(c), symbol('.')]).

:- end_tests(lexer).
