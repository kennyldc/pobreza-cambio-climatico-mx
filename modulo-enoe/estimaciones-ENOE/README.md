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

> En el planteamiento de esta estimación inicial se soluciona el problema agregando una constante (de uno) a cada una de las observaciones de la variable. Sin embargo, en la sección siguiente cambiamos ligeramente el enfoque.

Los resultados de las estimaciones de esta ecuación se pueden encontrar en la presentación adjunta de esta carpeta. 

### Efecto heterogéneo por género

Como se anticipaba líneas más arriba de este texto, con esta misma propuesta de ecuación podemos identificar la posible existencia de efectos heterogéneos. 

La primera propuesta consiste en estudiar un posible impacto del género como efecto mediador. 

Agregamos esta variable como una interacción en nuestro modelo OLS de manera que nuestra estimación queda de la siguiente manera:

$$
log(Ingreso_{i})=\beta_1 X_{id} + \beta_2 Género_{i} + \beta_3 X_{id} * Género_{i} +\delta_i+\phi_t+\epsilon_{i}
$$

donde $log(Ingreso)$, $X_{id}$, $\delta_{i}$, $\phi_{t}$ y $\epsilon_{sit}$ significan lo mismo que en la ecuación anterior. Sin embargo, en este caso $\beta_1$ es el parámetro que representa el efecto sobre el ingreso provocado por cambios en desastres naturales, $\beta_2$ el parámetro que identifica si hay alguna diferencia en ingreso entre hombre y mujeres (el género del individuo $i$) y $beta_3$ el nuevo parámetro de interés que identifica si hay un efecto heterogéneo de los desastres cuando la persona se identifica con determinado género.

Los resultados se muestran en la presentación adjunta a esta carpeta. Vale la pena notar que la categoría de referencia es la de género masculino ("hombre" en la base de datos).

### Efecto heterogéneo por nivel de urbanización (urbano/rural)

Siguiendo exactamente la misma lógica que en el caso anterior, ahora buscamos conocer si pertenecer a una comunidad "urbana" o "rural" hacen alguna diferencia (un efecto mediador) en la relación de los desastres naturales con el nivel de ingreso. 

El planteamiento es prácticamente el mismo:

$$
log(Ingreso_{i})=\beta_1 X_{id} + \beta_2 Urbano_{i} + \beta_3 X_{id} * Urbano_{i} +\delta_i+\phi_t+\epsilon_{i}
$$

Solo que en este caso, la variable $Urbano_i$ es una indicadora que toma el valor de 1 cuando la persona vive en una zona que el INEGI considera como urbana (según los criterios de la ENOE) y 0 cuando vive en una zona rural.

El coeficiente que nos indica si hay algún efecto heterogéneo entre quienes viven en cada una de los tipos de zona es de nueva cuenta $\beta_3$

Los resultados se muestran en la presentación adjunta a esta carpeta. Vale la pena notar que la categoría de referencia es la de zona rural.

## Ingreso mensual para las personas con ingreso positivo

> Una alternativa que sugerimos a la estimación del ingreso es utilizar únicamente en la regresión a las personas que tienen un ingreso positivo. 

Esta propuesta se realiza como medida cautelar debido a que algunos autores sugieren que agregar una constante a una variable continua para sacar el logaritmo natural puede crear sesgos (ejemplos Bellego et al 2022; Wooldridge).

Estas estimaciones permiten además ser exhaustivos en cuanto a todos los posibles efectos que tienen los desastres naturales. Sin embargo, se considera relevante dejar puntualizado que la teoría de cambio sufre modificaciones. 

En este caso, las estimaciones no se realizan para todas las observaciones en el panel, sino solo con aquellos individuos que tienen un ingreso positivo. Estamos identificando cambios en el ingreso provocados por desastres naturales _para personas que ya tenían ingresos y que nunca perdieron los mismos_.

En términos de la ecuación a estimar, podemos usar exactamente la misma que en el caso pasado. Esto es:

$$
log(Ingreso_{i})=\beta X_{id}+\delta_i+\phi_t+\epsilon_{i}
$$

Solo que en este caso $i$ representa a toda persona que haya respondido la ENOE y además refiera tener un ingreso positivo.

Los resultados se pueden encontrar en la presentación adjunta.

### Efecto heterogéneo por género para personas con ingresos positivos

Reestimamos:

$$
log(Ingreso_{i})=\beta_1 X_{id} + \beta_2 Género_{i} + \beta_3 X_{id} * Género_{i} +\delta_i+\phi_t+\epsilon_{i}
$$

Donde $i$ solo son individuos con ingreso positivo. Los resultados se pueden encontrar en la presentación adjunta.

### Efecto heterogéneo por urbano/rural para personas con ingresos positivos

Reestimamos: 

