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

La  primera versión de nuestro modelo se estima para las siguientes variables de respuesta que se pueden encontrar en los indicadores originales que mide la ENOE: a) Ingreso mensual (para todas las personas), b) Ingreso mensual (para todas las personas con ingreso positivo), c) Horas trabajadas (para todas las personas) y d) Horas trabajadas (para todas las personas con horas trabajadas positivas).

Cabe aclarar que en el último modelo de personas con horas trabajadas positivas solo hay personas ocupadas.

Como bien puede inferirse, esta primer versión del modelo es únicamente para variables continuas.

### Nota importante sobre efectos heterogéneos

Para poder llevar un órden con respecto a las diferentes variables dependientes que se utilizan en este proyecto, inmediatamente después de las estimaciones base se presentan también los resultados de investigar posibles efectos heterogénos en dos variables adicionales: 

1. Género
2. Tipo de urbanización (urbano/rural)

Dentro de cada sección donde se especifican las ecuaciones que se estiman para cada tipo de variable dependiente, también se agregarán las modificaciones para identificar estos efectos heterogéneos. 

En particular, esto lo haremos por medio de términos de interaccción en el cálculo del modelo. 

Un detalle inevitable al realizar efectos heterogéneos en un planteamiento como el que se sigue en este proyecto es que se multiplican la cantidad de coeficientes. Esto ocurre especialmente debido a la innovación que propusimos de identificar los efectos en diferentes tipos de fenómenos y para diversos cortes temporales. 

Se solicita al lector que no pierda de vista la variable dependiente que se está estimando y que trate, en la medida de lo posible, de hacer las interpretaciones por cada corte de tiempo.

## Ingreso mensual para todas las personas

La ecuación para nuestra primer variable candidata (ingreso mensual para todas las personas) se define de la siguiente manera:

$$
log(Ingreso_{i})=\beta X_{id}+\delta_i+\phi_t+\epsilon_{i}
$$

donde $log(Ingreso)$ es el logaritmo natural del ingreso mensual de la persona $i$ que contestó la ENOE y reportó en la encuesta. Y donde $X_{id}$ es el número de desastres naturales que vivió el individuo $i$ en los diferentes cortes de tiempo $d$: 0 a 90, 91 a 180, 181 a 360, 361 a 540, 541 a 720 y 721 a 1800 días antes de la entrevista. La expresión incluye los términos de efectos fijos: a) por individuo, $\delta_{i}$, que se activa cuando la observación corresponde a la persona que contestó la encuesta ($i$) y b) por período, $\phi_{t}$, que simplemente lleva el conteo del **trimestre** en el que se contestó la encuesta (*t*). El término de error $\epsilon_{sit}$ lleva el residual para cada individuo. Por último, cabe aclarar que los errores estimados son de tipo cluster agrupados también de manera individual por persona que contestó la encuesta.

Un detalle importante en la manera en que está planteada esta ecuación consiste en el uso de la transformación logarítmica en la variable dependiente. Por una parte, en variables como ingreso es útil incluirla ya que permite interpretar los coeficientes en términos de cambios porcentuales. Sin embargo, es evidente que también genera problemas al momento de enfrentarse a aquellas observaciones con un valor de 0. 

En el planteamiento de esta estimación inicial se soluciona el problema agregando una constante a cada una de las observaciones de la variable. Sin embargo, en la sección siguiente cambiamos ligeramente el enfoque.

Los resultados de las estimaciones de esta ecuación se pueden encontrar en la presentación adjunta de esta carpeta. 

### Efecto heterogéneo por género

Como se anticipaba líneas más arriba de este texto, con esta misma propuesta de ecuación podemos identificar la posible existencia de efectos heterogéneos. 

La primera propuesta consiste en estudiar un posible impacto del género como efecto mediador. 

Agregamos esta variable como una interacción en nuestro modelo OLS de manera que estimamos:

$$
log(Ingreso_{i})=\beta_1 X_{id} + \beta_2 Género{i} + \beta_3 X_{id} * Género_{i} +\delta_i+\phi_t+\epsilon_{i}
$$


## Ingreso mensual para las personas con ingreso positivo

Una alternativa que sugerimos a la estimación del ingreso es utilizar únicamente en la regresión a las personas que tienen un ingreso positivo. La ecuación es exactamente la misma:

$$
log(Ingreso_{i})=\beta X_{id}+\delta_i+\phi_t+\epsilon_{i}
$$

Solo que en este caso $i$ representa a toda persona que haya respondido la ENOE y además refiera tener un ingreso positivo. 

## Horas trabajadas para todas las personas

