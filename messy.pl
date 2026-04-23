% A messy fact
   person(  joe,  30  ).

% A messy rule with deep nesting and bad spacing
can_drink(Person):-person(Person,Age),
    Age   >=   21.

                    % A messy DCG (Definite Clause Grammar)
sentence-->noun_phrase(  Num  ),verb_phrase(Num).
noun_phrase(s)  -->  [  the  ],  [  cat  ].
verb_phrase(s)-->[eats].