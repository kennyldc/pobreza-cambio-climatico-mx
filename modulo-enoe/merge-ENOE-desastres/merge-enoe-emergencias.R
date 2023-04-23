# Merge ENOE con declaratorias de emergencia
# Nota que para este file se puede leer el archivo de declaratorias
# directamente desde el archivo de google drive
# Sin embargo, para el archivo de enoe sí es necesario tenerlo descargado

# Librerías y lecturas de files --------------------------------------------
# Traemos los paquetes relevantes a la sesión de R con p_load
# Si no tienes la librería pacman el siguiente código lo instalará
if (!require("pacman")) install.packages("pacman")
# Con p_load podemos traer a sesión todas las librerías que usaremos
pacman::p_load(tidyverse, janitor, lubridate, googlesheets4, ISOweek)

# Declaratorias de emergencia -----------------------------------------------------------
# Recordemos que necesitamos el archivo de declaratorias
declaratorias <- read.csv(sprintf("https://drive.google.com/uc?id=%s&export=download",
                                  "1Jlyrcq3XWR7QDn3RPU2R3Ee_ryNMSDOl"),
                          fileEncoding = "Latin1", check.names = F) |> 
  clean_names() |> # la opción de clean_names convierte los nombres de las columnas en camel_case
  mutate(across(c(fecha_publicacion:fecha_fin), ~ dmy(.)), # las columnas de fechas las vamos a volver date class
         across(c(clave_estado, clave_municipio), ~as.character(.))) # las claves del estado y del municipio no son propiamente números, son identificadores y las pondremos como character 

# Recordemos también que solo necesitamos las declaratorias de emergencia y solo para ciertos años
declaratorias <- declaratorias |> 
  filter(tipo_declaratoria == "Emergencia") |> 
  filter(fecha_inicio > "2006-01-01")

# Las observaciones de declaratorias son "poco problemáticas" para unirlas con las observaciones de declaratorias
# En realidad, la única transformación necesaria es juntar los municipios con los estados

declaratorias <- declaratorias |>
  mutate(clave_municipio = str_sub(clave_municipio, start= -3),
         across(c(clave_municipio, clave_estado), ~ as.integer(.)),
         llave_ent_mun = paste0(clave_estado, "-", clave_municipio))

# ENOE --------------------------------------------------------------------
# Vamos a cambiar de el directorio para traer la base de ENOE
# Aquí tendrás que cambiar el directorio al de tu computadora
setwd("/Users/carloslopezdelacerda/Library/CloudStorage/GoogleDrive-caribaz@gmail.com/Mi unidad/CEES-EASE/Proyecto Pobreza y Cambio Climático/archivos-de-trabajo/datos/transformados/enoe_sdem/")

# Para poder leer los datos a la sesión
enoe <- readRDS("tbl_enoe.rds")

# Ajustamos algunas variables tales como la de entidad
# para que correspondan al formato de dos dígitos que tienen las declaratorias
enoe <- enoe |>
  mutate(ent = str_pad(ent, 2, "left", "0"))

# En este proyecto nos propusimos imputar una fecha de entrevista a cada uno de los registros de la ENOE
# Esto aumenta de manera importante la precisión con la que podemos medir el impacto de los desastres ante diferentes
# ventanas de tiempo.
# No obstante, para lograr poner la fecha de la entrevista tenemos que hacer algunas transformaciones
# PREPARANDO EL FACTOR "TIEMPO" DE LA UNIÓN
# Lo primero con la base es separar el trimestre, el año, la semana y el mes.
enoe <- enoe |>
  mutate(trimestre = str_sub(per, 1,1),
         year = str_sub(per, 2,3),
         semana_de_trim = if_else(ur == 1, str_sub(d_sem, 2,3), NA_character_),
         mes_de_trim = if_else(ur == 2, str_sub(d_sem, 2,3), NA_character_))
