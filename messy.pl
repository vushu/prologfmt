% A messy fact
   person(  joe,  30  ).

% A messy rule with deep nesting and bad spacing
can_drink(Person):-person(Person,Age),
    Age   >=   21.

                    % A messy DCG (Definite Clause Grammar)
sentence-->noun_phrase(  Num  ),verb_phrase(Num).
noun_phrase(s)  -->  [  the  ],  [  cat  ].
verb_phrase(s)-->[eats].
some random junk text

% Will wrap when exceeding 80 characters
expression :-  [module_decl(token(identifier("printing"), pos(0, 7)), block_expr([function_decl(header(export(false), token(identifier("print_value"), pos(1, 6)), [param_decl(token(identifier("x"), pos(1, 18)), token(int, pos(1, 21))), param_decl(token(identifier("y"), pos(1, 26)), token(int, pos(1, 29)))], return_type(token(unit, pos(1, 37)))), body(block_expr([expr_stmt(factor_expr(primary_expr(token(literal(int(2)), pos(2, 1))), token(*, pos(2, 3)), primary_expr(token(literal(int(4)), pos(2, 5)))))]))), module_decl(token(identifier("mama"), pos(4, 8)), block_expr([function_decl(header(export(false), token(identifier("mama"), pos(5, 6)), [param_decl(token(identifier("x"), pos(5, 11)), token(int, pos(5, 14)))], return_type(token(unit, pos(5, 22)))), body(block_expr([expr_stmt(primary_expr(token(literal(int(43)), pos(6, 1))))])))]))]))].

some more junk that isn't valid prolog