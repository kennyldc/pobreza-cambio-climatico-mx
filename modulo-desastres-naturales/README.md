# Módulo de desastres naturales

Como se mencionó en la propuesta del proyecto (ver file principal) nuestra teoría de cambio parte de analizar fenómenos naturales como eventos exógenos (exacerbados por el cambio climático) y para ello se utilizarán los registros de las declaratorias de emergencia de CENAPRED.

La fuente original de estos datos se encuentra en el [siguiente link](http://www.atlasnacionalderiesgos.gob.mx/archivo/visualizacion-datos.html)

## Datos

El archivo que se utiliza en la investigación fue descargado del sitio de CENAPRED el 11 de noviembre de 2022. Esto es importante, porque las declaratorias que se publiquen después de esa fecha no entrarán al estudio de ninguna manera y además es un ejercicio de transparencia en caso de que por alguna razón las autoridades deseen cambiar información por alguna razón.

De este tipo de datos se puede extraer el estado y el municipio (ambos con su respectiva clave) para juntarlo con el resto de las fuentes.

El archivo csv que puede descargarse para replicar todo el análisis de esta investigación se encuentra de acceso público en el [siguiente enlace](https://drive.google.com/file/d/1Jlyrcq3XWR7QDn3RPU2R3Ee_ryNMSDOl/view?usp=sharing)

### Discusión sobre el tipo de declaratoria

Una observación muy importante corresponde a las diferentes declaratorias que están asociadas a cada uno de los fenómenos climáticos en la base original de CENAPRED. En particularse incluyen entradas vinculadas a declaratorias de: a) emergencia, b) desastre y c) contingencia climatológica.

La documentación de CENAPRED vinculada a estas bases especifica lo siguiente:

> Las declaratorias de desastre natural, de emergencia y de contingencia climatológica (a partir de 2011 publicadas como desastre natural en el sector agropecuario) son documentos mediante los cuales la Secretaría de Gobernación, para las dos primeras, o la SAGARPA, en el caso de la tercera, declaran formalmente y mediante publicación en el Diario Oficial de la Federación, en zona de emergencia, desastre natural o contingencia climatológica a determinados municipios, así como a los órganos político-administrativos en las demarcaciones territoriales de la Ciudad de México, para que se pueda tener acceso a los recursos de los fondos de atención respectivos.

> Cada declaratoria responde a aspectos diferentes ante un evento perturbador: la declaratoria de emergencia está dirigida a la atención de la vida y la salud de la población, la declaratoria de desastre tiene por objeto proporcionar recursos para la reconstrucción de los daños sufridos en las viviendas y la infraestructura pública; en tanto que el objetivo específico de la declaratoria de contingencia climatológica (o de desastre natural en el sector agropecuario) es apoyar a productores agropecuarios, pesqueros y acuícolas, de bajos ingresos, para reincorporarlos a sus actividades en el menor tiempo posible ante la ocurrencia de contingencias climatológicas atípicas, relevantes, no recurrentes e impredecibles.

Con esto en mente, puede que para un mismo evento climático exista más de una declaratoria. Por ejemplo, una de emergencia y una de desastre. O una de emergencia y una de contingencia. Por ello, *con fines prácticos en la investigación solo se tomarán en cuenta las declaratorias de emergencia al considerarse las más relacionadas con la vida de las personas.*