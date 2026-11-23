Informe de corrección — Taller 3: Memoria y disciplina
Curso: Fundamentos de Interpretación y Compilación de Lenguajes de Programación — Universidad del Valle, Sede Tuluá.


**Integrantes del grupo:**

| Nombre completo | Código | Correo institucional |
|---|---|---|
| Andres Felipe Quiceno Gil | 2477362 | quiceno.andres@correounivalle.edu.co |
| Yonier Alejandro Vega Rojas | 2477056 | yonier.vega@correounivalle.edu.co |
| Jhon Fabricio Hurtado Marin | 2459472 | hurtado.jhoan@correounivalle.edu.co |
| Juan Esteban Aguirre Castañeda | 2459676 | juan.esteban.aguirre@correounivalle.edu.co |


1. Marco formal
1.1 Corrección de programas recursivos
Sea $f : A \to B$ una función sobre un conjunto definido recursivamente, y sea $P_f$ una implementación. La corrección se expresa como:
\[
\forall a \in A,\quad P_f(a)=f(a).
\]
La inducción estructural demuestra primero los casos básicos y después los casos compuestos, suponiendo que las llamadas sobre subestructuras cumplen la especificación. Esta idea se utiliza para razonar sobre expresiones y derivaciones de tipos, cuya estructura es recursiva.
1.2 Corrección de programas iterativos
Para un estado inicial $s_0$, una transformación de estados y una condición de finalización, una invariante $\operatorname{Inv}(s)$ debe cumplir:
1. Inicialización: $\operatorname{Inv}(s_0)$.
2. Preservación: si $\operatorname{Inv}(s)$ y se ejecuta un paso válido, el nuevo estado también cumple la invariante.
3. Corrección al finalizar: el estado final satisface la postcondición.
4. Terminación: si hay iteraciones, se justifica una medida natural que disminuye estrictamente.
En este taller el almacén no se implementa como un ciclo iterativo: se estudia como una sucesión de operaciones que transforman su estado. Por eso demostramos que cada operación preserva la invariante. La terminación de las operaciones sobre listas se razona mediante la longitud de la lista pendiente.
2. Funciones analizadas
2.1 Corrección de newref!
Especificación.
- Tipo: newref! : valor -> referencia.
- Precondición: el almacén $\sigma$ está inicializado, es finito y satisface $\operatorname{Inv}(\sigma)$.
- Postcondición: si $n=|\sigma|$ y $\ell$ es la referencia retornada, entonces $\ell=\operatorname{a\text{-}ref}(n)$, $|\sigma'|=n+1$, $\sigma'(n)=v$ y $\sigma'(i)=\sigma(i)$ para $0\leq i<n$.
Código del módulo src/almacen.rkt:
(define newref!
  (lambda (val)
    (let ((pos (length the-store)))
      (set! the-store (append the-store (list val)))
      (a-ref pos))))
Estrategia de demostración: razonamiento sobre la operación de agregar un elemento al final de una lista.

Demostración. Antes de ejecutar newref!, la lista tiene $n$ celdas, con índices de $0$ a $n-1$. append conserva esos $n$ elementos en el mismo orden y añade val al final. Por tanto:
\[
\sigma'=\sigma\mathbin{+\!+}[v],\qquad |\sigma'|=n+1.
\]
La referencia construida es a-ref con posición $n$, que ahora está dentro del rango $0\leq n<n+1$. Ninguna posición anterior cambia de valor. La única modificación de longitud durante la ejecución ordinaria del almacén es esta reserva.

Terminación. length y append recorren listas finitas; su cantidad de elementos pendientes disminuye hasta llegar a la lista vacía.

Conclusión. newref! crea exactamente una celda, devuelve una referencia válida y conserva las anteriores.
2.2 Corrección de setref!
Especificación.
- Tipo: setref! : referencia × valor -> void.
- Precondición: $\ell=\operatorname{a\text{-}ref}(i)$ con $0\leq i<|\sigma|$.
- Postcondición: $|\sigma'|=|\sigma|$ y:
\[
\sigma'(j)=
\begin{cases}
v, & j=i,\\
\sigma(j), & j\neq i.
\end{cases}
\]
Código del módulo src/almacen.rkt:
(define reemplazar-en
  (lambda (lst pos val)
    (if (zero? pos)
        (cons val (cdr lst))
        (cons (car lst)
              (reemplazar-en (cdr lst) (- pos 1) val)))))

(define setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (set! the-store (reemplazar-en the-store pos val))
            (eopl:error 'setref!
                        "Referencia fuera de rango: ~s" pos))))))
Estrategia de demostración: inducción sobre la posición $i$ en reemplazar-en.

Caso base ($i=0$). La función construye (cons val (cdr lst)): reemplaza la cabeza y conserva exactamente la cola. La longitud no cambia y las posiciones posteriores mantienen sus valores.

Caso inductivo ($i>0$). Se conserva (car lst) y se llama recursivamente a reemplazar-en sobre (cdr lst) con índice $i-1$. Por hipótesis inductiva, en la cola se reemplaza solamente esa posición, sin modificar las demás. Al reconstruir la lista con cons, también se conserva la primera celda. Así, en la lista original cambia únicamente la posición $i$.

