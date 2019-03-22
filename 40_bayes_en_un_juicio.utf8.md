# Ejemplo: Bayes en juicio



### Caso jurídico (usando momios - odds)

Hace unos años se publicó la noticia de que un juez británico decidió que el teorema de Bayes, no debía usarse en casos de homicidio, o por lo menos, no como se venía haciendo. El detonante de esta decisión judicial es un caso real de asesinato que ocurrió en el Reino Unido. En este caso, el sospechoso recibió la con base en el hecho de que se encontraron unos tenis marca Nike en su domicilio, que coincidían con huellas encontradas en la escena del crimen. En el juicio, el testigo experto razonó ayesianamente y para eso requirió asignar una probabilidad al hecho de que una persona cualquiera llevase dicho modelo de tenis. Como el fabricante no tenía datos precisos para estimar tal cosa, el experto empleó una "estimación razonable" de esta información (práctica habitual bajo estas circunstancias). La noticia resulta que al juez citado no le gustó la idea de condenar a alguien con base a una estimación de este tipo.

Veamos como se suele emplear para determinar la probabilidad de que un acusado sea culpable.

El Momio (razón de probabilidades), de que el acusado sea culpable respecto a a ser inocente, antes de observar ninguna prueba o evidencia es:
$$
O(Culpable) = \frac{P(Culpable)}{P(Inocente)}
$$
Si conocemos la probabilidad de que se produzca la evidencia E cuando elsospechoso es culpable.

$$
P(E|Culpable)
$$
Así como la probabilidad de que se produzca la evidencia E cuando el sospechoso no esculpable.

$$
P(E|Inocente) 
$$

Entonces podemos calcular el momio de que el acusado sea culpable cuando hemos observado la evidencia E, respecto de la probabilidad de que sea inocente.

$$
O(Culpable|E)= \frac{P(E|Culpable)}{P(E|No culpable)}\cdot O(Culpable)
$$

## Más allá de una duda razonable: _in dubio pro reo_
¿Le ponemos números? Veamos un caso en el que se localizan rastros de sangre de un presunto homicida en la escena de un crimen. El análisis forense encuentra que este tipo de sangre se puede encontrar en $\frac{1}{15,000}$ personas en la población de referencia. Con base en este dato podemos calcular el momio de que se presente la evidencia, considerando que ya sabemos que el culpable tiene ese tipo de sangre, por lo tanto lo conocemos con probabilidad 1:


```r
o_evidencia <- 1 / (1 / 15000)
o_evidencia
```

```
## [1] 15000
```
Para aplicar Bayes sólo falta conocer las opciones de culpabilidad _a priori_ que tendría el sospechoso, independientemente de las pruebas de sangre.  Un planteamiento razonable sería pensar que estamos en una región de 2,000,000 de habitantes y aceptamos que el culpable debe vivir necesariamente aquí. Ahora, aplicamos la versión de momios de la regla de Bayes.


```r
o_culpable_a_priori <- 1 /(2000000 - 1) 
o_evidencia_culpable <- o_evidencia * o_culpable_a_priori
o_evidencia_culpable
```

```
## [1] 0.007500004
```

Por lo tanto, el presunto asesino tiene un momio de 0.0075 en su contra.

Como un momio es una razón de probabilidades, entonces
$$
O=\frac{P(A)}{P(no A)}=\frac{P(A)}{1-P(A)} \implies P(A)=\frac{O}{1+O}
$$ 
lo que permite calcular la probabilidad de ser culpable a la luz de la evidencia, en este caso: 0.74%. ¿Qué cabría decidir en el juicio?

Qué pasa con la decisión si el crimen ocurre en una población aislada de sólo 20,000 habitantes?


```r
o_culpable_a_priori <- 1 /(20000 - 1) 
o_evidencia_culpable <- o_evidencia * o_culpable_a_priori
o_evidencia_culpable
```

```
## [1] 0.7500375
```
En este otro escenario el presunto asesino tiene un momio de 0.7500375 en su contra y por lo tanto, la nueva probabilidad de ser culpable a la luz de la evidencia es: 42.86%. ¿Qué cabría decidir ahora en el juicio?


[Lectura complementaria](https://www.r-bloggers.com/bayesian-blood/)

[La noticia en el _Guardian_](https://www.theguardian.com/law/2011/oct/02/formula-justice-bayes-theorem-miscarriage)



