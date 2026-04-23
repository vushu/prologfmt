:- module(prologfmt, [format_string/2, format_prolog_file/1, run_formatter_tests/0, main/0]).

:- use_module(library(prolog_code)).
:- use_module(library(plunit)).

% =============================================================================
% CORE FORMATTING ENGINE
% =============================================================================

%% format_string(+RawCode:string, -Formatted:string) is det.
format_string(Raw, Formatted) :-
    setup_call_cleanup(
        open_string(Raw, In),
        with_output_to(string(Formatted), read_and_print(In)),
        close(In)
    ).

%% format_prolog_file(+File:atom) is det.
format_prolog_file(File) :-
    setup_call_cleanup(
        open(File, read, In),
        read_and_print(In),
        close(In)
    ).

%% read_and_print(+Stream:stream) is det.
read_and_print(In) :-
    read_and_print_grouped(In, none).

read_and_print_grouped(In, LastPred) :-
    % variable_names preserves X, Y, Z
    % consume_layout skips the '.' and whitespace to keep the stream moving
    read_term(In, Term, [
        variable_names(Vars), 
        comments(Comments), 
        consume_layout(true),
        module(user)
    ]),
    (   Term == end_of_file
    ->  print_comments(Comments)
    ;   extract_predicate_indicator(Term, CurrentPred),
        % If we changed predicates, add an extra newline for 'breathing room'
        (   (LastPred \= none, CurrentPred \= LastPred)
        ->  nl
        ;   true
        ),
        print_comments(Comments),
        portray_clause(current_output, Term, [variable_names(Vars)]),
        read_and_print_grouped(In, CurrentPred)
    ).

% =============================================================================
% UTILITIES
% =============================================================================

print_comments([]).
print_comments([_Pos-Comment|T]) :-
    format("~w~n", [Comment]),
    print_comments(T).

extract_predicate_indicator((Head :- _), Name/Arity) :- !, functor(Head, Name, Arity).
extract_predicate_indicator((Head --> _), Name/Arity) :- !, functor(Head, Name, Arity).
extract_predicate_indicator(Term, Name/Arity) :- functor(Term, Name, Arity).

% =============================================================================
% UNIT TESTS
% =============================================================================

:- begin_tests(prolog_formatter).

test(preserve_comments_and_space) :-
    Raw = "% Comment\na(1). b(1).",
    format_string(Raw, Formatted),
    assertion(sub_string(Formatted, _, _, _, "% Comment\na(1).\n\nb(1).")).

test(logic_preservation) :-
    Raw = "parent(X, Y) :- father(X, Y).",
    format_string(Raw, Formatted),
    term_string(T1, Raw),
    term_string(T2, Formatted),
    % Standard variant check: structurally identical
    assertion(T1 =@= T2).

test(multiple_clauses_no_clump) :-
    Raw = "f(1). f(2).",
    format_string(Raw, Formatted),
    % Clauses of the same predicate should only have one newline
    assertion(sub_string(Formatted, _, _, _, "f(1).\nf(2).")).

:- end_tests(prolog_formatter).

run_formatter_tests :-
    % Run tests and print a message only if they actually pass
    (   run_tests
    ->  format("~N% All tests passed!~n")
    ;   % If run_tests fails, it usually prints its own errors, 
        % but we ensure the process exits with an error code for the Makefile
        halt(1)
    ).

main :-
    current_prolog_flag(argv, Argv),
    (   Argv = [File]
    ->  (   exists_file(File)
        ->  format_prolog_file(File),
            halt(0)
        ;   format(user_error, "Error: File '~w' not found.~n", [File]),
            halt(1)
        )
    ;   % If no args, just show usage. 
        % We will run tests via the Makefile instead of the binary.
        format(user_error, "Usage: prologfmt <file>~n", []),
        halt(1)
    ).