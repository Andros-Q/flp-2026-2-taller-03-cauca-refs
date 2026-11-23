#lang eopl
;Autores: Andres Felipe Quiceno gil Codigo:2477362
;Yonier Alejandro Vega Rojas Codigo:2477056
;Jhon Fabricio Hurtado Marin Codigo: 2459472
;Juan Esteban Aguirre Castañeda Codigo:2459676

#|
  taller 3 - cauca con referencias y tipos.
  evaluacion y punto de entrada.

  el evaluador recorre el arbol con cases y apply-procedure liga los
  parametros de una clausura antes de evaluar su cuerpo. las dos se
  llaman mutuamente, asi que comparten modulo, y con ellas la copia por
  valor de los argumentos.

  el evaluador ignora las anotaciones de tipo: las lee el parser, quedan
  en el arbol y solo las usa el chequeador.

  la parte 2 vive en app-ref-exp: los argumentos deben ser identificadores
  ligados a referencias y los parametros quedan ligados a esas mismas
  referencias, no a una copia. eso es lo que separa apply de applyref.
|#

(require "sintaxis.rkt")
(require "almacen.rkt")
(require "ambiente.rkt")
(require "primitivas.rkt")

;; copia-por-valor : valor -> valor
;; recibe un valor y devuelve una copia. para un numero, un booleano o un
;; prosedimiento la copia es el mismo valor; para una referencia es una
;; celda nueva con el mismo contenido. applyref no usa esta funcion:
;; ahi el parametro queda ligado a la misma celda.
(define copia-por-valor
  (lambda (val)
    (if (referencia? val)
        (newref! (deref val))
        val)))

;; copiar-lista : lista de valores -> lista de valores
;; aplica copia-por-valor a cada argumento antes de entrar a una clausura.
(define copiar-lista
  (lambda (vals)
    (if (null? vals)
        '()
        (let ((copia (copia-por-valor (car vals))))
          (cons copia (copiar-lista (cdr vals)))))))

;; evaluar-lista : lista de expresiones x ambiente -> lista de valores
;; evalua las expresiones de izquierda a derecha y devuelve la lista de
;; valores. se usa en prim, let y apply para no perder el orden.
(define evaluar-lista
  (lambda (exps env)
    (if (null? exps)
        '()
        (let ((valor (evaluar-expresion (car exps) env)))
          (cons valor (evaluar-lista (cdr exps) env))))))

;; buscar-referencias : lista de symbol x ambiente -> lista de referencias
;; busca cada identificador en el ambiente y verifica que su valor sea una
;; referencia. si alguno no lo es, levanta eopl:error.
(define buscar-referencias
  (lambda (ids env)
    (if (null? ids)
        '()
        (let ((val (apply-env env (car ids))))
          (if (referencia? val)
              (cons val (buscar-referencias (cdr ids) env))
              (eopl:error 'evaluar-expresion
                          "el paso por referencia exige variables ligadas a referencias: ~s"
                          (car ids)))))))

;; evaluar-secuencia : lista de expresiones x ambiente -> valor
;; evalua la lista de izquierda a derecha y devuelve el valor de la ultima.
(define evaluar-secuencia
  (lambda (exps env)
    (if (null? (cdr exps))
        (evaluar-expresion (car exps) env)
        (begin
          (evaluar-expresion (car exps) env)
          (evaluar-secuencia (cdr exps) env)))))

;; buscar-rama : numero x lista de numeros x lista de expresiones x expresion x ambiente -> valor
;; busca el numero en la lista y evalua la expresion que le corresponde;
;; si no lo encuentra, evalua el default.
(define buscar-rama
  (lambda (n numeros exps default env)
    (cond ((null? numeros) (evaluar-expresion default env))
          ((= n (car numeros)) (evaluar-expresion (car exps) env))
          (else (buscar-rama n (cdr numeros) (cdr exps) default env)))))

;; apply-procedure : procval x lista de valores -> valor
;; verifica la aridad, copia los argumentos por valor y evalua el cuerpo
;; en el ambiente de la clausura extendido con los parametros.
(define apply-procedure
  (lambda (proc args)
    (if (procval? proc)
        (cases procval proc
          (cerradura (ids body env)
                     (if (= (length ids) (length args))
                         (evaluar-expresion body
                                            (ambiente-extendido
                                             ids
                                             (copiar-lista args)
                                             env))
                         (eopl:error 'apply-procedure
                                     "el procedimiento espera ~s argumentos y recibio ~s"
                                     (length ids)
                                     (length args)))))
        (eopl:error 'apply-procedure
                    "se intento aplicar un valor que no es un procedimiento: ~s"
                    proc))))