# Adicionalmente tenemos que separar a las observaciones del sector urbano con respecto a la rural
# Esto ocurre porque en las observaciones urbanas se registra con mucho mayor precisión la semana del trimestre
# en la que se les entrevistó. 
# En el caso de los individuos en zonas rurales solo se puede conocer el mes en el que se les entrevistó
# Creamos un GoogleSheets adicional para entender la "correspondencia" de las semanas del trimestre con 
# las semanas que tiene un año
# Por ejemplo la semana 1 del trimestre 1 es igual a la semana 1 del año, pero es un poco más difícil
# saber a que semana del año corresponde la semana 4 del trimestre 3 (por ejemplo). El Sheets hace estas conversiones
conversion <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1hTEyUOvY98D5YkuxSG6cX4VZ4W4HCf_0Wa69xJdvl9o/edit?usp=sharing",
                                        "semanas-trimestres") |>
  clean_names()

# El siguiente código une la información de la semana-año para cada observación del tipo urbano.
# Pero también crea una columna llamada consecutivo rural que identifica el (mes-año) de las entrevistas rurales
# Al final, utilizaremos esa información de las observaciones rurales aumentando el supuesto de que las entrevistas rurales
# se hicieron el primer día del mes.
enoe <- enoe |>
  mutate(llave = paste0(semana_de_trim, "-", trimestre)) |>
  # pegamos la info con la semana año que corresponde a cada semana trimestre
  safejoin::safe_left_join(conversion |>
                             mutate(across(semana_de_trimestre, ~ str_pad(., 2, side = "left", pad = "0")),
                                    llave = paste0(semana_de_trimestre, "-", trimestre)) |>
                             select(consecutivo, llave), check = "m", na_matches = "never") |>
  select(-llave) |>
  # creamos el identificador consecutivo urbano para los casos urbanos
  # y el identificador consecutivo rural para los casos rurales
  mutate(consecutivo_urbano = if_else(!is.na(consecutivo), paste0(consecutivo,"-","20",year), NA_character_),
         consecutivo_rural = if_else(is.na(consecutivo), paste0("20",year,"-", mes_de_trim), NA_character_))

# Guardando ENOE (paso intermedio) ----------------------------------------
# Como se ha notado hasta el momento, el número de observaciones de la ENOE es enorme
# A pesar de solo tener a individuos de 15 ó mas años, estas corresponden a 7,283,301
# Por las restricciones computacionales que una base de este tamaño impone, 
# En lo posterior trabajaremos con el subconjunto de datos urbanos por un lado (qué también dividiremos en 2)
# Y el subconjunto de datos rurales

# Podemos guardar la base que hemos trabajado hasta ahora en el directorio de trabajo
#enoe |> saveRDS(file = "enoe_para_separar.rds")
# Básicamente este es un checkpoint
enoe <- readRDS("enoe_para_separar.rds")

# Casos urbanos -----------------------------------------------------------
# Para superar los desafíos computacionales de los que se hablaba hace un momento
# trabajaremos de manera inicial con los casos urbanos
# Es necesario separar la base y trabajarla "por partes"

# El siguiente código, filtra las observaciones para solo tener las de este subconjunto y
# convierte "la semana del año" en una fecha específica utilizando la función ISOweek2date.
# Este paso es importante ya que a partir de ese punto las observaciones urbanas tienen una única fecha

urbanas_reps <- enoe |>
  filter(!is.na(consecutivo_urbano)) |>
  mutate(semana_iso = paste0("20", year, "-", "W", consecutivo,"-1"),
         date_entrevista = ISOweek2date(semana_iso)) |>
  select(-semana_iso)
remove(enoe)

# Adicionalmente debemos agregar un factor geográfico
# El siguiente elemento necesario para la unión es pegar los municipios-estados
# Crearemos una "llave" que esté compuesta por el número de la entidad y el número de municipio
# Para el caso de la enoe
# Creamos una función que cree la llave pegando entidad y municipio
crea_llave <- function(dataset){
  dataset |>
    mutate(across(c(mun, ent), ~ as.integer(.)),
           llave_ent_mun = paste0(ent, "-", mun))
}

# La aplicamos para el caso urbano
urbanas_reps <- urbanas_reps |> 
  crea_llave()

# Con las observaciones urbanas podemos crear una "mega base" que combina cada una de
# las observaciones de la ENOE con TODOS los desastres que se han vivido en su municipio
# desde 2010. Una vez que tenemos es "mega base" podemos filtrar el número de días anteriores 
# a la entrevista. Esto lo haremos con los cortes especificados en el cuerpo del texto
# 1) desastres en los últimos 90 días antes de la encuesta
# 2) desastres entre los 91 y 180 días antes de la encuesta
# 3) desastres entre 181 y 360 días antes de la encuesta
# 4) .... ...... ...... 361 y 540 días.................
# 5) ...................541 y 720 días.................
# 6) ...................721 y 1800 días................

