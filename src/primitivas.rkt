#lang eopl
;Autores: Andres Felipe Quiceno gil Codigo:2477362
;Yonier Alejandro Vega Rojas Codigo:2477056
;Jhon Fabricio Hurtado Marin Codigo: 2459472
;Juan Esteban Aguirre Castañeda Codigo:2459676

#|
  Taller 3 — Cauca con referencias y tipos.
  Primitivas del lenguaje.

  evaluar-primitiva recibe la primitiva del árbol y la lista de valores
  ya evaluados, revisa la cantidad y el tipo de los argumentos y produce
  el resultado. Solo necesita la gramática, no el evaluador.

  Las verificaciones de cantidad y de tipo van aquí, junto a la
  primitiva que las exige, y levantan eopl:error con un mensaje que
  nombre la primitiva.
|#

(require "sintaxis.rkt")

;; evaluar-primitiva : primitiva x lista de valores -> valor
;; Una cláusula por primitiva de la gramática, con cases.
(define evaluar-primitiva
  (lambda (prim args)
    (eopl:error 'evaluar-primitiva "Sin implementar")))

(provide (all-defined-out))
