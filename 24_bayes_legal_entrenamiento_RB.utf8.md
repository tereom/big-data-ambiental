# Clase miércoles 13/marzo/2019 Inecol

Generación de redes bayesianas con la biblioteca _bnlearn_. Diseño con base en
juicio experto, aprendizaje automatizado de topología y de tablas de 
probabilidad condicional.

También ejemplo de uso de Bayes en un caso legal y finalmente ejemplo de 
entrenamiento de una red con blearn utilizando el ejemplo bien conocido en la 
literatura del caso de riesgo de enfermedades pulmonares dada exposición a 
tabaquismo y tuberculósis asiática.


### Aprendizaje automatizado de redes bayesianas

Veremos como se puede generar automáticamente una topología de red, a partir de 
un conjunto de datos y también como estimmar las tablas de probabilidad de una 
_GAD_, nuevamente a partir de un conjunt de datos.




```
## Warning: package 'forcats' was built under R version 3.5.2
```


## Identificación de la estructura

Nuestro siguiente paso es describir la heurística de búsqueda para minimizar
el score, que en lo que sigue suponemos que es el AIC. 

Hay dos decisiones de diseño para decidir el algoritmo de aprendizaje de 
estructura:

**Técnicas de busqueda.**  
* Hill-climbing  
* Recocido simulado  
* Algoritmos genéticos

**Operadores de búsqueda** Locales  
* Agregar arista  
* Eliminar arista  
* Cambiar dirección de arista  

Globales (ej. cambiar un nodo de lugar, más costoso)

Aunque hay varios algoritmos, uno utilizado comunmente es el de hill climbing. 

### Hill-climbing, escalada simple o ascenso de colina


1. Iniciamos con una gráfica dada:
* Gráfica vacía  
* Gráfica aleatoria
* Conocimiento experto

2. En cada iteración:
* Consideramos el score para cada operador de búsqueda local 
(agregar, eliminar o cambiar la dirección de una arista)
* Aplicamos el cambio que resulta en un mayor incremento en el score. Si 
tenemos empates elijo una operación al azar.

3. Parar cuando ningún cambio resulte en mejoras del score.

**Ejemplo. Eliminación de aristas** Consideremos datos simulados de una red en 
forma de diamante: 


```r
set.seed(28)
n <- 600 # número de observaciones
a <- (rbinom(n, 1, 0.3)) # nodo raíz
b <- (rbinom(n, 1, a * 0.1 + (1 - a) * 0.8))
c <- (rbinom(n, 1, a * 0.2 + (1 - a) * 0.9))
d <- (rbinom(n, 1, b * c * 0.9 + (1 - b * c) * 0.1))
dat <- data.frame(a = factor(a), b = factor(b), c = factor(c), d = factor(d))
pander(head(dat), caption = "Muestra de la tabla de datos recien creada")
```


---------------
 a   b   c   d 
--- --- --- ---
 0   1   1   1 

 0   1   1   1 

 0   1   1   1 

 1   0   0   0 

 0   1   1   1 

 1   0   0   0 
---------------

Table: Muestra de la tabla de datos recien creada

### complejidad y score AIC

Una solución al problema de selección de modelos es usar una función de score
por una que penalice la verosimilitud según el número de parámetros en el modelo.
Una medida popular de este es el AIC (Aikaike information criterion). El AIC
se define como

<div class="caja">
El score AIC de un modelo se define como
$$AIC({\mathcal G}, \theta_{\mathcal G}) =
-\frac{2}{N}loglik + \frac{2d}{N}=Dev + \frac{2d}{N},$$
donde $d$ es el número de parámetros en $\theta_{\mathcal G}.$
</div>
<br/>

Nótemos que bajo este criterio, agregar una arista no necesariamente representa una
mejora, pues aunque $loglik$ no aumente o incluso disminuya, $d$ definitivamente aumenta (añadimos variables).  Es decir, el AIC es una combinación de una medida de ajuste del modelo con una penalización por complejidad, donde medimos complejidad por el número de parámetros del modelo.

¿Qué modelo debemos elegir de acuerdo al AIC?

No hay garantía de escoger el modelo óptimo usando el AIC (según la experiencia
tiende a escoger modelos quizá demasiado complejos), pero es una guía útil
para controlar complejidad.

Otra alternativa útil es el BIC, que también es un tipo de
verosimilitud penalizada:

En la práctica se utilizan AIC y BIC. El AIC tiende a producir modelos
más complejos con algún sobreajuste, mientras que el BIC tiende
a producir modelos más simples y a veces con falta de ajuste. 
No hay acuerdo en qué medida
es mejor en general, pero el balance se puede considerar como sigue: cuando
es importante predecir o hacer inferencia, y no nos preocupa tanto 
obtener algunas aristas espurias, preferimos el AIC. Cuando buscamos
la parte más robusta de la estructura de variación de las variables, aún
cuando perdamos algunas dependencias débiles, puede ser mejor usar el BIC.

Ahora, comenzamos el proceso con una gráfica vacía:


```r
# Esta función produce una especie de "devianza basada en AIC", útil para comparar modelo.
aic_dev <- function(fit, data){
  -2 * AIC(fit, data = data) / nrow(data)
}
grafica_0 <- empty.graph(c('a','b','c','d'))
fit_0 <- bn.fit(grafica_0, dat)
logLik(fit_0, data = dat)
```

```
## [1] -1543.696
```

```r
AIC(fit_0, data = dat) # cuatro parámetros
```

```
## [1] -1547.696
```

```r
aic_dev(fit_0, data = dat)
```

```
## [1] 5.158988
```

Consideramos agregar $a\to d$, la nueva arista que mejora el AIC, y escogemos 
este cambio. Notemos que esta arista no existe en el modelo que genera los datos,


```r
grafica_1 <- grafica_0
arcs(grafica_1) <- matrix(c('a', 'd'), ncol = 2, byrow = T)
fit_1 <- bn.fit(grafica_1, dat)
logLik(fit_1, data = dat)
```

```
## [1] -1458.222
```

```r
aic_dev(fit_1, data = dat) 
```

```
## [1] 4.877407
```

```r
graphviz.plot(grafica_1)
```

```
## Loading required namespace: Rgraphviz
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Ahora agregamos $a\to b$, que también mejora el AIC:


```r
grafica_2 <- grafica_0
arcs(grafica_2) <- matrix(c('a','d','a','b'), ncol = 2, byrow = T)
fit_2 <- bn.fit(grafica_2, dat)
logLik(fit_2, data = dat)
```

```
## [1] -1288.1
```

```r
aic_dev(fit_2, data = dat) 
```

```
## [1] 4.313667
```

```r
graphviz.plot(grafica_2)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-5-1.png" width="240" />

Igualmente, agregar $a\to c$ merjoar el AIC:


```r
grafica_3 <- grafica_0
arcs(grafica_3) <- matrix(c('a','d','a','b','a','c'), ncol = 2, byrow = T)
fit_3 <- bn.fit(grafica_3, dat)
logLik(fit_3, data = dat )
```

```
## [1] -1141.835
```

```r
aic_dev(fit_3, data = dat) 
```

```
## [1] 3.829451
```

