Informe de corrección — Taller 3: Memoria y disciplina
Curso: Fundamentos de Interpretación y Compilación de Lenguajes de Programación
Institución: Universidad del Valle, Sede Tuluá

Integrantes del grupo:
| Nombre completo | Código | Correo institucional |
|---|---|---|
| Andres Felipe Quiceno Gil | 2477362 | quiceno.andres@correounivalle.edu.co |
| Yonier Alejandro Vega Rojas | 2477056 | yonier.vega@correounivalle.edu.co |
| Jhon Fabricio Hurtado Marin | 2459472 | hurtado.jhoan@correounivalle.edu.co |
| Juan Esteban Aguirre Castañeda | 2459676 | juan.esteban.aguirre@correounivalle.edu.co |


1. Marco formal
1.1 Corrección de programas recursivos
Sea F: A\to B$ una función definida sobre estructuras recursivas, y sea $P_f$ su implementación. Para las entradas del dominio en las que el algoritmo termina, la corrección funcional se expresa como:
\[
\forall a\in A,\quad P_f(a)\downarrow\ \Longrightarrow\ P_f(a)=f(a).
\]
La notación $P_f(a)\downarrow$ indica que el cálculo termina. Para justificar esta propiedad usamos inducción estructural: primero demostramos los casos básicos y después los casos compuestos, suponiendo que las llamadas recursivas sobre las subestructuras satisfacen la especificación. En este taller aplicamos ese razonamiento a reemplazar-en, que recorre una lista, y a las reglas de tipado, que siguen la estructura de las expresiones del lenguaje.

La terminación se justifica por separado, identificando una medida que disminuya en las llamadas recursivas. En reemplazar-en, cuando el índice es válido, disminuyen la posición pendiente y la longitud de la cola por procesar.
1.2 Corrección de programas iterativos
Para una transformación de estados, una invariante $\operatorname{Inv}(s)$ se utiliza mediante cuatro elementos:
1. Inicialización: el estado inicial $s_0$ satisface $\operatorname{Inv}(s_0)$.
2. Preservación: si el estado actual satisface la invariante, cada operación permitida produce otro estado que también la satisface.
3. Postcondición: al terminar, la invariante y la condición de finalización permiten establecer el resultado esperado.
4. Terminación: si existe un ciclo, se demuestra que alguna medida bien fundada disminuye hasta alcanzar su condición de salida.
Aunque el almacén del proyecto no se implementa como un ciclo iterativo, podemos razonar sobre una secuencia de operaciones que va modificando su estado. La idea de invariante es la misma: comprobar que newref!, setref! y deref respetan las propiedades requeridas después de cada operación.
2. Funciones analizadas
Para las demostraciones representamos el almacén inicializado como una lista finita
\[
\sigma=[v_0,v_1,\ldots,v_{n-1}],\qquad n=|\sigma|,
\]
y una referencia como a-ref(i), donde $i$ es la posición de una celda. Los índices válidos pertenecen al conjunto ${0,\ldots,n-1}$.
2.1 Corrección de newref!
Especificación
- Contrato: newref! : valor -> referencia.
- Precondición: el almacén $\sigma$ está inicializado, es finito y cumple las propiedades del almacén.
- Postcondición: para un valor $v$, si $n=|\sigma|$, se devuelve $\ell=\operatorname{a\text{-}ref}(n)$ y el nuevo almacén cumple:
\[
|\sigma'|=n+1,\qquad
\sigma'(n)=v,\qquad
\forall i\ (0\leq i<n\Rightarrow\sigma'(i)=\sigma(i)).
\]
Implementación en src/almacen.rkt:
(define newref!
  (lambda (val)
    (let ((pos (length the-store)))
      (set! the-store (append the-store (list val)))
      (a-ref pos))))
Demostración. Antes de ejecutar newref!, el almacén contiene $n$ celdas y su última posición es $n-1$. La función calcula pos como $n$ y agrega el valor al final mediante append. Por la definición de concatenación de listas,
\[
\sigma'=\sigma\mathbin{+\!+}[v],\qquad |\sigma'|=n+1.
\]
Las primeras $n$ posiciones conservan sus contenidos y la posición nueva $n$ contiene $v$. Por tanto, la referencia devuelta, a-ref(n), es válida porque $0\leq n<n+1$.

Terminación. Las operaciones length y append trabajan sobre listas finitas y terminan después de recorrer una cantidad finita de elementos. La función no realiza llamadas recursivas propias.

Conclusión. newref! agrega exactamente una celda, retorna una referencia válida y conserva todas las celdas existentes.
2.2 Corrección de setref!
Especificación
- Contrato: setref! : referencia × valor -> void (el resultado de la asignación no se usa como valor del lenguaje).
- Precondición: $\ell=\operatorname{a\text{-}ref}(i)$ y $0\leq i<|\sigma|$.
- Postcondición: la longitud no cambia y solamente se actualiza la posición indicada:
\[
|\sigma'|=|\sigma|,\qquad
\sigma'(j)=
\begin{cases}
v, & j=i,\\
\sigma(j), & j\ne i.
\end{cases}
\]
Implementación en src/almacen.rkt:
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
Estrategia: inducción sobre la posición $i$ de reemplazar-en.

Caso base ($i=0$). La expresión (cons val (cdr lst)) sustituye el primer elemento por $v$ y mantiene intacta la cola. La lista resultante tiene la misma longitud que la original.

Caso inductivo ($i>0$). La función conserva (car lst) y aplica reemplazar-en sobre (cdr lst) con índice $i-1$. Por hipótesis inductiva, en esa cola se cambia exactamente la posición indicada y se conservan las demás. Al reconstruir la lista con cons, también se conserva el primer elemento. Por ello, en la lista completa solo cambia la celda $i$.

Terminación. En cada llamada recursiva se reduce el índice de búsqueda en una unidad y se procesa una cola más corta. Como el índice es válido, se alcanza el caso $i=0$ antes de agotar la lista.

Caso de error. Si $i<0$ o $i\geq|\sigma|$, posicion-valida? devuelve falso. Entonces setref! ejecuta eopl:error sin modificar the-store.

Conclusión. Para toda referencia válida, setref! preserva la longitud del almacén y modifica únicamente la celda solicitada.
2.3 Corrección de deref
Especificación
- Contrato: deref : referencia -> valor.
- Precondición de lectura exitosa: $\ell=\operatorname{a\text{-}ref}(i)$ y $0\leq i<|\sigma|$.
- Postcondición: devuelve $\sigma(i)$ sin cambiar el almacén:
\[
\operatorname{deref}(\sigma,\ell)=\sigma(i),\qquad\sigma'=\sigma.
\]
Implementación en src/almacen.rkt:
(define deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (list-ref the-store pos)
            (eopl:error 'deref
                        "Referencia fuera de rango: ~s" pos))))))
