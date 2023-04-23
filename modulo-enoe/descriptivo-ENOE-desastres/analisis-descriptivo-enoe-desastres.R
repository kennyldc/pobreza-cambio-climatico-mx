# Análisis descriptivo ENOE-Desastres
# Como se especifica en la información de cómo se armó la base de 
# ENOE-desastres. El dataset final se puede desacargar de 
# Google Drive : https://drive.google.com/file/d/1CMJvgDnB9FjN0AIoLyHBTR2L43uazy1j/view

# Librerías y lecturas de files --------------------------------------------
# Traemos los paquetes relevantes a la sesión de R con p_load
# Si no tienes la librería pacman el siguiente código lo instalará
if (!require("pacman")) install.packages("pacman")
# Con p_load podemos traer a sesión todas las librerías que usaremos
pacman::p_load(tidyverse, janitor, lubridate, googlesheets4, ISOweek)

# cambiando el directorio
setwd("/Users/carloslopezdelacerda/Library/CloudStorage/GoogleDrive-caribaz@gmail.com/Mi unidad/CEES-EASE/Proyecto Pobreza y Cambio Climático/datos/transformados/enoe_sdem/")
# leyendo la base de ENOE con los fenomenos
enoe_fenomenos <- readRDS(file = "enoe_fenomenos_nueva.rds")

# Con este datset tenemos la información de todos los participantes de la ENOE (tantas veces como hayan respondido la encuesta)
# junto con columnas que indican la cantidad de desastres a la que han sido expuestos
# en los últimos 90, 180, 540, 720 y 1800 días. 
# La información viene desagregada por tipo de fenónemo según la información original de la base de declaratorias:
# - actividad volcanica
# - ciclon tropical lluvias
# - deslave
# - deslizamiento
# - fuertes vientos
# - granizadas
# - heladas granizadas
# - heladas
# - hundimientos
# - incendio forestal
# - inundacion ciclon tropical
# - inundacion
# - lluvias ciclon tropical
# - lluvias inundacion
# - lluvias
# - nevadas, heladas, granizadas,
# - nevadas
# - sismos
# - temperatura extrema
# - tornado

# Adicionalmente se incluye la suma de desastres a la que ha estado expuesto en la misma cantidad de días:
# - suma_ultimos_180
# - suma_ultimos_1800
# - suma_ultimos_540
# - suma_ultimos_720
# - suma_ultimos_90

# Algunas descriptivas con la información de la ENOE ----------------------

# Para poder ver cuantas personas diferentes en la base necesitamos un identificador por persona
# Recordemos que este lo realizamos con la fecha de nacimiento y con las característica del hogar al no tener
# ninguna otra alternativa

# Con el identificador ya podemos hacer un group_by que nos permita identificar cuantas veces aparecen las personas
# en la base 

enoe_fenomenos |>
  group_by(identificador_persona) |>
  count()

enoe_fenomenos |> 
  slice_sample(n=300) |> 
  select(identificador_persona, r_def:upm, contains("suma_ultimos")) |> 
  View()

# Al realizar esta transformación notamos que algunos de los identificadores no 
# son útiles puesto que las personas no supieron responder su fecha de nacimiento.
# Lamentablemente no hay manera de reparar este problema dado que sin la 
# fecha de nacimiento no hay manera de identificar de manera única a las personas
# El problema afecta al 8% de la base que dada su magnitud parece ser un problema menor
numero_de_veces_que_aparece_persona <- enoe_fenomenos |>
  filter(nac_dia != "99" & nac_mes != "99" & nac_anio != "9999") |>
  group_by(identificador_persona) |>
  count()

numero_de_veces_que_aparece_persona |> 
  tabyl(n)

# Otro problema que se identificó fue con respecto a las personas que comparten fecha de nacimiento y viven en la misma casa
# Lógicamente esto les hace compartir identificadores: año_nac, mes_nac, dia_nac, upm, n_pro_viv, v_sel y n_hog
# Con ellos, tampoco hay manera de identificarlos únicamente.
# Si bien se podría utilizar el número de renglón (n_ren) para formar la llave, tampoco hay
# certeza de que de una entrevista a otra las personas hubiesen estado en el mismo renglón.
# El problema de las personas que tienen la misma fecha afecta al 1% de la base
# No hay ninguna otra manera de obtener un indicador único sobre las personas fuera de los ya utilizados