```r
graphviz.plot(grafica_3)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-6-1.png" width="672" />


Agregamos $b\to d$ y $c\to d$:


```r
grafica_4 <- grafica_0
arcs(grafica_4) <- matrix(c('a','d','a','b','a','c','b','d'), ncol = 2, 
  byrow = T)
fit_4 <- bn.fit(grafica_4, dat)
logLik(fit_4, data = dat )
```

```
## [1] -1064.735
```

```r
aic_dev(fit_4, data = dat) 
```

```
## [1] 3.579116
```

```r
grafica_4 <- grafica_0
arcs(grafica_4) <- matrix(c('a','d','a','b','a','c','b','d','c','d'), ncol = 2, 
  byrow = T)
fit_4 <- bn.fit(grafica_4, dat)
logLik(fit_4, data = dat )
```

```
## [1] -1015.777
```

```r
aic_dev(fit_4, data = dat) 
```

```
## [1] 3.429258
```

```r
graphviz.plot(grafica_4)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-7-1.png" width="672" />

Ahora nótese que podemos eliminar $a\to d$, y mejoramos el AIC:


```r
grafica_5 <- grafica_0
arcs(grafica_5) <- matrix(c('a','b','a','c','b','d','c','d'), ncol = 2, 
  byrow = T)
fit_5 <- bn.fit(grafica_5, dat)
logLik(fit_5, data = dat )
```

```
## [1] -1016.166
```

```r
aic_dev(fit_5, data = dat) 
```

```
## [1] 3.417219
```

```r
graphviz.plot(grafica_5)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-8-1.png" width="672" />

Este última gráfica es el modelo original. La eliminación de arcos
nos permitió recuperar el modelo original a pesar de nuestra decisión inicial
temporalmente incorrecta de agregar $a\to d$.

El algoritmo de _ascenso de colina_ como está implementado en _bn.learn_ resulta en:


```r
graf_hc <- hc(dat, score='aic')
graphviz.plot(graf_hc)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-9-1.png" width="672" />

**Ejemplo: Cambios de dirección**

Consideramos un ejemplo simple con un colisionador:


```r
set.seed(28)
n <- 600
b <- (rbinom(n, 1, 0.4))
c <- (rbinom(n, 1, 0.7))
d <- (rbinom(n, 1, b*c*0.9+ (1-b*c)*0.1 ))
dat <- data.frame(factor(b),factor(c),factor(d))
names(dat) <- c('b','c','d')
```

Supongamos que comenzamos agregando la arista $d\to c$ (sentido incorrecto).


```r
grafica_0 <- empty.graph(c('b','c','d'))
arcs(grafica_0) <- matrix(c('d','c'), ncol=2, byrow=T)
graphviz.plot(grafica_0)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-11-1.png" width="672" />

En el primer paso, agregamos $b \to d$, que muestra una mejora grande:


```r
graf_x <- hc(dat, start= grafica_0, score='aic', max.iter=1)
graphviz.plot(graf_x)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-12-1.png" width="672" />

Pero en el siguiente paso nos damos cuenta que podemos mejorar
considerablemente si construimos el modelo local de $d$ a partir
no sólo de $b$ sino también de $c$, y cambiamos dirección:


```r
graf_x <- hc(dat, start= grafica_0, score='aic', max.iter=2)
graphviz.plot(graf_x)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-13-1.png" width="672" />

Podemos examinar cada paso del algoritmo:


```r
hc(dat, start = grafica_0, score='aic', debug=T)
```

```
## ----------------------------------------------------------------
## * starting from the following network:
## 
##   Random/Generated Bayesian network
## 
##   model:
##    [b][d][c|d] 
##   nodes:                                 3 
##   arcs:                                  1 
##     undirected arcs:                     0 
##     directed arcs:                       1 
##   average markov blanket size:           0.67 
##   average neighbourhood size:            0.67 
##   average branching factor:              0.33 
## 
##   generation algorithm:                  Empty 
## 
## * current score: -1105.878 
## * whitelisted arcs are:
## * blacklisted arcs are:
## * caching score delta for arc b -> c (51.958371).
## * caching score delta for arc b -> d (127.579833).
## * caching score delta for arc c -> b (-0.955426).
## * caching score delta for arc c -> d (25.648932).
## * caching score delta for arc d -> c (-25.648932).
## ----------------------------------------------------------------
## * trying to add one of 4 arcs.
##   > trying to add b -> c.
##     > delta between scores for nodes b c is 51.958371.
##     @ adding b -> c.
##   > trying to add b -> d.
##     > delta between scores for nodes b d is 127.579833.
##     @ adding b -> d.
##   > trying to add c -> b.
##     > delta between scores for nodes c b is -0.955426.
##   > trying to add d -> b.
##     > delta between scores for nodes d b is 127.579833.
## ----------------------------------------------------------------
## * trying to remove one of 1 arcs.
##   > trying to remove d -> c.
##     > delta between scores for nodes d c is -25.648932.
## ----------------------------------------------------------------
## * trying to reverse one of 1 arcs.
##   > trying to reverse d -> c.
##     > delta between scores for nodes d c is 0.000000.
## ----------------------------------------------------------------
## * best operation was: adding b -> d .
## * current network is :
## 
##   Bayesian network learned via Score-based methods
## 
##   model:
##    [b][d|b][c|d] 
##   nodes:                                 3 
##   arcs:                                  2 
##     undirected arcs:                     0 
##     directed arcs:                       2 
##   average markov blanket size:           1.33 
##   average neighbourhood size:            1.33 
##   average branching factor:              0.67 
## 
##   learning algorithm:                    Hill-Climbing 
##   score:                                 AIC (disc.) 
##   penalization coefficient:              1 
##   tests used in the learning procedure:  5 
##   optimized:                             TRUE 
## 
## * current score: -978.2983 
## * caching score delta for arc b -> d (-127.579833).
## * caching score delta for arc c -> d (78.562729).
## ----------------------------------------------------------------
## * trying to add one of 2 arcs.
##   > trying to add b -> c.
##     > delta between scores for nodes b c is 51.958371.
##     @ adding b -> c.
##   > trying to add c -> b.
##     > delta between scores for nodes c b is -0.955426.
## ----------------------------------------------------------------
## * trying to remove one of 2 arcs.
##   > trying to remove b -> d.
##     > delta between scores for nodes b d is -127.579833.
##   > trying to remove d -> c.
##     > delta between scores for nodes d c is -25.648932.
## ----------------------------------------------------------------
## * trying to reverse one of 2 arcs.
##   > trying to reverse b -> d.
##     > delta between scores for nodes b d is 0.000000.
##   > trying to reverse d -> c.
##     > delta between scores for nodes d c is 52.913797.
##     @ reversing d -> c.
## ----------------------------------------------------------------
## * best operation was: reversing d -> c .
## * current network is :
## 
##   Bayesian network learned via Score-based methods
## 
##   model:
##    [b][c][d|b:c] 
##   nodes:                                 3 
##   arcs:                                  2 
##     undirected arcs:                     0 
##     directed arcs:                       2 
##   average markov blanket size:           2.00 
##   average neighbourhood size:            1.33 
##   average branching factor:              0.67 
## 
##   learning algorithm:                    Hill-Climbing 
##   score:                                 AIC (disc.) 
##   penalization coefficient:              1 
##   tests used in the learning procedure:  7 
##   optimized:                             TRUE 
## 
## * current score: -925.3845 
## * caching score delta for arc b -> c (-0.955426).
## * caching score delta for arc b -> d (-180.493630).
## * caching score delta for arc c -> d (-78.562729).
## * caching score delta for arc d -> c (25.648932).
## ----------------------------------------------------------------
## * trying to add one of 2 arcs.
##   > trying to add b -> c.
##     > delta between scores for nodes b c is -0.955426.
##   > trying to add c -> b.
##     > delta between scores for nodes c b is -0.955426.
## ----------------------------------------------------------------
## * trying to remove one of 2 arcs.
##   > trying to remove b -> d.
##     > delta between scores for nodes b d is -180.493630.
##   > trying to remove c -> d.
##     > delta between scores for nodes c d is -78.562729.
## ----------------------------------------------------------------
## * trying to reverse one of 2 arcs.
##   > trying to reverse b -> d.
##     > delta between scores for nodes b d is -52.913797.
##   > trying to reverse c -> d.
##     > delta between scores for nodes c d is -52.913797.
```


**Ejemplo simulado.**

Comenzamos con una muestra relativamente chica, y utilizamos el BIC:


```r
set.seed(280572)
n <- 300
a <- (rbinom(n, 1, 0.2))
b <- (rbinom(n, 1, a*0.1+(1-a)*0.8))
c <- (rbinom(n, 1, a*0.2+(1-a)*0.9))
d <- (rbinom(n, 1, b*c*0.9+ (1-b*c)*0.1 ))
e <- rbinom(n, 1, 0.4)
f <- rbinom(n, 1, e*0.3+(1-e)*0.6)
g <- rbinom(n, 1, f*0.2+(1-f)*0.8)
dat <- data.frame(factor(a),factor(b),factor(c),factor(d), factor(e), factor(f),
  factor(g))