$$
log(Ingreso_{i})=\beta_1 X_{id} + \beta_2 Urbano_{i} + \beta_3 X_{id} * Urbano_{i} +\delta_i+\phi_t+\epsilon_{i}
$$

Con la misma condición que en el otro modelo de efectos heterogéneos (género). Los resultados se encuentran en la presentación adjunta.

## Horas trabajadas para todas las personas

Una alternativa de indicador económico consiste en sustituir el ingreso del individuo por las horas trabajadas. Ambas son variables continuas por lo que es fácil adaptar la ecuación anterior de manera que: 

$$
log(HorasTrabajadas_{i})=\beta X_{id}+\delta_i+\phi_t+\epsilon_{i}
$$

donde $log(HorasTrabajadas)$ es el logaritmo natural de las horas trabajadas a la semana de la persona $i$ que contestó la ENOE y reportó en la encuesta. El resto de los términos tienen el mismo significado y nuestro interés está en el coeficiente $\beta$.

Otra vez tenemos la capacidad, gracias a nuestra innovación del diseño, de identificar si algunos desastres naturales tienen más (o menos) impacto. Además, también podemos ver si los que ocurren en el corto plazo afectan más que los de largo plazo, o viceversa, gracias a las diferentes ventanas temporales que agregamos.

Notemos que otra vez incluir el logaritmo natural en la variable dependiente requiere de nuestra atención ya que existen en la base algunas observaciones de individuos que trabajaron cero horas. 

En estas primeras estimaciones donde incluimos a toda la población, solucionamos este problema agregando una constante (de 0.5 horas trabajadas). 

Tal como se hizo para el caso del ingreso, líneas más adelante se probará una solución diferente.

Por lo pronto, considérese que los resultados de las estimaciones se encuentran en la presentación adjunta de esta carpeta.

### Efecto heterogeneo género en horas trabajadas para todas las personas

Tal como lo hicimos para el caso del ingreso, podemos repetir el uso de los términos de interacción para identificar si el género tiene un efecto mediador en la relación de desastres naturales. 

La ecuación es igual a la de ingreso por lo que se invita a considerar las líneas anteriores en este texto.

Los resultados se encuentran directamente en la presentación.

### Efecto heterogeneo urbano/rural en horas trabajadas para todas las personas.

En la presentación con los resultados se encuentran los resultados de la ecuación donde si incluye la variable urbano como término de interacción.

## Horas trabajadas para las personas con horas trabajadas positivas

Siguiendo la lógica que empleamos para el caso de la variable ingreso, en el caso de las horas trabajadas reestimamos nuestro modelo usando solo al subconjunto de personas que tienen horas trabajadas positivas en todos los períodos. 

Nótese que volvemos a la misma discusión al respecto del cambio en los alcances de nuestras estimaciones modificadas. Solo podríamos ver el efecto de los desastres para las personas que sí han trabajado y nunca han dejado de trabajar. 

La ecuación es la misma:

$$
log(HorasTrabajadas_{i})=\beta X_{id}+\delta_i+\phi_t+\epsilon_{i}
$$

Para un conjunto de individuos $i$ mucho más reducido.

## Modelo TWFE con variables dummy como dependientes

Llegamos así a la segunda versión de nuestro modelo. En ella utilizamos variables indicadores (o dummy) como dependientes. 

Técnicamente estas regresiones son de tipo binomial donde nosotros podemos escoger la función liga. Siguiendo las prácticas comunes de la literatura, nosotros escogemos la liga "logit" (que por algunos es conocido como modelo logit).

En entregas previas se experimentó también con la liga probit, sin embargo los resultados son muy similares.

Nuestras variables a estudiar, que entrarán como dependientes en la regresión, en este nuevo tipo de modelo son las siguientes:

1. Desempleo
2. Inactivo

En las siguientes secciones se desarrollará información complementaria para entender la creación de las variables.

## Notas sobre los efectos heterogéneos

Adicionalmente, para seguir un órden respecto a todas nuestras estimaciones, después de cada uno de los resultados principales (para cada variable dependiente) se incluirán los resultados de efectos heterogéneos de nueva cuenta por: i) género y ii) urbano/rural.

## Desempleo como variable dependiente

Para complementar nuestros resultados con respecto al ingreso y las horas trabajadas, en nuestro estudio se propone identificar los cambios en la probabilidad de que alguien entrara al desempleo.

Siguiendo la información disponible en INEGI esto se puede realizar por medio de los grupos en una variable categórica llamada "Clase2".

En este caso, para nuestras estimaciones se creó una nueva variable que tomara como insumo principal aquella. Esta nueva variable (de tipo dummy o indicadora) toma el valor de 1 cuando la persona está **desocupada** y 0 en cualquier otro caso.

Con esto logramos proponer la siguiente ecuación:

$$
\log \left(\frac{p}{1-p}\right)=\beta_0+\beta_1 X_{id}+ \delta_i+\phi_t+\epsilon_{i}
$$

