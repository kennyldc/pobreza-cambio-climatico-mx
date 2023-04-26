# Pobreza y Cambio Climático

En este repositorio incluyo toda la información asociada al proyecto "Pobreza y Cambio Climático".

En el archivo pdf adjunto se encuentra la propuesta original del proyecto con elementos tales como:
- Literatura relevante
- Teoría de cambio 
- Datos a emplear 
- Metodología 
- Factores relevantes a considerar

Por distintos factores que se identificarán desde la propuesta del proyecto, este puede considerarse como un meta-proyecto.

Esto es, hay un elemento conductor en el tema del proyecto, pero dentro de sí conviven prácticamente tres estudios (de gran envergadura y costo computacional) asociados a diferentes niveles de análisis.

Por un lado, se busca identificar la toma de decisiones "micro" de los mexicanos identificando como cambia su comportamiento y condiciones económicas en factores como su ingreso, probabilidad de empleo y horas trabajadas.

Por otro lado, se trata de medir factores "macro" vinculados hacia responder cómo cambia la condición de una entidad o región.

Definir cambio climático es un reto en todos los sentidos. Sin embargo, en este proyecto se asocia al número de declaratorias de emergencia provocadas por desastres naturales que ocurren en determinado momento.

Un desastre natural (exacerbado por el cambio climático) se puede entender como un choque exógeno a determinada población y como consecuencia de estos existe la posibilidad de que existan grandes cambios en diferentes indicadores económicos.

En el momento actual de la investigación nos encontramos con resultados detallados y exhaustivos en el nivel de análisis "micro" con las estimaciones de la ENOE las cuales se introducen líneas más abajo en este mismo texto.

## Módulo Desastres Naturales

En la carpeta "módulo desastres naturales" se condensa toda la información relacionada a cómo se identifican y contabilizan los desastres naturales en el estudio. 

Este elemento es clave para el resto de los niveles de análisis. En primer lugar, son el cimiento de conceptual del estudio, ya que entendemos que una manifestación del cambio climático global está vinculado al aumento en el número de desastres naturales. 

En segundo lugar, entender cómo y cuáles son los desastres que se contabilizan en el estudio tiene un impacto desde el punto de vista metodológico. A menudo son los desastres naturales los que se consideran como variables independientes en los diferentes niveles de análisis. El interés de nuestro estudio es identificar cómo el cambio en el número de desastres afecta indicadores claves económicos.

Dentro de la carpeta se detallan las fuentes de nuestros datos y se agrega un ejercicio de estadística descriptiva de los mismos poniendo énfasis en el componente geográfico del mismo. Esto es, con la ayuda de diverso mapas podemos identificar cuáles son las regiones que son más afectadas por los distintos tipos de fenómenos naturales que afectan el territorio mexicano.

## Módulo ENOE

En la carpeta "módulo ENOE" se incluye la información asociada al nivel individual de este estudio. 

Siguiendo el denominador del estudio, los desastres naturales se toman como factores exógenos a una población. 

A su vez, lo que se intenta explicar son cambios en:
1. Ingreso mensual
2. Horas trabajadas 
3. Probabilidad de desempleo
4. Probabilidad de estar inactivo

La verdadera innovación del proyecto consiste en agregar elementos a) geográficos, b) temporales y c) de tipo de fenómeno, sumamente granulares para analizar esta relación. Consideramos que simplemente analizar si una región o entidad ha sufrido a causa de un desastre natural no es suficiente para entender a fondo la relación entre estos dos fenómenos.

Como consecuencia, en nuestro análisis agregamos el concepto de ventanas temporales (también conocidos como cortes temporales). Esto es, identificamos si la persona vive en un municipio afectado por un desastre natural, pero también vemos cuántos días han pasado desde que ocurrió hasta el momento en qué contestó la encuesta de la ENOE. En ese sentido podemos ver si los desastres que ocurrieron en el corto plazo afectan más (o menos) que los que ocurrieron en el largo plazo. 
Las ventanas temporales son las siguientes:
- 0 a 90 días
- 91 a 180 días
- 181 a 360 días
- 361 a 540 días
- 541 a 720 días
- 721 a 1800 días

En relación al tipo de fenómeno, identificamos:
- Todos los desastres naturales
- Solo lluvias e inundaciones
- Solo ciclones tropicales
- Solo temperaturas extremas
- Solo heladas y nevadas

En términos de metodología, nuestras estimaciones utilizan efectos fijos cómo herramientas de causalidad. Para las variables dependientes continuas utilizamos regresiones de tipo OLS y para las variables dependientes binarias modelos de regresión binomial con ligas logit.

Adicionalmente se integra todo un análisis sumamente exhaustivo en el que se analiza si existen algunos efectos heterogéneos en los modelos de interés. Particularmente evaluamos si las siguientes variables logran explicar algún efecto diferenciado:

- Género
- Condición de urbanidad en la residencia

Para las estimaciones encontramos a las personas en diversos puntos del tiempo, desde 1 hasta 5 veces, gracias a las distintas respuestas períodicas que dan en la ENOE lo que nos da luhar a una base tipo panel.

Para la construcción de nuestros datos utilizamos a todas las personas que participaron en la encuesta desde 2016 hasta el segundo trimestre de 2022. A cada una de ella le identificamos los tipos de desastre que han vivido en cada uno de los cortes temporales.

Este proceso requirió de un trabajo muy arduo, particularmente en cuanto a costo computacional se refiere. Por ello, en este estudio existe toda una sección donde se detallan todas las decisiones que se tomaron para la construcción de la base y el algoritmo (o los pasos) que se siguió para juntar la información de desastres. 

Por esta misma razón, la base de datos resultante del proceso es sumamente valiosa aunque también de una magnitud relativamente considerable. En términos de observaciones supera los 6.5 millones. Cada una de ellas tiene combinaciones de tipo de desastre que vivió en cada corte de tiempo (113 aproximadamente) las cuáles se suman a variables con los indicadores de interés y algunos otros identificadores de la persona.

Se recomienda ampliamente explorar la carpeta referente al módulo ENOE para analizar todos los pasos que se siguieron desde la preparación de la base hasta las estimaciones econométricas.