names(dat) <- c('a','b','c','d','e','f','g')
```



```r
grafica.1 <- hc(dat, score='bic')
graphviz.plot(grafica.1)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-16-1.png" width="672" />


```r
set.seed(280572)
n <- 300
a <- (rbinom(n, 1, 0.3))
b <- (rbinom(n, 1, a*0.1+(1-a)*0.8))
c <- (rbinom(n, 1, a*0.2+(1-a)*0.9))
d <- (rbinom(n, 1, b*c*0.9+ (1-b*c)*0.1 ))
e <- rbinom(n, 1, 0.4)
f <- rbinom(n, 1, e*0.3+(1-e)*0.6)
g <- rbinom(n, 1, f*0.2+(1-f)*0.8)
dat <- data.frame(factor(a),factor(b),factor(c),factor(d), factor(e), factor(f),
  factor(g))
names(dat) <- c('a','b','c','d','e','f','g')
```



```r
grafica.1 <- hc(dat, score='aic')
graphviz.plot(grafica.1)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-18-1.png" width="672" />

En este ejemplo, con el AIC obtenemos algunas aristas espurias, que en todo
caso muestran relaciones aparentes débiles en los datos de entrenamiento.
Nótese que AIC captura las relaciones importantes, y erra en cautela en 
cuanto a qué independencias están presentes en los datos.


### Incorporando información acerca de la estructura

En algunos casos, tenemos información adicional de las posibles
estructuras gráficas que son aceptables o deseables en los modelos
que buscamos ajustar. 

Esta información es muy valiosa cuando tenemos pocos datos o muchas
variables (incluso puede ser crucial para obtener un modelo de buena calidad),
y puede incorporarse en prohibiciones acerca de qué estructuras puede
explorar el algoritmo.

Consideremos nuestro ejemplo anterior con considerablemente menos datos:


```r
set.seed(28)
n <- 100
a <- (rbinom(n, 1, 0.2))
b <- (rbinom(n, 1, a*0.1+(1-a)*0.8))
c <- (rbinom(n, 1, a*0.2+(1-a)*0.9))
d <- (rbinom(n, 1, b*c*0.9+ (1-b*c)*0.1 ))
e <- rbinom(n, 1, 0.4)
f <- rbinom(n, 1, e*0.3+(1-e)*0.6)
g <- rbinom(n, 1, f*0.2+(1-f)*0.8)
dat <- data.frame(factor(a),factor(b),factor(c),factor(d), factor(e), factor(f),
  factor(g))
names(dat) <- c('a','b','c','d','e','f','g')
```


```r
grafica.1 <- hc(dat, score='bic')
graphviz.plot(grafica.1)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-20-1.png" width="672" />

Nótese que en este ejemplo BIC falla en identificar una dependencia, y afirma
que hay una independencia condicional entre a y d dado c. AIC sin embargo captura
la dependencia con un modelo demasiado complejo (tres flechas espurias):


```r
grafica.1 <- hc(dat, score='aic')
graphviz.plot(grafica.1)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-21-1.png" width="672" />

Sin embargo, si sabemos, por ejemplo, que no debe haber una flecha de c a f, y tiene
que haber una de a a c, podemos mejorar nuestros modelos:


```r
b.list <- data.frame(from=c('c','f'), to=c('f','c'))
w.list <- data.frame(from=c('a'), to=c('c'))
grafica.bic <- hc(dat, score='bic', blacklist=b.list, whitelist=w.list)
graphviz.plot(grafica.bic)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-22-1.png" width="672" />



```r
grafica.aic <- hc(dat, score='aic', blacklist=b.list, whitelist=w.list)
graphviz.plot(grafica.aic)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-23-1.png" width="672" />

En este ejemplo estamos seguros de las aristas que forzamos. Muchas
veces este no es el caso, y debemos tener cuidado:

<div class="caja">
* Forzar la inclusión de una arista cuando esto no es necesario puede
resultar en modelos demasiado complicados que incluyen estructuras espurias.

* Exclusión de muchas aristas puede provocar también modelos que ajustan mal
y no explican los datos.
</div>




```r
set.seed(28)
n <- 600
b <- (rbinom(n, 1, 0.4))
c <- (rbinom(n, 1, 0.7))
d <- (rbinom(n, 1, b*c*0.9+ (1-b*c)*0.1 ))
dat.x <- data.frame(factor(b),factor(c),factor(d))
names(dat.x) <- c('b','c','d')
```


Supongamos que comenzamos agregando la arista $d\to b$ (sentido incorrecto).



```r
graphviz.plot(hc(dat.x, score='bic', whitelist=data.frame(from=c('d'), to=c('b'))))
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-25-1.png" width="672" />

Y no aprendimos nada, pues cualquier conjunta se factoriza de esta manera.

### Sentido de las aristas

Los métodos de score a lo más que pueden aspirar es a capturar la 
clase de equivalencia Markoviana de la conjunta que nos interesa (es decir,
gráficas que tienen las mismas independencias, y que cubren a exactamente las mismas conjuntas que se factorizan sobre ellas). Esto implica
que hay cierta arbitrariedad en la selección de algunas flechas.

En la siguiente gráfica, por ejemplo, ¿qué pasa si cambiamos  el sentido de la flecha
entre e y f?


