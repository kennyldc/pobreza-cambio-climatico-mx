# Construcción ENOE

# En estre código se muestra el proceso de juntar las 25 bases de datos SDEM
# en una sola base que se utilizará para el resto el análisis. 

# Librerías y lectura del file --------------------------------------------

# Traemos los paquetes relevantes a la sesión de R con p_load
# Si no tienes la librería pacman el siguiente código lo instalará
if (!require("pacman")) install.packages("pacman")
# Con p_load podemos traer a sesión todas las librerías que usaremos
pacman::p_load(tidyverse, janitor)

# Una condición previa a ejecutar el siguiente código es tener descargadas
# las 25 bases de datos sdem que se pueden bajar de INEGI
# En nuestro caso, ya las decargamos y almacenamos en una misma carpeta
# Puedes encontrar esta carpeta y descargar los files a local
# en el siguiente link: https://drive.google.com/drive/folders/1P08DNeSjzI2NvKd0wyzdEDPdqtca-Ksl?usp=sharing

# ENOE --------------------------------------------------------------------
# Vamos a cambiar el directorio para que esté en la carpeta 
# local donde tengo unicamente las bases de sdem de todos los años

# NOTA: SI QUIERES REPLICAR ESTE PROCESO TIENES QUE CAMBIAR EL DIRECTORIO AL QUE CORRESPONDA A TU COMPUTADORA
# Como alternativa puedes utilizar directamente el file del output (ver última línea)

setwd("/Users/carloslopezdelacerda/Library/CloudStorage/GoogleDrive-caribaz@gmail.com/Mi unidad/CEES-EASE/Proyecto Pobreza y Cambio Climático/archivos-de-trabajo/datos/crudos/enoe/sdem_todos/")

# con este código se pueden leer todos los archivos csv de las bases demográficas y juntarlas
# a un solo dataframe

# NOTA: ESTE CÓDIGO UTILIZA MUCHOS RECURSOS COMPUTACIONALES
# DEPENDIENDO DE LA CAPACIDAD DE TU EQUIPO SERÁ LA VELOCIDAD CON LA QUE 
# SE EJECUTE EL PROCESO. SIN EMBARGO, ES TARDADO
tbl <- list.files(pattern = "*.csv") %>%
  map_df(~read_csv(., col_types = cols(.default = "c"),
                   name_repair = ~ tolower(.)))

# Hay que notar que en esta base estarán TODAS las columnas de TODOS los años.
# Si en algún año no hubiera información de esa columna, en ese caso toda queda con valores de NA

# Quitamos aquellos casos en los que pudiera haber un row con solo NA
tbl <- tbl |> 
  remove_empty()

# con este ajuste tenemos nuestra nueva base de 9,803,789 entradas y 119 columnas

# Podemos quitar a las personas menores de 15 años
tbl <- tbl |>
  mutate(across(eda, ~ as.numeric(.))) |>
  filter(eda >= 15)

# Salvamos la versión completa de todas las enoe
saveRDS(tbl, file = "tbl_enoe.rds")

# Este archivo con todas las observaciones se encuentra directamente
# almacenado en la nube de Google Drive. Puedes bajarlo en tu computadora
# en el siguiente link: https://drive.google.com/file/d/1LJTjBMrTME-y-DMm0guL5XNBPAGbMOTK/view?usp=sharing