# Crearemos una función puesto que repetiremos este paso para las observaciones rurales

crea_observaciones_con_declaratorias <- function(dataset){
  dataset |>
    safejoin::safe_left_join(declaratorias, na_matches = "never", check = "m") |>
    mutate(tiempo_inicio = (fecha_inicio - date_entrevista)*-1,
           tiempo_publicacion = (fecha_publicacion - date_entrevista) *-1,
           tiempo_fin = (fecha_fin - date_entrevista) *-1) |>
    filter(tiempo_inicio >= 0 & tiempo_publicacion >= 0 & tiempo_fin >= 0)
}

observaciones_con_declaratorias_urbanas <- urbanas_reps |> crea_observaciones_con_declaratorias()

# Vamos a empezar a crear las ventanas temporales que especificamos arriba. 
# Crearemos funciones porque repetiremos este paso con con las rurales
# El código es una especie de "remedial" (workaround) ya que no hay un id único de las personas
# Lo que hace este código es que separa a todas las personas de la ENOE para después separar
# de TODOS los eventos que pudo haber vivido solo quedarse con los de cierto rango de días antes de la encuesta
# Además los crea con formato de columna donde cada columna tiene el tipo de delito y el rango al que hace referencia
# También identifica que si no hay desastres de ese tipo el valor correcto es de 0

# La parte inicial del proceso es igual para todas solo cambiando el rango de días. 
# Pero después de eso se tiene que realizar una para cada rango puesto que las columnas tienen un formato específico

recorte_rango <- function(dataset, lim_inf, lim_sup){
  dataset |>
    group_by(r_def, mun, est, est_d, ageb, t_loc, 
             cd_a, ent, con, upm, d_sem, n_pro_viv, v_sel, 
             n_hog, h_mud, n_ent, per, n_ren, c_res, par_c, 
             sex, eda, nac_dia, nac_mes, nac_anio, l_nac_c, 
             cs_p12, cs_p13_1, cs_p13_2, cs_p14_c, cs_p15, 
             cs_p16, cs_p17, n_hij, e_con, cs_ad_mot, 
             cs_p20_des, cs_ad_des, cs_nr_mot, cs_p22_des, 
             cs_nr_ori, ur, zona, salario, fac, clase1, 
             clase2, clase3, pos_ocu, seg_soc, rama, c_ocu11c, 
             ing7c, dur9c, emple7c, medica5c, buscar5c, rama_est1,
             rama_est2, dur_est, ambito1, ambito2, tue1, tue2, tue3,
             busqueda, d_ant_lab, d_cexp_est, dur_des, sub_o,
             s_clasifi, remune2c, pre_asa, tip_con, dispo, nodispo,
             c_inac5c, pnea_est, niv_ins, eda5c, eda7c, eda12c,
             eda19c, hij5c, domestico, anios_esc, hrsocup, ingocup,
             ing_x_hrs, tpg_p8a, tcco, cp_anoc, imssissste, ma48me1sm, 
             p14apoyos, scian, t_tra, emp_ppal, tue_ppal, trans_ppal, 
             mh_fil2, mh_col, sec_ins, est_d_tri, est_d_men, t_loc_tri,
             t_loc_men, fac_tri, fac_men, tipo, mes_cal, ca, cs_p20a_1,
             cs_p20a_c, cs_p20b_1, cs_p20b_c, cs_p20c_1, cs_p21_des,
             cs_p23_des, llave_ent_mun, tipo_fenomeno) %>%
    filter(tiempo_inicio >= lim_inf & tiempo_inicio <= lim_sup) |>
    count()
}

