# Estimaciones ENOE desastres

# Recordemos del resto de nuestros códigos que el dataset de trabajo
# (enoe-desastres) se puede descargar directamente desde Google Drive
# en la siguiente liga: https://drive.google.com/file/d/1CMJvgDnB9FjN0AIoLyHBTR2L43uazy1j/view

# Esta base de datos se construyó por medio de unir información económica
# de 25 trimestres de la ENOE con los diferentes tipos de desastres que registró
# el CENAPRED desde 2016.

# Librerías y lecturas de files --------------------------------------------
# Traemos los paquetes relevantes a la sesión de R con p_load
# Si no tienes la librería pacman el siguiente código lo instalará
if (!require("pacman")) install.packages("pacman")
# Con p_load podemos traer a sesión todas las librerías que usaremos
pacman::p_load(tidyverse, janitor, safejoin, lfe, broom, googlesheets4, alpaca)

# cambiando el directorio
# En este paso es necesario que el usuario cambie de manera manual su directorio
# de trabajo y ponga aquel donde descargó la base de datos de trabajo
setwd("/Users/carloslopezdelacerda/Library/CloudStorage/GoogleDrive-caribaz@gmail.com/Mi unidad/CEES-EASE/Proyecto Pobreza y Cambio Climático/archivos-de-trabajo/datos/transformados/enoe_sdem/")
# leyendo la base de ENOE con los fenomenos
enoe_fenomenos <- readRDS(file = "enoe_fenomenos_nueva.rds")

# Estimaciones con efectos fijos ------------------------------------------
## Hay algunas de las variables en la enoe que tienen la clase incorrecta
# Corregimos con 
enoe_fenomenos <- enoe_fenomenos |>
  mutate(across(c(eda, hrsocup, ingocup, ing_x_hrs), ~ as.numeric(.)))

# Al tener las variables en la clase correcta podemos entonces correr algunas regresiones de efectos fijos
# Se recomienda ver la discusión de este asunto en el documento que se preparó de manera adjunta. 
# Pero, por lo pronto, sirva recordar que los modelos de efectos fijos controlan por el elemento de tiempo (en ese caso el período)
# Y por la unidad de observación (en este caso el individuo que contestó la enoe)

# Regresiones de tipo efectos fijos  -----------------------------------------

# Para facilitar la presentación de los resultados se crea la siguiente función que utiliza los pasos del paquete lfe
# Pero regresa solamente una tabla con un formato mucho más exportable
# Esta nueva regresión es útil para variables dependientes CONTINUAS.
# El procedimiento utiliza OLS con los efectos fijos ya especificados

reg_felm <-  function(indicador_dependiente, independiente_dias, data_enoe){
  indicador_dependiente <- deparse(substitute(indicador_dependiente))
  f <- formula(paste(indicador_dependiente, "~", independiente_dias, "| identificador_persona + per | 0 | identificador_persona")) # specification with 2way fixed effects and class formula
  regresion <- data_enoe %>% felm(f, data=.)
  tabla <- summary(regresion)$coefficients # gets the coefficients info (coef, sd, p value)
  tabla <- tibble::rownames_to_column(as.data.frame(tabla), "termino") # format the results to dataframe
  adjr <- tibble(adj_r_squared = summary(regresion)$r.squared) # gets the adjusted R2 of the regression
  variable_dependiente <- tibble(DependentVar = indicador_dependiente)
  tabla <- cbind(variable_dependiente, tabla, adjr) # adds the adjusted R to the dataframe in order to get a summary
  tabla <- tabla |> mutate(Significance = case_when(`Pr(>|t|)` <= 0.01 ~ "***",
                                                    (`Pr(>|t|)` > 0.01 & `Pr(>|t|)` <= 0.05) ~ "**",
                                                    (`Pr(>|t|)` > 0.05 & `Pr(>|t|)` <= 0.1) ~ "*",
                                                    TRUE ~ ""), .after = Estimate)
  tabla <- tabla |> mutate(Percent_change_by_unit = (exp(Estimate)-1) * 100, .after = Significance)
  return(tabla)
}

# Además creamos un vector con todos las posibles variables independientes
# que corresponden a las diferentes combinaciones de tipo de fenómeno y del número de días

combinaciones_tiempo <- c("suma_ultimos_90",
                          "suma_ultimos_180",
                          "suma_ultimos_360",
                          "suma_ultimos_540",
                          "suma_ultimos_720",
                          "suma_ultimos_1800")

# Ingreso mensual como variable dependiente -------------------------------
# Uno de los primeros experimentos que podemos realizar consiste en estimar el efecto de los desastres:
# sobre el ingreso mensual de las personas

# Estas serían nuestras estimaciones "base" ya que contemplan a TODOS los desastres naturales
# en todas las combinaciones posibles de tiempo.

# En la ecuación se plantea la clásica solución de aumentar una constante a la variable dependiente
# de manera que podamos calcular el logaritmo natural.

# Un ejemplo de qué estamos "corriendo en R" es el siguiente
regresion <- felm(log(ingocup+1) ~ suma_ultimos_90 | identificador_persona + per | 0 | identificador_persona, data=enoe_fenomenos)
# En este ejemplo estamos usando ln(ingreso + 1) como dependiente y la suma de todos los desastres de 0 a 90 dias
# como variable independiente.

# Para nuestro ejemplo podemos correr 
regresion |> summary()
# En cuyo caso veremos los coeficientes y demás información útil

# Nótese como tenemos una variedad enorme de combinaciones en cuanto a variables independientes
# provocadas por el hecho de que tenemos distintos cortes de tiempo
# y distintos tipos de fenómeno natural

# sería ineficiente escribir regresión por regresión y una de nuestras ventajas
# comparativas en el estudio es el uso de R

