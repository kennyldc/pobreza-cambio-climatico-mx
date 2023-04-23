# Análisis descriptivo ENOE-Desastres

# Recordemos del resto de nuestros códigos que el dataset de trabajo
# (enoe-desastres) se puede descargar directamente desde Google Drive
# en la siguiente liga: https://drive.google.com/file/d/1CMJvgDnB9FjN0AIoLyHBTR2L43uazy1j/view

# El proceso de construcción de esta base se detalla ampliamente en las carpetas del repositorio 

# Librerías y lecturas de files --------------------------------------------
# Traemos los paquetes relevantes a la sesión de R con p_load
# Si no tienes la librería pacman el siguiente código lo instalará
if (!require("pacman")) install.packages("pacman")
# Con p_load podemos traer a sesión todas las librerías que usaremos
pacman::p_load(tidyverse, janitor, googlesheets4, skimr)

# cambiando el directorio
# En este paso es necesario que el usuario cambie de manera manual su directorio
# de trabajo y ponga aquel donde descargó la base de datos de trabajo
setwd("/Users/carloslopezdelacerda/Library/CloudStorage/GoogleDrive-caribaz@gmail.com/Mi unidad/CEES-EASE/Proyecto Pobreza y Cambio Climático/archivos-de-trabajo/datos/transformados/enoe_sdem/")
# leyendo la base de ENOE con los fenomenos
enoe_fenomenos <- readRDS(file = "enoe_fenomenos_nueva.rds")

# Algunas descriptivas con la información de la ENOE ----------------------

# Para poder ver cuantas personas diferentes en la base
enoe_fenomenos |>
  group_by(identificador_persona) |>
  count()

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

# Particularmente es interesante saber el número máximo de fenómenos que una persona experimentó
# en cada una de las combinaciones.

# LLUVIAS
enoe_fenomenos |>
  select(contains("categoria_lluvias_e_inundaciones_ultimos")) |>
  skim()

# CICLON 
enoe_fenomenos |>
  select(contains("categoria_ciclon_tropical_ultimos")) |>
  skim()

# TEMPERATURAS EXTREMAS
enoe_fenomenos |>
  select(contains("categoria_temperaturas_extremas_ultimos")) |>
  skim()

# HELADAS
enoe_fenomenos |>
  select(contains("categoria_heladas_y_nevadas_ultimos")) |>
  skim()

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