fenomenos_0_90 <- function(dataset, lim_inf, lim_sup){
  data_intermedia <- recorte_rango(dataset, lim_inf, lim_sup) |>
    pivot_wider(names_from = "tipo_fenomeno",
                values_from = "n",
                names_glue = "{tipo_fenomeno}_ultimos_{90}") |>
    clean_names() |>
    ungroup()
  data_final <- data_intermedia %>%
    mutate_if(grepl("ultimos_90", names(.)), funs(replace(., is.na(.), 0))) |>
    mutate(suma_ultimos_90 = rowSums(data_intermedia[,grep("ultimos_90",colnames(data_intermedia))], na.rm = TRUE))
  return(data_final)
}

fenomenos_91_180 <- function(dataset, lim_inf, lim_sup){
  data_intermedia <- recorte_rango(dataset, lim_inf, lim_sup) |>
    pivot_wider(names_from = "tipo_fenomeno",
                values_from = "n",
                names_glue = "{tipo_fenomeno}_ultimos_{180}") |>
    clean_names() |>
    ungroup()
  data_final <- data_intermedia %>%
    mutate_if(grepl("ultimos_180", names(.)), funs(replace(., is.na(.), 0))) |>
    mutate(suma_ultimos_180 = rowSums(data_intermedia[,grep("ultimos_180",colnames(data_intermedia))], na.rm = TRUE))
  return(data_final)
}

fenomenos_181_360 <- function(dataset, lim_inf, lim_sup){
  data_intermedia <- recorte_rango(dataset, lim_inf, lim_sup) |>
    pivot_wider(names_from = "tipo_fenomeno",
                values_from = "n",
                names_glue = "{tipo_fenomeno}_ultimos_{360}") |>
    clean_names() |>
    ungroup()
  data_final <- data_intermedia %>%
    mutate_if(grepl("ultimos_360", names(.)), funs(replace(., is.na(.), 0))) |>
    mutate(suma_ultimos_360 = rowSums(data_intermedia[,grep("ultimos_360",colnames(data_intermedia))], na.rm = TRUE))
  return(data_final)
}

fenomenos_361_540 <- function(dataset, lim_inf, lim_sup){
  data_intermedia <- recorte_rango(dataset, lim_inf, lim_sup) |>
    pivot_wider(names_from = "tipo_fenomeno",
                values_from = "n",
                names_glue = "{tipo_fenomeno}_ultimos_{540}") |>
    clean_names() |>
    ungroup()
  data_final <- data_intermedia %>%
    mutate_if(grepl("ultimos_540", names(.)), funs(replace(., is.na(.), 0))) |>
    mutate(suma_ultimos_540 = rowSums(data_intermedia[,grep("ultimos_540",colnames(data_intermedia))], na.rm = TRUE))
  return(data_final)
}

fenomenos_541_720 <- function(dataset, lim_inf, lim_sup){
  data_intermedia <- recorte_rango(dataset, lim_inf, lim_sup) |>
    pivot_wider(names_from = "tipo_fenomeno",
                values_from = "n",
                names_glue = "{tipo_fenomeno}_ultimos_{720}") |>
    clean_names() |>
    ungroup()
  data_final <- data_intermedia %>%
    mutate_if(grepl("ultimos_720", names(.)), funs(replace(., is.na(.), 0))) |>
    mutate(suma_ultimos_720 = rowSums(data_intermedia[,grep("ultimos_720",colnames(data_intermedia))], na.rm = TRUE))
  return(data_final)
}

fenomenos_721_1800 <- function(dataset, lim_inf, lim_sup){
  data_intermedia <- recorte_rango(dataset, lim_inf, lim_sup) |>
    pivot_wider(names_from = "tipo_fenomeno",
                values_from = "n",
                names_glue = "{tipo_fenomeno}_ultimos_{1800}") |>
    clean_names() |>
    ungroup()
  data_final <- data_intermedia %>%
    mutate_if(grepl("ultimos_1800", names(.)), funs(replace(., is.na(.), 0))) |>
    mutate(suma_ultimos_1800 = rowSums(data_intermedia[,grep("ultimos_1800",colnames(data_intermedia))], na.rm = TRUE))
  return(data_final)
}

# Ahora aplicamos la función que genera el conteo y además
# agregamos código para que los guarde en la computadora de manera local
# El paso de guardarlas no es obligatorio pero sí es recomendable ya que 
# los códigos tardan mucho tiempo es común dejarlos trabajando