# Simplificamos todo el proceso de escribir una y otra vez el código de las estimaciones
# Utilizando la función map_df de la librería purr. 
# Nosotros simplemente tenemos que pasarle el vector con las combinaciones
# de tiempo (algo que hicimos más arriba)
# Y R se encarga de correr determinada función (en nuestro casa la tabla que saca
# la info de las regresiones) tantas veces hasta llegar al número de elementos del vector
# que nosotros le pasamos

estimaciones_con_ingreso <- map_df(combinaciones_tiempo, \(x) reg_felm(log(ingocup+1), x, enoe_fenomenos))
# Como es un proceso de alto costo computacional, dejamos el código funcionando y cuando 
# acabe de ejectuarlo pondrá los resultados en un spreadsheet de Google.

estimaciones_con_ingreso |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                        sheet = "Estimaciones_Todos")

# El siguiente paso consiste en hacer el mismpo procedimiento pero en esta ocasión para los diferentes
# tipos de fenómenos naturales

# LA ventaja de nuestra base consiste en que se puede separar el efecto por tipo de fenómeno
# De manera que podemos ver el impacto de las lluvias/temperaturas extremas/heladas, etc.
# Nos concentraremos en las emergencias naturales que con mayor frecuencia afectaron a las personas

# Tal como se pudo identificar en el análisis descriptivo, el fenómeno que más afecta a las personas
# son las lluvias. Dicho eso, podemos repetir la estimación pero solo considerando a las lluvias como variable independiente
startTime <- Sys.time()

enoe_fenomenos <- enoe_fenomenos |> 
  mutate(resto_desastres_lluvia_ultimos_90 = suma_ultimos_90 - categoria_lluvias_e_inundaciones_ultimos_90,
         resto_desastres_lluvia_ultimos_180 = suma_ultimos_180 - categoria_lluvias_e_inundaciones_ultimos_180,
         resto_desastres_lluvia_ultimos_360 = suma_ultimos_360 - categoria_lluvias_e_inundaciones_ultimos_360,
         resto_desastres_lluvia_ultimos_540 = suma_ultimos_540 - categoria_lluvias_e_inundaciones_ultimos_540,
         resto_desastres_lluvia_ultimos_720 = suma_ultimos_720 - categoria_lluvias_e_inundaciones_ultimos_720,
         resto_desastres_lluvia_ultimos_1800 = suma_ultimos_1800 - categoria_lluvias_e_inundaciones_ultimos_1800) 

combinaciones_lluvias <- c("categoria_lluvias_e_inundaciones_ultimos_90 + resto_desastres_lluvia_ultimos_90",
                           "categoria_lluvias_e_inundaciones_ultimos_180 + resto_desastres_lluvia_ultimos_180",
                           "categoria_lluvias_e_inundaciones_ultimos_360 + resto_desastres_lluvia_ultimos_360",
                           "categoria_lluvias_e_inundaciones_ultimos_540 + resto_desastres_lluvia_ultimos_540",
                           "categoria_lluvias_e_inundaciones_ultimos_720 + resto_desastres_lluvia_ultimos_720",
                           "categoria_lluvias_e_inundaciones_ultimos_1800 + resto_desastres_lluvia_ultimos_1800")

lluvias_con_ingreso <- map_df(combinaciones_lluvias, \(x) reg_felm(log(ingocup+1), x, enoe_fenomenos))
lluvias_con_ingreso |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                   sheet = "Estimaciones_Lluvias")

# Podemos también visualizar el efecto del segundo tipo de fenómeno que más afecta: el ciclón tropical
startTime <- Sys.time()
enoe_fenomenos <- enoe_fenomenos |> 
  mutate(resto_desastres_ciclon_ultimos_90 = suma_ultimos_90 - categoria_ciclon_tropical_ultimos_90,
         resto_desastres_ciclon_ultimos_180 = suma_ultimos_180 - categoria_ciclon_tropical_ultimos_180,
         resto_desastres_ciclon_ultimos_360 = suma_ultimos_360 - categoria_ciclon_tropical_ultimos_360,
         resto_desastres_ciclon_ultimos_540 = suma_ultimos_540 - categoria_ciclon_tropical_ultimos_540,
         resto_desastres_ciclon_ultimos_720 = suma_ultimos_720 - categoria_ciclon_tropical_ultimos_720,
         resto_desastres_ciclon_ultimos_1800 = suma_ultimos_1800 - categoria_ciclon_tropical_ultimos_1800) 


ciclon_tropical <- c("categoria_ciclon_tropical_ultimos_90 + resto_desastres_ciclon_ultimos_90",
                     "categoria_ciclon_tropical_ultimos_180 + resto_desastres_ciclon_ultimos_180",
                     "categoria_ciclon_tropical_ultimos_360 + resto_desastres_ciclon_ultimos_360",
                     "categoria_ciclon_tropical_ultimos_540 + resto_desastres_ciclon_ultimos_540",
                     "categoria_ciclon_tropical_ultimos_720 + resto_desastres_ciclon_ultimos_720",
                     "categoria_ciclon_tropical_ultimos_1800 + resto_desastres_ciclon_ultimos_1800")

ciclon_con_ingreso <- map_df(ciclon_tropical, \(x) reg_felm(log(ingocup+1), x, enoe_fenomenos))
ciclon_con_ingreso |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                  sheet = "Estimaciones_Ciclon")

