# Estadística descriptivas de las declaratorias de emergencia


# Librerías y lectura del file --------------------------------------------

# Traemos los paquetes relevantes a la sesión de R con p_load
# Si no tienes la librería pacman el siguiente código lo instalará
if (!require("pacman")) install.packages("pacman")
# Con p_load podemos traer a sesión todas las librerías que usaremos
pacman::p_load(tidyverse, janitor, lubridate, mxmaps)

# leemos el archivo de las declaratorias en csv
# Note como no es necesario cambiar ningún working directory en R ya que
# el archivo está directamente hosteado en Google Drive

declaratorias <- read.csv(sprintf("https://drive.google.com/uc?id=%s&export=download",
                                  "1Jlyrcq3XWR7QDn3RPU2R3Ee_ryNMSDOl"),
                 fileEncoding = "Latin1", check.names = F) |> 
  clean_names() # la opción de clean_names convierte los nombres de las columnas en camel_case

# Vamos a modificar las clases de algunas de las variables
declaratorias <- declaratorias |>
  mutate(across(c(fecha_publicacion:fecha_fin), ~ dmy(.)), # las columnas de fechas las vamos a volver date class
         across(c(clave_estado, clave_municipio), ~as.character(.))) # las claves del estado y del municipio no son propiamente números, son identificadores y las pondremos como character 


# Filter de tipo de emergencia y años -------------------------------------
# Explorando la base notamos que en ocasiones el mismo fenómeno fue reportado
# con dos tipos de declaratorias diferentes (a pesar de ser el mismo evento).
# Por ejemplo como uno de emergencia y de desastre. O de emergencia y contingencia, etc.
# Para resolver este conflicto, utilizaremos únicamente los asociados a emergencia.

declaratorias <- declaratorias |>
  filter(tipo_declaratoria == "Emergencia")

# Adicionalmente, como se menciona en los comentarios del proyecto, para el enfoque con la ENOE
# solo se utilizarán emergencias que hayan "iniciado" después del 2006
declaratorias <- declaratorias |>
  filter(fecha_inicio > "2006-01-01")

# Unidad de observación ---------------------------------------------------
# Otra aclaración importante es que no todas las observaciones (rows) son un
# una emergencia. En realidad, una misma emergencia puede tener varias observaciones
# en la base ya que podría estar afectando a más de un mismo municipio.

# Sobre esto hay más información en la presentación ejecutiva adjunta.
# Podemos identificar que la unidad de observación de la base es desastre-municipio

# La variable de la base "identificador" es la que lleva registro de los diferentes
# desastres que ocurrieron
# Como se puede identificar en el siguiente código, ocurrieron 6,986
# desastres diferentes en el período. 
# Asimismo, existen 11,897 observaciones del tipo desastre-municipio
declaratorias |> 
  distinct(identificador) |> 
  count()

# Tablas de frecuencia y EDA ----------------------------------------------
# Tabla de frecuencia de desastres tipo de fenómeno
declaratorias |> 
  distinct(identificador, .keep_all = T) |> 
  tabyl(tipo_fenomeno) |> 
  mutate(across(where("is.numeric"), \(x) round(x, 4)),
         percent = percent*100) |> 
  arrange(desc(n)) 

# Tabla de frecuencia de desastre por estado
declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  count(clave_estado) |> 
  arrange(desc(n))

# Podemos juntar los dos hallazgos con una función en la cual nosotros establecemos
# la clave del estado y R nos dirá cuantos desastres ha vivido y desagregar la información
# por tipo de desastre

frecuencia_desastres_estado <- function(numero_inegi_estado){
declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(clave_estado == numero_inegi_estado) |> 
  tabyl(tipo_fenomeno) |>
  arrange(-n) |> 
    adorn_totals()
}

# Podemos ejecutar esta función para cualquier estado que sea de nuestro interés
# Solo debemos modificar el número dentro de la función por la clave que el INEGI le asigna al mismo
# En la siguiente línea ejecutamos la función para el estado de Zacatecas
# INEGI identifica Zacatecas con el número 32

frecuencia_desastres_estado(32)

# Mapa de cantidad de declaratorias agregados ----------------------------
# Por estado
mxmaps::df_mxstate_2020 |>
  left_join(declaratorias |> 
              distinct(identificador, .keep_all = T) |>
              count(clave_estado) |>
              rename(declaratorias = n) |>
              mutate(across(clave_estado, ~ str_pad(., 2, side = "left", pad = "0"))),
            by = c("region" = "clave_estado")) |>
  rename(value = declaratorias) |> 
  mxstate_choropleth(num_colors = 7,
                     title = "Estados con la mayor cantidad de declaratorias de emergencia de enero de 2006 a noviembre de 2022")