# 1) de 0 a 90
fenomenos_ultimos_0a90_urbanos <- observaciones_con_declaratorias_urbanas |> fenomenos_0_90(0,90)
fenomenos_ultimos_0a90_urbanos |> saveRDS(file = "fenomenos_ultimos_0a90_urbanos.rds")

# 2) 91 a 180
fenomenos_ultimos_91a180_urbanos <- observaciones_con_declaratorias_urbanas |> fenomenos_91_180(91,180)
fenomenos_ultimos_91a180_urbanos |> saveRDS(file = "fenomenos_ultimos_91a180_urbanos.rds")

# 2) 181 a 360
fenomenos_ultimos_181a360_urbanos <- observaciones_con_declaratorias_urbanas |> fenomenos_181_360(181,360)
fenomenos_ultimos_181a360_urbanos |> saveRDS(file = "fenomenos_ultimos_181a360_urbanos.rds")

# 2) 361 a 540
fenomenos_ultimos_361a540_urbanos <- observaciones_con_declaratorias_urbanas |> fenomenos_361_540(361,540)
fenomenos_ultimos_361a540_urbanos |> saveRDS(file = "fenomenos_ultimos_361a540_urbanos.rds")

# 2) 541 a 720
fenomenos_ultimos_541a720_urbanos <- observaciones_con_declaratorias_urbanas |> fenomenos_541_720(541,720)
fenomenos_ultimos_541a720_urbanos |> saveRDS(file = "fenomenos_ultimos_541a720_urbanos.rds")

# 2) 721 a 1800
fenomenos_ultimos_721a1800_urbanos <- observaciones_con_declaratorias_urbanas |> fenomenos_721_1800(721,1800)
fenomenos_ultimos_721a1800_urbanos |> saveRDS(file = "fenomenos_ultimos_721a1800_urbanos.rds")
beepr::beep()

# Casos RURALES -----------------------------------------------------------
# Ahora podemos seguir el mismo procedimiento que ejecutamos para las observaciones urbanas pero con las rurales
# Recordemos que tenemos que separar la base porque es muy grande
enoe <- readRDS("enoe_para_separar.rds")

# En el caso de las observaciones rurales, la información no es tan granular. 
# El INEGI solo reporta en qué mes los entrevistaron. PAra poder superar este desafío,
# tendremos que asumir que la entrevista fue en la primera semana de esos meses.

rurales_reps <- enoe |>
  filter(!is.na(consecutivo_rural)) |>
  mutate(date_entrevista = paste0(consecutivo_rural,"-","01"),
         across(date_entrevista, ~ as.Date(.)))

# Agregamos la llave para el factor geográfico
rurales_reps <- rurales_reps |> crea_llave()

# podemos hacer ahora la "mega base" que tiene TODOS los desastres
# y después filtrar con esa información los diferentes rangos de días

observaciones_con_declaratorias_rurales <- rurales_reps |> crea_observaciones_con_declaratorias()
# El paso final

# 1) de 0 a 90
fenomenos_ultimos_0a90_rurales <- observaciones_con_declaratorias_rurales |> fenomenos_0_90(0,90)
fenomenos_ultimos_0a90_rurales |> saveRDS(file = "fenomenos_ultimos_0a90_rurales.rds")

# 2) 91 a 180
fenomenos_ultimos_91a180_rurales <- observaciones_con_declaratorias_rurales |> fenomenos_91_180(91,180)
fenomenos_ultimos_91a180_rurales |> saveRDS(file = "fenomenos_ultimos_91a180_rurales.rds")

# 2) 181 a 360
fenomenos_ultimos_181a360_rurales <- observaciones_con_declaratorias_rurales |> fenomenos_181_360(181,360)
fenomenos_ultimos_181a360_rurales |> saveRDS(file = "fenomenos_ultimos_181a360_rurales.rds")

# 2) 361 a 540
fenomenos_ultimos_361a540_rurales <- observaciones_con_declaratorias_rurales |> fenomenos_361_540(361,540)
fenomenos_ultimos_361a540_rurales |> saveRDS(file = "fenomenos_ultimos_361a540_rurales.rds")

# 2) 541 a 720
fenomenos_ultimos_541a720_rurales <- observaciones_con_declaratorias_rurales |> fenomenos_541_720(541,720)
fenomenos_ultimos_541a720_rurales |> saveRDS(file = "fenomenos_ultimos_541a720_rurales.rds")

