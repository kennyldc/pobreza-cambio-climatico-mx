# Módulo de ENOE

El nivel de análisis "micro" tiene como cimiento principal la Encuesta Nacional de Ocupación y Empleo (ENOE). En este módulo del estudio se puede consultar:

- El contexto de los datos ENOE.
- La preparación de los datos para la construcción del panel con la información económica y de tipo de desastre.
- Los resultados del análisis

Dentro de cada sección se hará referencia al contenido y estructura de cada una de las carpetas que existen en este módulo.

## Contexto de los datos

Esta base de datos del Instituto Nacional de Estadística y Geografía (INEGI) representa uno de los esfuerzos continuos más importantes que lleva este organismo de manera cotidiana para entender la dinámica de empleo en la población mexicana.

De acuerdo con la [documentación de la base](https://www.inegi.org.mx/programas/enoe/15ymas/):

> La Encuesta Nacional de Ocupación y Empleo (ENOE) es la principal fuente de información sobre el mercado laboral mexicano al ofrecer datos mensuales y trimestrales de la fuerza de trabajo, la ocupación, la informalidad laboral, la subocupación y la desocupación. Constituye también el proyecto estadístico continuo más grande del país al proporcionar cifras nacionales y de cuatro tamaños de localidad, de cada una de las 32 entidades federativas y para un total de 39 ciudades.

La encuesta recaba información de una muestra representativa de población de 12 ó mas años a través de un panel rotatorio. 

Este mecanismo se define en la documentación de la siguiente manera:

> El diseño de la encuesta es de panel rotatorio, la muestra está dividida en cinco paneles y cada uno permanece en la muestra durante cinco trimestres, por lo que, pasado dicho tiempo, se sustituye por otro de características similares. La quinta parte de la muestra que ya cumplió con su ciclo de cinco visitas se reemplaza cada tres meses. Este esquema garantiza la confiabilidad de la información obtenida, ya que en cada trimestre se mantiene el 80% de la muestra, lo que en términos prácticos significa:
- La posibilidad de hacer estudios longitudinales de los paneles de viviendas que permanecen en la muestra de un trimestre a otro o de un panel durante cinco trimestres.
- Existe la posibilidad de hacer estimaciones utilizando información de trimestres anteriores, por medio de estimadores de regresión.
- Entrevistar en cinco ocasiones a las viviendas seleccionadas, lo cual disminuye el cansancio en los informantes al permanecer las viviendas en la muestra durante un corto periodo de tiempo.

Lo que en términos prácticos significa para nuestro estudio, es que cada persona puede estar en la muestra de 1 a 5 veces con lo que se facilita el proceso de elaborar una base de datos panel y observar cómo cambian diversos indicadores económicos ante perturbaciones de tipo climatológico.

La ENOE publica los resultados de su encuesta de manera trimestral aunque en cada uno de ellos hace accesible a la población 5 bases de datos distintas. Lo referente a cómo se prepararon y limpiaron los datos para el análisis se detalla en la siguiente sección.

## Preparación de los datos

La preparación de los datos para este módulo del estudio se separa en dos etapas:

- Limpieza de los datos de la ENOE para base panel.
- Algoritmo para juntar (merge) los datos de la ENOE con los desastres naturales.

Cada una de estas etapas pasó por todo un proceso amplio de construcción los cuales se pueden consultar en las dos carpetas de este módulo:

- `limpieza-ENOE`
- `merge-ENOE-desastres`

En la primera etapa se juntó toda la información de 25 trimestres de la ENOE en una sola base de datos desde la cual podemos identificar a todas las personas que entraron al análisis. Después de condensar esta fuente en una sola se realizó todo un procedimiento para incluir la información de los desastres naturales de tal manera que se pudieran identificar los diversos elementos geográficos: qué el municipio donde vive la persona haya sido afectado por un fenómeno de este tipo. Y elementos temporales: identificar el tiempo que hubiese pasado entre el fenómeno y los indicadores económicos que reportó.

## Análisis estadístico con la información económica de la ENOE.

Una vez que logramos tener la base de datos de trabajo, el siguiente paso consiste en estimar propiamente las ecuaciones y coeficientes que identifiquen la relación entre los fenómenos. 

Este proceso se detalla en la carpeta `estimaciones-ENOE`. Dentro de esta se puede identificar: 

1. El planteamiento econométrico de las estimaciones.
2. Los resultados obtenidos en este nivel de análisis.