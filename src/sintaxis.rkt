#lang eopl
;Autores: Andres Felipe Quiceno gil Codigo:2477362
;Yonier Alejandro Vega Rojas Codigo:2477056
;Jhon Fabricio Hurtado Marin Codigo: 2459472
;Juan Esteban Aguirre Castañeda Codigo:2459676

#|
  Taller 3 — Cauca con referencias y tipos.
  Especificación léxica y gramatical.

  Aquí van los tokens, las producciones con las anotaciones de tipo, los
  datatypes que SLLGEN genera a partir de ellas (programa, expresion,
  tipo, primitiva), el scanner y el parser.

  El módulo no requiere ningún otro: lo requieren los cinco del
  intérprete y los dos del chequeador, de modo que la gramática se
  escribe una sola vez y los dos lados recorren el mismo árbol.

  Lo que hay ahora es una producción por no terminal, lo mínimo para
  que los módulos carguen. La gramática completa es la del Taller 2 con
  los dos cambios de la sección «Especificación de Cauca con
  referencias y tipos» del enunciado.
|#

;;; ==========================================================
;;; 1. Especificación léxica
;;; ==========================================================
;; Los comentarios de línea, los identificadores y los números.

(define especificacion-lexica
  '(;; Comentarios y espacios
    (comentario ("//" (arbno (not #\newline))) skip)
    (espacio-blanco (whitespace) skip)

    ;; Identificadores
    (identificador
     (letter (arbno (or letter digit "_" "?")))
     symbol)

    ;; Numeros enteros positivos y negativos
    (numero (digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)) number)

    ;; Numeros flotantes positivos y negativos
    (numero (digit (arbno digit) "." digit (arbno digit)) number)
    (numero ("-" digit (arbno digit) "." digit (arbno digit)) number)
    
    ))

;;; ==========================================================
;;; 2. Especificación gramatical
;;; ==========================================================
;; Cuatro no terminales: programa, expresion, tipo y primitiva.
;;
;; Faltan, con los nombres de constructor que fija el enunciado:
;;   - las expresiones del Taller 2: var-exp, true-exp, false-exp,
;;     if-exp, let-exp, proc-exp, app-exp, letrec-exp, case-exp
;;   - las de la Parte 1: newref-exp, deref-exp, setref-exp, swap-exp,
;;     begin-exp
;;   - la de la Parte 2: app-ref-exp
;;   - los tipos: num-tipo, bool-tipo, ref-tipo, proc-tipo
;;   - las primitivas del Taller 2
;;
;; proc-exp y letrec-exp llevan las anotaciones de tipo. El tipo que
;; antecede al nombre en letrec es el del resultado del procedimiento.

(define especificacion-gramatical
  '((programa (expresion) a-program)

     ;; Expresiones basicas
    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)

    ;; Aplicacion de primitivas
    (expresion
     (primitiva "(" (separated-list expresion ",") ")")
     prim-exp)

    ;; Condicionales
    (expresion
     ("if" expresion "then" expresion "else" expresion "end")
     if-exp)

    ;; Ligadura local
    (expresion
     ("let" (arbno identificador "=" expresion)
      "in" expresion "end")
     let-exp)

    ;; Procedimientos adaptado a estos nuevos cambios
    (expresion
     ("proc" "(" (separated-list identificador ":" tipo) ")"
      expresion "end")
     proc-exp) ;;proc-exp(ids, tipos, body)

    ;; Aplicacion de procedimientos
    (expresion
     ("apply" expresion "(" (separated-list expresion ",") ")")
     app-exp)

    ;; Recursion mediante letrec adaptado a estos nuevos cambios
    (expresion
     ("letrec"
      (arbno tipo identificador
             "(" (separated-list identificador ":" tipo) ")"
             "=" expresion)
      "in" expresion "end")
     letrec-exp)
   ;;letrec-exp(tipos-res,proc-names,idss,tipos-args,bodies,body)
    
    ;; Seleccion mediante case
    (expresion
     ("case" expresion
      (arbno "of" numero "=>" expresion)
      "otherwise" "=>" expresion "end")
     case-exp)

    ;;Gramatica de las expresiones nuevas

    (expresion ("newref" "(" expresion ")") newref-exp)
    ;;newref-exp(exp)
    (expresion ("deref" "(" expresion ")") deref-exp)
     ;;deref-exp(exp)
    (expresion ("setref" "(" expresion "," expresion ")") setref-exp)
     ;;setref-exp(ref, exp)
    (expresion ("swap" "(" expresion "," expresion ")") swap-exp)
     ;;swap-exp(ref1, ref2)
    (expresion ("begin" expresion (arbno ";" expresion) "end" ) begin-exp)
     ;;begin-exp(exp, exps)
    (expresion ("applyref" expresion "("
     (separated-list identificador ",") ")") app-ref-exp)
     ;;app-ref-exp(rator, ids)

      ;;Gramatica de Tipos
    (tipo ("num") num-tipo)
    ;;num-tipo()
    (tipo ("bool") bool-tipo)
    ;;bool-tipo()
    (tipo ("refto" "(" tipo ")") ref-tipo)
    ;;ref-tipo(t)
    (tipo ("(" (arbno tipo) "->" tipo ")") proc-tipo)
    ;;proc-tipo(args, res)

    
    ;; Primitivas aritmeticas
    (primitiva ("+") sum-prim)
    (primitiva ("-") minus-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("/") div-prim)
    (primitiva ("add1") add-prim)
    (primitiva ("sub1") sub-prim)

    ;; Primitivas relacionales
    (primitiva (">") mayor-prim)
    (primitiva (">=") mayorigual-prim)
    (primitiva ("<") menor-prim)
    (primitiva ("<=") menorigual-prim)
    (primitiva ("==") igual-prim)

    ;; Primitivas booleanas originales
    (primitiva ("not") not-prim)
    (primitiva ("and") and-prim)
    (primitiva ("or") or-prim)

    ;; Primitivas adicionales
    (primitiva ("xor") xor-prim)
    (primitiva ("implica") implica-prim)
    (primitiva ("abs") abs-prim)
    (primitiva ("mcd") mcd-prim)
    (primitiva ("mcm") mcm-prim)
    (primitiva ("promedio") promedio-prim)
    (primitiva ("entre") entre-prim)
    
    ))

;;; ==========================================================
;;; 3. Datatypes, scanner y parser
;;; ==========================================================

(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

;; mostrar-datatypes : -> void
;; Imprime los define-datatype que SLLGEN generó a partir de la gramática.
(define mostrar-datatypes
  (lambda () (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; scanner : string -> lista de tokens
;; Recibe el codigo fuente como una cadena de texto
;; y devuelve la lista de tokens reconocidos.
(define scanner
  (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

;; parser : string -> programa
;; Recibe el codigo fuente como una cadena de texto
;; y devuelve el programa representado mediante el AST.
(define parser
  (sllgen:make-string-parser especificacion-lexica especificacion-gramatical))

(provide (all-defined-out))