# 2) 721 a 1800
fenomenos_ultimos_721a1800_rurales <- observaciones_con_declaratorias_rurales |> fenomenos_721_1800(721,1800)
fenomenos_ultimos_721a1800_rurales |> saveRDS(file = "fenomenos_ultimos_721a1800_rurales.rds")

# Juntando los casos urbanos con rurales en una misma base --------
# Vamos a empezar juntando a los urbanos
fenomenos_ultimos_0a90_urbanos <- readRDS(file = "fenomenos_ultimos_0a90_urbanos.rds")
fenomenos_ultimos_91a180_urbanos <- readRDS(file = "fenomenos_ultimos_91a180_urbanos.rds")
fenomenos_ultimos_181a360_urbanos <- readRDS(file = "fenomenos_ultimos_181a360_urbanos.rds")
fenomenos_ultimos_361a540_urbanos <- readRDS(file = "fenomenos_ultimos_361a540_urbanos.rds")
fenomenos_ultimos_541a720_urbanos <- readRDS(file = "fenomenos_ultimos_541a720_urbanos.rds")
fenomenos_ultimos_721a1800_urbanos <- readRDS(file = "fenomenos_ultimos_721a1800_urbanos.rds")

# Creamos una función que "corrige" las clases 
# de algunas variables relevantes
corrige_clase <- function(dataset){
  dataset |>
    mutate(across(c(mun,ent), ~ as.character(.)))
}

urbanas_reps <- urbanas_reps |> corrige_clase()
fenomenos_ultimos_0a90_urbanos <- fenomenos_ultimos_0a90_urbanos |>
  corrige_clase()
fenomenos_ultimos_91a180_urbanos <- fenomenos_ultimos_91a180_urbanos |> 
  corrige_clase()
fenomenos_ultimos_181a360_urbanos <- fenomenos_ultimos_181a360_urbanos |> 
  corrige_clase()
fenomenos_ultimos_361a540_urbanos <- fenomenos_ultimos_361a540_urbanos |> 
  corrige_clase()
fenomenos_ultimos_541a720_urbanos <- fenomenos_ultimos_541a720_urbanos |> 
  corrige_clase()
fenomenos_ultimos_721a1800_urbanos <- fenomenos_ultimos_721a1800_urbanos |> 
  corrige_clase()

# Ahora juntamos los fenómenos a las observaciones de cada individuo
urbanas_enoe_con_fenomenos <- urbanas_reps |>
  safejoin::safe_left_join(fenomenos_ultimos_0a90_urbanos) |>
  safejoin::safe_left_join(fenomenos_ultimos_91a180_urbanos) |>
  safejoin::safe_left_join(fenomenos_ultimos_181a360_urbanos) |>
  safejoin::safe_left_join(fenomenos_ultimos_361a540_urbanos) |>
  safejoin::safe_left_join(fenomenos_ultimos_541a720_urbanos) |>
  safejoin::safe_left_join(fenomenos_ultimos_721a1800_urbanos)

# Ajustamos las variables para que en los casos que exista un NA pongamos un 0
urbanas_enoe_con_fenomenos <- urbanas_enoe_con_fenomenos %>%
  mutate_if(grepl("ultimos", names(.)), funs(replace(., is.na(.), 0)))

# De nuevo guardamos porque es una base computacional enorme
# y no podríamos seguir teniendola en la sesión
urbanas_enoe_con_fenomenos |> saveRDS(file = "urbanas_enoe_con_fenomenos.rds")

# Repetimos el proceso para las rurales
rurales_reps <- rurales_reps |> crea_llave()
fenomenos_ultimos_0a90_rurales <- readRDS(file = "fenomenos_ultimos_0a90_rurales.rds")
fenomenos_ultimos_91a180_rurales <- readRDS(file = "fenomenos_ultimos_91a180_rurales.rds")
fenomenos_ultimos_181a360_rurales <- readRDS(file = "fenomenos_ultimos_181a360_rurales.rds")
fenomenos_ultimos_361a540_rurales <- readRDS(file = "fenomenos_ultimos_361a540_rurales.rds")
fenomenos_ultimos_541a720_rurales <- readRDS(file = "fenomenos_ultimos_541a720_rurales.rds")
fenomenos_ultimos_721a1800_rurales <- readRDS(file = "fenomenos_ultimos_721a1800_rurales.rds")