;; evaluar-expresion : expresion x ambiente -> valor
;; una clausula por variante de la gramatica. la condicion de un if se
;; verifica con boolean? antes de ramificar.
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp

      (lit-exp (datum) datum)

      (var-exp (id) (apply-env env id))

      (true-exp () #t)

      (false-exp () #f)

      (prim-exp (prim rands)
                (evaluar-primitiva prim (evaluar-lista rands env)))

      (if-exp (test rama-si rama-no)
              (let ((valor-test (evaluar-expresion test env)))
                (if (boolean? valor-test)
                    (if valor-test
                        (evaluar-expresion rama-si env)
                        (evaluar-expresion rama-no env))
                    (eopl:error 'evaluar-expresion
                                "la condicion del if debe ser booleana, se encontro ~s"
                                valor-test))))

      (let-exp (ids rands body)
               (let ((valores (evaluar-lista rands env)))
                 (evaluar-expresion body
                                    (ambiente-extendido ids valores env))))

      (proc-exp (ids tipos body)
                (cerradura ids body env))

      (app-exp (rator rands)
         (let* ((proc (evaluar-expresion rator env))
          (args (evaluar-lista rands env)))
        (if (procval? proc)
         (apply-procedure proc args)
           (eopl:error 'evaluar-expresion
                    "Se esperaba un procedimiento, se recibió: ~s"
                    proc)))
       )

      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
                  (evaluar-expresion
                   body
                   (ambiente-recursivo proc-names idss bodies env)))

      (case-exp (exp-central numeros exps default)
                (let ((n (evaluar-expresion exp-central env)))
                  (if (number? n)
                      (buscar-rama n numeros exps default env)
                      (eopl:error 'evaluar-expresion
                                  "el case espera un numero, se encontro ~s"
                                  n))))

      (newref-exp (exp)
                  (newref! (evaluar-expresion exp env)))

      (deref-exp (exp)
                 (let ((val (evaluar-expresion exp env)))
                   (if (referencia? val)
                       (deref val)
                       (eopl:error 'evaluar-expresion
                                   "deref espera una referencia, se encontro ~s"
                                   val))))

      (setref-exp (ref exp)
                  (let* ((r (evaluar-expresion ref env))
                         (val (evaluar-expresion exp env)))
                    (if (referencia? r)
                        (begin
                          (setref! r val)
                          1)
                        (eopl:error 'evaluar-expresion
                                    "setref espera una referencia, se encontro ~s"
                                    r))))

      (swap-exp (ref1 ref2)
                (let* ((r1 (evaluar-expresion ref1 env))
                       (r2 (evaluar-expresion ref2 env)))
                  (if (and (referencia? r1) (referencia? r2))
                      (let ((v1 (deref r1))
                            (v2 (deref r2)))
                        (setref! r1 v2)
                        (setref! r2 v1)
                        v2)
                      (eopl:error 'evaluar-expresion
                                  "swap espera dos referencias, se encontro ~s y ~s"
                                  r1 r2))))

      (begin-exp (exp exps)
                 (let ((primero (evaluar-expresion exp env)))
                   (if (null? exps)
                       primero
                       (evaluar-secuencia exps env))))

      ;; paso por referencia: no se copia nada, se pasan las mismas
      ;; referencias que tienen los identificadores en el ambiente.
      (app-ref-exp (rator ids)
                   (let ((proc (evaluar-expresion rator env)))
                     (if (procval? proc)
                         (cases procval proc
                           (cerradura (parametros body env-clausura)
                                      (if (= (length parametros) (length ids))
                                          (let ((refs (buscar-referencias ids env)))
                                            (evaluar-expresion
                                             body
                                             (ambiente-extendido
                                              parametros
                                              refs
                                              env-clausura)))
                                          (eopl:error 'evaluar-expresion
                                                      "el procedimiento espera ~s argumentos y recibio ~s"
                                                      (length parametros)
                                                      (length ids)))))
                         (eopl:error 'evaluar-expresion
                                     "se intento aplicar un valor que no es un procedimiento: ~s"
                                     proc)))))))

;; evaluar-programa : programa -> valor
;; deja el almacen vacio y evalua el cuerpo en el ambiente inicial.
(define evaluar-programa
  (lambda (pgm)
    (initialize-store!)
    (cases programa pgm
      (a-program (exp)
                 (evaluar-expresion exp (ambiente-inicial))))))

;; interpretar : string -> valor
;; analiza el texto con el parser y lo evalua.
(define interpretar
  (lambda (texto)
    (evaluar-programa (parser texto))))

;; interpretador : -> void
;; el ciclo de lectura, con sllgen:make-rep-loop sobre evaluar-programa.
(define interpretador
  (lambda ()
    (sllgen:make-rep-loop
     "--> "
     evaluar-programa
     (sllgen:make-stream-parser
      especificacion-lexica
      especificacion-gramatical))))

(provide (all-defined-out))