Terminación. En cada llamada recursiva disminuyen tanto el índice no negativo como la longitud de la lista restante. La precondición garantiza que se llega al caso $i=0$ antes de agotar la lista.

Caso de error. Si $i<0$ o $i\geq|\sigma|$, posicion-valida? es falso y setref! produce eopl:error sin ejecutar la asignación.

Conclusión. setref! preserva la longitud y modifica exclusivamente la celda indicada.
2.3 Corrección de deref
Especificación.
- Tipo: deref : referencia -> valor.
- Precondición para una lectura exitosa: $\ell=\operatorname{a\text{-}ref}(i)$ con $0\leq i<|\sigma|$.
- Postcondición: retorna $\sigma(i)$ y el almacén queda igual: $\sigma'=\sigma$.
Código del módulo src/almacen.rkt:
(define deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (list-ref the-store pos)
            (eopl:error 'deref
                        "Referencia fuera de rango: ~s" pos))))))
Demostración. Si la posición es válida, list-ref obtiene el elemento en el índice indicado. La función no ejecuta set! ni llama a ninguna operación de escritura; por tanto, el estado posterior es el mismo:
\[
\operatorname{deref}(\sigma,\ell)=\sigma(i),\qquad \sigma'=\sigma.
\]
Si la posición no está en el rango permitido, se ejecuta eopl:error y no se realiza lectura fuera de los límites. list-ref termina porque la lista es finita y el índice es válido.

Conclusión. deref devuelve el contenido correcto sin alterar el almacén y rechaza referencias fuera de rango.
3. Propiedades adicionales
3.1 Invariante del almacén (Parte 5.1)
Representamos el almacén inicializado como una lista finita $\sigma=[v_0,v_1,\ldots,v_{n-1}]$ y una referencia como $\operatorname{a\text{-}ref}(i)$. El invariante $\operatorname{Inv}(\sigma)$ reúne las cuatro condiciones del enunciado:
1. Referencias válidas al reservar: cada referencia entregada por newref! identifica una posición existente, es decir, $0\leq i<|\sigma|$ inmediatamente después de reservarla.
2. Crecimiento controlado: durante la ejecución de un programa, solo newref! aumenta la longitud; setref! y deref la conservan.
3. Escritura localizada: si $\sigma'=\operatorname{setref!}(\sigma,\ell,v)$ y $\ell=\operatorname{a\text{-}ref}(i)$ es válida, entonces:
   \[
   \sigma'(i)=v\quad\land\quad
   \forall j\neq i,\ 0\leq j<|\sigma|\Rightarrow\sigma'(j)=\sigma(j).
   \]
4. Lectura segura: si $i\notin{0,\ldots,|\sigma|-1}$, deref(a-ref(i)) levanta eopl:error.
Inicialización. initialize-store! deja $\sigma_0=[]$. No existen referencias entregadas por newref! en ese programa, así que la primera condición se cumple vacíamente. Las demás se satisfacen porque no hay celdas ni escrituras. La inicialización es un reinicio entre programas, no una operación de crecimiento dentro de un programa.

Preservación. Las demostraciones de las secciones 2.1, 2.2 y 2.3 establecen, respectivamente, que reservar crea una referencia válida sin cambiar las celdas previas; escribir modifica una sola celda; y leer no modifica ninguna. Por inducción sobre una secuencia finita de operaciones válidas, $\operatorname{Inv}(\sigma)$ se conserva después de cada paso.
3.2 Corrección de swap-exp (Parte 5.2)
Especificación. Sean $\ell_1=\operatorname{a\text{-}ref}(i)$ y $\ell_2=\operatorname{a\text{-}ref}(j)$ dos referencias válidas. Si el almacén inicial es $\sigma$ y el final es $\sigma'$, se exige:
\[
\sigma'(i)=\sigma(j),\qquad
\sigma'(j)=\sigma(i),\qquad
\forall k\notin\{i,j\},\ \sigma'(k)=\sigma(k).
\]
Además, el valor retornado debe ser el contenido anterior de la segunda celda, $\sigma(j)$.

Secuencia de operaciones que debe implementar swap-exp:
; Esquema de la operación, no código verificado del intérprete.
; Después de evaluar ambos operandos y comprobar referencia?:
(let ((anterior-primera (deref ref1))
      (anterior-segunda (deref ref2)))
  (setref! ref1 anterior-segunda)
  (setref! ref2 anterior-primera)
  anterior-segunda)
Demostración para $i\neq j$. Denotemos $a=\sigma(i)$ y $b=\sigma(j)$. Primero se guardan ambos valores en variables locales, antes de modificar el almacén. La primera escritura deja $\sigma_1(i)=b$ y mantiene $\sigma_1(j)=a$. La segunda escritura deja $\sigma'(j)=a$ y, como $i\neq j$, conserva $\sigma'(i)=b$. Por la propiedad de setref!, ninguna otra celda cambia. El valor $a$ no se pierde porque fue guardado antes de la primera escritura. La expresión final retorna $b=\sigma(j)$.

