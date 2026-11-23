#lang eopl
;Autores: Andres Felipe Quiceno gil Codigo:2477362
;Yonier Alejandro Vega Rojas Codigo:2477056
;Jhon Fabricio Hurtado Marin Codigo: 2459472
;Juan Esteban Aguirre Castañeda Codigo:2459676

#|
  Pruebas del interpretador con referencias y del chequeador de tipos.

  Se ejecuta con:  racket pruebas-cauca-refs.rkt
|#

(require rackunit)
(require rackunit/text-ui)
(require (only-in racket/base exn:fail? with-handlers exn-message))
(require "interprete-cauca-refs.rkt")
(require "checker-cauca.rkt")

(define corre (lambda (texto) (interpretar texto)))
(define tipo-de (lambda (texto) (tipo-de-texto texto)))

;; mensaje-de : string -> string
;; El mensaje que produce el chequeador, para comprobarlo textualmente.
(define mensaje-de
  (lambda (texto)
    (with-handlers ((exn:fail? (lambda (e) (exn-message e))))
      (string-append "sin error: " (tipo-de texto)))))

;; contiene? : string x string -> boolean
(define contiene?
  (lambda (texto fragmento)
    (letrec ((desde (lambda (i)
                      (cond ((> (+ i (string-length fragmento)) (string-length texto)) #f)
                            ((string=? (substring texto i (+ i (string-length fragmento)))
                                       fragmento) #t)
                            (else (desde (+ i 1)))))))
      (desde 0))))

;;; ==========================================================
;;; Interprete
;;; ==========================================================

(define almacen
  (test-suite
   "Parte 1: almacen y expresiones nuevas"
   (test-case "newref y deref"
              (check-equal? (corre "deref(newref(42))") 42)
              (check-equal? (corre "deref(newref(true))") #t))
   (test-case "setref escribe y retorna 1"
              (check-equal? (corre "setref(newref(1), 2)") 1)
              (check-equal? (corre "let c = newref(1) in begin setref(c, 9); deref(c) end end") 9))
   (test-case "el contador sobrevive entre llamadas"
              (check-equal? (corre "let contador = newref(0)
in
  begin
    setref(contador, add1(deref(contador)));
    setref(contador, add1(deref(contador)));
    setref(contador, add1(deref(contador)));
    deref(contador)
  end
end") 3))
   (test-case "swap intercambia el contenido y retorna el nuevo valor de la primera"
              (check-equal? (corre "let a = newref(7)
    b = newref(2)
in
  begin
    swap(a, b);
    +(deref(a), *(10, deref(b)))
  end
end") 72)
              (check-equal? (corre "let a = newref(7) b = newref(2) in swap(a, b) end") 2))
   (test-case "begin evalua de izquierda a derecha y retorna la ultima"
              (check-equal? (corre "begin 1; 2; 3 end") 3)
              (check-equal? (corre "let c = newref(0)
                                    in begin setref(c, 5); setref(c, 6); deref(c) end end") 6))
   (test-case "alias: dos nombres, una sola celda"
              (check-equal? (corre "let celda = newref(5)
in
  let otro = celda
  in
    begin
      setref(otro, 99);
      deref(celda)
    end
  end
end") 99))
   (test-case "el almacen arranca vacio en cada programa"
              (check-equal? (corre "deref(newref(1))") 1)
              (check-equal? (corre "deref(newref(1))") 1))
   (test-case "los casos de error del almacen"
              (check-exn exn:fail? (lambda () (corre "deref(5)")))
              (check-exn exn:fail? (lambda () (corre "setref(1, 2)")))
              (check-exn exn:fail? (lambda () (corre "swap(1, newref(2))"))))))

;;; ==========================================================
;;; ejemplos de la parte 1
;;; ==========================================================

;; diez ejemplos cortos que cubren las cinco expresiones nuevas
;; (newref, deref, setref, swap y begin), los dos casos de alias y
;; los tres errores del enunciado.
(define ejemplos-parte-1
  (test-suite
   "Parte 1: ejemplos de ejecucion"
   (test-case "newref reserva una celda y deref la lee"
              (check-equal? (corre "deref(newref(10))") 10)
              (check-equal? (corre "deref(newref(true))") #t)
              (check-equal? (corre "deref(deref(newref(newref(7))))") 7))
   (test-case "setref escribe y retorna 1"
              (check-equal? (corre "setref(newref(0), 7)") 1)
              (check-equal? (corre "let c = newref(3) in begin setref(c, 8); deref(c) end end") 8))
   (test-case "swap retorna el contenido anterior de la segunda"
              (check-equal? (corre "let a = newref(5) b = newref(6) in swap(a, b) end") 6))
   (test-case "swap deja los contenidos cambiados"
              (check-equal? (corre "let a = newref(5)
                                    b = newref(6)
                                    in begin swap(a, b); -(deref(a), deref(b)) end
                                    end") 1))
   (test-case "begin respeta el orden de izquierda a derecha"
              (check-equal? (corre "begin 10; 20; 30 end") 30))
   (test-case "alias: dos nombres para la misma celda"
              (check-equal? (corre "let celda = newref(1)
                                    in let otro = celda
                                       in begin setref(otro, 99); deref(celda) end
                                       end
                                    end") 99))
   (test-case "alias con swap: escribir por un nombre se ve por el otro"
              (check-equal? (corre "let a = newref(1)
                                    in let b = a
                                           c = newref(9)
                                       in begin swap(b, c); deref(a) end
                                       end
                                    end") 9))
   (test-case "error: deref sobre algo que no es referencia"
              (check-exn exn:fail? (lambda () (corre "deref(5)"))))
   (test-case "error: setref sobre algo que no es referencia"
              (check-exn exn:fail? (lambda () (corre "setref(1, 2)"))))
   (test-case "error: swap con algo que no es referencia"
              (check-exn exn:fail? (lambda () (corre "swap(1, newref(2))"))))))

(define paso-por-referencia
  (test-suite
   "Parte 2: paso por referencia"
   (test-case "applyref deja que el procedimiento escriba en la celda del que llama"
              (check-equal? (corre "let x = newref(11)
    y = newref(4)
in
  let intercambiar = proc (u : refto(num), v : refto(num))
                       swap(u, v)
                     end
  in
    begin
      applyref intercambiar (x, y);
      -(deref(x), deref(y))
    end
  end
end") -7))
   (test-case "el mismo programa con apply no toca las celdas del que llama"
              (check-equal? (corre "let x = newref(11)
    y = newref(4)
in
  let intercambiar = proc (u : refto(num), v : refto(num))
                       swap(u, v)
                     end
  in
    begin
      apply intercambiar (x, y);
      -(deref(x), deref(y))
    end
  end
end") 7))
   (test-case "applyref sobre una sola celda"
              (check-equal? (corre "let c = newref(1)
                                    in let poner = proc (u : refto(num)) setref(u, 100) end
                                       in begin applyref poner (c); deref(c) end end end") 100))
   (test-case "applyref con dos celdas independientes"
              (check-equal? (corre "let a = newref(1)
    b = newref(2)
in let sumar = proc (u : refto(num), v : refto(num))
                 setref(u, +(deref(u), deref(v)))
               end
   in begin applyref sumar (a, b); *(deref(a), deref(b)) end
end end") 6))
   (test-case "apply si comparte el procedimiento, no la celda"
              (check-equal? (corre "let c = newref(1)
                                    in let poner = proc (u : refto(num)) setref(u, 100) end
                                       in begin apply poner (c); deref(c) end end end") 1))
   (test-case "applyref exige variables ligadas a referencias"
              (check-exn exn:fail?
                         (lambda () (corre "let z = 1
                                            in let f = proc (u : refto(num)) deref(u) end
                                               in applyref f (z) end end"))))
   (test-case "applyref exige un procedimiento como operador"
              (check-exn exn:fail?
                         (lambda () (corre "let z = newref(1) in applyref 5 (z) end"))))))

;;; ==========================================================
;;; Chequeador
;;; ==========================================================

(define bien-tipados
  (test-suite
   "Parte 3: programas bien tipados"
   (test-case "procedimiento anotado"
              (check-equal? (tipo-de "proc (a : num, b : num) +(a, b) end") "(num * num -> num)"))
   (test-case "celda con lectura y escritura"
              (check-equal? (tipo-de "let celda = newref(0)
in
  begin
    setref(celda, 42);
    deref(celda)
  end
end") "num"))
   (test-case "newref anida los tipos"
              (check-equal? (tipo-de "newref(newref(true))") "refto(refto(bool))"))
   (test-case "swap devuelve el tipo de la celda"
              (check-equal? (tipo-de "let a = newref(1) b = newref(2) in swap(a, b) end") "num"))
   (test-case "letrec recursivo"
              (check-equal? (tipo-de "letrec num fact (k : num) =
                                        if ==(k, 0) then 1 else *(k, apply fact (sub1(k))) end
                                      in apply fact (5) end") "num"))
   (test-case "applyref con una celda"
              (check-equal? (tipo-de "let x = newref(1)
                                      in let f = proc (u : refto(num)) deref(u) end
                                         in applyref f (x) end end") "num"))
   (test-case "case con ramas del mismo tipo"
              (check-equal? (tipo-de "case n of 1 => 10 of 2 => 20 otherwise => 0 end") "num"))
   (test-case "procedimiento de orden superior"
              (check-equal? (tipo-de "proc (f : (num -> num), x : num) apply f (x) end")
                            "((num -> num) * num -> num)"))))

(define mal-tipados
  (test-suite
   "Parte 3: cada mensaje de error"
   (test-case "la condicion del if no es booleana"
              (check-true (contiene? (mensaje-de "if n then 1 else 2 end")
                                     "La condicion del if debe ser bool, se encontro num")))
   (test-case "las ramas del if no coinciden"
              (check-true (contiene? (mensaje-de "if >(n, m) then 1 else false end")
                                     "Las ramas del if deben coincidir: num vs bool")))
   (test-case "se aplica algo que no es procedimiento"
              (check-true (contiene? (mensaje-de "apply 5 (1)")
                                     "Se intento aplicar un valor de tipo num")))
   (test-case "aridad incorrecta"
              (check-true (contiene? (mensaje-de "let f = proc (a : num, b : num) +(a, b) end
                                                  in apply f (1) end")
                                     "El procedimiento espera 2 argumentos y recibio 1")))
   (test-case "argumento de tipo equivocado"
              (check-true (contiene? (mensaje-de "let f = proc (a : num) a end
                                                  in apply f (true) end")
                                     "El argumento 1 debe ser num, se encontro bool")))
   (test-case "deref sobre algo que no es referencia"
              (check-true (contiene? (mensaje-de "deref(5)")
                                     "deref espera refto(t), se encontro num")))
   (test-case "setref con tipos incompatibles"
              (check-true (contiene? (mensaje-de "let celda = newref(0)
                                                  in setref(celda, true) end")
                                     "La celda guarda num y se intento escribir bool")))
   (test-case "el cuerpo del letrec no da el tipo declarado"
              (check-true (contiene? (mensaje-de "letrec num f (k : num) = true
                                                  in apply f (1) end")
                                     "El procedimiento f declara num y su cuerpo da bool")))
   (test-case "identificador no declarado"
              (check-true (contiene? (mensaje-de "z") "Variable no declarada: z")))
   (test-case "applyref con una variable que no es referencia"
              (check-exn exn:fail?
                         (lambda () (tipo-de "let z = 1
                                              in let f = proc (u : refto(num)) deref(u) end
                                                 in applyref f (z) end end"))))))



;; pruebas extra de la parte 2: paso por referencia
(define parte-2-extra
  (test-suite
   "Parte 2: ejemplos extra de paso por referencia"
   (test-case "applyref incrementa la misma celda dos veces"
              (check-equal? (corre "let c = newref(0)
                                    in let inc = proc (u : refto(num))
                                                   setref(u, add1(deref(u)))
                                                end
                                       in begin applyref inc (c); applyref inc (c); deref(c) end
                                       end
                                    end") 2))
   (test-case "apply incrementa una copia y deja la celda original"
              (check-equal? (corre "let c = newref(0)
                                    in let inc = proc (u : refto(num))
                                                   setref(u, add1(deref(u)))
                                                end
                                       in begin apply inc (c); apply inc (c); deref(c) end
                                       end
                                    end") 0))
   (test-case "applyref intercambia dos celdas"
              (check-equal? (corre "let a = newref(1)
                                    b = newref(2)
                                    in let f = proc (u : refto(num), v : refto(num))
                                                 swap(u, v)
                                              end
                                       in begin applyref f (a, b); -(deref(a), deref(b)) end
                                       end
                                    end") 1))
   (test-case "applyref rechaza un argumento que no es referencia"
              (check-exn exn:fail?
                         (lambda () (corre "let z = true
                                            in let f = proc (u : refto(num)) deref(u) end
                                               in applyref f (z) end
                                            end"))))
   (test-case "applyref rechaza un operador que no es procedimiento"
              (check-exn exn:fail?
                         (lambda () (corre "let x = newref(1)
                                            in applyref true (x) end
                                            end"))))))

;;Pruebas de la Parte 3: 8 programas bien tipados
(define programas_bien_tipados
  (test-suite
   "Parte 3: programas bien tipados sin errores de tipamiento"

   (test-case "procedimiento con retorno booleano"
     (check-equal?
      (tipo-de "proc (x : num) >(x, 5) end")
      "(num -> bool)"))

   (test-case "if con resultado booleano"
     (check-equal?
      (tipo-de "if <(n, m) then true else false end")
      "bool"))

   (test-case "variable calculada dentro de let"
     (check-equal?
      (tipo-de "let resultado = *(n, p) in +(resultado, 10) end")
      "num"))

   (test-case "aplicacion de procedimiento con dos parametros"
     (check-equal?
      (tipo-de
       "let sumar = proc (x : num, y : num) +(x, y) end
        in apply sumar(+(2, 3), *(4, 2)) end")
      "num"))

   (test-case "referencia anidada"
     (check-equal?
      (tipo-de "newref(newref(+(3, 4)))")
      "refto(refto(num))"))

   (test-case "begin retorna booleano"
     (check-equal?
      (tipo-de
       "begin
          +(n, 5);
          *(m, 2);
          >(p, q)
        end")
      "bool"))

   (test-case "case con resultados booleanos"
     (check-equal?
      (tipo-de
       "case n
          of 1 => true
          of 2 => false
          otherwise => >(p, q)
        end")
      "bool"))

   (test-case "letrec con procedimiento recursivo"
     (check-equal?
      (tipo-de
       "letrec bool positivo(k : num) =
          if ==(k, 0)
          then false
          else if >(k, 0)
               then true
               else apply positivo(sub1(k))
               end
          end
        in apply positivo(5) end")
      "bool"))))

;;9  programas mal tipados con mensaje de error diferente en cada uno para cubrir los posibles casos de error solicitados
(define programas_mal_tipados
  (test-suite
   "Parte 3: programas mal tipados
     cada uno con su mensaje de error del chequeador estatico de tipos"

   (test-case "condicion numerica en if"
     (check-true
      (contiene?
       (mensaje-de "if +(n, 1) then true else false end")
       "La condicion del if debe ser bool, se encontro num")))

   (test-case "ramas incompatibles en if"
     (check-true
      (contiene?
       (mensaje-de "if true then >(n, m) else 15 end")
       "Las ramas del if deben coincidir: bool vs num")))

   (test-case "aplicacion sobre una variable numerica"
     (check-true
      (contiene?
       (mensaje-de "apply n(3)")
       "Se intento aplicar un valor de tipo num")))

   (test-case "aplicacion con argumentos insuficientes"
     (check-true
      (contiene?
       (mensaje-de
        "let operacion = proc (a : num, b : num, c : num)
                           +(+(a, b), c)
                         end
         in apply operacion(4, 5) end")
       "El procedimiento espera 3 argumentos y recibio 2")))

   (test-case "argumento booleano donde se espera numero"
     (check-true
      (contiene?
       (mensaje-de
        "let duplicar = proc (x : num) *(x, 2) end
         in apply duplicar(true) end")
       "El argumento 1 debe ser num, se encontro bool")))

   (test-case "deref sobre un booleano"
     (check-true
      (contiene?
       (mensaje-de "deref(true)")
       "deref espera refto(t), se encontro bool")))

   (test-case "escritura incompatible en una referencia"
     (check-true
      (contiene?
       (mensaje-de
        "let dato = newref(true)
         in setref(dato, 25) end")
       "La celda guarda bool y se intento escribir num")))

   (test-case "retorno incorrecto en procedimiento recursivo"
     (check-true
      (contiene?
       (mensaje-de
        "letrec bool verificar(x : num) = +(x, 1)
         in apply verificar(4) end")
       "El procedimiento verificar declara bool y su cuerpo da num")))

   (test-case "variable inexistente"
     (check-true
      (contiene?
       (mensaje-de "variable_inexistente")
       "Variable no declarada: variable_inexistente")))))

;;; ==========================================================
;;; Pruebas extra: aridad de primitivas en el chequeador
;;; ==========================================================

;; aridad-primitivas-extra : test-suite
;; Comprueba que el chequeador exija las mismas cantidades de argumentos
;; que el interprete para and, or, mcd y mcm.
(define aridad-primitivas-extra
  (test-suite
   "Parte 3: aridad de primitivas"

   ;; Cuatro programas que deben rechazarse por aridad insuficiente.
   (test-case "and rechaza un solo argumento"
              (check-true
               (contiene? (mensaje-de "and(true)")
                          "La primitiva and espera 2 argumentos y recibio 1")))
   (test-case "or rechaza un solo argumento"
              (check-true
               (contiene? (mensaje-de "or(true)")
                          "La primitiva or espera 2 argumentos y recibio 1")))
   (test-case "mcd rechaza un solo argumento"
              (check-true
               (contiene? (mensaje-de "mcd(6)")
                          "La primitiva mcd espera al menos 2 argumentos y recibio 1")))
   (test-case "mcm rechaza un solo argumento"
              (check-true
               (contiene? (mensaje-de "mcm(6)")
                          "La primitiva mcm espera al menos 2 argumentos y recibio 1")))

   ;; Cuatro programas validos: deben conservar su tipo de retorno.
   (test-case "and con dos argumentos"
              (check-equal? (tipo-de "and(true, false)") "bool"))
   (test-case "or con dos argumentos"
              (check-equal? (tipo-de "or(true, false)") "bool"))
   (test-case "mcd con dos argumentos"
              (check-equal? (tipo-de "mcd(6, 12)") "num"))
   (test-case "mcm con dos argumentos"
              (check-equal? (tipo-de "mcm(6, 12)") "num"))))

(define fallidas
  (+ (run-tests almacen)
     (run-tests ejemplos-parte-1)
     (run-tests paso-por-referencia)
     (run-tests parte-2-extra)
     (run-tests bien-tipados)
     (run-tests mal-tipados)
     (run-tests programas_bien_tipados)
     (run-tests programas_mal_tipados)
     (run-tests aridad-primitivas-extra)
     ))

(eopl:printf "~%==========================================~%")
(eopl:printf "  pruebas fallidas en total: ~s~%" fallidas)
(eopl:printf "==========================================~%")
