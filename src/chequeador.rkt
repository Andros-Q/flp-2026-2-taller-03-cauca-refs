#lang eopl
;Autores: Andres Felipe Quiceno gil Codigo:2477362
;Yonier Alejandro Vega Rojas Codigo:2477056
;Jhon Fabricio Hurtado Marin Codigo: 2459472
;Juan Esteban Aguirre Castañeda Codigo:2459676

#|
  Taller 3 — Cauca con referencias y tipos.
  Reglas de tipado y chequeo del programa (Parte 3).

  type-of recorre el árbol con cases sobre un ambiente de tipos y no
  evalúa nada: una regla por variante de expresión, tal como están
  escritas en el cuadro del enunciado.

  Los mensajes de error se distinguen uno de otro. Son los nueve del
  cuadro «Mensajes de error», con ese texto.

  El módulo requiere sintaxis.rkt y tipos.rkt, y ningún otro módulo del
  intérprete: el árbol que recorre es el que produjo el parser, con las
  anotaciones de tipo adentro.
|#

(require "sintaxis.rkt")
(require "tipos.rkt")

;; verificar-aridad : integer x integer -> symbol
;; Verifica que la cantidad de argumentos coincida.
(define verificar-aridad
  (lambda (esperados recibidos)
    (if (= esperados recibidos)
        'ok
        (eopl:error
         'type-of
         "El procedimiento espera ~a argumentos y recibio ~a"
         esperados
         recibidos))))

;; verificar-argumentos : lista de tipo x lista de tipo x integer -> symbol
;; Verifica los tipos de los argumentos uno por uno.
(define verificar-argumentos
  (lambda (esperados recibidos posicion)
    (if (null? esperados)
        'ok
        (begin
          (if (tipos-iguales? (car esperados) (car recibidos))
              'ok
              (eopl:error
               'type-of
               "El argumento ~a debe ser ~a, se encontro ~a"
               posicion
               (tipo->texto (car esperados))
               (tipo->texto (car recibidos)))

          )
          (verificar-argumentos
           (cdr esperados)
           (cdr recibidos)
           (+ posicion 1))))))

;; exigir-tipo : tipo x tipo x string -> void
;; Comprueba que dos tipos sean iguales.

(define exigir-tipo
  (lambda (esperado obtenido mensaje)
    (if (tipos-iguales? esperado obtenido)
        'ok
        (eopl:error
         'type-of
         "~a. Se esperaba ~a, pero se encontro ~a"
         mensaje
         (tipo->texto esperado)
         (tipo->texto obtenido)))))


;; ultimo-tipo : lista de tipos -> tipo
;; Obtiene el ultimo tipo de una lista no vacia.

(define ultimo-tipo
  (lambda (tipos)
    (if (null? (cdr tipos))
        (car tipos)
        (ultimo-tipo (cdr tipos)))))


;; verificar-todos-mismo-tipo : tipo x lista de tipos x string -> void
;; Comprueba que todos los tipos de una lista coincidan.

(define verificar-todos-mismo-tipo
  (lambda (esperado obtenidos mensaje)
    (if (null? obtenidos)
        'ok
        (begin
          (exigir-tipo esperado (car obtenidos) mensaje)
          (verificar-todos-mismo-tipo
           esperado
           (cdr obtenidos)
           mensaje)))))


;; verificar-parametros-ref : lista de tipos -> boolean
;; Comprueba que todos los parametros sean referencias.