# Y también las estimaciones del tercer fenómeno más importante: temperatura extrema
enoe_fenomenos <- enoe_fenomenos |> 
  mutate(resto_desastres_temperaturas_ultimos_90 = suma_ultimos_90 - categoria_temperaturas_extremas_ultimos_90,
         resto_desastres_temperaturas_ultimos_180 = suma_ultimos_180 - categoria_temperaturas_extremas_ultimos_180,
         resto_desastres_temperaturas_ultimos_360 = suma_ultimos_360 - categoria_temperaturas_extremas_ultimos_360,
         resto_desastres_temperaturas_ultimos_540 = suma_ultimos_540 - categoria_temperaturas_extremas_ultimos_540,
         resto_desastres_temperaturas_ultimos_720 = suma_ultimos_720 - categoria_temperaturas_extremas_ultimos_720,
         resto_desastres_temperaturas_ultimos_1800 = suma_ultimos_1800 - categoria_temperaturas_extremas_ultimos_1800) 

temperatura_extrema <- c("categoria_temperaturas_extremas_ultimos_90 + resto_desastres_temperaturas_ultimos_90",
                         "categoria_temperaturas_extremas_ultimos_180 + resto_desastres_temperaturas_ultimos_180",
                         "categoria_temperaturas_extremas_ultimos_360 + resto_desastres_temperaturas_ultimos_360",
                         "categoria_temperaturas_extremas_ultimos_540 + resto_desastres_temperaturas_ultimos_540",
                         "categoria_temperaturas_extremas_ultimos_720 + resto_desastres_temperaturas_ultimos_720",
                         "categoria_temperaturas_extremas_ultimos_1800 + resto_desastres_temperaturas_ultimos_1800")

temperatura_extrema_con_ingreso <- map_df(temperatura_extrema, \(x) reg_felm(log(ingocup+1), x, enoe_fenomenos))
temperatura_extrema_con_ingreso |>  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                sheet = "Estimaciones_Temperatura")

# Por último, veremos las del cuarto tipo de fenómeno que afecta más: heladas
enoe_fenomenos <- enoe_fenomenos |> 
  mutate(resto_desastres_heladas_ultimos_90 = suma_ultimos_90 - categoria_heladas_y_nevadas_ultimos_90,
         resto_desastres_heladas_ultimos_180 = suma_ultimos_180 - categoria_heladas_y_nevadas_ultimos_180,
         resto_desastres_heladas_ultimos_360 = suma_ultimos_360 - categoria_heladas_y_nevadas_ultimos_360,
         resto_desastres_heladas_ultimos_540 = suma_ultimos_540 - categoria_heladas_y_nevadas_ultimos_540,
         resto_desastres_heladas_ultimos_720 = suma_ultimos_720 - categoria_heladas_y_nevadas_ultimos_720,
         resto_desastres_heladas_ultimos_1800 = suma_ultimos_1800 - categoria_heladas_y_nevadas_ultimos_1800) 

heladas <- c("categoria_heladas_y_nevadas_ultimos_90 + resto_desastres_heladas_ultimos_90",
             "categoria_heladas_y_nevadas_ultimos_180 + resto_desastres_heladas_ultimos_180",
             "categoria_heladas_y_nevadas_ultimos_360 + resto_desastres_heladas_ultimos_360",
             "categoria_heladas_y_nevadas_ultimos_540 + resto_desastres_heladas_ultimos_540",
             "categoria_heladas_y_nevadas_ultimos_720 + resto_desastres_heladas_ultimos_720",
             "categoria_heladas_y_nevadas_ultimos_1800 + resto_desastres_heladas_ultimos_1800")

heladas_con_ingreso <- map_df(heladas, \(x) reg_felm(log(ingocup+1), x))
heladas_con_ingreso |>  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                    sheet = "Estimaciones_Heladas")


# Género en Ingreso mensual (todos)  --------------------------------------
combinaciones_tiempo_sexo <- c("suma_ultimos_90 + sex + suma_ultimos_90*sex",
                               "suma_ultimos_180 + sex + suma_ultimos_180*sex",
                               "suma_ultimos_360 + sex + suma_ultimos_360*sex",
                               "suma_ultimos_540 + sex + suma_ultimos_540*sex",
                               "suma_ultimos_720 + sex + suma_ultimos_720*sex",
                               "suma_ultimos_1800 + sex + suma_ultimos_1800*sex")

combinaciones_lluvias_sexo <- c("categoria_lluvias_e_inundaciones_ultimos_90 + resto_desastres_lluvia_ultimos_90 + sex + categoria_lluvias_e_inundaciones_ultimos_90*sex",
                           "categoria_lluvias_e_inundaciones_ultimos_180 + resto_desastres_lluvia_ultimos_180 + sex + categoria_lluvias_e_inundaciones_ultimos_180*sex",
                           "categoria_lluvias_e_inundaciones_ultimos_360 + resto_desastres_lluvia_ultimos_360 + sex + categoria_lluvias_e_inundaciones_ultimos_360*sex",
                           "categoria_lluvias_e_inundaciones_ultimos_540 + resto_desastres_lluvia_ultimos_540 + sex + categoria_lluvias_e_inundaciones_ultimos_540*sex",
                           "categoria_lluvias_e_inundaciones_ultimos_720 + resto_desastres_lluvia_ultimos_720 + sex + categoria_lluvias_e_inundaciones_ultimos_720*sex",
                           "categoria_lluvias_e_inundaciones_ultimos_1800 + resto_desastres_lluvia_ultimos_1800 + sex + categoria_lluvias_e_inundaciones_ultimos_1800*sex")