# Por municipio
df_mxmunicipio_2020 |> 
  safejoin::safe_left_join(declaratorias |> 
                             distinct(identificador, .keep_all = T) |>
                             tabyl(clave_municipio) |> 
                             mutate(clave_municipio = str_pad(clave_municipio, 5, side = "left", pad = "0")) |> 
                             rename(value = n),
                           by = c("region" = "clave_municipio")) |> 
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxmunicipio_choropleth(num_colors = 1,
                         title = "Municipios con la mayor cantidad de declaratorias de emergencia de enero de 2006 a noviembre de 2022")


# Frecuencias de declaratorias por municipio ------------------------------

# Top 5 municipios con mayor cantidad de declaratorias
declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  count(clave_municipio) |> 
  arrange(-n) |> 
  slice(1:5)

# Cantidad de declaratorias por municipio
# Ajuste para los que tienen mas de diez aparezcan en la categoría 10+

df_mxmunicipio_2020 |> 
  safejoin::safe_left_join(declaratorias |> 
                             distinct(identificador, .keep_all = T) |>
                             tabyl(clave_municipio) |> 
                             mutate(clave_municipio = str_pad(clave_municipio, 5, side = "left", pad = "0")) |> 
                             rename(value = n),
                           by = c("region" = "clave_municipio")) |> 
  mutate(across(value, ~ replace_na(., 0))) |> 
  mutate(value = ifelse(value >= 10, "10+", value)) |> 
  tabyl(value) |>
  adorn_totals() |> 
  mutate(across(where("is.numeric"), \(x) round(x, 4)),
         percent = percent*100) |> 
  arrange(value)

# Mapas por tipo de fenómeno ----------------------------------------------
# En los siguientes códigos se realizan los mapas por tipo de fenómeno:
# Se reliza un código para cada uno (en lugar de una función) para
# ajustar los colores de los mapas

# LLUVIAS -----------------------------------------------------------------
# A NIVEL ESTATAL

declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Lluvias") |> 
  tabyl(clave_estado) |> 
  arrange(-n)

mxmaps::df_mxstate_2020 |>
  left_join(declaratorias |> 
              distinct(identificador, .keep_all = T) |>
              filter(tipo_fenomeno == "Lluvias") |> 
              count(clave_estado) |>
              rename(declaratorias = n) |>
              mutate(across(clave_estado, ~ str_pad(., 2, side = "left", pad = "0"))),
            by = c("region" = "clave_estado")) |>
  rename(value = declaratorias) |>
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxstate_choropleth(num_colors = 7,
                     title = "Estados con la mayor cantidad de declaratorias de emergencia por lluvias de enero de 2006 a noviembre de 2022") +
  scale_fill_manual(values = c("#b3e4d2", "#8ed8bd", "#6acba8", "#45bf93", "#369d78", "#29795c", "#1d5440"), na.value="gray35")

# MUNICIPIO

declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Lluvias") |> 
  tabyl(clave_municipio) |> 
  arrange(-n)

df_mxmunicipio_2020 |> 
  safejoin::safe_left_join(declaratorias |> 
                             distinct(identificador, .keep_all = T) |>
                             filter(tipo_fenomeno == "Lluvias") |> 
                             tabyl(clave_municipio) |> 
                             mutate(clave_municipio = str_pad(clave_municipio, 5, side = "left", pad = "0")) |> 
                             rename(value = n),
                           by = c("region" = "clave_municipio")) |> 
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxmunicipio_choropleth(num_colors = 1,
                         title = "Municipios con la mayor cantidad de declaratorias de emergencia por lluvias de enero de 2006 a noviembre de 2022") +
  scale_fill_gradient("", low = "white", high = "#1d5440")

# Nevadas y heladas -------------------------------------------------------

declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Nevadas, Heladas, Granizadas") |> 
  tabyl(clave_estado) |> 
  arrange(-n)

mxmaps::df_mxstate_2020 |>
  left_join(declaratorias |> 
              distinct(identificador, .keep_all = T) |>
              filter(tipo_fenomeno == "Nevadas, Heladas, Granizadas") |> 
              count(clave_estado) |>
              rename(declaratorias = n) |>
              mutate(across(clave_estado, ~ str_pad(., 2, side = "left", pad = "0"))),
            by = c("region" = "clave_estado")) |>
  rename(value = declaratorias) |>
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxstate_choropleth(num_colors = 7,
                     title = "Estados con la mayor cantidad de declaratorias de emergencia por Nevadas, Heladas, Granizadas de enero de 2006 a noviembre de 2022") +
  scale_fill_manual(values = c("#f2d6dd", "#e7b0bf", "#dc8aa0", "#d16481", "#c63f62", "#7d253c", "#581a2a"), na.value="gray35")

#MUNI

declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Nevadas, Heladas, Granizadas") |> 
  tabyl(clave_municipio) |> 
  arrange(-n)

df_mxmunicipio_2020 |> 
  safejoin::safe_left_join(declaratorias |> 
                             distinct(identificador, .keep_all = T) |>
                             filter(tipo_fenomeno == "Nevadas, Heladas, Granizadas") |> 
                             tabyl(clave_municipio) |> 
                             mutate(clave_municipio = str_pad(clave_municipio, 5, side = "left", pad = "0")) |> 
                             rename(value = n),
                           by = c("region" = "clave_municipio")) |> 
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxmunicipio_choropleth(num_colors = 1,
                         title = "Municipios con la mayor cantidad de declaratorias de emergencia por Nevadas, Heladas, Granizada de enero de 2006 a noviembre de 2022") +
  scale_fill_gradient("", low = "white", high = "#581a2a")


# Ciclón ------------------------------------------------------------------
declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Ciclón Tropical") |> 
  tabyl(clave_estado) |> 
  arrange(-n)

declaratorias |> 
  tabyl(tipo_fenomeno)

mxmaps::df_mxstate_2020 |>
  left_join(declaratorias |> 
              distinct(identificador, .keep_all = T) |>
              filter(tipo_fenomeno == "Ciclón Tropical") |> 
              count(clave_estado) |>
              rename(declaratorias = n) |>
              mutate(across(clave_estado, ~ str_pad(., 2, side = "left", pad = "0"))),
            by = c("region" = "clave_estado")) |>
  rename(value = declaratorias) |>
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxstate_choropleth(num_colors = 7,
                     title = "Estados con la mayor cantidad de declaratorias de emergencia por Ciclones Tropicales de enero de 2006 a noviembre de 2022") +
  scale_fill_manual(values = c("#CB8AFF", "#B75CFF", "#A32EFF", "#8F00FF", "#7500D1", "#5C00A3", "#420075"), na.value="gray55")


declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Ciclón Tropical") |> 
  tabyl(clave_municipio) |> 
  arrange(-n)

df_mxmunicipio_2020 |> 
  safejoin::safe_left_join(declaratorias |> 
                             distinct(identificador, .keep_all = T) |>
                             filter(tipo_fenomeno == "Ciclón Tropical") |> 
                             tabyl(clave_municipio) |> 
                             mutate(clave_municipio = str_pad(clave_municipio, 5, side = "left", pad = "0")) |> 
                             rename(value = n),
                           by = c("region" = "clave_municipio")) |> 
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxmunicipio_choropleth(num_colors = 1,
                         title = "Municipios con la mayor cantidad de declaratorias de emergencia por Ciclones de enero de 2006 a noviembre de 2022") +
  scale_fill_gradient("", low = "white", high = "#420075")

declaratorias |> 
  tabyl(tipo_fenomeno)


# Temperatura extrema -----------------------------------------------------
declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Temperatura Extrema") |> 
  tabyl(clave_estado) |> 
  arrange(-n)

declaratorias |> 
  tabyl(tipo_fenomeno)

mxmaps::df_mxstate_2020 |>
  left_join(declaratorias |> 
              distinct(identificador, .keep_all = T) |>
              filter(tipo_fenomeno == "Temperatura Extrema") |> 
              count(clave_estado) |>
              rename(declaratorias = n) |>
              mutate(across(clave_estado, ~ str_pad(., 2, side = "left", pad = "0"))),
            by = c("region" = "clave_estado")) |>
  rename(value = declaratorias) |>
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxstate_choropleth(num_colors = 1,
                     title = "Estados con la mayor cantidad de declaratorias de emergencia por temperaturas extremas de enero de 2006 a noviembre de 2022") +
  scale_fill_gradient("", low = "white", high = "#CD2A1C")


declaratorias |> 
  distinct(identificador, .keep_all = T) |>
  filter(tipo_fenomeno == "Temperatura Extrema") |> 
  tabyl(clave_municipio) |> 
  arrange(-n)

df_mxmunicipio_2020 |> 
  safejoin::safe_left_join(declaratorias |> 
                             distinct(identificador, .keep_all = T) |>
                             filter(tipo_fenomeno == "Temperatura Extrema") |> 
                             tabyl(clave_municipio) |> 
                             mutate(clave_municipio = str_pad(clave_municipio, 5, side = "left", pad = "0")) |> 
                             rename(value = n),
                           by = c("region" = "clave_municipio")) |> 
  mutate(across(value, ~ replace_na(., 0))) |> 
  mxmunicipio_choropleth(num_colors = 1,
                         title = "Municipios con la mayor cantidad de declaratorias de emergencia por temperaturas extremas de enero de 2006 a noviembre de 2022") +
  scale_fill_gradient("", low = "white", high = "#CD2A1C")