Demostración. Si la posición $i$ es válida, list-ref recupera exactamente el elemento en esa posición. La función no ejecuta ninguna asignación ni llama a operaciones que escriban en el almacén, por lo que $\sigma'=\sigma$.

Si $i$ está fuera de rango, el código ejecuta eopl:error y evita invocar list-ref con una posición inválida. La lectura de una posición válida termina porque la lista es finita.

Conclusión. deref lee el contenido correcto sin modificar el almacén y rechaza mediante eopl:error las referencias cuya posición está fuera de rango.
3. Propiedades adicionales
3.1 Invariante del almacén (Parte 5.1)
Consideramos una ejecución iniciada con initialize-store! y formada por operaciones válidas sobre el almacén. Las cuatro propiedades exigidas describen tanto sus estados alcanzables como el comportamiento de las operaciones:
1. Validez de referencias nuevas. Cada referencia que devuelve newref! apunta a una posición existente inmediatamente después de la reserva. Como las operaciones posteriores no reducen el almacén dentro de la misma ejecución, continúa siendo válida.
2. Crecimiento controlado. Entre operaciones ordinarias del almacén, solo newref! aumenta su longitud y lo hace en exactamente una celda. setref! y deref mantienen esa longitud.
3. Escritura localizada. Si $\ell=\operatorname{a\text{-}ref}(i)$ es válida, entonces la transición producida por setref! satisface:
   \[
   \sigma'(i)=v\quad\land\quad
   \forall j\,\bigl(0\leq j<|\sigma|\land j\ne i\Rightarrow\sigma'(j)=\sigma(j)\bigr).
   \]
4. Lectura segura. Si $i\notin{0,\ldots,|\sigma|-1}$, la llamada deref(a-ref(i)) provoca eopl:error en lugar de leer fuera de los límites.
Inicialización. initialize-store! establece $\sigma_0=[]$. Todavía no se han creado referencias de esta ejecución y no existen celdas que puedan haber sido modificadas. La inicialización es un reinicio entre ejecuciones de programas, no una operación ordinaria de crecimiento.

Preservación. Por la sección 2.1, newref! agrega una única celda y produce una referencia válida sin alterar las anteriores. Por la sección 2.2, setref! cambia solamente la posición indicada. Por la sección 2.3, deref consulta una posición válida sin escribir y produce un error explícito cuando el índice no es válido.

Por inducción sobre el número de operaciones de una ejecución, estas propiedades se mantienen en todos los estados alcanzables. En particular, las referencias creadas durante una ejecución no quedan fuera de rango por una lectura o escritura posterior.
3.2 Corrección de swap-exp (Parte 5.2)
Especificación. Una vez evaluados los dos operandos de swap, sean $\ell_1=\operatorname{a\text{-}ref}(i)$ y $\ell_2=\operatorname{a\text{-}ref}(j)$ sus referencias y sea $\sigma$ el almacén en ese momento. Si ambas referencias son válidas, el resultado debe cumplir:
\[
\sigma'(i)=\sigma(j),\qquad
\sigma'(j)=\sigma(i),\qquad
\forall k\notin\{i,j\},\ \sigma'(k)=\sigma(k).
\]
El valor retornado debe ser el contenido anterior de la segunda celda, es decir, $\sigma(j)$, y la longitud del almacén debe permanecer igual.

La especificación se toma después de evaluar los operandos porque estos, al ser expresiones, podrían producir cambios en el almacén antes del intercambio.

Implementación verificada en src/interprete.rkt:
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
Demostración cuando $i\ne j$. Llamemos $a=\sigma(i)$ y $b=\sigma(j)$. La implementación guarda ambos valores antes de hacer cualquier escritura: v1 = a y v2 = b.
- La instrucción (setref! r1 v2) deja $\sigma_1(i)=b$ y, como $i\ne j$, conserva $\sigma_1(j)=a$.
- La instrucción (setref! r2 v1) deja $\sigma'(j)=a$ sin modificar el nuevo contenido de $i$, por lo que $\sigma'(i)=b$.
- Por la escritura localizada de setref!, toda posición $k\notin{i,j}$ conserva su valor y la longitud no cambia.
Ningún valor original se pierde: tanto $a$ como $b$ fueron almacenados en v1 y v2 antes de efectuar las escrituras. Finalmente, la expresión devuelve v2, que sigue siendo $b=\sigma(j)$.

Caso $i=j$ (aliasing). Si ambas referencias apuntan a la misma celda, las dos lecturas obtienen el mismo valor $a=\sigma(i)$. Las instrucciones (setref! r1 v2) y (setref! r2 v1) escriben nuevamente $a$ en esa posición. Así,
\[
\sigma'=\sigma,\qquad\operatorname{valor\ retornado}=a.
\]
Este caso también satisface la especificación: intercambiar una celda consigo misma no altera su contenido y el resultado sigue siendo el antiguo valor de la segunda referencia.

Operandos inválidos. Si cualquiera de los resultados evaluados no es una referencia, el if ejecuta eopl:error en lugar de efectuar el intercambio. La comprobación ocurre antes de las dos llamadas a deref y setref!.

Conclusión. Contrastamos la demostración con el caso swap-exp implementado por Yonier en src/interprete.rkt: se evalúan los operandos, se comprueba que sean referencias, se guardan los dos contenidos originales, se intercambian mediante setref! y se retorna el segundo valor original. Por las propiedades del almacén, la implementación cumple el intercambio, conserva las demás celdas y maneja correctamente el aliasing.
3.3 Solidez del chequeador de tipos (Parte 5.3)
Enunciado para el fragmento sin referencias. Si el ambiente de tipos $\Gamma$ permite derivar que una expresión $e$ tiene tipo $t$, y el ambiente de valores $\rho$ concuerda con $\Gamma$, entonces una evaluación que termina normalmente produce un valor del tipo indicado:
\[
\Gamma\vdash e:t\ \land\ \rho\models\Gamma
\quad\Longrightarrow\quad
\operatorname{value\text{-}of}(e,\rho)\in\llbracket t\rrbracket,
\quad\text{si la evaluación termina normalmente}.
\]
La condición de terminación es importante porque letrec permite definir procedimientos recursivos; el tipado correcto no garantiza que todos los programas terminen.

Concordancia entre ambientes. Escribimos $\rho\models\Gamma$ si, para cada identificador $x$ declarado en $\Gamma$, el ambiente $\rho$ le asigna un valor que corresponde a $\Gamma(x)$. Un valor de tipo num es numérico, uno de tipo bool es booleano y una clausura con tipo de procedimiento acepta valores de los tipos de sus parámetros y, si su cuerpo termina normalmente bajo un ambiente concordante, devuelve un valor del tipo de retorno.

El argumento informal procede por inducción sobre la derivación de tipado. Presentamos los casos solicitados.

Caso if. La regla exige una condición booleana y dos ramas con el mismo tipo:
\[
\frac{\Gamma\vdash e_1:\mathrm{bool}\qquad
      \Gamma\vdash e_2:t\qquad
      \Gamma\vdash e_3:t}
     {\Gamma\vdash \mathrm{if}\ e_1\ \mathrm{then}\ e_2\ \mathrm{else}\ e_3\ \mathrm{end}:t}.
\]
Por hipótesis inductiva, una evaluación normal de $e_1$ produce un booleano. El intérprete selecciona una sola rama de acuerdo con ese valor. Como ambas ramas fueron verificadas con tipo $t$, la hipótesis inductiva garantiza que la rama ejecutada devuelve un valor de tipo $t$, siempre que termine normalmente. Por tanto, la evaluación del if conserva el tipo establecido por el chequeador.

Caso apply. Si el operador tiene tipo de procedimiento y cada argumento posee el tipo esperado, la aplicación tiene el tipo del resultado:
\[
\frac{\Gamma\vdash f:(t_1\times\cdots\times t_n\to t)\qquad
      \Gamma\vdash e_i:t_i\quad (1\leq i\leq n)}
     {\Gamma\vdash \operatorname{apply}\ f(e_1,\ldots,e_n):t}.
\]
Por hipótesis inductiva, el operador evaluado es una clausura compatible con el tipo declarado y los argumentos evaluados corresponden a los tipos $t_1,\ldots,t_n$. El intérprete extiende el ambiente capturado por la clausura con los parámetros y sus valores. En el fragmento sin referencias, la copia por valor no cambia sus tipos. El ambiente extendido sigue siendo concordante con los tipos de los parámetros, por lo que la hipótesis inductiva aplicada al cuerpo permite concluir que su resultado, si termina normalmente, pertenece al tipo $t$.

¿Qué cambia al incorporar referencias? Con referencias, la concordancia de $\rho$ con $\Gamma$ no es suficiente: una variable puede contener una referencia cuyo contenido cambia durante la ejecución. Hace falta un tipado del almacén $\Sigma$, que asigne tipos a las posiciones almacenadas, y una relación de consistencia entre los ambientes, las referencias y el almacén:
\[
\rho,\sigma\models\Gamma,\Sigma,
\qquad
\forall i\in\operatorname{dom}(\Sigma),\quad
\sigma(i)\in\llbracket\Sigma(i)\rrbracket.
\]
Así, una referencia de tipo $\operatorname{refto}(t)$ debe apuntar a una posición registrada en $\Sigma$ cuyo contenido tenga tipo $t$. En una demostración de solidez para el lenguaje completo, newref extiende de manera coherente el almacén y $\Sigma$; setref preserva el tipo de una celda; y swap requiere que los contenidos intercambiados tengan tipos compatibles.

Conclusión. Los casos if y apply muestran cómo las reglas del chequeador y la evaluación preservan el tipo de las expresiones en el fragmento sin referencias. Esta es una justificación informal de los casos solicitados, no una demostración exhaustiva de todos los constructores. El argumento presupone que las reglas de tipado de las primitivas y sus controles de ejecución son compatibles. Para extenderlo al lenguaje con referencias es necesario mantener, además, la consistencia entre $\sigma$ y $\Sigma$.
4. Referencias
- Delgado S., C. A. (2026). Taller 3: Memoria y disciplina. Fundamentos de Interpretación y Compilación de Lenguajes de Programación, Universidad del Valle.
- Friedman, D. P., & Wand, M. (2008). Essentials of Programming Languages (3.ª ed.). MIT Press. Capítulo 4, secciones 4.2 y 4.3; capítulo 7, secciones 7.1 a 7.3.
- Pierce, B. C. (2002). Types and Programming Languages. MIT Press. Capítulos 8 y 13.