ciclon_tropical_sexo <- c("categoria_ciclon_tropical_ultimos_90 + resto_desastres_ciclon_ultimos_90 + sex + categoria_ciclon_tropical_ultimos_90*sex",
                     "categoria_ciclon_tropical_ultimos_180 + resto_desastres_ciclon_ultimos_180 + sex + categoria_ciclon_tropical_ultimos_180*sex",
                     "categoria_ciclon_tropical_ultimos_360 + resto_desastres_ciclon_ultimos_360 + sex + categoria_ciclon_tropical_ultimos_360*sex",
                     "categoria_ciclon_tropical_ultimos_540 + resto_desastres_ciclon_ultimos_540 + sex + categoria_ciclon_tropical_ultimos_540*sex",
                     "categoria_ciclon_tropical_ultimos_720 + resto_desastres_ciclon_ultimos_720 + sex + categoria_ciclon_tropical_ultimos_720*sex",
                     "categoria_ciclon_tropical_ultimos_1800 + resto_desastres_ciclon_ultimos_1800 + sex + categoria_ciclon_tropical_ultimos_1800*sex")

temperatura_extrema_sexo <- c("categoria_temperaturas_extremas_ultimos_90 + resto_desastres_temperaturas_ultimos_90 + sex + categoria_temperaturas_extremas_ultimos_90*sex",
                         "categoria_temperaturas_extremas_ultimos_180 + resto_desastres_temperaturas_ultimos_180 + sex + categoria_temperaturas_extremas_ultimos_180*sex",
                         "categoria_temperaturas_extremas_ultimos_360 + resto_desastres_temperaturas_ultimos_360 + sex + categoria_temperaturas_extremas_ultimos_360*sex",
                         "categoria_temperaturas_extremas_ultimos_540 + resto_desastres_temperaturas_ultimos_540 + sex + categoria_temperaturas_extremas_ultimos_540*sex",
                         "categoria_temperaturas_extremas_ultimos_720 + resto_desastres_temperaturas_ultimos_720 + sex + categoria_temperaturas_extremas_ultimos_720*sex",
                         "categoria_temperaturas_extremas_ultimos_1800 + resto_desastres_temperaturas_ultimos_1800 + sex + categoria_temperaturas_extremas_ultimos_1800*sex")

heladas_sexo <- c("categoria_heladas_y_nevadas_ultimos_90 + resto_desastres_heladas_ultimos_90 + sex + categoria_heladas_y_nevadas_ultimos_90*sex",
             "categoria_heladas_y_nevadas_ultimos_180 + resto_desastres_heladas_ultimos_180 + sex + categoria_heladas_y_nevadas_ultimos_180*sex",
             "categoria_heladas_y_nevadas_ultimos_360 + resto_desastres_heladas_ultimos_360 + sex + categoria_heladas_y_nevadas_ultimos_360*sex",
             "categoria_heladas_y_nevadas_ultimos_540 + resto_desastres_heladas_ultimos_540 + sex + categoria_heladas_y_nevadas_ultimos_540*sex",
             "categoria_heladas_y_nevadas_ultimos_720 + resto_desastres_heladas_ultimos_720 + sex + categoria_heladas_y_nevadas_ultimos_720*sex",
             "categoria_heladas_y_nevadas_ultimos_1800 + resto_desastres_heladas_ultimos_1800 + sex + categoria_heladas_y_nevadas_ultimos_1800*sex")

start <- Sys.time()

