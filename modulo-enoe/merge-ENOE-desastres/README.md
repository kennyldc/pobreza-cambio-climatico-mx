# Merge ENOE-desastres

Como se especifica en la carpeta de `limpieza-ENOE`, los datos de la ENOE originales fueron transformados a una base de datos "concentradora" de 7,283,301 observaciones, en cuyo caso cada observación representa las ocasiones en que INEGI tuvo contacto con el entrevistado.

En esta sección se detalla el proceso y las decisiones que tomaron al momento de juntar esta nueva base con la información de las declaratorias de emergencia de los desastres naturales.

Vale la pena recordar que en el repositorio principal del proyecto también existe una carpeta que especifica como se construyó la base de desastres naturales.

Se recomienda ampliamente revisar todo el texto aunque se destaca como resumen que dentro de esta carpeta se incluye:

- `merge-enoe-emergencias.R` : Código con el cual se juntó la información del panel ENOE con las declaratorias de emergencia.

- `presentacion-ejecutiva-merge-enoe-emergencias.pdf` : Una presentación ejecutiva donde se destacan puntos principales del proceso de juntar (merge) la información del ENOE con los desastres.

## Características de las bases a unir

Una manera de empezar la discusión consiste en recordar las características de cada una de las bases. Por un lado, en la base de desastres naturales aparece el tipo de desastre, el municipio que afecta, la fecha de inicio, de publicación y de finalización del desastre.

Por el otro, en la ENOE SDEM (que juntamos en el código de la carpeta `limpieza-ENOE`) hay variables identificadoras de la residencia de la persona y sus características relacionadas al empleo como la actividad, el número de horas trabajadas, el ingreso, entre otras. Dentro de las identificadoras también se puede identificar el trimestre del cual corresponden las respuestas y una variable denominada período que se vuelve clave en nuestro proceso de juntar las bases.

## Características y retos del merge de las bases

Para unir de manera definitiva las declaratorias con las respuestas de la ENOE hay que tomar en cuenta que existe un elemento geográfico (el municipio donde ocurrió el desastre) y uno temporal (el momento del año del evento).

La precisión y el detalle de la base de desastres permite conocer: a) la fecha de inicio del evento climático, b) la fecha de término de la contingencia y c) la fecha en que se publicó la declaratoria. 

Para el caso de la ENOE, el elemento geográfico es muy claro pero en lo referente a la temporalidad de las respuestas hay elementos adicionales que vale la pena considerar. En primer lugar, las bases que utilizamos (la sociodemográfica) se publican de manera trimestral. No obstante, el trabajo del INEGI en campo se efectúa por medio de **rondas de entrevistas semanales**. 

De manera más precisa, "el levantamiento de la muestra autorepresentada inicia el lunes y termina el domingo de cada semana", aunque existen diferencias entre el caso de unidades urbanas y rurales. En total cada trimestre es dividido en 13 semanas y en cualquier punto de este período puede ocurrir el levantamiento de la información en los hogares urbanos. Para el caso de los rurales, la información se capta en rondas mensuales por lo que solo es posible conocer el mes en el que se extrajo la información.

Todo esto se menciona con el propósito de puntualizar que la unión de los desastres con la información laboral se realiza, en la medida de lo posible, al nivel más desagregado y preciso. Esto es, para el caso urbano será posible pegar si ocurrió un desastre hasta el nivel de la semana de la encuesta.

En la práctica, esto implica contar el número de semanas que han transcurrido desde un desastre hasta el momento en que se está elaborando el cuestionario en su hogar.

Para el caso de las entrevistas rurales el nivel de precisión sólo es posible hasta el mes de la encuesta. Por ello, se asume que se hicieron el primer día del mes. Esto es, asumimos que la encuesta se realizó el primer día del mes y sobre este día contamos el número de días que han ocurrido desde el último desastre natural que vivió la persona.

## Innovación en la construcción de la base de datos

Es precisamente en relación al merge temporal donde ocurre una de las innovaciones más importantes de nuestro proyecto. Mientras que en muchos estudios solo se considera si ocurrió o no un fenómeno climático en el municipio de la persona que está respondiendo la encuesta, en nuestro proyecto somos capaces de contabilizar el número de días que han pasado desde el último desastre natural hasta el momento en que responde la ENOE.

Como se detallará más adelante en el análisis, ese número de días que han transcurrido entre ambos sucesos permite realizar agrupaciones de bloques de tiempo (que conoceremos como ventanas o cortes temporales). Podremos identificar si los desastres qué ocurrieron en un período de tiempo muy cercano a la encuesta afectan de manera diferente a los que ocurrieron en el largo o mediano plazo.

## Algoritmo (procedimiento) para unir las bases

Con las aclaraciones expuestas, el algoritmo que se sigue para unir las bases se encuentra en el código `merge-enoe-emergencias.R`. Este se puede explicar con palabras de la siguiente manera: 

1. Identificar en la base de las declaratorias de emergencia la semana del año en que ocurrieron los deastres (identificado a partir de la variable de clase date "fecha-inicio").

2. Identificar en la ENOE el tipo de entrevista (rural ó urbano). Algo que se identifica por medio de la variable "ur".

3. Identificar el trimestre y el año en el cuál se recabó la información económica (ENOE). Algo que se puede notar en la variable "per".

4. Identificar la semana del trimestre a la que se está haciendo referencia para los casos *urbanos* y que indica cuando levantaron la encuesta. Para ello, hay que separar la variable d_sem la cual indica en los dos últimos dígitos la semana del trimestre en la que se levantó la información.

5. Identificar el mes del trimestre para los casos rurales y que también indica el momento del levantamiento de la información. Aquí también se utiliza la variable "d_sem" pero solo se extrae el mes. Adicionalmente, se asume que la entrevista se hizo en la primer semana de ese mes para homologarlo con respecto a la semana del trimestre que correspondería a las entrevistas urbanas.

6. Convertir la semana del trimestre (d_sem) en la semana del año para cada uno de los años de la encuesta. Para ilustrarlo, la semana 1 del trimestre 1 del año 2016 se convertirá en la semana 1 del año 2016. A su vez, la semana 1 del trimestre 2 de ese mismo año se convertirá en la semana 14 del 2016; la semana 1 del trimestre 3 se convertirá en la 27 de ese año y así respectivamente hasta llegar a la última semana del año que equivale a la última semana del último trimestre.

7. Convertir la semana de la encuesta en una fecha específica. Esto es, se aproxima la fecha en la que las personas respondieron.

8. Se ajusta la información geográfica para tener una llave única en la ENOE y en la base de declaratorias que una el estado con el municipio.

9. Con la información geográfica del encuestado se obtienen todos los desastres que ha vivido su vivienda en los últimos "n" años.

10. Se realiza una resta para saber la cantidad de días que han pasado desde el desastre hasta la fecha de la encuesta.

11. Se filtran los desastres que ha vivido una persona en los últimos 0 a 90 días, 91 a 180 días, 181 a 360 días, 361 a 540 días, 541 a 720 días y 721 a 1800 días anteriores a la encuesta.

12. Se desagregan estos desastres por tipo. De manera que se lleva un conteo de qué fenómeno en particular vivió en ese "t"" rango de días y en otra columna se registra la suma de desastres totales.