# Dado esto, debemos filtrar nuestra base para que solo aparezcan las personas que están en 
# de 1 a 5 veces, recordando que 5 es el número máximo de veces que una persona puede contestar la enoe
# Creamos un vector con los identificadores de las personas que aparecen de 1 a 5 veces
personas_5_o_menos <- numero_de_veces_que_aparece_persona |>
  filter(n<=5) |>
  pull(identificador_persona)

# Filtramos la base enoe_fenomenos para solo tener a las personas que aparecen de 1 a 5 veces
enoe_fenomenos <- enoe_fenomenos |>
  filter(identificador_persona %in% personas_5_o_menos)

# Notamos que mientras el tamaño original de enoe_fenomenos (panel) era de 7,283,301
# Con el ajuste obtenemos 6,587,307 observaciones. Bastante útil para continuar con el analisis
# Y de ninguna manera afecta la representatividad.

enoe_fenomenos |>
  group_by(identificador_persona) |>
  count() |>
  filter(n>1) |> 
  nrow()

# Podemos ahora sacar estadísticas para conocer quien/quienes son los más afectados por desastres naturales
# en las diferentes combinaciones posibles de tiempo.

# En primer término podemos conocer los que fueron más afectados por todos los desastres sin distinción
enoe_fenomenos |>
  select(contains("suma_ultimos")) |>
  skimr::skim()

# También podemos conocer sobre desastres en específico. 
# Seleccionaremos aquellos desastres de tipos representativos:
# 1) Lluvias e inundaciones
# 2) Ciclón tropical
# 3) Heladas y nevadas
# 4) Temperaturas extremas

# Varias de esas categorías no vienen literal en la base sino que se contruyeron 
# de unir más de un tipo de fenómeno. Esto ayuda a evitar problemas de que en la base original
# existían categorías redundantes o repetitivas.
# En particular
# 1) Lluvias e inundaciones: Proviene de juntar los siguientes tipos de fenómenos: lluvias, inundación, "lluvias inundación"
# 2) Ciclón tropical: de juntar los tipos de fenómenos, ciclón tropical, "ciclon tropical lluvias", "inundación ciclón tropical", "lluvias ciclón tropical"
# 3) Heladas y nevadas: de juntar heladas, "heladas granizadas y nevadas", "nevadas heladas y granizadas" y nevadas.

# Como se puede inferir de esa descripción. Juntar las categorías era un paso necesario
# para evitar tener información redundante.
# Esto también se puede ver en el siguiente Spreadsheets: https://docs.google.com/spreadsheets/d/1fgULFF1rVaSH4WkxBzhkgj27Zag_Z4CSAf9qA0LNc9k/edit?usp=sharing
# Arreglando esto en la base creamos las "mega categorías":

