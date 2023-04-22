# Modelo econométrico y estimaciones para el nivel de ENOE

El objetivo primordial de nuestra investigación consiste en estimar de manera causal el impacto de un desastre natural (exacerbado por el cambio climático) sobre indicadores económicos de interés.

Conceptualmente, esto se puede entender aclarando que no es de nuestro interés saber si los individuos que se enfrentan a más (o menos) desastres naturales tienen mejores o peores condiciones económicas. Lo que nos interesa es saber cómo un desastre natural adicional, ceteris paribus, impacta a una persona en indicadores de interés.

Para lograr este objetivo, la propuesta en nuestro estudio consiste en la estimación del método de efectos fijos "two-way fixed effects" (TWFE). Como quedará especificado en las ecuaciones que se presentan a continuación, una manera muy simple de resumir esta estrategia econométrica que usa los efectos fijos por período y por individuo es por medio de variables *dummy* (o variables de estado) para cada periodo y unidad. Así cada una de ellas indicará la diferencia ponderada con respecto a un valor de referencia y eliminará el sesgo que puede causar una variable que sea constante.

Esto es una manera de lidiar con el hecho de que el número de desastres naturales no es aleatorio y de que existen otras variables, observables y no observables, (también conocidas como *cofounders*) que pueden estar correlacionadas tanto con el número de desastres como con el algunos indicadores económicos.

De manera aún más específica, planteamos dos versiones de modelo para el caso: a) donde la variable de interés es continua y b) donde la variable de interés es binaria.

Se recomienda ampliamente revisar todo lo que resta del texto aunque se destaca como resumen que dentro de la carpeta se incluye:

- `estimaciones-enoe-desastres.R` : Código con el cual se realizaron las estimaciones de las ecuaciones que se plantean a continuación.

- `presentacion-ejecutiva-esimaciones-enoe-desastres.pdf` : Una presentación ejecutiva con las tablas de las estimaciones y los principales hallazgos de la inverstigación.

## Modelo TWFE con variables continuas

La primera versión de nuestro modelo se estima para las siguientes variables de respuesta que se pueden encontrar en los indicadores originales que mide la ENOE:

1. Ingreso mensual
2. Horas trabajadas

De manera específica, la ecuación para el ingreso mensual se plantea como:

$$
log(Ingreso_{i})=\beta X_{id}+\delta_i+\phi_t+\epsilon_{i}
$$


