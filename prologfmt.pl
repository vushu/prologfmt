:- module(prologfmt,
          [ format_string/2,
            format_prolog_file/1,
            run_formatter_tests/0,
            main/0
          ]).
:- use_module(library(prolog_code)).
:- use_module(library(plunit)).

%% format_string(+RawCode:string, -Formatted:string) is det.
format_string(Raw, Formatted) :-
    setup_call_cleanup(open_string(Raw, In),
                       with_output_to(string(Formatted),
                                      read_and_print(In)),
                       close(In)).

%% format_prolog_file(+File:atom) is det.
format_prolog_file(File) :-
    setup_call_cleanup(open(File, read, In),
                       read_and_print(In),
                       close(In)).

%% read_and_print(+Stream:stream) is det.
read_and_print(In) :-
    read_and_print_grouped(In, none).

read_and_print_grouped(In, LastPred) :-
    stream_property(In, position(StartPos)), % Remember where we started
    catch(
        read_term(In, Term, [
            variable_names(Vars),
            comments(Comments),
            consume_layout(true),
            module(user)
        ]),
        Error,
        (handle_and_restore(In, StartPos, Error), Term = error_skipped)
    ),
    (   Term == end_of_file
    ->  print_comments(Comments)
    ;   Term == error_skipped
    ->  read_and_print_grouped(In, none) % Reset group on junk
    ;   process_valid_term(Term, Vars, Comments, LastPred, CurrentPred),
        read_and_print_grouped(In, CurrentPred)
    ).

%% If parsing fails, rewind and print the raw text
handle_and_restore(In, StartPos, _Error) :-
    set_stream_position(In, StartPos),
    % Skip leading whitespace/newlines so we don't 'double-tap' the Enter key
    peek_code(In, Code),
    (   char_type(Code, space)
    ->  get_code(In, _), handle_and_restore(In) % Recursive skip
    ;   read_line_to_string(In, Junk),
        (   Junk == end_of_file
        ->  true
        ;   format("~s~n", [Junk]) 
        )
    ).

% Simplified helper for the recursion
handle_and_restore(In) :-
    peek_code(In, Code),
    (   char_type(Code, space)
    ->  get_code(In, _), handle_and_restore(In)
    ;   read_line_to_string(In, Junk),
        ( Junk \== end_of_file -> format("~s~n", [Junk]) ; true )
    ).

is_test_predicate(test/_).

process_valid_term(Term, Vars, Comments, LastPred, CurrentPred) :-
    extract_predicate_indicator(Term, CurrentPred),
    (   LastPred \== none, CurrentPred \= LastPred
    ->  format("~n", []) % Only add one newline between different predicates
    ;   true
    ),
    print_comments(Comments),
    portray_clause(current_output, Term, [
        variable_names(Vars), 
        right_margin(80), 
        indent_arguments(4)
    ]).

%% Helper to report the error and skip the problematic part
handle_syntax_error(_, In) :-
    % message_to_string(Error, Message),
    % format(user_error, "% Syntax Error Encountered: ~w~n", [Message]),
    % Skip until the next period or newline to try and recover
    % This is a simple recovery strategy
    skip_to_next_term(In).

skip_to_next_term(In) :-
    get_code(In, Code),
    (   Code == -1 % EOF
    ->  true
    ;   Code == 46 % Period '.'
    ->  true
    ;   skip_to_next_term(In)
    ).

%% Move the logic for printing into its own predicate for cleanliness
process_term(Term, Vars, Comments, LastPred, CurrentPred) :-
    extract_predicate_indicator(Term, CurrentPred),
    (   LastPred \== none, CurrentPred \= LastPred
    ->  nl
    ;   true
    ),
    print_comments(Comments),
    portray_clause(current_output, Term, [
        variable_names(Vars), 
        right_margin(80), 
        indent_arguments(4)
    ]).

