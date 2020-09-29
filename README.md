# Top Coders Mexico

Based on Github Stats

[![CodeCogsEqn.svg](images/demo.png)](https://ealexisaraujo.github.io/top-coders-mexico/)

<br/>

## ¿Cómo se calcula el Raking?

Para generar el ranking se realiza un calculo del indice rock star, considerando las siguientes variables:

- Popularidad (_Número de seguidores_)
- Impacto (_Número de estrellas en repositorios propios_)
- Actividad (_Número de commits en el ultimo año_)
- OpenSource (_Numero de proyectos personales públicos_)

El indice de cada una de estas variables se divide entre el máximo general encontrado para cada variable, esto permitirá obtener un indice relativo al total de la muestra.

<br/>

![CodeCogsEqn.svg](images/CodeCogsEqn.svg)

<br/>

## ¿Cómo funciona?

La pagina esta basada en Jekyll para la generación de contenido estático y de Travis CI para la generación automática de nuevos deploys cada dia, manteniendo actualizada la información del ranking.

## ¿Como Contribuir?

1. Crear un issue con la descripción de la contribución
2. Hacer un fork del proyecto
3. Hacer los cambios y enviar un Pull Request

### Para iniciar el proyecto localmente necesitas

- Ejecutar `bundle install`
- Ejecutar `jekyll build`
- Podrás ver el sitio web generado en la carpeta `_site`
