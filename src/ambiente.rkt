#lang eopl
;Autores: Andres Felipe Quiceno gil Codigo:2477362
;Yonier Alejandro Vega Rojas Codigo:2477056
;Jhon Fabricio Hurtado Marin Codigo: 2459472
;Juan Esteban Aguirre Castañeda Codigo:2459676

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD ambiente y valor procedimiento.

  Las dos definiciones van en el mismo módulo porque se nombran entre
  sí: el campo del ambiente dentro de una clausura pide ambiente?, y
  apply-env construye una clausura cuando resuelve un nombre ligado por
  letrec. Separarlas deja uno de los dos campos sin predicado.

  Faltan los dos datatypes:
    - ambiente, con las variantes ambiente-vacio, ambiente-extendido y
      ambiente-recursivo
    - procval, con la variante de la clausura: los parámetros, el cuerpo
      y el ambiente donde se creó

  El cuerpo de una clausura es una expresion?, que viene de sintaxis.rkt.
|#

(require "sintaxis.rkt")

;;Creacion de datatype de ambiente con su variante de ambiente extendido y su otra de recursivo
(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido  (ids (list-of symbol?));;ids
                       (valores list?)
                       (env ambiente?)
                     
   )
  (ambiente-recursivo
           (proc-names (list-of symbol?))
           (idss list?)
           (bodies (list-of expresion?))
           (env ambiente?))
  )

;;Creo datatype de la cerradura que va guardar el cuerpo del proc recursivo
(define-datatype procval procval?
  (cerradura
   (ids (list-of symbol?))
   (body expresion?)
   (env (lambda (v) #t))))
;; Tipo de dato: valor de procedimiento.
;; Nombre: procval
;; Contrato: procval = cerradura(ids, body, env)
;; Propósito:
;; Representar un procedimiento mediante una clausura que conserva
;; sus parámetros, su cuerpo y el ambiente donde fue definido.



;; apply-env : ambiente x symbol -> valor
;; Busca la ligadura del identificador. Sobre el ambiente vacío levanta
;; eopl:error; sobre el recursivo construye la clausura del procedimiento.
(define apply-env
  (lambda (env id)
    (cases ambiente env
    (ambiente-vacio () (eopl:error 'apply-env "No se
encontro el identificador "))
    (ambiente-extendido (ids valores env-old)
         (letrec(
         [buscar-listasId
            (lambda (ids valores id)
                (cond
       [(null? ids) (apply-env env-old id)]
       [(eq? (car ids) id) (car valores)];;Si encontro el id correspondiente devuelve su valor 
      [else  ;;Parte recursiva donde se mueven ambas listas al tiempo
       (buscar-listasId (cdr ids) (cdr valores) id)]
         ))]
       ) ;;Llamo la funcion auxiliar recursiva metida en el letrec
         (buscar-listasId ids valores id)
       )
   )
           
   (ambiente-recursivo (proc-names idss bodies env-old2)
                       
    (letrec(
      [buscar-proc-recursivo
       (lambda (proc-names idss bodies env-old2 env-currently id)
          (cond
            [(null? proc-names) (apply-env env-old2 id)]
            [(eq? (car proc-names) id)
               (cerradura (car idss) ;;Cerradura contiene el id , su cuerpo y el ambiente al que pertenece
                          (car bodies) env-currently)]
            [else (buscar-proc-recursivo ;;Recorre al mismo tiempo los proc-names,sus identificadores y la lista de cuerpo por cada proc
               (cdr proc-names) (cdr idss) (cdr bodies)
               env-old2 env-currently id )]
           ) 
       )       
      ]);;Aqui va lo del llamado a la funcion aux dentro del letrec
        (buscar-proc-recursivo proc-names idss bodies env-old2 env id)
      )                  
    )
 )))


;; ambiente-inicial : -> ambiente
;; El del enunciado: n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r) '(10 3 7 2 5)
                         (ambiente-vacio)))
   )

(provide (all-defined-out))