% UTILITIES
% =============================================================================
print_comments([]).
print_comments([_Pos-Comment|T]) :-
    format("~w~n", [Comment]),
    print_comments(T).

extract_predicate_indicator((Head:-_), Name/Arity) :-
    !,
    functor(Head, Name, Arity).
extract_predicate_indicator((Head-->_), Name/Arity) :-
    !,
    functor(Head, Name, Arity).
extract_predicate_indicator(Term, Name/Arity) :-
    functor(Term, Name, Arity).

% UNIT TESTS
% =============================================================================
:- begin_tests(prolog_formatter).

test(preserve_comments_and_space) :-
    Raw="% Comment\na(1). b(1).",
    format_string(Raw, Formatted),
    assertion(sub_string(Formatted,
                         _,
                         _,
                         _,
                         "% Comment\na(1).\n\nb(1).")).

% Standard variant check: structurally identical
test(logic_preservation) :-
    Raw="parent(X, Y) :- father(X, Y).",
    format_string(Raw, Formatted),
    term_string(T1, Raw),
    term_string(T2, Formatted),
    assertion(T1=@=T2).

% Clauses of the same predicate should only have one newline
test(multiple_clauses_no_clump) :-
    Raw="f(1). f(2).",
    format_string(Raw, Formatted),
    assertion(sub_string(Formatted, _, _, _, "f(1).\nf(2).")).

:- end_tests(prolog_formatter).

run_formatter_tests :-
    (   run_tests
    ->  format("~N% All tests passed!~n")
    ;   halt(1)
    ).

print_help :-
    format("prologfmt - A simple Prolog formatter~n~n"),
    format("Usage:~n"),
    format("  prologfmt FILE                 Format file and print to stdout~n"),
    format("  prologfmt -i FILE              Format file in-place~n"),
    format("  prologfmt --in-place FILE      Same as -i~n"),
    format("  prologfmt --stdin              Read from stdin, write to stdout~n"),
    format("  prologfmt < FILE               Implicit stdin mode (pipe input)~n"),
    format("  prologfmt -h, --help           Show this help message~n"),
    format("  prologfmt -t, --test           Run internal test suite~n"),
    format("~n"),
    format("Examples:~n"),
    format("  prologfmt messy.pl~n"),
    format("  prologfmt -i messy.pl~n"),
    format("  cat messy.pl | prologfmt~n").

% Help
% Tests (explicit only)
% In-place formatting
% File → stdout
% Explicit stdin
% Implicit stdin (pipe)
% Default: show help
main :-
    current_prolog_flag(argv, Argv),
    (   member(Arg, Argv),
        member(Arg, ['-h', '--help'])
    ->  print_help,
        halt(0)
    ;   member(Arg, Argv),
        member(Arg, ['-t', '--test'])
    ->  run_formatter_tests,
        halt(0)
    ;   Argv=[Flag, File],
        member(Flag, ['-i', '--in-place'])
    ->  format_string_to_file(File),
        halt(0)
    ;   Argv=[File],
        \+ sub_string(File, 0, 1, _, "-")
    ->  format_prolog_file(File),
        halt(0)
    ;   Argv=['--stdin']
    ->  read_string(user_input, _, Raw),
        format_string(Raw, Formatted),
        format("~s", [Formatted]),
        halt(0)
    ;   Argv=[],
        \+ stream_property(user_input, tty(true))
    ->  read_string(user_input, _, Raw),
        format_string(Raw, Formatted),
        format("~s", [Formatted]),
        halt(0)
    ;   print_help,
        halt(0)
    ).

% Ensure it writes the string correctly
format_string_to_file(File) :-
    (   exists_file(File)
    ->  read_file_to_string(File, Raw, []),
        format_string(Raw, Formatted),
        setup_call_cleanup(open(File, write, Out),
                           format(Out, "~s", [Formatted]),
                           close(Out))
    ;   format(user_error, "Error: File '~w' not found.~n", [File]),
        halt(1)
    ).