```r
set.seed(28)
n <- 500
a <- (rbinom(n, 1, 0.2))
b <- (rbinom(n, 1, a*0.1+(1-a)*0.8))
c <- (rbinom(n, 1, a*0.2+(1-a)*0.9))
d <- (rbinom(n, 1, b*c*0.9+ (1-b*c)*0.1 ))
e <- rbinom(n, 1, 0.4)
f <- rbinom(n, 1, e*0.3+(1-e)*0.6)
g <- rbinom(n, 1, f*0.2+(1-f)*0.8)
dat <- data.frame(factor(a),factor(b),factor(c),factor(d), factor(e), factor(f),
  factor(g))
names(dat) <- c('a','b','c','d','e','f','g')
grafica.bic <- hc(dat, score='bic')
```



```r
graphviz.plot(grafica.bic)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-27-1.png" width="672" />

```r
arcos <- grafica.bic$arcs
arcos
```

```
##      from to 
## [1,] "b"  "d"
## [2,] "a"  "b"
## [3,] "f"  "g"
## [4,] "a"  "c"
## [5,] "c"  "d"
## [6,] "e"  "f"
```

```r
arcos[3,] <- c('g','f')
arcos[6,] <- c('f','e')
grafica.2 <- grafica.bic
arcs(grafica.2) <- arcos
graphviz.plot(grafica.2)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-27-2.png" width="672" />

```r
graphviz.plot(grafica.bic)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-27-3.png" width="672" />

Vemos que no cambia la log-verosimilitud, ni ninguno de nuestros scores. 


```r
logLik(grafica.bic, data=dat)
```

```
## [1] -1648.022
```

```r
logLik(grafica.2, data=dat)
```

```
## [1] -1648.022
```

```r
BIC(grafica.bic, data=dat)
```

```
## [1] -1691.525
```

```r
BIC(grafica.2, data=dat)
```

```
## [1] -1691.525
```

```r
AIC(grafica.bic, data=dat)
```

```
## [1] -1662.022
```

```r
AIC(grafica.2, data=dat)
```

```
## [1] -1662.022
```

Esto implica que la dirección de estas flechas no puede determinarse 
solamente usando los datos. Podemos seleccionar la dirección de estas
flechas por otras consideraciones, como explicaciones causales, temporales,
o de interpretación. Los modelos son equivalentes, pero tienen
una parametrización destinta.

![](./imagenes/manicule2.jpg)  Mostrar que cambiar el sentido de una 
flecha que colisiona en $d$ (que es un colisionador no protegido) **no** da
scores equivalentes.


### Variaciones de Hill-climbing

<div class="clicker">
¿Cuál(es) de las siguientes opciones puede ser un problema para aprender la 
estructura de la red?  
a. Máximos locales.  
b. Pasos discretos en los scores cuando se perturba la estructura.  
c. Eliminar un arco no se puede expresar como una operación atómica en la 
estructura.  
d. Perturbaciones chicas en la estructura de la gráfica producen cambios muy 
chicos o nulos en el score (plateaux).  
</div>

¿Por que consideramos el operador de cambiar dirección como candidato en cada
iteración si es el resultado de elminar un arco y añadir un arco? 
Eliminar un 
arco en hill-climbing tiende a disminuir el score de tal manera que el paso 
inicial de eliminar el arco no se tomará.

Revertir la dirección 
es una manera de evitar máximos locales.

Algunas modificaciones de hill-climbing consisten en incluir estrategias:

* **Inicios aleatorios**: Si estamos en una llanura, tomamos un número de pasos
aleatorios para intentar encontrar una nueva pendiente y entonces comenzar a escalar nuevamente.  

* **Tabu**: Guardar una lista de los k pasos más recientes y la búsqueda no 
puede revertir estos pasos.



# Caso jurídico (usando _momios_ - odds)

Hace unos años se publicó la noticia de que un juez británico decidió que el teorema de Bayes, no debía usarse en casos de homicidio, o por lo menos, no como se venía haciendo. El detonante de esta decisión judicial es un caso real de asesinato que ocurrió en el Reino Unido. En este caso, el sospechoso recibió la condena con base en el hecho de que se encontraron unos tenis marca _Nike_ en su domicilio, que coincidían con huellas encontradas en la escena del crimen. En el juicio, el testigo experto razonó bayesianamente. Para hacerlo requirió asignar una probabilidad a la posibilidad de que una persona cualquiera llevase dicho modelo de tenis. Como el fabricante no tenía datos precisos para estimar tal cosa, el experto empleó una "estimación razonable" de esta información (práctica habitual bajo estas circunstancias). La noticia resalta que al juez citado no le gustó la idea de condenar a alguien con base a una estimación de este tipo.

Veamos como se suele emplear para determinar la probabilidad de que un acusado sea culpable.

El _momio_ (razón de probabilidades), de que el acusado sea culpable respecto a ser inocente, antes de observar ninguna prueba o evidencia es:
$$
O(Culpable) = \frac{P(Culpable)}{P(Inocente)}
$$
Si conocemos la probabilidad de que se produzca la evidencia _E_ cuando elsospechoso es culpable.

$$
P(E|Culpable)
$$
Así como la probabilidad de que se produzca la evidencia __E_ cuando el sospechoso no es culpable.

$$
P(E|Inocente) 
$$

Entonces podemos calcular el _momio_ de que el acusado sea culpable cuando hemos observado la evidencia E, respecto de la probabilidad de que sea inocente.

$$
O(Culpable|E)= \frac{P(E|Culpable)}{P(E|No culpable)}\cdot O(Culpable)
$$

## Más allá de una duda razonable: _in dubio pro reo_
¿Le ponemos números? Veamos un caso en el que se localizan rastros de sangre de un presunto homicida en la escena de un crimen. El análisis forense encuentra que este tipo de sangre se puede encontrar en $\frac{1}{15,000}$ personas en la población de referencia. Con base en este dato podemos calcular el _momio_ de que se presente la evidencia, considerando que ya sabemos que el culpable tiene ese tipo de sangre, por lo tanto lo conocemos con probabilidad 1:


```r
p_evidencia_culpable  <- 1
p_evidencia_inocente  <- 1 / 15000

o_evidencia_culpable <- p_evidencia_culpable / p_evidencia_inocente
o_evidencia_culpable
```

```
## [1] 15000
```
Para aplicar Bayes sólo falta conocer las opciones de culpabilidad _a priori_ que tendría el sospechoso, independientemente de las pruebas de sangre.  Un planteamiento razonable sería pensar que estamos en una región de 2,000,000 de habitantes y aceptamos que el culpable debe vivir necesariamente aquí. Ahora, aplicamos la versión de _momios_ de la regla de Bayes.


```r
p_culpable <- 1 /(2000000)
p_inocente <- (2000000 - 1)/2000000

o_culpable_a_priori <- p_culpable/p_inocente

