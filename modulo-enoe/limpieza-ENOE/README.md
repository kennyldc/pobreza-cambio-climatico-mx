# Limpieza y preparación de la ENOE

La ENOE es una fuente de información sumamente amplia con un gran número de particularidades que la hacen valiosa para un análisis económico pero desafiante en términos de limpieza de datos. 

Para poder utilizar esta fuente en nuestro estudio, se transitó por una serie de decisiones importantes sobre cómo se incluirían estos datos con el objetivo se poder analizarlos en conjunto con los desastres naturales. Como contexto, tal y cómo se aclara en la sección principal del módulo ENOE del estudio, INEGI publica la información con periodicidad trimestral pero dentro de cada una de ellos publica 5 bases de datos aunado a diversos directorios e identificadores. 

En esta sección se documentan las decisiones y soluciones que se implementan en el estudio así como los códigos en R que se utilizaron para preparar los datos.

Se recomienda ampliamente revisar todo el texto aunque se destaca como resumen que dentro de la carpeta se incluye:

- `construccion-enoe.R` : Código con el cual se juntó la información de todos los períodos de la ENOE en un mismo panel.

- `presentacion-ejecutiva-construccion-enoe.pdf` : Una presentación ejecutiva donde se destacan puntos principales del proceso de construcción de la base de datos tipo panel.

## Años a incluir en el análisis

La ENOE se ha realizado desde 2005 por el INEGI. No obstante, ha sufrido cambios importantes a lo largo del tiempo. Algunos han sido de tipo menor, pero otros han tenido gran relevancia como lo fueron los cambios de representatividad y los ajustes de los factores de expansión que se vinculan a los datos que ha recopilado INEGI para proyectar el crecimiento poblacional en México. 

La decisión para nuestro estudio respecto a los años del análisis, consistió en incluir los datos de la ENOE del año 2016 a 2022 (inclusive). Esto responde a que para el período en que se obtuvieron los datos (finales de 2022) todos estos años comparten un mismo ajuste de factor de expansión lo cuál vuelve todos los trimestres estrictamente comparables.

Esto lo encontramos en una nota publicada por el INEGI donde especifican:

>En 18 de agosto de 2022, se reemplazaron los archivos de las Bases de datos de los cuatro trimestres de 2016, debido a que se actualizaron las estimaciones de población, con base en la propia actualización del Marco de Muestreo del INEGI. Asimismo, se reemplazaron los archivos de Bases de datos de los cuatro trimestres de 2017, 2018 y tercer trimestre de 2020, debido a que se modificaron los registros de no entrevista en el valor de la variable FAC, FAC_TRI y FAC_MEN, ya que su valor asignado era mayor a cero.

Esta selección de años ya es un reto bastante considerable tomando en cuenta que en cada año se publican 4 trimestres (con excepción de 2020 que solo se publicaron tres) y que la información viene desagregada en 5 bases diferentes. El origen de los datos del portal del INEGI se toma de la sección Microdatos de la página de la Encuesta. Solo para un trimestre se descarga también la información de la sección de Datos Abiertos. La única diferencia entre los dos es que en esta última vienen diccionarios detallados de cada sección y en los de microdatos solo vienen las bases.

## Base de datos que se utiliza en cada trimestre

Otra de las decisiones importantes consiste en especificar, de las 5 bases de datos que vienen en cada trimestre por parte de la ENOE, cuál es útil para el estudio. 

Tomando en cuenta que tenemos 25 trimestres desde el primero de 2016 y hasta el segundo de 2022 (el último que se descargó para el análisis) y que cada trimestre tiene 5 bases, solo de esta fuente de datos hay 125 archivos de datos. Las 5 bases de datos responden a diferentes secciones de la ENOE en las cuáles se encuentran diferentes datos de cada individuo o del hogar. La descripción de cada una de las 5 bases junto con sus nombres se pueden consultar [en el siguiente manual que se realizó para nuestro estudio](https://docs.google.com/document/d/1lgZIjmYw-LbkzDcV1rUi7UjAAeXX5QcbNT0J9JNUmuQ/edit?usp=sharing).

La postura para nuestro estudio consistió en sólo incluir una de las 5 bases para cada trimestre. Esto es, para cada trimestre, se consulta de la ENOE la base de datos "sdem" con las características sociodemográficas de los individuos que respondieron la encuesta. En total, tenemos 25 bases distintas de ENOE, una para cada trimestre.

### Características de la Base de datos de características sociodemográficas (SDEM) en la ENOE

A grandes rasgos, la base de datos SDEM es una especie de “resumen” donde no vienen todos los detalles que se preguntan en los cuestionarios ampliados de la ENOE pero sí vienen las variables más importantes del entrevistado tales como: la localidad, género, edad, alfabetismo, estudios, si vive en una zona urbana o rural, a qué clasificación del tipo ecónomico pertenece (PEA/PNEA), características de ocupación (ocupado/disponible/desempleado, etc), horas trabajadas a la semana, ingreso mensual, entre otras. 

El diccionario completo de la SDEM se puede consultar en [el siguiente enlace](https://drive.google.com/file/d/1Qz1CRv9SgtRNZxi5llQf1SosYHcTAXPC/view?usp=sharing).

Como cada una de las "respuestas" de cada variable se registra en códigos, también se deben consultar los catálogos de respuestas de cada variable que se encuentran en el [siguiente link](https://drive.google.com/drive/folders/1MzPSmmK7GBPZpNB6TrWnqzoeIrGhzHTl?usp=sharing).

Es necesario puntualizar que en la base sdem vienen *todos los integrantes del hogar* mayores a 12 años. En análisis posteriores con esta base se filtrará la información para solo incluir a aquellos en edad laboral (15 años o mas).

## Construcción de la base de datos ENOE-SDEM

Como se destacó en las secciones anteriores, fue necesario seleccionar qué años entrarían al estudio y que información sería útil para el mismo.

Adicionalmente, en términos de manejo de datos es necesario juntar los 25 trimestres en una misma base de datos que contenga la información necesaria en forma panel. El código `construccion-enoe.R` dentro de esta misma carpeta documenta toda la elaboración de la base de datos que se usa para el análisis.

El output final (la base) se puede consultar en el [siguiente enlace](https://drive.google.com/file/d/1LJTjBMrTME-y-DMm0guL5XNBPAGbMOTK/view?usp=sharing).

Al juntar toda la información con los diferentes trimestres posibles, nos encontramos con una base de 9,803,789 entradas que representan todas las veces que el INEGI tuvo un acercamiento con alguna persona en el hogar en algún punto del tiempo. Cada persona aparece tantas veces como se le haya entrevistado. Esto es, puede aparecer entre 1 y 5 veces como máximo. 

En pasos posteriores se filtra la base, de tal manera que contando solo a los individuos de 15 años ó mas (quienes están en edad de trabajar de acuerdo a las leyes mexicanas), obtenemos 7,283,301 observaciones.