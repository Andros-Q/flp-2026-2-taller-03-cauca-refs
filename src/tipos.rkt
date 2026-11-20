#lang eopl
;Autores: Andres Felipe Quiceno gil Codigo:2477362
;Yonier Alejandro Vega Rojas Codigo:2477056
;Jhon Fabricio Hurtado Marin Codigo: 2459472
;Juan Esteban Aguirre Castañeda Codigo:2459676

#|
  Taller 3 — Cauca con referencias y tipos.
  El tipo y el ambiente de tipos (Parte 3).

  El datatype tipo lo genera la gramática, porque las anotaciones se
  escriben dentro del programa. Aquí van la comparación estructural de
  dos tipos, el texto con que un tipo aparece en los mensajes de error y
  el ambiente de tipos, con las mismas tres variantes del ambiente de
  valores: tenv-vacio, tenv-extendido y tenv-recursivo. La recursiva
  guarda el tipo declarado de cada procedimiento, que es lo que permite
  chequear el cuerpo de un letrec sin evaluarlo.

  El módulo requiere sintaxis.rkt y ningún otro del intérprete.
|#

(require "sintaxis.rkt")

;; tenv : ambiente de tipos Γ
(define-datatype tenv tenv?
  (tenv-vacio)
  (tenv-extendido
   (ids (list-of symbol?))
   (tipos (list-of tipo?))
   (env tenv?))
  (tenv-recursivo
   (nombres (list-of symbol?))
   (tipos (list-of tipo?))
   (env tenv?)))

;; tipos-lista->texto : lista de tipos -> string
;; Los tipos separados por " * ", como en (num * num -> bool).
(define tipos-lista->texto
  (lambda (ts)
    (cond ((null? ts) "")
          ((null? (cdr ts)) (tipo->texto (car ts)))
          (else (string-append (tipo->texto (car ts)) " * "
                               (tipos-lista->texto (cdr ts)))))))

;; tipo->texto : tipo -> string
;; La forma en que los tipos aparecen en los mensajes de error:
;; "num", "bool", "refto(num)", "(num * num -> bool)".
(define tipo->texto
  (lambda (t)
    (cases tipo t
      (num-tipo () "num")
      (bool-tipo () "bool")
      (ref-tipo (s) (string-append "refto(" (tipo->texto s) ")"))
      (proc-tipo (args res)
                 (string-append "(" (tipos-lista->texto args)
                                (if (null? args) "-> " " -> ")
                                (tipo->texto res) ")")))))