o_culpable_evidencia <- o_evidencia_culpable * o_culpable_a_priori
o_culpable_evidencia
```

```
## [1] 0.007500004
```

Por lo tanto, el presunto asesino tiene un _momio_ de 0.0075 en su contra.

Como un _momio_ es una razón de probabilidades, entonces
$$
O=\frac{P(A)}{P(no A)}=\frac{P(A)}{1-P(A)} \implies P(A)=\frac{O}{1+O}
$$ 
lo que permite calcular la probabilidad de ser culpable a la luz de la evidencia, en este caso: 0.7444%. ¿Qué cabría decidir en el juicio?

Qué pasa con la decisión si el crimen ocurre en una población aislada de sólo 20,000 habitantes?


```r
o_culpable_a_priori <- 1 /(20000 - 1) 
o_evidencia_culpable <- o_evidencia_culpable * o_culpable_a_priori
o_evidencia_culpable
```

```
## [1] 0.7500375
```
En este otro escenario el presunto asesino tiene un _momio_ de 0.0075 en su contra y por lo tanto, la nueva probabilidad de ser culpable a la luz de la evidencia es: 0.7444%. ¿Qué cabría decidir ahora en el juicio?


[Lectura complementaria](https://www.r-bloggers.com/bayesian-blood/)

[La noticia en el _Guardian_](https://www.theguardian.com/law/2011/oct/02/formula-justice-bayes-theorem-miscarriage)


# Ejemplo de red bayesiana "Asia"


```r
library(bnlearn)
library(pander)
pander(head(asia))
```


---------------------------------------------
 A     S     T    L     B     E     X     D  
---- ----- ----- ---- ----- ----- ----- -----
 no   yes   no    no   yes   no    no    yes 

 no   yes   no    no   no    no    no    no  

 no   no    yes   no   no    yes   yes   yes 

 no   no    no    no   yes   no    no    yes 

 no   no    no    no   no    no    no    yes 

 no   yes   no    no   no    no    no    yes 
---------------------------------------------

El Conjunto de datos _Asia_ contiene las siguientes variables:

D (disnea), un factor con dos niveles  _yes_ and _no_.  
T (tuberculosis), un factor con dos niveles  _yes_ and _no_.  
L (cancer pulmonar), un factor con dos niveles  _yes_ and _no_.  
B (bronquitis), un factor con dos niveles  _yes_ and _no_.  
A (visita a Asia), un factor con dos niveles  _yes_ and _no_.  
S (fumador), un factor con dos niveles  _yes_ and _no_.
X (rayos-X del Catastro toraxico), un factor con dos niveles  _yes_ and _no_.  
E (tuberculosis o cancer de pulmón), un factor con dos niveles  _yes_ and _no_.  

Para referencia posterior, la "verdadera" estructura de la red se muestra en seguida

[Red Asia](https://www.bayesserver.com/examples/networks/asia)
And for later reference, the ‘true’ network structure is shown below: 

![Asia Data Set Structure](imagenes/asia.png)


## Preparación de la red

Antes de trabajar con el conjunnto de datos _Asia_ mostraremos un ejemplo de como crear una estructura de red sencilla desde cero. Podríamos empezar por crear bien una red vacía (sin arcos) o una red aleatoria (arcos que unen aleatoriamente los nodos), pero no haremos nada de eso (en el sitio de __blearn__ se puede encontrar como hacerlo). Lo que haremos es crear una estructura de red particular, según nuestro antojo. Esto puede ser el caso cuando se tiene suficiente confianza en conocer la "verdader" estructura de la red.


```r
#create an empty DAG with nodes
dag= empty.graph(LETTERS[c(1,19,20,12,2,5,24,4)])

#assign the DAG structure, from to 
asia.structure = matrix(c("A", "S", "S", "T", "T","L", "L","B", "B", "E","E", "X","X","D"), ncol = 2, byrow = TRUE, dimnames = list(NULL, c("from", "to"))) 
pander(asia.structure)
```


-----------
 from   to 
------ ----
  A     S  

  S     T  

  T     L  

  L     B  

  B     E  

  E     X  

  X     D  
-----------




```r
#now asign the structure to the empty graph using arcs, which makes it a bnlearn object
arcs(dag) <- asia.structure 
dag
```

```
## 
##   Random/Generated Bayesian network
## 
##   model:
##    [A][S|A][T|S][L|T][B|L][E|B][X|E][D|X] 
##   nodes:                                 8 
##   arcs:                                  7 
##     undirected arcs:                     0 
##     directed arcs:                       7 
##   average markov blanket size:           1.75 
##   average neighbourhood size:            1.75 
##   average branching factor:              0.88 
## 
##   generation algorithm:                  Empty
```

```r
plot(dag)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-34-1.png" width="672" />

Si optamos por usar arcos no dirigidos entonces podemos hacer esto.


```r
dag2 = empty.graph(LETTERS[c(1,19,20,12)])
asia.structure2 = matrix(c("A", "S", "S", "A", "T","L", "L", "T"),
                      ncol = 2, byrow = TRUE,
                       dimnames = list(NULL, c("from", "to")))
arcs(dag2) = asia.structure2
plot(dag2)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-35-1.png" width="672" />

Cuando ejecutamos estos comandos, automáticamente se realizan una serie de verificaciones para evitar faltas a los requerimientos en la estructuración de la red.
Las fallas detectadas se reportarán mediante mensajees de error. La principal verificación de faltas es contra la falta de nodos, la presencia de ciclos y circuitos.

Este otro ejemplo muestra una estructura de red derivada de "opinión experta", a la que añadimos estimadores justo en las distribuciones de probabilidad condicional conjunta del nodo. 



```r
Expert1 = matrix(c(0.4, 0.6), ncol = 2, dimnames = list(NULL, c("BAJO", "ALTO")))
dag
```

```
## 
##   Random/Generated Bayesian network
## 
##   model:
##    [A][S|A][T|S][L|T][B|L][E|B][X|E][D|X] 
##   nodes:                                 8 
##   arcs:                                  7 
##     undirected arcs:                     0 
##     directed arcs:                       7 
##   average markov blanket size:           1.75 
##   average neighbourhood size:            1.75 
##   average branching factor:              0.88 
## 
##   generation algorithm:                  Empty
```

```r
Expert1
```

```
##      BAJO ALTO
## [1,]  0.4  0.6
```




```r
Expert2 = c(0.5, 0.5, 0.4, 0.6, 0.3, 0.7, 0.2, 0.8)
dim(Expert2) = c(2, 2, 2)
dimnames(Expert2) = list("C" = c("CIERTO", "FALSO"), "A" =  c("BAJO", "ALTO"), "B" = c("BUENO", "MALO"))
Expert2
```

```
## , , B = BUENO
## 
##         A
## C        BAJO ALTO
##   CIERTO  0.5  0.4
##   FALSO   0.5  0.6
## 
## , , B = MALO
## 
##         A
## C        BAJO ALTO
##   CIERTO  0.3  0.2
##   FALSO   0.7  0.8
```

## Aprendizaje de la estructura de la red
Además de poder crear la estructura de un red manualmente, también es posible crearla a partir de los datos mediante algoritmos de aprendizaje de la estructura.

Hay tres tipos principalees de algoritmos de aprendizaje de la estructura de una red: basados en restricciones, basados en puntajes e híbridos (alguna mezcla de los dos anteriores). E usuario puede especifica un criterio de valoración AIC (Akaike Information Criterion), BIC (Bayesian Information Criterion) o BDE (Bayesian Dirichlet) para la determinación de la mejor estructura de la red. Los algoritmos usan diferentes técnicas para iterar en torno a las varias estructuras posibles de una red y entonces elige la mejor, dependiendo de la calificación que produzca. El método de calificación usado por defecto con los algorítmmos basados en puntajes o los bpibridos es el BIC.

Basado en restricciones
No se utiliza ninguna estructura de modelo de arranque/inicio con estos algoritmos. Los algoritmos construyen la estructura buscando dependencias condicionales entre las variables. __bnlearn__ incluye los siguientes algoritmos basados en restricciones:

Grow-Shrink (GS)  
Asociación Incremental Markov Blanket (IAMB)  
Asociación Incremental Rápida (Fast-IAMB)  
Asociación Incremental Interleaved (Inter-IAMB)  
Max-Min Parents & Children (MMPC)  
Hiton-PC semi-intercalada (SI-HITON-PC)  

### Basado en la puntuación:

El usuario aprovecha su conocimiento del sistema para crear una red, codifica su confianza en la red e ingresa los datos. El algoritmo luego estima la estructura del modelo más probable. **bnlearn** incluye los siguientes algoritmos basados en 
puntuación:  

Escalada simple (HC)  
Tabu Search (Tabu)  

Híbrido:  
Mezcla de métodos basados en restricciones y basados en puntajes. __bnlearn__ incluye los siguientes algoritmos híbridos:

Max-Min Hill Climbing (MMHC)  
Maximización restringida general de 2 fases (RSMAX2)  


Ahora veamos un ejemplo del aprendizaje basado en restricciones que utiliza el algoritmo de Manta de Markov con Asociación Incremental (IAMB):



```r
iambex <- iamb(asia) #structure learning
iambex
```

```
## 
##   Bayesian network learned via Constraint-based methods
## 
##   model:
##    [A][S][T][L][X][D][B|S:D][E|T:L] 
##   nodes:                                 8 
##   arcs:                                  4 
##     undirected arcs:                     0 
##     directed arcs:                       4 
##   average markov blanket size:           1.50 
##   average neighbourhood size:            1.00 
##   average branching factor:              0.50 
## 
##   learning algorithm:                    IAMB 
##   conditional independence test:         Mutual Information (disc.) 
##   alpha threshold:                       0.05 
##   tests used in the learning procedure:  180 
##   optimized:                             FALSE
```

```r
plot(iambex)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-38-1.png" width="672" />