rurales_enoe_con_fenomenos <- rurales_reps |>
  safejoin::safe_left_join(fenomenos_ultimos_0a90_rurales) |>
  safejoin::safe_left_join(fenomenos_ultimos_91a180_rurales) |>
  safejoin::safe_left_join(fenomenos_ultimos_181a360_rurales) |>
  safejoin::safe_left_join(fenomenos_ultimos_361a540_rurales) |>
  safejoin::safe_left_join(fenomenos_ultimos_541a720_rurales) |>
  safejoin::safe_left_join(fenomenos_ultimos_721a1800_rurales)

rurales_enoe_con_fenomenos <- rurales_enoe_con_fenomenos %>%
  mutate_if(grepl("ultimos", names(.)), funs(replace(., is.na(.), 0)))

# guardamos para no tener que consumir recursos de la sesión
rurales_enoe_con_fenomenos |> saveRDS(file = "rurales_enoe_con_fenomenos.rds")

## Por último, llegamos al paso de simplemte juntarlas
# ejecutar este código limpiará todo de la sesión:
remove(list = ls())
# Con ambas secciones necesitamos homologar las columnas para pegar la base -----------------------------------------------------
# Leemos ambas en la sesión

urbanas_enoe_con_fenomenos <- readRDS(file = "urbanas_enoe_con_fenomenos.rds")
rurales_enoe_con_fenomenos <- readRDS(file = "rurales_enoe_con_fenomenos.rds")

# Vamos a ver que variables no están en las dos bases para hacerlas del mismo tamaño y luego pegarlas
setdiff(names(urbanas_enoe_con_fenomenos), names(rurales_enoe_con_fenomenos))
# Poniendo las columnas que no están en rurales
rurales_enoe_con_fenomenos <- rurales_enoe_con_fenomenos |> 
  mutate("temperatura_extrema_ultimos_90" = 0,     
         "actividad_volcanica_ultimos_90" = 0,
         "lluvias_ciclon_tropical_ultimos_90" = 0, 
         "hundimiento_ultimos_90" = 0,
         "tornado_ultimos_90" = 0,                 
         "fuertes_vientos_ultimos_180" = 0,
         "tornado_ultimos_180" = 0,                
         "nevadas_ultimos_180" = 0,                
         "ciclon_tropical_lluvias_ultimos_360" = 0,
         "lluvias_ciclon_tropical_ultimos_360" = 0,
         "hundimiento_ultimos_540" = 0,
         "ciclon_tropical_lluvias_ultimos_720" = 0,
         "lluvias_ciclon_tropical_ultimos_720" = 0,
         "deslave_ultimos_1800" = 0)

setdiff(names(rurales_enoe_con_fenomenos), names(urbanas_enoe_con_fenomenos))
urbanas_enoe_con_fenomenos <- urbanas_enoe_con_fenomenos |> 
  mutate("lluvias_inundacion_ultimos_180" = 0,         
         "inundacion_ciclon_tropical_ultimos_180" = 0,
         "lluvias_inundacion_ultimos_360" = 0,         
         "lluvias_inundacion_ultimos_540" = 0,         
         "inundacion_ciclon_tropical_ultimos_540" = 0,
         "lluvias_inundacion_ultimos_720" = 0,         
         "lluvias_inundacion_ultimos_1800" = 0,    
         "heladas_granizadas_nevadas_ultimos_1800" = 0,
         "inundacion_ciclon_tropical_ultimos_1800" = 0)

# Para poder ver cuántas personas diferentes existen en la base necesitamos un identificador por persona
# En las encuestas de la ENOE este dato no existe por lo que es necesario
# construirle un identificador "sintético" o imputado a cada persona.
# La alternativa más viable para solucionar este problema consiste en usar la fecha de nacimiento y 
# los identificadores de su hogar. Esta es prácticamente la única solución 
# posible para identificar a las personas de manera única.