map_df(combinaciones_tiempo_sexo,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
         write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Ingresos_Genero")

map_df(combinaciones_lluvias_sexo,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Ingresos_lluvias_Genero")
map_df(ciclon_tropical_sexo,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |>
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Ingresos_ciclon_Genero")

map_df(temperatura_extrema_sexo,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Ingresos_temperatura_Genero")

map_df(heladas_sexo,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Ingresos_heladas_Genero")

# Urbano/Rural en Ingreso mensual (todos)  --------------------------------------

combinaciones_tiempo_urbano <- c("suma_ultimos_90 + ur + suma_ultimos_90*ur",
                               "suma_ultimos_180 + ur + suma_ultimos_180*ur",
                               "suma_ultimos_360 + ur + suma_ultimos_360*ur",
                               "suma_ultimos_540 + ur + suma_ultimos_540*ur",
                               "suma_ultimos_720 + ur + suma_ultimos_720*ur",
                               "suma_ultimos_1800 + ur + suma_ultimos_1800*ur")

combinaciones_lluvias_urbano <- c("categoria_lluvias_e_inundaciones_ultimos_90 + resto_desastres_lluvia_ultimos_90 + ur + categoria_lluvias_e_inundaciones_ultimos_90*ur",
                                "categoria_lluvias_e_inundaciones_ultimos_180 + resto_desastres_lluvia_ultimos_180 + ur + categoria_lluvias_e_inundaciones_ultimos_180*ur",
                                "categoria_lluvias_e_inundaciones_ultimos_360 + resto_desastres_lluvia_ultimos_360 + ur + categoria_lluvias_e_inundaciones_ultimos_360*ur",
                                "categoria_lluvias_e_inundaciones_ultimos_540 + resto_desastres_lluvia_ultimos_540 + ur + categoria_lluvias_e_inundaciones_ultimos_540*ur",
                                "categoria_lluvias_e_inundaciones_ultimos_720 + resto_desastres_lluvia_ultimos_720 + ur + categoria_lluvias_e_inundaciones_ultimos_720*ur",
                                "categoria_lluvias_e_inundaciones_ultimos_1800 + resto_desastres_lluvia_ultimos_1800 + ur + categoria_lluvias_e_inundaciones_ultimos_1800*ur")

ciclon_tropical_urbano <- c("categoria_ciclon_tropical_ultimos_90 + resto_desastres_ciclon_ultimos_90 + ur + categoria_ciclon_tropical_ultimos_90*ur",
                          "categoria_ciclon_tropical_ultimos_180 + resto_desastres_ciclon_ultimos_180 + ur + categoria_ciclon_tropical_ultimos_180*ur",
                          "categoria_ciclon_tropical_ultimos_360 + resto_desastres_ciclon_ultimos_360 + ur + categoria_ciclon_tropical_ultimos_360*ur",
                          "categoria_ciclon_tropical_ultimos_540 + resto_desastres_ciclon_ultimos_540 + ur + categoria_ciclon_tropical_ultimos_540*ur",
                          "categoria_ciclon_tropical_ultimos_720 + resto_desastres_ciclon_ultimos_720 + ur + categoria_ciclon_tropical_ultimos_720*ur",
                          "categoria_ciclon_tropical_ultimos_1800 + resto_desastres_ciclon_ultimos_1800 + ur + categoria_ciclon_tropical_ultimos_1800*ur")

temperatura_extrema_urbano <- c("categoria_temperaturas_extremas_ultimos_90 + resto_desastres_temperaturas_ultimos_90 + ur + categoria_temperaturas_extremas_ultimos_90*ur",
                              "categoria_temperaturas_extremas_ultimos_180 + resto_desastres_temperaturas_ultimos_180 + ur + categoria_temperaturas_extremas_ultimos_180*ur",
                              "categoria_temperaturas_extremas_ultimos_360 + resto_desastres_temperaturas_ultimos_360 + ur + categoria_temperaturas_extremas_ultimos_360*ur",
                              "categoria_temperaturas_extremas_ultimos_540 + resto_desastres_temperaturas_ultimos_540 + ur + categoria_temperaturas_extremas_ultimos_540*ur",
                              "categoria_temperaturas_extremas_ultimos_720 + resto_desastres_temperaturas_ultimos_720 + ur + categoria_temperaturas_extremas_ultimos_720*ur",
                              "categoria_temperaturas_extremas_ultimos_1800 + resto_desastres_temperaturas_ultimos_1800 + ur + categoria_temperaturas_extremas_ultimos_1800*ur")

heladas_urbano <- c("categoria_heladas_y_nevadas_ultimos_90 + resto_desastres_heladas_ultimos_90 + ur + categoria_heladas_y_nevadas_ultimos_90*ur",
                  "categoria_heladas_y_nevadas_ultimos_180 + resto_desastres_heladas_ultimos_180 + ur + categoria_heladas_y_nevadas_ultimos_180*ur",
                  "categoria_heladas_y_nevadas_ultimos_360 + resto_desastres_heladas_ultimos_360 + ur + categoria_heladas_y_nevadas_ultimos_360*ur",
                  "categoria_heladas_y_nevadas_ultimos_540 + resto_desastres_heladas_ultimos_540 + ur + categoria_heladas_y_nevadas_ultimos_540*ur",
                  "categoria_heladas_y_nevadas_ultimos_720 + resto_desastres_heladas_ultimos_720 + ur + categoria_heladas_y_nevadas_ultimos_720*ur",
                  "categoria_heladas_y_nevadas_ultimos_1800 + resto_desastres_heladas_ultimos_1800 + ur + categoria_heladas_y_nevadas_ultimos_1800*ur")

map_df(combinaciones_tiempo_urbano,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_Urbano")

map_df(combinaciones_lluvias_urbano,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_lluvias_Urbano")

map_df(ciclon_tropical_urbano,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_ciclon_Urbano")

map_df(temperatura_extrema_urbano,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_temperatura_Urbano")

map_df(heladas_urbano,
       \(x) reg_felm(log(ingocup+1), x, 
                     enoe_fenomenos |>
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_heladas_Urbano")

# Ingreso mensual para aquellos individuos con ingreso positivo -----------
# Ahora repetiremos lo mismo pero para los individuos con ingreso positivo
map_df(combinaciones_tiempo,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |> 
                       filter(ingocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                        sheet = "Estimaciones_IngPositivos")

map_df(combinaciones_lluvias,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |> 
                       filter(ingocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "IngPositivos_lluvias")
map_df(ciclon_tropical,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |> 
                       filter(ingocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "IngPositivos_ciclon")

map_df(temperatura_extrema,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |> 
                       filter(ingocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "IngPositivos_temperatura")

map_df(heladas,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |> 
                       filter(ingocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "IngPositivos_heladas")

# GENERO EN INGRESO MENSUAL POSITIVO --------------------------------------

map_df(combinaciones_tiempo_sexo,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_Positivos_Genero")

start <- Sys.time()
map_df(combinaciones_lluvias_sexo,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_Positivos_Lluvias_Genero")

map_df(ciclon_tropical_sexo,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_Positivos_Ciclon_Genero")

map_df(temperatura_extrema_sexo,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_Positivos_Temperatura_Genero")

map_df(heladas_sexo,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Ingresos_Positivos_Heladas_Genero")

# URBANO EN INGRESO MENSUAL POSITIVO --------------------------------------
start <- Sys.time()

ing_pos1 <- map_df(combinaciones_tiempo_urbano,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur))))

ing_pos2 <- map_df(combinaciones_lluvias_urbano,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) 
  
ing_pos3 <- map_df(ciclon_tropical_urbano,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) 


ing_pos4 <- map_df(temperatura_extrema_urbano,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur))))
ing_pos5 <- map_df(heladas_sexo,
       \(x) reg_felm(log(ingocup), x, 
                     enoe_fenomenos |>
                       filter(ingocup > 0) |> 
                       mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                              ur = as.factor(ur)))) 

ing_pos1 |>  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
            sheet = "Ingresos_Positivos_Urbano")
ing_pos2 |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
            sheet = "Ingresos_Positivos_Lluvias_Urbano")
ing_pos3 |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
            sheet = "Ingresos_Positivos_Ciclon_Urbano")
ing_pos4 |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                          sheet = "Ingresos_Positivos_Temperatura_Urbano")
ing_pos5 |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
            sheet = "Ingresos_Positivos_Heladas_Urbano")

# Horas trabajadas (todas las observaciones) ------------------------------
# Repetimos el proceso de ingreso
estimaciones_con_horas <- map_df(combinaciones_tiempo, \(x) reg_felm(log(hrsocup+0.5), x))
estimaciones_con_horas |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                      sheet = "Horas_Estimaciones_Todos")

## Luvias 
lluvias_con_horas <- map_df(combinaciones_lluvias, \(x) reg_felm(log(hrsocup+0.5), x))
lluvias_con_horas |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                 sheet = "Horas_Estimaciones_Lluvias")

## Ciclón 
ciclon_con_horas <- map_df(ciclon_tropical, \(x) reg_felm(log(hrsocup+0.5), x))
ciclon_con_horas |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                sheet = "Horas_Estimaciones_Ciclon")

## Temperaturas extremas
temperatura_extrema_horas <- map_df(temperatura_extrema, \(x) reg_felm(log(hrsocup+0.5), x))
temperatura_extrema_horas |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                         sheet = "Horas_Estimaciones_Temperatura")

## Heladas
heladas_con_horas <- map_df(heladas, \(x) reg_felm(log(hrsocup+0.5), x))
heladas_con_horas |>write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                sheet = "Horas_Estimaciones_Heladas")

# Género en horas trabajadas (todos) --------------------------------------
start <- Sys.time()

map_df(combinaciones_tiempo_sexo,
       \(x) reg_felm(log(hrsocup + 0.5), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Horas_Trabajadas_Genero")

map_df(combinaciones_lluvias_sexo,
       \(x) reg_felm(log(hrsocup + 0.5), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Horas_Trabajadas_lluvias_Genero")

map_df(ciclon_tropical_sexo,
       \(x) reg_felm(log(hrsocup + 0.5), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |>
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Horas_trabajadas_ciclon_Genero")

map_df(temperatura_extrema_sexo,
       \(x) reg_felm(log(hrsocup + 0.5), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Horas_trabajadas_temperatura_Genero")

map_df(heladas_sexo,
       \(x) reg_felm(log(hrsocup + 0.5), x, 
                     enoe_fenomenos |>
                       mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                              sex = as.factor(sex)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
              sheet = "Horas_trabajadas_heladas_Genero")


# Urbano/rural en horas trabajadas (todos) --------------------------------

genera_spread_sheet_horas_trabajadas <- function(combinaciones, nombre_dep){
  map_df(combinaciones,
         \(x) reg_felm(log(hrsocup + 0.5), x, 
                       enoe_fenomenos |>
                         mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                                ur = as.factor(ur)))) |> 
    write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                sheet = paste0(nombre_dep,"_Urbano"))
}

combinaciones_tiempo_urbano |> 
  genera_spread_sheet_horas_trabajadas("Horas_trabajadas")

combinaciones_lluvias_urbano |> 
  genera_spread_sheet_horas_trabajadas("Horas_trabajadas_lluvias")

ciclon_tropical_urbano |> 
  genera_spread_sheet_horas_trabajadas("Horas_trabajadas_ciclon")

temperatura_extrema_urbano |> 
  genera_spread_sheet_horas_trabajadas("Horas_trabajadas_temperatura")

heladas_urbano |> 
  genera_spread_sheet_horas_trabajadas("Horas_trabajadas_heladas")

end <- Sys.time()
print(end-start)
beepr::beep()

# Horas trabajadas personas con horas trabajadas positivas ----------------

# nótese que las personas con horas trabajadas positivas
# son todas ocupadas

enoe_fenomenos |> 
  filter(hrsocup > 0) |> 
  tabyl(clase2)

map_df(combinaciones_tiempo,
       \(x) reg_felm(log(hrsocup), x, 
                     enoe_fenomenos |> 
                       filter(hrsocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Horas_positivas_todos")
map_df(combinaciones_lluvias,
       \(x) reg_felm(log(hrsocup), x, 
                     enoe_fenomenos |> 
                       filter(hrsocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Horas_positivas_lluvias")
                                                            
map_df(ciclon_tropical,
       \(x) reg_felm(log(hrsocup), x, 
                     enoe_fenomenos |> 
                       filter(hrsocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Horas_positivas_ciclon")

map_df(temperatura_extrema,
       \(x) reg_felm(log(hrsocup), x, 
                     enoe_fenomenos |> 
                       filter(hrsocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Horas_positivas_temperatura")

map_df(heladas,
       \(x) reg_felm(log(hrsocup), x, 
                     enoe_fenomenos |> 
                       filter(hrsocup > 0))) |> write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                                                            sheet = "Horas_positivas_heladas")

# GÉNERO EN HORAS TRABAJADAS POSITIVAS ------------------------------------
start <- Sys.time()

genera_spreadsheet_genero_horas_positivas <- function(combinaciones, nombre_dep){
  map_df(combinaciones,
         \(x) reg_felm(log(hrsocup), x, 
                       enoe_fenomenos |>
                         filter(hrsocup > 0) |> 
                         mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
                                sex = as.factor(sex)))) |> 
    write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                sheet = paste0(nombre_dep,"_Genero"))
}

combinaciones_tiempo_sexo |> 
  genera_spreadsheet_genero_horas_positivas("Horas_Positivas")

combinaciones_lluvias_sexo |> 
  genera_spreadsheet_genero_horas_positivas("Horas_Positivas_Lluvias")

ciclon_tropical_sexo |> 
  genera_spreadsheet_genero_horas_positivas("Horas_Positivas_Ciclon")

temperatura_extrema_sexo |> 
  genera_spreadsheet_genero_horas_positivas("Horas_Positivas_Temperatura")

heladas_sexo |> 
  genera_spreadsheet_genero_horas_positivas("Horas_Positivas_Heladas")

# URBANO/RURAL EN HORAS TRABAJADAS POSITIVAS ------------------------------

genera_spreadsheet_urbano_horas_positivas <- function(combinaciones, nombre_dep){
  map_df(combinaciones,
         \(x) reg_felm(log(hrsocup), x, 
                       enoe_fenomenos |>
                         filter(hrsocup > 0) |> 
                         mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
                                ur = as.factor(ur)))) |> 
  write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                sheet = paste0(nombre_dep,"_Urbano"))
}

combinaciones_tiempo_urbano |> 
  genera_spreadsheet_urbano_horas_positivas("Horas_Positivas")

combinaciones_lluvias_urbano |> 
  genera_spreadsheet_urbano_horas_positivas("Horas_Positivas_Lluvias")

ciclon_tropical_urbano |> 
  genera_spreadsheet_urbano_horas_positivas("Horas_Positivas_Ciclon")

temperatura_extrema_urbano |> 
  genera_spreadsheet_urbano_horas_positivas("Horas_Positivas_Temperatura")

heladas_urbano |> 
  genera_spreadsheet_urbano_horas_positivas("Horas_Positivas_Heladas")

# Segundo modelo de efectos fijos. Regresiones binomiales  ---------------------------------------------------
# Nuestra segunda versión del modelo de efectos fijos consiste en especificar
# una regresión de tipo binomial donde podamos usar como variables dependientes
# algunas indicadoras. Esta puede ser la prob de desempleo, de inactivo, etc

# En el texto que se preparó de manera djunta a este código se pueden identificar
# las ecuaciones exactas que se plantean. 
# En términos de programación basta con mencionar que se utilizó la librería alpaca
# Que permite estimar regresiones binomiales para diferentes ligas (logit o probit)

# Para que nuestros resultados salgan en formato de tabla, de nueva cuenta
# especificamos una función que permita obtener los coeficientes y la información 
# relevante de los outputs de manera sencilla.

# A nuestra función le debemos especificar la variable dependiente. 
# la variable independiente y la "liga", pudiendo esta última ser probit o logit

reg_binfelm <-  function(indicador_dependiente, independiente_dias, familia_liga){
  indicador_dependiente <- deparse(substitute(indicador_dependiente))
  #independiente_dias <- deparse(substitute(independiente_dias))
  f <- formula(paste(indicador_dependiente, "~", independiente_dias, "| identificador_persona + per | identificador_persona")) # specification with 2way fixed effects and class formula
  regresion <- enoe_fenomenos |> 
    mutate(ur = case_when(ur==1 ~ "URBANO", TRUE ~ "RURAL"),
           ur = as.factor(ur)) |>
    mutate(sex = case_when(sex==1 ~ "HOMBRE", TRUE ~ "MUJER"),
           sex = as.factor(sex)) %>%
    feglm(f, data=., family = binomial(familia_liga))
  tabla <- summary(regresion)$cm # gets the coefficients info (coef, sd, p value)
  tabla <- tibble::rownames_to_column(as.data.frame(tabla), "termino") # format the results to dataframe
  variable_dependiente <- tibble(DependentVar = indicador_dependiente)
  tabla <- cbind(variable_dependiente, tabla) # adds the adjusted R to the dataframe in order to get a summary
  tabla <- tabla |> mutate(Significance = case_when(`Pr(> |z|)` <= 0.01 ~ "***",
                                                    (`Pr(> |z|)` > 0.01 & `Pr(> |z|)` <= 0.05) ~ "**",
                                                    (`Pr(> |z|)` > 0.05 & `Pr(> |z|)` <= 0.1) ~ "*",
                                                    TRUE ~ ""), .after = Estimate)
  apes.stat <- getAPEs(regresion)
  ape <- tibble(`Average Partial Effect (APE)` = summary(apes.stat)$cm[1],
                se_APE = summary(apes.stat)$cm[2])
  tabla <- cbind(tabla, ape)
  tabla <- tabla |> select(1:5,8,9,6,7)
  return(tabla)
}


# Probabilidad de desempleo/desocupado con logit --------------------------

# En nuestras estimaciones creamos una variable indicadora que toma un valor de 1 cuando
# la persona está desocupada y 0 en cualquier otro caso. A esto es a lo que le llamamos desempleo

enoe_fenomenos <- enoe_fenomenos |>
  mutate(desempleado = ifelse(clase2 == 2, 1, 0))

# El siguiente es un ejemplo del tipo de regresión que estamos estimando
# Nótese que aquí lo hacemos para todos los desastres en los últimos 90 días
stat <- enoe_fenomenos %>%
  feglm(
    desempleado ~ suma_ultimos_90 | identificador_persona + per | identificador_persona,
    data   = .,
    family = binomial("logit"))

# Con la ayuda de nuestra función podemos repetir el proceso para todos los cortes
# temporales

# Creamos una función más que permita directamente guardar en un GoogleSpreadsheet
# los resultados generados en todas las combinaciones. Así obtenemos lo siguiente:

genera_spreadsheet_binomial <- function(combinaciones, indicador_dependiente, nombre_sheet, familia_liga){
  map_df(combinaciones,
         \(x) reg_binfelm({{indicador_dependiente}}, x, familia_liga)) |> 
    write_sheet("https://docs.google.com/spreadsheets/d/1Gonxqm9MUD-GmK9qAkcFCbkcvbHUI4S-muz01x-th_w/edit?usp=sharing",
                sheet = paste0(nombre_sheet,"_",familia_liga))
}

# Para todos los desastres
combinaciones_tiempo |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Todos", "logit")

# Para los desastres de lluvia
combinaciones_lluvias |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_lluvias", "logit")

# Para los ciclones
ciclon_tropical |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_ciclones", "logit")

# Para la temperatura
temperatura_extrema |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_temperatura", "logit")

# Para las heladas
heladas |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_heladas", "logit")

# Género en prob de desempleo logit ---------------------------------------

# Para identificar si hay efectos heterogéneos usamos
# la variable de género y la de urbano/rural
# Nuestra función es lo suficientemente flexible para únicamente
# cambiar los términos de la variable independiente. 

# Aquí tenemos los de género:
combinaciones_tiempo_sexo |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Todos_Genero", "logit")

combinaciones_lluvias_sexo |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Lluvias_Genero", "logit")

ciclon_tropical_sexo |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Tropical_Genero", "logit")

temperatura_extrema_sexo |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Temperatura_Genero", "logit")

heladas_sexo |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Heladas_Genero", "logit")

# Urbano/Rural en prob de desempleo logit ---------------------------------
# Aquí tenemos los de rural

start <- Sys.time()

combinaciones_tiempo_urbano |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Todos_Urbano", "logit")

combinaciones_lluvias_urbano |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Lluvias_Urbano", "logit")

ciclon_tropical_urbano |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Tropical_Urbano", "logit")

c("categoria_temperaturas_extremas_ultimos_180 + resto_desastres_temperaturas_ultimos_180 + ur + categoria_temperaturas_extremas_ultimos_180*ur",
                                "categoria_temperaturas_extremas_ultimos_360 + resto_desastres_temperaturas_ultimos_360 + ur + categoria_temperaturas_extremas_ultimos_360*ur",
                                "categoria_temperaturas_extremas_ultimos_540 + resto_desastres_temperaturas_ultimos_540 + ur + categoria_temperaturas_extremas_ultimos_540*ur",
                                "categoria_temperaturas_extremas_ultimos_720 + resto_desastres_temperaturas_ultimos_720 + ur + categoria_temperaturas_extremas_ultimos_720*ur",
                                "categoria_temperaturas_extremas_ultimos_1800 + resto_desastres_temperaturas_ultimos_1800 + ur + categoria_temperaturas_extremas_ultimos_1800*ur") |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Temperatura_Urbano", "logit")

heladas_urbano |> 
  genera_spreadsheet_binomial(desempleado, "Desempleado_Heladas_Urbano", "logit")

end <- Sys.time()
print(end-start)
beepr::beep()

# Probabilidad de inactivo DISPONIBLE con logit --------------------------

# Este grupo de inactivos está constituido por las personas de 12 y más años que no 
# trabajaron ni tenían empleo y no buscaron activamente uno, por desaliento o porque 
# piensan que no se los darían por la edad, porque no tienen estudios, etc.; 
# pero estarían dispuestas a aceptar un trabajo si se les ofreciera, 
# sin embargo no buscan activamente uno.

# Lo más cercano a este grupo es la clase de ocupación "disponibles" en el dataset de la
# ENOE. Construimos una nueva variable indicadora a partir de este level
# Esto es, de la variable categórica clase 2, construimos una dummy
# que toma el valor de 1 cuando la persona está disponible y 0 en cualquier
# otro caso

enoe_fenomenos <- enoe_fenomenos |>
  mutate(inactivo = ifelse(clase2 == 3, 1, 0))

start <- Sys.time()

# Para todos los desastres
combinaciones_tiempo |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Todos", "logit")

# Para los desastres de lluvia
combinaciones_lluvias |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_lluvias", "logit")

# Para los ciclones
ciclon_tropical |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_ciclones", "logit")

# Para la temperatura
temperatura_extrema |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_temperatura", "logit")

# Para las heladas
heladas |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_heladas", "logit")

# Género en prob inactivo -------------------------------------------------

combinaciones_tiempo_sexo |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Todos_Genero", "logit")

combinaciones_lluvias_sexo |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Lluvias_Genero", "logit")

ciclon_tropical_sexo |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Tropical_Genero", "logit")

temperatura_extrema_sexo |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Temperatura_Genero", "logit")

heladas_sexo |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Heladas_Genero", "logit")

# Urbano/Rural en prob de inactivo logit ---------------------------------

combinaciones_tiempo_urbano |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Todos_Urbano", "logit")

combinaciones_lluvias_urbano |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Lluvias_Urbano", "logit")

ciclon_tropical_urbano |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Tropical_Urbano", "logit")

c("categoria_temperaturas_extremas_ultimos_180 + resto_desastres_temperaturas_ultimos_180 + ur + categoria_temperaturas_extremas_ultimos_180*ur",
  "categoria_temperaturas_extremas_ultimos_360 + resto_desastres_temperaturas_ultimos_360 + ur + categoria_temperaturas_extremas_ultimos_360*ur",
  "categoria_temperaturas_extremas_ultimos_540 + resto_desastres_temperaturas_ultimos_540 + ur + categoria_temperaturas_extremas_ultimos_540*ur",
  "categoria_temperaturas_extremas_ultimos_720 + resto_desastres_temperaturas_ultimos_720 + ur + categoria_temperaturas_extremas_ultimos_720*ur",
  "categoria_temperaturas_extremas_ultimos_1800 + resto_desastres_temperaturas_ultimos_1800 + ur + categoria_temperaturas_extremas_ultimos_1800*ur") |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Temperatura_Urbano", "logit")

heladas_urbano |> 
  genera_spreadsheet_binomial(inactivo, "Inactivo_Heladas_Urbano", "logit")

end <- Sys.time()
print(end-start)
beepr::beep()