Ahora, un ejemplo de aprendizaje basado en puntuación usando el algoritmo de escalada simple (HC):


```r
hcex <- hc(asia)
hcex
```

```
## 
##   Bayesian network learned via Score-based methods
## 
##   model:
##    [A][S][T][L|S][B|S][E|T:L][X|E][D|B:E] 
##   nodes:                                 8 
##   arcs:                                  7 
##     undirected arcs:                     0 
##     directed arcs:                       7 
##   average markov blanket size:           2.25 
##   average neighbourhood size:            1.75 
##   average branching factor:              0.88 
## 
##   learning algorithm:                    Hill-Climbing 
##   score:                                 BIC (disc.) 
##   penalization coefficient:              4.258597 
##   tests used in the learning procedure:  77 
##   optimized:                             TRUE
```

```r
mmex <- mmhc(asia)
mmex
```

```
## 
##   Bayesian network learned via Hybrid methods
## 
##   model:
##    [A][S][T][X][L|S][B|S][E|T:L][D|B] 
##   nodes:                                 8 
##   arcs:                                  5 
##     undirected arcs:                     0 
##     directed arcs:                       5 
##   average markov blanket size:           1.50 
##   average neighbourhood size:            1.25 
##   average branching factor:              0.62 
## 
##   learning algorithm:                    Max-Min Hill-Climbing 
##   constraint-based method:               Max-Min Parent Children 
##   conditional independence test:         Mutual Information (disc.) 
##   score-based method:                    Hill-Climbing 
##   score:                                 BIC (disc.) 
##   alpha threshold:                       0.05 
##   penalization coefficient:              4.258597 
##   tests used in the learning procedure:  339 
##   optimized:                             TRUE
```

```r
plot(mmex)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-40-1.png" width="672" />
### Redes por puntajes

A continuación se muestran ejemplos de las puntuaciones de AIC y BDE para la mejor red en el algoritmo de escalada simple (HC), aplicando el algorítmmo de aprendizaje basado en la puntuación que se muestra más arriba.

```r
score(hcex,asia,type="aic") #getting aic value for full network
```

```
## [1] -11051.9
```

```r
score(hcex,asia,type="bde") #getting bde value for full network
```

```
## [1] -11095.79
```

Los resultados del algoritmo anterior también proporcionan un buen ejemplo de lo que sucede cuando la “mejor” estructura de red, no contiene arcos para todos los nodos. La red del algoritmo basado en puntuaciones es la más cercana a la red “verdadera”, pero el nodo A no está conectado a la red. Podemos investigar por qué este es el caso con el nodo A. Por ejemplo, del modelo verdadero sabemos que el nodo A influye en el nodo T. Calculemos la puntuación de A a T, y luego de T a A.


```r
#setting arcs to get actual scores from individual relationships
eq.net = set.arc(hcex, "A", "T") 

#setting arcs to get actual scores from individual relationships
eq.net1 = set.arc(hcex,"T", "A") 
puntaje_net = score(eq.net, asia, type="aic") #retriving score
puntaje_net1 = score(eq.net1, asia, type="aic") #retriving score
plot(eq.net)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-42-1.png" width="672" />

```r
plot(eq.net1)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-42-2.png" width="672" />
Con estos comandos obtenemos el puntaje que está sociado con relaciones particulares:

|Red   | puntaje        |
|------|----------------|
|"net" |-11051.09|
|"net1"|-11051.09|

Vemos que cuando establecemos el arco de A a T, o de T a A, obtenemos la misma puntuación de red (-11051.09). Por lo tanto, la relación entre A y T se denomina "puntuación equivalente", ya que cualquier dirección proporciona la misma puntuación de red equivalente. Cambiar la dirección del vínculo entre dos nodos no cambia la puntuación de red.

Por otro lado, si cambiamos la dirección de la flecha entre otros dos nodos que incluyen otras interconexiones en la red, veremos el cambio de la puntuación de la red. Por ejemplo, si cambiamos la relación entre los nodos L y E:


```r
eq.net = set.arc(hcex, "L", "E")
eq.net1 = set.arc(hcex,"E", "L")
score(eq.net, asia, type="aic")
```

```
## [1] -11051.9
```

```r
plot(eq.net)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-43-1.png" width="672" />

```r
plot(eq.net1)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-43-2.png" width="672" />

```r
puntaje_net = score(eq.net,asia, type="aic")
puntaje_net1 = score(eq.net1,asia, type="aic")
```
El resultado de este cambio es el siguiente:

| Red     |  puntaje       |
|---------|----------------|
|"net"    |-11051.897 |
|"net1"   |-11271.589|

Vemos que la puntuación de la red disminuye cuando invertamos la dirección entre los nodos L y E.

En este punto, dado que los algoritmos no han podido determinar la relación de A a T (u otros nodos), es posible que queramos recurrir a la literatura, la opinión "experta", la teoría de la ecología, etc. para argumentar la mejor relación entre el nodo A y el nodo T o el resto de la estructura.


## "Aprendizaje de parámetros" o "estructuración de la red" 

El comando bn.fit genera estimaciones de parámetros para las tablas de probabilidad condicionales en cada nodo. Sin embargo, el comando bn.fit requiere que la estructura de red represente un DAG (gráfico acíclico dirigido), "de lo contrario no se pueden estimar sus parámetros porque la factorización de la distribución de probabilidad global de los datos en los locales (uno para cada variable en el modelo) no se conoce completamente". Por lo tanto, los arcos no dirigidos deben establecerse antes de la estimación de parámetros. Vemos en la estructura anterior estimada que el nodo "A" no está conectado a la estructura de red. Por lo tanto, antes de aplicar bn.fit, debemos establecer un arco direccional para A. debido a la opinión "experta", el conocimiento del sistema, o estudios previos, vamos a establecer un arco entre A y T. El método predeterminado para la estimación de parámetros es el de máxima verosimilitud (MLE).



```r
#creating a new DAG with the A to T relationship(based on our previous knowledge that goint to asia effects having tuberculosis)
hcex1 = set.arc(hcex, from  = "A", to = "T") 
plot(hcex1)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-44-1.png" width="672" />