urbanas_enoe_con_fenomenos <- urbanas_enoe_con_fenomenos |>
  mutate(identificador_persona = paste0(upm,"-",n_pro_viv,"-",v_sel, "-", n_hog, "-", nac_dia,"-", nac_mes, "-", nac_anio))

rurales_enoe_con_fenomenos <- rurales_enoe_con_fenomenos |>
  mutate(identificador_persona = paste0(upm,"-",n_pro_viv,"-",v_sel, "-", n_hog, "-", nac_dia,"-", nac_mes, "-", nac_anio))

# ponemos las columnas en el mismo órden para hacer el rbind
urbanas_enoe_con_fenomenos <- urbanas_enoe_con_fenomenos |>
  select(r_def:llave_ent_mun, all_of(names(urbanas_enoe_con_fenomenos) |> 
                                       sort()))
rurales_enoe_con_fenomenos <- rurales_enoe_con_fenomenos |>
  select(r_def:llave_ent_mun, all_of(names(urbanas_enoe_con_fenomenos) |> 
                                       sort()))

# El paso final consiste en volver a pegar las observaciones del lado urbano
# con las observaciones del lado rural
# Nuestro nuevo dataset tiene el mismo número de observaciones que el 
# dataset con el que empezamos el proceso de la ENOE, pero ahora
# ya incluye las columnas con la cantidad de desastres que ocurrieron
# de determinado tipo de fenómeno en cada corte temporal (t)

enoe_fenomenos <- rbind(urbanas_enoe_con_fenomenos,
                        rurales_enoe_con_fenomenos)

# Al igual que antes, podemos guardar ese dataset (nuestro output)
# Este será el que utilicemos para el análisis y los modelos de regresión
enoe_fenomenos |> 
  saveRDS(file = "enoe_fenomenos_nueva.rds")

# Ajustes a la base post-algoritmo para comenzar las estimaciones ---------

# Con este datset tenemos la información de todos los participantes de la ENOE (tantas veces como hayan respondido la encuesta)
# junto con columnas que indican la cantidad de desastres a la que han sido expuestos
# en los últimos 0 a 90 días, 91 a 180 días, 181 a 360 días, 361 a 540 días, 
# 541 a 720 días y 721 a 1800 días
# La información viene desagregada por tipo de fenómeno según la información original de la base de declaratorias:
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

# Problemas con el identificador:
# En pasos previos de este código creamos un identificador por persona el cuál 
# sale de combinar la fecha de nacimiento con alguna información identificadora del hogar
# Sin embargo, uno de los ajustes post-algoritmo retoma este asunto
# ya que esa solución (además de ser la única) tiene algunos problemas que necesitan
# ajustarse antes de utilizar la base para las estimaciones.

# Notamos que algunos de los identificadores no 
# son útiles puesto que las personas no supieron responder su fecha de nacimiento.
# Lamentablemente no hay manera de reparar este problema dado que sin la 
# fecha de nacimiento no hay manera de identificar de manera única a las personas
# El problema afecta al 8% de la base que dada su magnitud parece ser un problema menor

numero_de_veces_que_aparece_persona <- enoe_fenomenos |>
  filter(nac_dia != "99" & nac_mes != "99" & nac_anio != "9999") |>
  group_by(identificador_persona) |>
  count()

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

# Notamos que mientras el tamaño original de enoe_fenomenos (post algoritmo) era de 7,283,301
# Con el ajuste obtenemos 6,587,307 observaciones. Bastante útil para continuar con el analisis

# El último ajuste relevante consistió en crear categorías de tipo de desastre más precisas 
# para agrupar todas las que venían originalmente en CENAPRED.
# Por ejemplo, en CENAPRED original era posible identificar tipos de desastre: 
# i) inundación, ii) lluvias y iii) lluvias e inundación. 
# Esto es un problema en el sentido que nos está dando información redundante y que bien podríamos agrupar todo en una misma categoría: lluvias.

# Algo similar pasa con otros de los tipos de desastres por lo que optamos por las siguientes categorías:
#   
# Lluvias e inundaciones
# Ciclón tropical
# Temperaturas extremas
# Heladas y nevadas

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

# Esta base es la que podemos guardar de cara a las estadísticas
# descriptivas y a las estimaciones

enoe_fenomenos |> 
  saveRDS(file = "enoe_fenomenos_nueva.rds")