Caso $i=j$ (alias de la misma celda). Ambas lecturas obtienen el mismo valor $a=\sigma(i)$. Las dos escrituras vuelven a guardar $a$ en esa única celda, de modo que $\sigma'=\sigma$. La expresión retorna $a$, que es también el contenido anterior de la segunda referencia. Por tanto, la especificación se cumple incluso al intercambiar una referencia consigo misma.

Conclusión. La secuencia presentada satisface el intercambio, conserva las otras celdas y retorna el contenido anterior de la segunda. Esta demostración deberá contrastarse con el código definitivo de swap-exp en src/interprete.rkt cuando se integre.
3.3 Solidez del chequeador de tipos (Parte 5.3)
Enunciado para el fragmento sin referencias. Si $\Gamma\vdash e:t$ y el ambiente de valores $\rho$ concuerda con $\Gamma$, entonces, si la evaluación de $e$ termina normalmente, su resultado es un valor del tipo $t$:
\[
\Gamma\vdash e:t\ \land\ \rho\models\Gamma
\quad\Longrightarrow\quad
\operatorname{value\text{-}of}(e,\rho)\in\llbracket t\rrbracket.
\]
La condición de terminación evita afirmar que todo programa bien tipado termina, ya que letrec permite recursión.

Concordancia de ambientes. Escribimos $\rho\models\Gamma$ cuando, para cada identificador $x$ declarado en $\Gamma$, el valor ligado a $x$ en $\rho$ pertenece a la interpretación del tipo $\Gamma(x)$. Para num se consideran valores numéricos y para bool, valores booleanos. Una clausura tiene tipo $t_1*\cdots*t_n\to t$ cuando acepta argumentos de los tipos indicados y su cuerpo, bajo un ambiente concordante extendido con ellos, produce un valor de tipo $t$ si termina normalmente.

Caso if. La regla de tipado exige:
\[
\frac{\Gamma\vdash e_1:\mathrm{bool}\qquad
      \Gamma\vdash e_2:t\qquad
      \Gamma\vdash e_3:t}
     {\Gamma\vdash \mathrm{if}\ e_1\ \mathrm{then}\ e_2\ \mathrm{else}\ e_3\ \mathrm{end}:t}.
\]
Por hipótesis inductiva, si la evaluación de $e_1$ termina, produce un booleano. Por ello se selecciona una de las dos ramas. Ambas tienen tipo $t$ y, por hipótesis inductiva, la rama elegida produce un valor de tipo $t$ si termina. En consecuencia, el if conserva el tipo anunciado.

Caso apply. La regla exige que el operador tenga un tipo de procedimiento y que cada argumento coincida con su parámetro:
\[
\frac{\Gamma\vdash f:(t_1*\cdots*t_n\to t)\qquad
      \Gamma\vdash e_i:t_i\ (1\leq i\leq n)}
     {\Gamma\vdash\operatorname{apply}\ f(e_1,\ldots,e_n):t}.
\]
Por hipótesis inductiva, el operador produce una clausura del tipo declarado y cada argumento evaluado produce un valor del tipo correspondiente. Al extender el ambiente de la clausura con los parámetros y esos valores, se mantiene la concordancia con el ambiente de tipos del cuerpo. La hipótesis inductiva aplicada al cuerpo garantiza que, si termina, el resultado es de tipo $t$. Por tanto, apply preserva el tipo de retorno.

¿Qué cambia al agregar referencias? La concordancia entre $\rho$ y $\Gamma$ ya no basta: una variable puede contener una referencia a una celda cuyo contenido cambia. Es necesario incorporar un tipado del almacén $\Sigma$, que asocia a cada posición su tipo, y exigir:
\[
\rho,\sigma\models\Gamma,\Sigma
\quad\text{y}\quad
\forall i\in\operatorname{dom}(\Sigma),\ 
\sigma(i)\in\llbracket\Sigma(i)\rrbracket.
\]
Así, una referencia de tipo $\operatorname{refto}(t)$ debe apuntar a una celda registrada en $\Sigma$ con tipo $t$. newref amplía el almacén y su tipado; setref solo puede escribir un valor del tipo de la celda; swap exige referencias compatibles. Sin esa condición, el ambiente podría seguir asignando a una variable el tipo refto(num) aunque su celda contuviera un booleano, invalidando la garantía de tipos.

Conclusión. En el fragmento funcional, las reglas de if y apply preservan los tipos bajo ambientes concordantes. Con referencias, la propiedad de solidez debe incluir también la concordancia del almacén con su tipado.
4. Referencias
- Delgado S., C. A. (2026). Taller 3: Memoria y disciplina. Fundamentos de Interpretación y Compilación de Lenguajes de Programación, Universidad del Valle.
- Friedman, D. P., & Wand, M. (2008). Essentials of Programming Languages (3.ª ed.). MIT Press. Capítulo 4, secciones 4.2 y 4.3; capítulo 7, secciones 7.1 a 7.3.
- Pierce, B. C. (2002). Types and Programming Languages. MIT Press. Capítulos 8 y 13.