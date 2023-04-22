#|
    Implementation of a token reader
    using a DFA

    Joaquin Badillo
    21/Apr/2023
|#

#lang racket

(provide arithmetic-lexer)

; Define a stucture that describes a DFA
(struct dfa (transition initial accept))

; String lexer: takes a string of characters and returns the tokens and values on the string
(define (arithmetic-lexer strng)
  (validate-dfa strng (dfa delta-arithmetic 'start '(int float exp var spa par_open par_close comment))))

; Function to evaluate a string using a DFA
; Receives the string to test and a structure for a DFA
(define (validate-dfa input dfa-def)
  (let loop
    ([char-list (string->list input)]
     [state (dfa-initial dfa-def)]
     [str '()]
     [tokens '()])
    (cond
      [(eq? state 'inv) #f]
      [(empty? char-list)
       (if (member state (dfa-accept dfa-def))
         (reverse (cons (list (list->string (reverse str)) state) tokens))
         #f)]
      [(eq? state 'comment)
        (reverse (cons (list (list->string (append str char-list)) state) tokens))]
      [else
        (let-values
          ([(new-state found) ((dfa-transition dfa-def) state (car char-list))])
          (loop
            (cdr char-list)
            new-state
            (cond 
                [(char-whitespace? (car char-list)) '()]
                [found (list (car char-list))]
                [else (cons (car char-list) str)])
            (if found 
                (cons (list (list->string (reverse str)) (if (eq? state 'op_slash) 'op state)) tokens) 
                tokens)))])))

; Checks if the character is a valid operator (excluding the slash "/" operator)
(define (char-operator? char)
  (member char (string->list "=+-*^")))


; Transition function created from the DFA's graph representation
(define (delta-arithmetic state char)
  (cond
    [(eq? state 'start) (cond
        [(char-numeric? char) (values 'int #f)]
        [(or (eq? char #\+) (eq? char #\-)) (values 'sign #f)]
        [(char-alphabetic? char) (values 'var #f)]
        [(eq? char #\_) (values 'var #f)]
        [(eq? char #\() (values 'par_open #f)]
        [(eq? char #\/) (values 'inv_slash #f)]
        [else (values 'inv #f)])]
    [(eq? state 'sign) (cond
        [(char-numeric? char) (values 'int #f)]
        [else (values 'inv #f)])]
    [(eq? state 'int) (cond
        [(char-numeric? char) (values 'int #f)]
        [(eq? char #\.) (values 'dot #f)]
        [(or (eq? char #\e) (eq? char #\E)) (values 'e #f)]
        [(char-operator? char) (values 'op 'int)]
        [(char-whitespace? char) (values 'spa 'int)]
        [(eq? char #\/) (values 'op_slash 'int)]
        [(eq? char #\)) (values 'par_close 'int)]
        [else (values 'inv #f)])]
    [(eq? state 'dot) (cond
        [(char-numeric? char) (values 'float #f)]
        [else (values 'inv #f)])]
    [(eq? state 'float) (cond
        [(char-numeric? char) (values 'float #f)]
        [(or (eq? char #\e) (eq? char #\E)) (values 'e #f)]
        [(char-operator? char) (values 'op 'float)]
        [(char-whitespace? char) (values 'spa 'float)]
        [(eq? char #\/) (values 'op_slash 'float)]
        [(eq? char #\)) (values 'par_close 'float)]
        [else (values 'inv #f)])]
    [(eq? state 'e) (cond
        [(char-numeric? char) (values 'exp #f)]
        [(or (eq? char #\+) (eq? char #\-)) (values 'e_sign #f)]
        [else (values 'inv #f)])]
    [(eq? state 'e_sign) (cond
        [(char-numeric? char) (values 'exp #f)]
        [else (values 'inv #f)])]
    [(eq? state 'exp) (cond
        [(char-numeric? char) (values 'exp #f)]
        [(char-operator? char) (values 'op 'exp)]
        [(char-whitespace? char) (values 'spa 'exp)]
        [(eq? char #\/) (values 'op_slash 'exp)]
        [(eq? char #\)) (values 'par_close 'exp)]
        [else (values 'inv #f)])]
    [(eq? state 'var) (cond
        [(char-numeric? char) (values 'var #f)]
        [(char-alphabetic? char) (values 'var #f)]
        [(eq? char #\_) (values 'var #f)]
        [(char-operator? char) (values 'op 'var)]
        [(char-whitespace? char) (values 'spa 'var)]
        [(eq? char #\/) (values 'op_slash 'var)]
        [(eq? char #\() (values 'par_open 'var)]
        [(eq? char #\)) (values 'par_close 'var)]
        [else (values 'inv #f)])]
    [(eq? state 'op) (cond
        [(char-numeric? char) (values 'int 'op)]
        [(or (eq? char #\+) (eq? char #\-)) (values 'sign 'op)]
        [(char-alphabetic? char) (values 'var 'op)]
        [(eq? char #\_) (values 'var 'op)]
        [(char-whitespace? char) (values 'op_spa 'op)]
        [(eq? char #\() (values 'par_open 'op)]
        [else (values 'inv #f)])]
    [(eq? state 'spa) (cond
        [(char-operator? char) (values 'op #f)]
        [(char-whitespace? char) (values 'spa #f)]
        [(eq? char #\/) (values 'op_slash #f)]
        [(eq? char #\)) (values 'par_close #f)]
        [else (values 'inv #f)])]
    [(eq? state 'op_spa) (cond
        [(char-numeric? char) (values 'int #f)]
        [(or (eq? char #\+) (eq? char #\-)) (values 'sign #f)]
        [(char-alphabetic? char) (values 'var #f)]
        [(eq? char #\_) (values 'var #f)]
        [(char-whitespace? char) (values 'op_spa #f)]
        [(eq? char #\() (values 'par_open #f)]
        [else (values 'inv #f)])]
    [(eq? state 'par_open) (cond
        [(char-numeric? char) (values 'int 'par_open)]
        [(or (eq? char #\+) (eq? char #\-)) (values 'sign 'par_open)]
        [(char-alphabetic? char) (values 'var 'par_open)]
        [(eq? char #\_) (values 'var 'par_open)]
        [(char-whitespace? char) (values 'op_spa 'par_open)]
        [(eq? char #\() (values 'par_open 'par_open)]
        [(eq? char #\)) (values 'par_close 'par_open)]
        [else (values 'inv #f)])]
    [(eq? state 'par_close) (cond
        [(char-operator? char) (values 'op 'par_close)]
        [(char-whitespace? char) (values 'spa 'par_close)]
        [(eq? char #\/) (values 'op_slash 'par_close)]
        [(eq? char #\)) (values 'par_close 'par_close)]
        [else (values 'inv #f)])]
    [(eq? state 'op_slash) (cond
        [(char-numeric? char) (values 'int 'op)]
        [(or (eq? char #\+) (eq? char #\-)) (values 'sign 'op)]
        [(char-alphabetic? char) (values 'var 'op)]
        [(eq? char #\_) (values 'var 'op)]
        [(char-whitespace? char) (values 'op_spa 'op)]
        [(eq? char #\() (values 'par_open 'op)]
        [(eq? char #\/) (values 'comment #f)]
        [else (values 'inv #f)])]
    [(eq? state 'inv_slash) (cond
        [(eq? char #\/) (values 'comment #f)]
        [else (values 'inv #f)])]
    [(eq? state 'comment) (values 'comment #f)]))