(define verificar-parametros-ref
  (lambda (tipos)
    (if (null? tipos)
        #t
        (cases tipo (car tipos)
          (ref-tipo (contenido)
            (verificar-parametros-ref (cdr tipos)))
          (else #f)))))


;; type-of : expresion x tenv -> tipo
;; El tipo de la expresión bajo el ambiente de tipos, o eopl:error con
;; el mensaje que explique el conflicto.
(define type-of
  (lambda (exp amb)
    (cases expresion exp
       ;; Literales
     (lit-exp (n) (num-tipo))
      (true-exp () (bool-tipo))
      (false-exp () (bool-tipo))
      
      ;; Identificadores ambientes
      (var-exp (id) (apply-tenv amb id))

      ;; Primitivas tanto numericas como booleanas
      (prim-exp(prim rands)
         (tipo-de-primitiva prim
             (map (lambda(rand) ;;Aqui hallo los tipos que tiene el rand para saber los tipos de los argumentos de la expresion
                (type-of rand amb)) rands))
       )

      ;; if
      (if-exp (test true-exp false-exp)
           (let(      ;;Busca el tipo de test en el ambiente
                [ts (type-of test amb)] 
                )
              (if (tipos-iguales? (bool-tipo) ts) ;;Comprobar si el test del cuerpo es bool
                  (let(
                    [t_cumple (type-of true-exp amb)]
                    [t_no_cumple (type-of false-exp amb)]
                   )
                    (cond
                    [(tipos-iguales? t_cumple t_no_cumple)
                     t_cumple]
                    [else (eopl:error 'type-of
                    "Las ramas del if deben coincidir: ~a vs ~a"
                     (tipo->texto t_cumple)
                     (tipo->texto t_no_cumple))]
                    ) 
                   )
                  (eopl:error 'type-of
                          "La condicion del if debe ser bool, se encontro ~a"
                          (tipo->texto ts))
               )
             
            )
       )

      ;; let
      (let-exp (ids rands body)
         (let ([tipos (map (lambda (rand) ;;Devuelve una lista con los tipos de los argumentos
                (type-of rand amb)) rands)]
              )
          (type-of body
            (tenv-extendido ids tipos amb))))
 
      ;; proc
     (proc-exp (ids tipos body) ;;le paso el cuerpo del proc y el ambiente extendido
       (let([t_body (type-of 
            body (tenv-extendido ids tipos amb))
              ]
            )
          (proc-tipo tipos t_body) 
         ))

      ;; apply
      (app-exp (rator rands)

  (let ((tipo-operador (type-of rator amb))
        (tipos-argumentos
         (map
          (lambda (arg)
            (type-of arg amb))
          rands)))

    (cases tipo tipo-operador

      (proc-tipo (tipos-parametros tipo-retorno)

        ;; se comprueba la cantidad primero
        (verificar-aridad
         (length tipos-parametros)
         (length tipos-argumentos))

        ;; despues de comprobar la cantidad se comprueba cada tipo.
        (verificar-argumentos
         tipos-parametros
         tipos-argumentos
         1)

        tipo-retorno)

      (else
       (eopl:error
        'type-of
        "Se intento aplicar un valor de tipo ~a"
        (tipo->texto tipo-operador))))))

      ;; letrec
      
      (letrec-exp
       (tipos-res proc-names idss tipos-args bodies body)

       (let* ((tipos-procs
               (map
                (lambda (args res)
                  (proc-tipo args res))
                tipos-args
                tipos-res))

              ;;Ambiente que contiene el procedure que permite las llamadas recursivas
              (amb-recursivo
               (tenv-recursivo
                proc-names tipos-procs amb)))

         ;; Aqui se verifica el cuerpo de cada proc
         (letrec
             ((verificar-cuerpos
               (lambda (nombres-lista ids-lista args-lista res-lista cuerpos-lista)

                 (if (null? cuerpos-lista)
                     'ok
                     (let ((tipo-cuerpo
                            (type-of
                             (car cuerpos-lista)
                             (tenv-extendido
                              (car ids-lista)
                              (car args-lista)
                              amb-recursivo))))

                       ;; Aqui el tipo del cuerpo debe coincidir con el tipo de retorno declarado 
                     
                       (if (tipos-iguales? (car res-lista) tipo-cuerpo)
                           'ok
                           (eopl:error
                            'type-of
                            "El procedimiento ~a declara ~a y su cuerpo da ~a"
                            (car nombres-lista)
                            (tipo->texto (car res-lista))
                            (tipo->texto tipo-cuerpo)))

                       (verificar-cuerpos
                        (cdr nombres-lista)
                        (cdr ids-lista)
                        (cdr args-lista)
                        (cdr res-lista)
                        (cdr cuerpos-lista))
                       )))))

           ;; se comprueban todos los procedimientos que hay en el letrec
           (verificar-cuerpos
            proc-names
            idss
            tipos-args
            tipos-res
            bodies)

           ;; se comprueba el cuerpo principal
           (type-of body amb-recursivo))))


    
      ;;case
     
      (case-exp (exp valores acciones default)

        (let ((tipo-selector (type-of exp amb))
              (tipos-alternativas
               (map
                (lambda (e)
                  (type-of e amb))
                acciones))
              (tipo-default (type-of default amb)))

         
          (exigir-tipo
           (num-tipo)
           tipo-selector
           "El selector de case debe ser numerico")

          (verificar-todos-mismo-tipo
           tipo-default
           tipos-alternativas
           "Todas las alternativas de case deben tener el mismo tipo")

          tipo-default))


     
      ;;referencia: newref  
   
      ;; newref(exp) devuelve una referencia al tipo de e.

      (newref-exp (exp)
        (ref-tipo (type-of exp amb)))


      ;;referencia: deref

      ;; deref(exp) devuelve el tipo contenido en la referencia.

      (deref-exp (exp)

        (let ((tipo-e (type-of exp amb)))

          (cases tipo tipo-e

            (ref-tipo (tipo-contenido)
              tipo-contenido)

            (else
             (eopl:error
              'type-of
              "deref espera refto(t), se encontro ~a"
              (tipo->texto tipo-e))))))


      ;;referencia: setref 

      ;; setref(ref, exp)lo que hace es que comprueba que el valor asignado pueda coincidir con el tipo contenido en la referencia
     
      (setref-exp (ref exp)

        (let ((tipo-ref (type-of ref amb))
              (tipo-e (type-of exp amb)))

          (cases tipo tipo-ref

            (ref-tipo (tipo-contenido)

              (if (tipos-iguales? tipo-contenido tipo-e)
                  'ok
                  (eopl:error
                   'type-of
                   "La celda guarda ~a y se intento escribir ~a"
                   (tipo->texto tipo-contenido)
                   (tipo->texto tipo-e)))

              (num-tipo))

            (else
             (eopl:error
              'type-of
              "setref requiere una referencia, pero recibio ~a"
              (tipo->texto tipo-ref))))))


      ;;referencia: swap 
      
      ;;aqui en swap(ref1, ref2) se comprueba que ambas referencias tengan el mismo tipo

      (swap-exp (ref1 ref2)

        (let ((tipo-ref1 (type-of ref1 amb))
              (tipo-ref2 (type-of ref2 amb)))

          (cases tipo tipo-ref1

            (ref-tipo (contenido1)

              (cases tipo tipo-ref2

                (ref-tipo (contenido2)

                  (exigir-tipo
                   contenido1
                   contenido2
                   "swap requiere referencias de tipos compatibles")

                  contenido1)

                (else
                 (eopl:error
                  'type-of
                  "El segundo argumento de swap no es una referencia"))))

            (else
             (eopl:error
              'type-of
              "El primer argumento de swap no es una referencia")))))


      ;;begin

      ;;Aqui begin retorna el tipo de la ultima expresion

      (begin-exp (exp exps)

        (let ((tipos
               (cons
                (type-of exp amb)
                (map
                 (lambda (e)
                   (type-of e amb))
                 exps))))

          (ultimo-tipo tipos)))


      ;;applyref
      
      (app-ref-exp (rator ids)

        (let ((tipo-operador (type-of rator amb)))

          (cases tipo tipo-operador

            (proc-tipo (tipos-parametros tipo-retorno)

              (let ((tipos-ids
                     (map
                      (lambda (id)
                        (apply-tenv amb id))
                      ids)))

                ;; para poder funcionar los parametros del procedimiento deben ser refencias
   
                (if (not (verificar-parametros-ref tipos-parametros))

                    (eopl:error
                     'type-of
                     "Los parametros de applyref deben ser referencias")

                    ;;deben coincidir los identificadores con los tipos de parametros
                   
                    (if (tipos-iguales-lista?
                         tipos-parametros
                         tipos-ids)

                        tipo-retorno

                        (eopl:error
                         'type-of
                         "Los argumentos de applyref deben coincidir con los parametros del procedimiento")))))

            (else
             (eopl:error
              'type-of
              "applyref requiere un procedimiento, pero recibio ~a"
              (tipo->texto tipo-operador))))))
      )))


;; type-of-program : programa -> tipo
;; Chequea el programa en el ambiente de tipos inicial.
(define type-of-program
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp)
        (type-of exp (tenv-inicial))))
   ))

;; tipo-de-texto : string -> string
;; Analiza el texto, lo chequea y describe el tipo resultante.
(define tipo-de-texto
  (lambda (texto)
    (tipo->texto   
     (type-of-program
      (parser texto)))
   ))
;;(tipo-de-texto 
(provide (all-defined-out))
