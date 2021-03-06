#lang scribble/manual
@;
@; Copyright 2018 Dionna Glaze
@;
@; Licensed under the Apache License, Version 2.0 (the "License");
@; you may not use this file except in compliance with the License.
@; You may obtain a copy of the License at
@;
@;     http://www.apache.org/licenses/LICENSE-2.0
@;
@; Unless required by applicable law or agreed to in writing, software
@; distributed under the License is distributed on an "AS IS" BASIS,
@; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@; See the License for the specific language governing permissions and
@; limitations under the License.
@;
@(require scribble/eval 
          racket/sandbox
          (for-label scribble/struct
                     "for-acc.rkt"
                     racket/set
                     racket/base))
@(declare-exporting "for-acc.rkt")
@(define for-eval
   (parameterize ([sandbox-output 'string]
                  [sandbox-error-output 'string])
         (make-evaluator 'racket/base #:requires (list 'racket/set "for-acc.rkt"))))

@title[#:tag "for-acc"]{Defined accumulators for @racket[for]}

This library provides support for combining different accumulator
styles in the same form. For example, @racket[for/sum] and
@racket[for/list] can be combined to sum the first value returned in a
@racket[for] body, and make a list out of the second value returned in
that body. Accumulator styles are user-definable and are flexible
enough to support all current @racket[for/*] forms.

@defform/subs[(define-accumulator name [accumulator-id optionals] ...)
              ([optionals #:suppress
                          (code:line #:initial initial-expr)
                          (code:line #:bind bind-id/s)
                          (code:line #:inner inner-expr)
                          (code:line #:post post-expr)]
               [bind-id/s id
                          (id ...)])]{

Defines an accumulation style named @racket[name] that uses the
following accumulator identifiers with optional initial value,
optional post-processing (say to reverse the produced list), and how
to accumulate the value that corresponds to its position, optionally named with @racket[#:bind].

If an accumulation style requires several accumulators to perform the
task, you can suppress some bindings from being in the return values
of @racket[for/acc]. At least one accumulator must not be
suppressed.

@examples[#:eval for-eval
(define-accumulator list
    [lst #:initial '() #:bind v #:inner (cons v lst) #:post (reverse lst)])
(define-accumulator hash [h #:initial #hash() #:bind (k v) #:inner (hash-set h k v)])
(define-accumulator union [st #:initial (set) #:bind v #:inner (set-union v st)])
]}

@defform/subs[(for/acc (accumulator ...) for-clauses body-or-break ... body)
              ([accumulator [id initial-expr]
                            [optional-ids kw-optionals optional-initial-expr]]
               [optional-ids (code:line)
                             id
                             (id ...)]
               [optional-initial-expr (code:line)
                                      initial-expr]
               [kw-optionals (code:line #:type style-id)
                             (code:line #:initial initial-expr/s)
                             (code:line #:named-initial ([id initial-expr] ...))
                             (code:line #:drop)]
               [initial-expr/s initial-expr
                               (values initial-expr ...)])]{

A defined accumulator may be used with the @racket[#:type] form.
If @racket[optional-ids] are given with @racket[#:type], then there must be as many given identifiers as there are non-supressed accumulator identifiers defined in the accumulation style.
If the @racket[#:initial] form is given, there must be as many expressions assigning initial values as there are non-supressed accumulator identifiers.
To otherwise partially specify initial values, the @racket[#:named-initial] form may be used.
Any named accumulator for initial values must either be given in @racket[optional-ids], or be @racket[free-identifier=?] to an accumulator identifier defined in the accumulation style.
It is a syntax error to not specify initial values for accumulators which do not have predefined initial values.

An @racket[accumulator] that also has @racket[#:drop] specified will
not return the values of the accumulators as part of the values of the
entire @racket[for/acc] form.

The @racket[body] expression is expected to return as many values as
there are non-suppressed identifiers for accumulators.

Here @racket[for-clauses], @racket[body-or-break] and @racket[body] are the same as in @racket[for].
@racket[for/acc] is backwards-compatible with @racket[for/fold].

@examples[#:eval for-eval
(for/acc ([#:type set]
          [#:type hash (hash -1 1)])
    ([i 5])
  (values i i (- i)))
(for/acc ([#:type sum]
                 [a '()]
                 [#:type prod])
    ([i (in-range 1 5)])
  (values i (cons i a) i))
]}

@defform[(for*/acc (accumulator ...) for-clauses body-or-break ... body)]{

Like @racket[for/acc], but uses @racket[for*/fold] as the base
iteration form. Backwards-compatible with @racket[for*/fold].}

@defform[(let/for/acc ((accumulator ...) for-clauses body-or-break ... body) lbody ...)]{
Runs @racket[(lbody ...)] in the context of only non-suppressed identifiers of the accumulation.
}

@defform[(let/for*/acc ((accumulator ...) for-clauses body-or-break ... body) lbody ...)]{
Like @racket[let/for/acc], but uses @racket[for*/acc].}

@defform[(define/for/acc (accumulator ...) for-clauses body-or-break ... body)]{
Like @racket[let/for/acc], but defines the non-suppressed accumulators within the current internal-definition-context.}

@defform[(define/for*/acc (accumulator ...) for-clauses body-or-break ... body)]{
Like @racket[define/for/acc], but uses @racket[for*/acc].}

@close-eval[for-eval]