;; tipos-iguales-lista? : lista de tipos x lista de tipos -> boolean
;; Igualdad estructural elemento a elemento; falso si difieren en longitud.
(define tipos-iguales-lista?
  (lambda (l1 l2)
    (cond ((and (null? l1) (null? l2)) #t)
          ((or (null? l1) (null? l2)) #f)
          (else (and (tipos-iguales? (car l1) (car l2))
                     (tipos-iguales-lista? (cdr l1) (cdr l2)))))))

;; tipos-iguales? : tipo x tipo -> boolean
;; Compara dos tipos por estructura, no por identidad.
(define tipos-iguales?
  (lambda (t1 t2)
    (cases tipo t1
      (num-tipo () (cases tipo t2 (num-tipo () #t) (else #f)))
      (bool-tipo () (cases tipo t2 (bool-tipo () #t) (else #f)))
      (ref-tipo (s1) (cases tipo t2
                       (ref-tipo (s2) (tipos-iguales? s1 s2))
                       (else #f)))
      (proc-tipo (a1 r1) (cases tipo t2
                           (proc-tipo (a2 r2)
                                      (and (tipos-iguales-lista? a1 a2)
                                           (tipos-iguales? r1 r2)))
                           (else #f))))))

;; buscar-posicion : symbol x lista de symbol -> integer | #f
;; La posición del identificador en la lista, o #f si no está.
(define buscar-posicion
  (lambda (id ids)
    (letrec ((buscar (lambda (l i)
                       (cond ((null? l) #f)
                             ((eqv? id (car l)) i)
                             (else (buscar (cdr l) (+ i 1)))))))
      (buscar ids 0))))

;; apply-tenv : tenv x symbol -> tipo
;; Busca el tipo del identificador. Si no está declarado levanta
;; eopl:error con «Variable no declarada: <x>».
(define apply-tenv
  (lambda (amb id)
    (cases tenv amb
      (tenv-vacio ()
                  (eopl:error 'apply-tenv "Variable no declarada: ~a" id))
      (tenv-extendido (ids tipos env)
                      (let ((pos (buscar-posicion id ids)))
                        (if pos (list-ref tipos pos) (apply-tenv env id))))
      (tenv-recursivo (nombres tipos env)
                      (let ((pos (buscar-posicion id nombres)))
                        (if pos (list-ref tipos pos) (apply-tenv env id)))))))

;; tenv-inicial : -> tenv
;; Declara como num las cinco variables del ambiente inicial.
(define tenv-inicial
  (lambda ()
    (tenv-extendido '(n m p q r)
                    (list (num-tipo) (num-tipo) (num-tipo) (num-tipo) (num-tipo))
                    (tenv-vacio))))

;; primitiva->texto : primitiva -> string
;; El nombre de la primitiva como se escribe en el programa.
(define primitiva->texto
  (lambda (prim)
    (cases primitiva prim
      (sum-prim () "+") (minus-prim () "-") (mult-prim () "*") (div-prim () "/")
      (add-prim () "add1") (sub-prim () "sub1")
      (mayor-prim () ">") (mayorigual-prim () ">=") (menor-prim () "<")
      (menorigual-prim () "<=") (igual-prim () "==")
      (not-prim () "not") (and-prim () "and") (or-prim () "or")
      (xor-prim () "xor") (implica-prim () "implica")
      (abs-prim () "abs") (mcd-prim () "mcd") (mcm-prim () "mcm")
      (promedio-prim () "promedio") (entre-prim () "entre"))))

;; aridad-de-primitiva : primitiva -> integer | #f
;; La cantidad exacta de argumentos que exige, o #f si admite cualquier
;; cantidad (>= 1).
(define aridad-de-primitiva
  (lambda (prim)
    (cases primitiva prim
      (add-prim () 1) (sub-prim () 1) (abs-prim () 1) (not-prim () 1)
      (mayor-prim () 2) (mayorigual-prim () 2) (menor-prim () 2)
      (menorigual-prim () 2) (igual-prim () 2)
      (xor-prim () 2) (implica-prim () 2)
      (entre-prim () 3)
      (else #f))))

;; tipo-args-de-primitiva : primitiva -> tipo
;; El tipo que la primitiva exige de cada uno de sus argumentos.
(define tipo-args-de-primitiva
  (lambda (prim)
    (cases primitiva prim
      (not-prim () (bool-tipo)) (and-prim () (bool-tipo)) (or-prim () (bool-tipo))
      (xor-prim () (bool-tipo)) (implica-prim () (bool-tipo))
      (else (num-tipo)))))

;; tipo-res-de-primitiva : primitiva -> tipo
;; El tipo que retorna: las aritméticas num; las relacionales, las
;; booleanas y entre, bool.
(define tipo-res-de-primitiva
  (lambda (prim)
    (cases primitiva prim
      (sum-prim () (num-tipo)) (minus-prim () (num-tipo)) (mult-prim () (num-tipo))
      (div-prim () (num-tipo)) (add-prim () (num-tipo)) (sub-prim () (num-tipo))
      (abs-prim () (num-tipo)) (mcd-prim () (num-tipo)) (mcm-prim () (num-tipo))
      (promedio-prim () (num-tipo))
      (else (bool-tipo)))))

;; verificar-args-primitiva : primitiva x tipo x lista de tipos x integer -> void
;; Revisa uno a uno que cada argumento tenga el tipo exigido.
(define verificar-args-primitiva
  (lambda (prim esperado tipos i)
    (if (null? tipos)
        'ok
        (begin
          (if (tipos-iguales? esperado (car tipos))
              'ok
              (eopl:error 'tipo-de-primitiva
                          "La primitiva ~a espera ~a en el argumento ~a, se encontro ~a"
                          (primitiva->texto prim) (tipo->texto esperado) i
                          (tipo->texto (car tipos))))
          (verificar-args-primitiva prim esperado (cdr tipos) (+ i 1))))))

;; tipo-de-primitiva : primitiva x lista de tipos -> tipo
;; Lo que cada primitiva exige de sus argumentos y lo que retorna: las
;; aritméticas retornan num; las relacionales, las booleanas y entre
;; retornan bool. Verifica cantidad y tipo de los argumentos.
(define tipo-de-primitiva
  (lambda (prim tipos)
    (let ((aridad (aridad-de-primitiva prim)))
      (begin
        (if (if aridad (not (= aridad (length tipos))) (null? tipos))
            (eopl:error 'tipo-de-primitiva
                        "La primitiva ~a espera ~a argumentos y recibio ~a"
                        (primitiva->texto prim)
                        (if aridad aridad "al menos 1")
                        (length tipos))
            'ok)
        (verificar-args-primitiva prim (tipo-args-de-primitiva prim) tipos 1)
        (tipo-res-de-primitiva prim)))))

(provide (all-defined-out))