Ahora podemos ejecutar el comando bn.fit para obtener los estimadores de los parámetros:


```r
# fitting the network with conditoinal probability tables
fit = bn.fit(hcex1, asia) 
fit 
```

```
## 
##   Bayesian network parameters
## 
##   Parameters of node A (multinomial distribution)
## 
## Conditional probability table:
##      no    yes 
## 0.9916 0.0084 
## 
##   Parameters of node S (multinomial distribution)
## 
## Conditional probability table:
##     no   yes 
## 0.497 0.503 
## 
##   Parameters of node T (multinomial distribution)
## 
## Conditional probability table:
##  
##      A
## T              no         yes
##   no  0.991528842 0.952380952
##   yes 0.008471158 0.047619048
## 
##   Parameters of node L (multinomial distribution)
## 
## Conditional probability table:
##  
##      S
## L             no        yes
##   no  0.98631791 0.88230616
##   yes 0.01368209 0.11769384
## 
##   Parameters of node B (multinomial distribution)
## 
## Conditional probability table:
##  
##      S
## B            no       yes
##   no  0.7006036 0.2823062
##   yes 0.2993964 0.7176938
## 
##   Parameters of node E (multinomial distribution)
## 
## Conditional probability table:
##  
## , , L = no
## 
##      T
## E     no yes
##   no   1   0
##   yes  0   1
## 
## , , L = yes
## 
##      T
## E     no yes
##   no   0   0
##   yes  1   1
## 
## 
##   Parameters of node X (multinomial distribution)
## 
## Conditional probability table:
##  
##      E
## X              no         yes
##   no  0.956587473 0.005405405
##   yes 0.043412527 0.994594595
## 
##   Parameters of node D (multinomial distribution)
## 
## Conditional probability table:
##  
## , , E = no
## 
##      B
## D             no        yes
##   no  0.90017286 0.21373057
##   yes 0.09982714 0.78626943
## 
## , , E = yes
## 
##      B
## D             no        yes
##   no  0.27737226 0.14592275
##   yes 0.72262774 0.85407725
```

Podemos recuperar la probabilidad condicional de un nodo específico mediante el operador usual "$":


```r
fit$L
```

```
## 
##   Parameters of node L (multinomial distribution)
## 
## Conditional probability table:
##  
##      S
## L             no        yes
##   no  0.98631791 0.88230616
##   yes 0.01368209 0.11769384
```


```r
fit$D
```

```
## 
##   Parameters of node D (multinomial distribution)
## 
## Conditional probability table:
##  
## , , E = no
## 
##      B
## D             no        yes
##   no  0.90017286 0.21373057
##   yes 0.09982714 0.78626943
## 
## , , E = yes
## 
##      B
## D             no        yes
##   no  0.27737226 0.14592275
##   yes 0.72262774 0.85407725
```

Si lo queremos, podemos también visualizar la tabla de probabilidad condicional mmediante gráficas de barras:


```r
bn.fit.barchart(fit$D)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-48-1.png" width="672" />

o, si lo preferimos, como una gráfica de puntos:

```r
bn.fit.dotplot(fit$D)
```

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-49-1.png" width="672" />

In addition to maximum likelihood, parameter estimation can be done performed with Bayesian methods - but currently only with discrete data. Below is an example with the Asia dataset. The same bn.fit command line is used, but the method is specified as ‘bayes’.


```r
fit1 = bn.fit(hcex1, asia, method = "bayes")
fit1
```

```
## 
##   Bayesian network parameters
## 
##   Parameters of node A (multinomial distribution)
## 
## Conditional probability table:
##         no       yes 
## 0.9915017 0.0084983 
## 
##   Parameters of node S (multinomial distribution)
## 
## Conditional probability table:
##         no       yes 
## 0.4970006 0.5029994 
## 
##   Parameters of node T (multinomial distribution)
## 
## Conditional probability table:
##  
##      A
## T              no         yes
##   no  0.991479278 0.947058824
##   yes 0.008520722 0.052941176
## 
##   Parameters of node L (multinomial distribution)
## 
## Conditional probability table:
##  
##      S
## L             no        yes
##   no  0.98622008 0.88223017
##   yes 0.01377992 0.11776983
## 
##   Parameters of node B (multinomial distribution)
## 
## Conditional probability table:
##  
##      S
## B            no       yes
##   no  0.7005633 0.2823494
##   yes 0.2994367 0.7176506
## 
##   Parameters of node E (multinomial distribution)
## 
## Conditional probability table:
##  
## , , L = no
## 
##      T
## E               no          yes
##   no  9.999730e-01 3.105590e-03
##   yes 2.699638e-05 9.968944e-01
## 
## , , L = yes
## 
##      T
## E               no          yes
##   no  3.831418e-04 2.941176e-02
##   yes 9.996169e-01 9.705882e-01
## 
## 
##   Parameters of node X (multinomial distribution)
## 
## Conditional probability table:
##  
##      E
## X              no         yes
##   no  0.956538171 0.006072874
##   yes 0.043461829 0.993927126
## 
##   Parameters of node D (multinomial distribution)
## 
## Conditional probability table:
##  
## , , E = no
## 
##      B
## D             no        yes
##   no  0.90012963 0.21376147
##   yes 0.09987037 0.78623853
## 
## , , E = yes
## 
##      B
## D             no        yes
##   no  0.27777778 0.14630225
##   yes 0.72222222 0.85369775
```


## Validación del modelo
Ahora que tenemos una estructura de red y tablas de probabilidad condicional en los nodos, el siguiente paso es validar el modelo o, más bien, evaluar el modelo ajustado a los datos. "La validación cruzada es una forma estándar de obtener estimaciones imparciales de la bondad de ajuste de un modelo. Comparando tales medidas para diferentes estrategias de aprendizaje (diferentes combinaciones de algoritmos de aprendizaje, técnicas de adaptación y los parámetros respectivos) podemos elegir la óptima para los datos que tenemos en mano de una manera basada en principios de objetividad".

_bnlearn_ tiene 3 métodos para validación cruzada: `k-fold`(default), `custom`, and `hold out`. Para el ejercicio coparemos las primeras dos: `k-fold` and `custom`.

Este es el ejemplo del método `k-fold`

Los datos se "particionan" (separan), en _k_ subconjuntos del mmismo tamaño cada uno. Cada subconjunto es usado por turnos para validar el modelo que ha sido entrenado con los restante _k_-1 subconjuntos.

A lower expected loss value is better. Here we will cross-validate two learning algorithms - Max-Min Hill-Climb (mmhc) and Hill-Climb (hc). And the BDE scoring method will be used, which requires an iss (‘imaginery sample size’ used for bde scores) term.


```r
bn.cv(asia, bn = "mmhc", algorithm.args = list())
```

```
## 
##   k-fold cross-validation for Bayesian networks
## 
##   target learning algorithm:             Max-Min Hill-Climbing 
##   number of folds:                       10 
##   loss function:                         Log-Likelihood Loss (disc.) 
##   expected loss:                         2.423674
```

```r
bn.cv(asia, bn = "hc", algorithm.args = list(score = "bde", iss = 1))
```

```
## 
##   k-fold cross-validation for Bayesian networks
## 
##   target learning algorithm:             Hill-Climbing 
##   number of folds:                       10 
##   loss function:                         Log-Likelihood Loss (disc.) 
##   expected loss:                         2.209672
```

Podemos especifica el número de repeticiones, lo usual es hacer 10.


```r
cv_mmhc = bn.cv(asia, bn = "hc", runs = 10, 
                algorithm.args = list(score = "bde", iss = 1))