Donde $p$ es la probabilidad de estar desempleado. Y el resto de los parámetros son los ya introducidos en las ecuaciones previas. Así, $X_{id}$ son los desastres naturales que vivió la persona $i$ para los diferentes rangos de tiempo $d$, $\delta_{i}$, se activa cuando la observación corresponde a la persona que contestó la encuesta ($i$), $\phi_{t}$, lleva el conteo del **trimestre** en el que se contestó la encuesta (*t*). Y el término de error $\epsilon_{sit}$ lleva el residual para cada individuo. En este caso también agrupamos los errores estándar de tipo cluster por persona que contestó la encuesta.

Los coeficientes de un modelo logit se encuentran en una escala de momios (o log-odds) por lo que fuera del signo, es algo compleja la interpretación de estas razones de probabilidad y además requieren de pasos adicionales.

Con esto en mente, en los resultados que se encuentran en la presentación adjunta de este carpeta optamos por crear una columna adicional  donde se encuentran los valores asociados al **Average Partial Effect (APE)** o Average Marginal Effect, que muestra el cambio en probabilidad ante un cambio en la variable $X$. En una definición más formal, el APE es la derivada promedio de $\frac{\partial p}{\partial X_j}$.

El procedimiento lo dejamos en manos de la librería de R alpaca, que suele ser utilizada en varios modelos y gozar de cierta reputación para implementar modelos de efectos fijos con logit.

En la documentación de ayuda se describe lo siguiente:

> getAPEs is a post-estimation routine that can be used to estimate average partial effects with respect to all covariates in the model and the corresponding covariance matrix. The estimation of the covariance is based on a linear approximation (delta method) plus an optional finite population correction. Note that the command automatically determines which of the regressors are binary or non-binary.

Se recomienda revisar la documentación principal del autor para más información, [en este link](https://github.com/amrei-stammann/alpaca).

Los valores del Average Partial Effect o Average Marginal Effect ya tiene una interpretación natural. Se pueden leer como el cambio en la probabilidad de $y$ ante el cambio de una unidad de $x$.

Las tablas con los resultados se pueden consultar en la presentación adjunta de esta carpeta.

### Modelos por tipo de desastre

Siguiendo la lógica de las estimaciones anteriores, nos interesa también conocer el efecto para diferentes tipos de desastres.

En este caso estimamos:

$$
\log \left(\frac{p}{1-p}\right)=\beta_0+\beta_1 X_{id}+ \mathbf{W}_{id} + \delta_i+\phi_t+\epsilon_{i}
$$

los posibles valores de $X$ puede ser: {lluvias, ciclón tropical, temperatura extrema, heladas} en todas las combinaciones de tiempo $d$: {0 a 90, 91 a 180, 181 a 360, 361 a 540, 541 a 720 y 721 a 1800}.

Los resultados se presentan en el mismo formato que las tablas anteriores.

### Efecto heterogeneo género en desempleo

También en este modelo podemos investigar si hay algún efecto heterogéneo dependiendo del género de la persona.

Reestimamos de forma fácil nuestra ecuación para agregar el término de género y una interacción con los desastres. 

Esta se puede entender como: 

$$
\log \left(\frac{p}{1-p}\right)=\beta_0+\beta_1 X_{id}+ \beta_2 Género_i + \beta3 X_{id} * Género_i \delta_i+\phi_t+\epsilon_{i}
$$

Igualmente aplicamos la variación para los modelos con los distintos tipos de fenómenos. 

Los resultados se encuentran en la presentación adjunta.

### Efecto heterogeneo urbano/rural en desempleo

En la presentación con los resultados se encuentran los resultados de la ecuación donde se incluye la variable urbano como término de interacción.

## Inactivo como variable dependiente

Llegamos así a nuestras últimas estimaciones de este módulo del proyecto. Estas forman parte de la variación del modelo de efectos fijos en la cual incluimos variables binarias como dependientes solo que en este caso nuestra variable de respuesta es "inactivo".

Para construir esta variable, recurrimos de nuevo a la información con la que ya contamos de la ENOE. 

De acuerdo al glosario, la definición para **inactivo disponible** es:

> Este grupo de inactivos está constituido por las personas de 12 y más años que no trabajaron ni tenían empleo y no buscaron activamente uno, por desaliento o porque piensan que no se los darían por la edad, porque no tienen estudios, etc.; pero estarían dispuestas a aceptar un trabajo si se les ofreciera, sin embargo no buscan activamente uno.

Dentro del dataset, lo más cercano a este grupo se encuentra como una categoría de la variable "clase 2" ya que ahí se encuentra el grupo (level) "disponible".

Por ello, construimos una nueva variable indicadora a partir de este level. Esto es, de la variable categórica "clase 2" construimos una dummy que toma el valor de 1 cuando la persona está disponible y 0 en cualquier otro caso.


