Taller 3 — Cauca con referencias y tipos
Curso: Fundamentos de Interpretación y Compilación de Lenguajes de Programación
Institución: Escuela de Ingeniería de Sistemas y Computación, Universidad del Valle
Docente: Carlos Andrés Delgado Saavedra

Este proyecto amplía el lenguaje Cauca con un almacén de memoria indexado por referencias, operaciones de lectura y escritura, intercambio de contenidos, paso por referencia y chequeo estático de tipos. La implementación se desarrolló en Racket con #lang eopl, utilizando SLLGEN para el análisis sintáctico.

Las operaciones incorporadas son newref, deref, setref, swap y begin. También se incluye applyref, que permite compartir las referencias originales entre el procedimiento y quien lo invoca. Por su parte, el chequeador recorre el AST y analiza los tipos sin ejecutar el programa.

El enunciado completo, las especificaciones y las rúbricas del taller se encuentran en el Campus Virtual.
Integrantes del grupo:
| Nombre completo | Código | Correo institucional |
|---|---|---|
| Andres Felipe Quiceno Gil | 2477362 | quiceno.andres@correounivalle.edu.co |
| Yonier Alejandro Vega Rojas | 2477056 | yonier.vega@correounivalle.edu.co |
| Jhon Fabricio Hurtado Marin | 2459472 | hurtado.jhoan@correounivalle.edu.co |
| Juan Esteban Aguirre Castañeda | 2459676 | juan.esteban.aguirre@correounivalle.edu.co |


Cómo se entrega
1. La entrega se realiza desde un fork público del repositorio original del taller. De acuerdo con el enunciado, entregar un repositorio que no sea un fork implica una penalización del 30 %.
2. Se entrega el enlace del fork en la actividad del Campus Virtual, no un archivo comprimido ni una copia del código por correo.
3. Fecha límite: lunes 23 de noviembre de 2026 a las 17:58:59. Se toma en cuenta el último commit anterior a ese momento.
4. La entrega incluye archivos .rkt en la raíz y en src/, e informes .md en docs/. Las fórmulas se escriben en LaTeX y los diagramas en Mermaid dentro del Markdown; no se entregan PDF, DOCX ni imágenes insertadas.
5. Los archivos .rkt deben incluir los autores y sus códigos en las primeras líneas, así como los contratos y propósitos de las funciones.
6. El historial de commits permite identificar los aportes de cada integrante. Según las condiciones del taller, los cambios exclusivamente de formato o comentarios no constituyen aportes de implementación.
La tabla de integrantes debe mantenerse completa: el enunciado establece una penalización del 20 % si falta o está incompleta.
Cómo está organizado
src/
  sintaxis.rkt              Léxico, gramática, datatypes, scanner y parser con SLLGEN
  almacen.rkt               TAD referencia, inicialización y operaciones del almacén
  ambiente.rkt              Ambientes de valores, clausuras y búsqueda de identificadores
  primitivas.rkt            Evaluación de primitivas y validación de argumentos
  interprete.rkt            Evaluación de expresiones, procedimientos y paso por referencia
  tipos.rkt                 Tipos, ambientes de tipos y tipos de primitivas
  chequeador.rkt            Chequeo estático de expresiones y programas

interprete-cauca-refs.rkt    Fachada pública del intérprete
checker-cauca.rkt            Fachada pública del chequeador
pruebas-cauca-refs.rkt       Pruebas del intérprete y del chequeador con rackunit
README.md                   Información del proyecto, integrantes y ejecución

docs/
  informe-ast.md            Parte 4: gramática, AST, traza y estados del almacén
  informe-correccion.md     Parte 5: invariantes y argumentos de corrección
Los módulos de src/ contienen la implementación. Las dos fachadas de la raíz reúnen y reexportan sus funciones mediante (provide (all-from-out ...)) para que las pruebas y los usuarios puedan acceder a ellas sin importar directamente cada módulo interno.

La gramática se define una sola vez en src/sintaxis.rkt. Tanto el intérprete como el chequeador utilizan los AST generados por esa gramática; las anotaciones de tipo se conservan en el árbol para que el chequeador pueda consultarlas.
Funcionalidades implementadas
Parte 1. Almacén y referencias
- newref(exp) reserva una celda nueva y devuelve su referencia.
- deref(exp) obtiene el contenido de una referencia válida.
- setref(ref, exp) actualiza el contenido de una celda y, como expresión del lenguaje, devuelve 1.
- swap(ref1, ref2) intercambia los contenidos de dos referencias y devuelve el valor anterior de la segunda.
- begin ... end evalúa sus expresiones en orden y devuelve el resultado de la última.
Parte 2. Paso por referencia
applyref recibe identificadores vinculados a referencias y permite que el procedimiento trabaje sobre las mismas celdas del llamador. En cambio, en la aplicación ordinaria con apply, el intérprete copia las referencias recibidas a nuevas celdas antes de ligar los parámetros, para conservar el comportamiento por valor definido en este proyecto.
Parte 3. Chequeador estático de tipos
El chequeador reconoce los tipos num, bool, refto(t) y los tipos de procedimiento. Comprueba, entre otros casos, condiciones de if, parámetros y resultados de procedimientos, aplicaciones, operaciones con referencias y compatibilidad de tipos en swap y applyref.

El chequeo se realiza sin ejecutar las expresiones del programa; los conflictos detectados se informan mediante eopl:error.
Partes 4 y 5. Informes
- docs/informe-ast.md: gramática, diagramas Mermaid de AST, traza de evaluación, cadena de ambientes y estados del almacén.
- docs/informe-correccion.md: demostraciones de las propiedades del almacén, corrección de swap y argumento informal de solidez del chequeador.
Cómo se corre
Se necesita Racket, con soporte para #lang eopl. Los comandos se ejecutan desde la carpeta raíz del proyecto.

Ejecutar las pruebas:
racket pruebas-cauca-refs.rkt
En la última ejecución reportada por el grupo, el archivo de pruebas produjo 65 pruebas exitosas, 0 fallidas y 0 errores. Este resultado describe los casos incluidos en la suite, no una garantía de que se hayan probado todas las entradas posibles.

Probar el intérprete y el chequeador desde el REPL de Racket:
(require "interprete-cauca-refs.rkt")
(require "checker-cauca.rkt")

; Escritura y lectura de una referencia: resultado esperado 9
(interpretar "let c = newref(0) in begin setref(c, 9); deref(c) end end")

; Tipo esperado: (num * num -> num)
(tipo-de-texto "proc (a : num, b : num) +(a, b) end")
Para abrir el REPL desde una terminal, se puede ejecutar racket en la raíz del repositorio y escribir las expresiones anteriores.