cv_hc = bn.cv(asia, bn = "mmhc", runs = 10, algorithm.args = list())

cv_mmhc
```

```
## 
##   k-fold cross-validation for Bayesian networks
## 
##   target learning algorithm:             Hill-Climbing 
##   number of folds:                       10 
##   loss function:                         Log-Likelihood Loss (disc.) 
##   number of runs:                        10 
##   average loss over the runs:            2.210296 
##   standard deviation of the loss:        0.0004522641
```

```r
cv_hc
```

```
## 
##   k-fold cross-validation for Bayesian networks
## 
##   target learning algorithm:             Max-Min Hill-Climbing 
##   number of folds:                       10 
##   loss function:                         Log-Likelihood Loss (disc.) 
##   number of runs:                        10 
##   average loss over the runs:            2.423507 
##   standard deviation of the loss:        0.0003462725
```

De esta manera, los resultados de la validación cruzada, sugieren que el algoritmo basado en "escalada simple" (Hill-Climb) produce una estructura del modelo/red que ajusta bastante bien a los datos, a juzgar por el valor de error total al predecir (loss):

|Algoritmo    | error (loss)    |
|-------------|-----------------|
| mmhc        |2.210296|
| hc          |2.423507  |



## Inferencia

Ahora que tenemos la estructura y las estimmaciones de los parámetros de la red podemos hacer inferencias con ella. Una ventaja de las redes bayesianas es que la inferencia puede hacerse en cualquier dirección (omnidireccional), de principio hacia el final o del final hacia el principio o de en medio hacia alguno de los extremos. Cada uan de esas modalidades se puede reconocer como una forma distinta de "razonamiento". Veamos un par de ejeplos:

Inicio a final: de Asia  rayos-X:


```r
consulta_red = cpquery(fit1, event = (X=="yes"), evidence = ( A=="yes"))
```

la probabilidad de que tu catastro toraxico sea positivo cuando has estado en Asia es alrededor de 22.22%.

Ahora el caso contrario: rayos-X Xray implicación respecto de Asia:


```r
consulta_red = cpquery(fit1, event = (A=="yes"), evidence = ( X=="yes"))
```

En este caso la probabilidad de haber estado en Asia dado que se te encontró una placa de rayos-X positiva es alrededor de 1.4%.



# Ejemplo dulces en bolsas

Tenemos cinco tipos de bolsas sin marcas particulares que contienen dulces de dos tipo: cereza y limón. En cada bolsa hay distinta proporción de cada uno de ellos:



![](./imagenes/bolsas.png){width=50%}

|bolsa     | cereza |  limón |frecuencia |
|----------|--------|--------|-----------|
|$b_1$     |  100%  |   0%   |    0.1    |
|$b_2$     |   75%  |  25%   |    0.2    |
|$b_3$     |   50%  |  50%   |    0.4    |
|$b_4$     |   25%  |  75%   |    0.2    |
|$b_5$     |    0%  | 100%   |    0.1    |

Recibes de regalo una de estas bolsas ¿de qué tipo será?. De inicio y considerando que no te gustan los dulces de limón, piensas que ojalá tu bolsa sea del tipo $b_3$, notando que es el tipo más frecuente de bolsa. Finalmente, te enfrentas a la realidad y empiezas a examinarlos (es decir, obtienes datos de entrenamiento, $\textbf{d}$) y entonces tu hipótesis respecto del tipo de bolsa que es más probable que tengas se ajustará correspondientemente.

Cada tipo de bolsa tiene probabilidad de estar en tus manos según la siguiente expresión (_verosimilitud_:

$$
P(b_i|\textbf{d}) = \alpha P(\textbf{d}|b_i) P(b_i)
$$
Si nos preguntamos sobre la probabilidad de que el siguiente dulce que tome sea de limón sin saber el tipo de bolsa que tengo, necesito generar la distribución de probabilidades del asunto. Para calcular la distribucipón de probabilidad de una bolsa desconocida, dada la muestra de dulces que tenga, $\textbf{X}$, recurro a la siguiente expresión (_probabilidad total_):
$$
P(X|\textbf{d}) = \sum_{i} P(X|\textbf{d}, b_i) P(b_i|\textbf{d}) = \sum_{i} P(X|b_i)P(b_i|\textbf{d})
$$
Si las observacions $\textbf{d}$ son independientes, entonces

$$
P(\textbf{d}|b_i) = \prod_j P(d_j|b_i)
$$
Supongamos que los primeros 10 dulces que sacaste de la bolas fueron todos de limón. ¿Cómo afecta eso mi creencia inicial al pensar que la bolsa era de tipo $b_3$? Con el supuesto de que la bolsa es de tipo 3, las cantidades de los dos dulces es la misma, la probabilidad de cada tipo (suponiendo que no alteramos esas proporciones al sacarlos) es 0.5, y por tanto, la probabilidad de obtener una muestra de 10 dulces de limón condicionado a que tiene una bolsa tipo 3 es: $P(\textbf{d}|b_3) = 5^{10} \approx 0.001$.



```r
p_d_b3 <- 0.5^10
p_d_b3
```

```
## [1] 0.0009765625
```

Si hacemos esto mismo para distinto número de apariciones de dulces de limón en la muestra, obtenemos las siguientes gráficas.

<img src="24_bayes_legal_entrenamiento_RB_files/figure-html/unnamed-chunk-56-1.png" width="672" />

Una función para calcular estas probabilidades.


```r
bayes_dulces <- function(n_muestra, n_limon, bolsas, prop_dulces)
{
    priors <- bolsas
    dulces_limon_bi <- prop_dulces
    verosimilitud_bi_n_limon <- dbinom(n_limon, n_muestra, dulces_limon_bi)
    total_p <- sum(priors * verosimilitud_bi_n_limon)
    posterior <- priors * verosimilitud_bi_n_limon / total_p
}
```

¿Qué tipo de bolsa puedo tener si tomo una muestra de 11 dulces y obtengo 8 dulces de limón?
 

 bolsa   posterior 
------- -----------
  b1         0     
  b2     0.002527  
  b3      0.3834   
  b4      0.6141   
  b5         0     

Table: Probabilidades a posteriori para cada tipo de bolsa




