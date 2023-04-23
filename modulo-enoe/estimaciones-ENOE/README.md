# Modelo econométrico y estimaciones para el nivel de ENOE

El objetivo primordial de nuestra investigación consiste en estimar de manera causal el impacto de un desastre natural (exacerbado por el cambio climático) sobre indicadores económicos de interés.

Conceptualmente, esto se puede entender aclarando que no es de nuestro interés saber si los individuos que se enfrentan a más (o menos) desastres naturales tienen mejores o peores condiciones económicas. Lo que nos interesa es saber cómo un desastre natural adicional, ceteris paribus, impacta a una persona en indicadores de interés.

Para lograr este objetivo, la propuesta en nuestro estudio consiste en la estimación del método de efectos fijos "two-way fixed effects" (TWFE). Como quedará especificado en las ecuaciones que se presentan a continuación, una manera muy simple de resumir esta estrategia econométrica que usa los efectos fijos por período y por individuo es por medio de variables *dummy* (o variables de estado) para cada periodo y unidad. Así cada una de ellas indicará la diferencia ponderada con respecto a un valor de referencia y eliminará el sesgo que puede causar una variable que sea constante.

Esto es una manera de lidiar con el hecho de que el número de desastres naturales no es aleatorio y de que existen otras variables, observables y no observables, (también conocidas como *cofounders*) que pueden estar correlacionadas tanto con el número de desastres como con el algunos indicadores económicos.

De manera aún más específica, planteamos dos versiones de modelo para el caso: a) donde la variable de interés es continua y b) donde la variable de interés es binaria.

Se recomienda ampliamente revisar todo lo que resta del texto aunque se destaca como resumen que dentro de la carpeta se incluye:

- `estimaciones-enoe-desastres.R` : Código con el cual se realizaron las estimaciones de las ecuaciones que se plantean a continuación.

- `presentacion-ejecutiva-esimaciones-enoe-desastres.pdf` : Una presentación ejecutiva con las tablas de las estimaciones y los principales hallazgos de la investigación.

## Modelo TWFE con variables continuas

La  primera versión de nuestro modelo se estima para las siguientes variables de respuesta que se pueden encontrar en los indicadores originales que mide la ENOE: a) Ingreso mensual (para todas las personas), b) Ingreso mensual (para todas las personas con ingreso positivo), c) Horas trabajadas (para todas las personas), d) Horas trabajadas (para todas las personas con horas trabajadas positivas).

Como bien puede inferirse, esta primer versión del modelo es únicamente para variables continuas,

## Ingreso mensual para todas las personas

La ecuación para nuestra primer variable candidata (ingreso mensual para todas las personas) se define de la siguiente manera:

$$
log(Ingreso_{i})=\beta X_{id}+\delta_i+\phi_t+\epsilon_{i}
$$

donde $log(Ingreso)$ es el logaritmo natural del ingreso mensual de la persona $i$ que contestó la ENOE y reportó en la encuesta. Y donde $X_{id}$ es el número de desastres naturales que vivió el individuo $i$ en los diferentes cortes de tiempo $d$: 0 a 90, 91 a 180, 181 a 360, 361 a 540, 541 a 720 y 721 a 1800 días antes de la entrevista. La expresión incluye los términos de efectos fijos: a) por individuo, $\delta_{i}$, que se activa cuando la observación corresponde a la persona que contestó la encuesta ($i$) y b) por período, $\phi_{t}$, que simplemente lleva el conteo del **trimestre** en el que se contestó la encuesta (*t*). El término de error $\epsilon_{sit}$ lleva el residual para cada individuo. Por último, cabe aclarar que los errores estimados son de tipo cluster agrupados también de manera individual por persona que contestó la encuesta.