enoe_fenomenos <- enoe_fenomenos |> 
  mutate(categoria_lluvias_e_inundaciones_ultimos_90 = inundacion_ultimos_90 + lluvias_ultimos_90,  # no hay "lluvias_inundacion 90"
         categoria_lluvias_e_inundaciones_ultimos_180 = inundacion_ultimos_180 + lluvias_ultimos_180 + lluvias_inundacion_ultimos_180,
         categoria_lluvias_e_inundaciones_ultimos_360 = inundacion_ultimos_360 + lluvias_ultimos_360 + lluvias_inundacion_ultimos_360,
         categoria_lluvias_e_inundaciones_ultimos_540 = inundacion_ultimos_540 + lluvias_ultimos_540 + lluvias_inundacion_ultimos_540,
         categoria_lluvias_e_inundaciones_ultimos_720 = inundacion_ultimos_720 + lluvias_ultimos_720 + lluvias_inundacion_ultimos_720,
         categoria_lluvias_e_inundaciones_ultimos_1800 = inundacion_ultimos_1800 + lluvias_ultimos_1800 + lluvias_inundacion_ultimos_1800,
         categoria_ciclon_tropical_ultimos_90 = ciclon_tropical_lluvias_ultimos_90 + ciclon_tropical_ultimos_90 + lluvias_ciclon_tropical_ultimos_90, # no hay "inundacion_ciclon_tropical 90"
         categoria_ciclon_tropical_ultimos_180 = ciclon_tropical_lluvias_ultimos_180 + ciclon_tropical_ultimos_180 + lluvias_ciclon_tropical_ultimos_180 + inundacion_ciclon_tropical_ultimos_180,
         categoria_ciclon_tropical_ultimos_360 = ciclon_tropical_lluvias_ultimos_360 + ciclon_tropical_ultimos_360 + lluvias_ciclon_tropical_ultimos_360, # no hay "inundacion_ciclon_tropical 360"
         categoria_ciclon_tropical_ultimos_540 = ciclon_tropical_lluvias_ultimos_540 + ciclon_tropical_ultimos_540 + lluvias_ciclon_tropical_ultimos_540 + inundacion_ciclon_tropical_ultimos_540,
         categoria_ciclon_tropical_ultimos_720 = ciclon_tropical_lluvias_ultimos_720 + ciclon_tropical_ultimos_720 + lluvias_ciclon_tropical_ultimos_720, # no hay "inundacion_ciclon_tropical_720
         categoria_ciclon_tropical_ultimos_1800 = ciclon_tropical_lluvias_ultimos_1800 + ciclon_tropical_ultimos_1800 + lluvias_ciclon_tropical_ultimos_1800 + inundacion_ciclon_tropical_ultimos_1800,
         categoria_heladas_y_nevadas_ultimos_90 = heladas_ultimos_90 + nevadas_heladas_granizadas_ultimos_90 + nevadas_ultimos_90,
         categoria_heladas_y_nevadas_ultimos_180 = heladas_ultimos_180 + nevadas_heladas_granizadas_ultimos_180 + nevadas_ultimos_180,
         categoria_heladas_y_nevadas_ultimos_360 = heladas_ultimos_360 + nevadas_heladas_granizadas_ultimos_360 + nevadas_ultimos_360,
         categoria_heladas_y_nevadas_ultimos_540 = heladas_ultimos_540 + nevadas_heladas_granizadas_ultimos_540 + nevadas_ultimos_540,
         categoria_heladas_y_nevadas_ultimos_720 = heladas_ultimos_720 + nevadas_heladas_granizadas_ultimos_720 + nevadas_ultimos_720,
         categoria_heladas_y_nevadas_ultimos_1800 = heladas_ultimos_1800 + nevadas_heladas_granizadas_ultimos_1800 + nevadas_ultimos_1800 + heladas_granizadas_nevadas_ultimos_1800) |> 
  rename(categoria_temperaturas_extremas_ultimos_90 = temperatura_extrema_ultimos_90,
         categoria_temperaturas_extremas_ultimos_180 = temperatura_extrema_ultimos_180,
         categoria_temperaturas_extremas_ultimos_360 = temperatura_extrema_ultimos_360,
         categoria_temperaturas_extremas_ultimos_540 = temperatura_extrema_ultimos_540,
         categoria_temperaturas_extremas_ultimos_720 = temperatura_extrema_ultimos_720,
         categoria_temperaturas_extremas_ultimos_1800 = temperatura_extrema_ultimos_1800)

# Particularmente es interesante saber el número máximo de fenómenos que una persona experimentó
# en cada una de las combinaciones.

# LLUVIAS
enoe_fenomenos |>
  select(contains("categoria_lluvias_e_inundaciones_ultimos")) |>
  skimr::skim()

# CICLON 
enoe_fenomenos |>
  select(contains("categoria_ciclon_tropical_ultimos")) |>
  skimr::skim()

# TEMPERATURAS EXTREMAS
enoe_fenomenos |>
  select(contains("categoria_temperaturas_extremas_ultimos")) |>
  skimr::skim()

# HELADAS
enoe_fenomenos |>
  select(contains("categoria_heladas_y_nevadas_ultimos")) |>
  skimr::skim()


# Estadísticas descriptivas de los diferentes indicadores -----------------
enoe_fenomenos |> 
  pull(ingocup) |> 
  mean()

enoe_fenomenos |> 
  pull(hrsocup) |> 
  mean()

enoe_fenomenos |> 
  pull(desempleado) |> 
  sd()