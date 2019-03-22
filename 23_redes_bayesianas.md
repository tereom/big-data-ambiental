# Redes bayesianas

Los paquetes que usaremos en esta sección son:

* CRAN: tidyverse (dplyr, ggplot2, purrr), bnlearn, 
BiocManager, igraph, gRain.

* Bioconductor: Rgraphviz, RBGL

```
install.packages("BiocManager")
BiocManager::install("Rgraphviz")
```

Y las referencias son @koller, @ross y @wasserman.

```
## Warning: package 'forcats' was built under R version 3.5.2
```


### Intoducción: Modelos gráficos {-}

Un modelo gráfico es una red de variables aleatorias donde:

* Nodos representan variables aleatorias.

* Arcos (dirigidos o no) representan dependencia

Los dos esquemas generales para representar dependencias/independiencias 
(condicionales) de forma gráfica son los modelos dirigidos (redes bayesianas) y 
no dirigidos (redes markovianas).

En este módulo nos enfocaremos en **modelos dirigidos** veamos un ejemplo de una
red de seguros de auto.

En este ejemplo nos interesa entender los patrones de dependencia entre 
variables como edad, calidad de conductor y tipo de accidente:


```
#>   GoodStudent        Age   SocioEcon RiskAversion VehicleYear ThisCarDam
#> 1       False      Adult       Prole  Adventurous       Older   Moderate
#> 2       False     Senior       Prole     Cautious     Current       None
#> 3       False     Senior UpperMiddle   Psychopath     Current       None
#> 4       False Adolescent      Middle       Normal       Older       None
#> 5       False Adolescent       Prole       Normal       Older   Moderate
#> 6       False      Adult UpperMiddle       Normal     Current   Moderate
#>   RuggedAuto Accident   MakeModel DrivQuality    Mileage Antilock
#> 1   EggShell     Mild     Economy        Poor TwentyThou    False
#> 2   Football     None     Economy      Normal TwentyThou    False
#> 3   Football     None FamilySedan   Excellent     Domino     True
#> 4   EggShell     None     Economy      Normal  FiftyThou    False
#> 5   Football Moderate     Economy        Poor  FiftyThou    False
#> 6   EggShell Moderate   SportsCar        Poor  FiftyThou     True
#>   DrivingSkill SeniorTrain ThisCarCost Theft   CarValue HomeBase AntiTheft
#> 1  SubStandard       False     TenThou False   FiveThou     City     False
#> 2       Normal        True    Thousand False    TenThou     City      True
#> 3       Normal       False    Thousand False TwentyThou     City     False
#> 4       Normal       False    Thousand False   FiveThou   Suburb     False
#> 5  SubStandard       False     TenThou False   FiveThou     City     False
#> 6  SubStandard       False HundredThou False TwentyThou   Suburb      True
#>      PropCost OtherCarCost OtherCar  MedCost Cushioning Airbag  ILiCost
#> 1     TenThou     Thousand     True Thousand       Poor  False Thousand
#> 2    Thousand     Thousand     True Thousand       Good   True Thousand
#> 3    Thousand     Thousand    False Thousand       Good   True Thousand
#> 4    Thousand     Thousand     True Thousand       Fair  False Thousand
#> 5     TenThou     Thousand    False Thousand       Fair  False Thousand
#> 6 HundredThou  HundredThou     True  TenThou       Poor   True Thousand
#>   DrivHist
#> 1     Many
#> 2     Zero
#> 3      One
#> 4     Zero
#> 5     Many
#> 6     Many
```

Aprendemos la estructura de la red:


```r
insurance_gm <- hc(insurance_dat, blacklist = blacklist)
graphviz.plot(insurance_gm)
#> Loading required namespace: Rgraphviz
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-3-1.png" width="672" />

```r
insurance.fit <- bn.fit(insurance_gm, data = insurance_dat, 
                        method = 'bayes', iss = 1)
```

¿Cómo interpretar esta gráfica?

Vemos por ejemplo como mucho de la asociación entre edad y tipo de accidente 
desaparece cuando condicionamos a calidad de conductor.


```r
prop.table(table(insurance$Age, insurance$Accident), margin = 1)
#>             
#>                Mild Moderate   None Severe
#>   Adolescent 0.1214   0.1172 0.5734 0.1881
#>   Adult      0.0844   0.0780 0.7331 0.1044
#>   Senior     0.0593   0.0493 0.8137 0.0778
prop.table(table(insurance$Age, insurance$Accident, insurance$DrivQuality), 
           margin = c(1, 3))
#> , ,  = Excellent
#> 
#>             
#>                 Mild Moderate    None  Severe
#>   Adolescent 0.01163  0.00194 0.98256 0.00388
#>   Adult      0.01118  0.00437 0.98154 0.00292
#>   Senior     0.00449  0.00359 0.98833 0.00359
#> 
#> , ,  = Normal
#> 
#>             
#>                 Mild Moderate    None  Severe
#>   Adolescent 0.01676  0.01341 0.96144 0.00838
#>   Adult      0.02236  0.01110 0.96012 0.00641
#>   Senior     0.02531  0.01395 0.95558 0.00517
#> 
#> , ,  = Poor
#> 
#>             
#>                 Mild Moderate    None  Severe
#>   Adolescent 0.19847  0.19507 0.28687 0.31959
#>   Adult      0.20812  0.20861 0.29054 0.29273
#>   Senior     0.19283  0.17492 0.31928 0.31296
```

También podemos entender cómo depende calidad de conductor de edad y aversión al riesgo (modelo local para DrvQuality):


```r
prop_tab_q <- prop.table(table(insurance$DrivQuality, insurance$RiskAversion, insurance$Age), c(2, 3))
prop_tab_q
#> , ,  = Adolescent
#> 
#>            
#>             Adventurous Cautious Normal Psychopath
#>   Excellent      0.1832   0.1667 0.0444     0.2195
#>   Normal         0.1762   0.3519 0.4349     0.0732
#>   Poor           0.6406   0.4815 0.5207     0.7073
#> 
#> , ,  = Adult
#> 
#>            
#>             Adventurous Cautious Normal Psychopath
#>   Excellent      0.2882   0.2295 0.0964     0.2516
#>   Normal         0.2413   0.4704 0.6071     0.1355
#>   Poor           0.4705   0.3001 0.2965     0.6129
#> 
#> , ,  = Senior
#> 
#>            
#>             Adventurous Cautious Normal Psychopath
#>   Excellent      0.2515   0.3751 0.1582     0.2500
#>   Normal         0.1871   0.4920 0.5459     0.1136
#>   Poor           0.5613   0.1329 0.2959     0.6364

df_q <- data.frame(prop_tab_q)
names(df_q) <- c('DrvQuality', 'RiskAversion', 'Age', 'Prop')
ggplot(df_q, aes(x = Age, y = Prop, colour = RiskAversion, 
                 group = RiskAversion)) + 
  geom_line() + facet_wrap(~DrvQuality) +
  geom_point()
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-5-1.png" width="672" />

Otras asociaciones con _DrvQuality_ podemos entenderlas a través de estas
dos variables: edad y aversión al riesgo.
Veremos cómo modelar estas estructuras (además de usar las tablas, que corresponden
a estimación de máxima verosimilitud sin restricciones, podemos usar por ejemplo
GLMs).

### ¿Por qué modelos gráficos?  {-}

* Usando modelos gráficos podemos representar de manera compacta y atractiva
distribuciones de probabilidad entre variables aleatorias.

* Auxiliar en el diseño de modelos.  
  + Fácil combinar información proveniente de los datos con conocimiento de 
  expertos.

* Proveen un marco general para el estudio de modelos más específicos. Muchos
de los modelos probabilísticos multivariados clásicos son casos particulares 
del formalismo general de modelos gráficos (mezclas gaussianas, modelos de 
espacio de estados ocultos, análisis de factores, filtro de Kalman,...).

* Juegan un papel importante en el diseño y análisis de algoritmos de
aprendizaje máquina.

## Gráficas dirigidas

Una gráfica dirigida ${\mathcal G}$ es un conjunto de vértices junto con
un subconjunto de aristas dirigidas (pares ordenados de vértices). 
En nuestro caso, cada vértice corresponde a una variable aleatoria, y cada
arista dirigida representa una asociación probabilística entre las variables 
(vértices) que conecta. Nos interesan en particular las **gráficas dirigidas acíclicas** (GADs), estas son aquellas que no tienen caminos dirigidos partiendo 
de un vértice y regresando al mismo (ciclos).


**Ejemplo.**

```r
library(igraph, warn.conflicts = FALSE)
gr <- graph(c(1, 2, 3, 2, 3, 4))
plot(gr, 
  vertex.label = c('Dieta', 'Enf. corazón', 'Fuma', 'Tos'), 
  layout = matrix(c(0, 0.5, 2, 0, 4, 0.5, 6, 0), byrow = TRUE, ncol = 2),
  vertex.size = 23, vertex.color = 'salmon', vertex.label.cex = 1.2,
  vertex.label.color = 'gray40', vertex.frame.color = NA, asp = 0.5, 
  edge.arrow.size = 1)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-6-1.png" width="480" />

Nos interesan estas gráficas por lo que pueden representar acerca de la 
estructura de la distribución conjunta de las variables. Recordemos que 
la distribución conjunta es el modelo completo del fenómeno, a partir de la cual
podemos contestar cualquier pregunta de inferencia, asociación, independencia, 
etc.

En las siguientes secciones explicaremos dos enfoques para 
interpretar una gráfica dirigida probabilísticamente (en términos de la 
distribución conjunta).

* Por una parte la gráfica define un esqueleto que sirve para 
representar de manera compacta una distribución de dimensión alta, esto es:
En lugar de codificar la probabilidad de todos los posibles valores de las 
variables en nuestro dominio, podemos separar la distribución en factores
más chicos, cada uno sobre un conjunto de posibilidades mucho más chico. Una
vez que definimos los factores podemos definir la distribución conjunta como
el producto de los factores.

* La segunda perspectiva es que la gráfica es una representación compacta 
de un conjunto de independencias que se sostienen en la distribución (la 
distribución que codifica nuestras creencias de una situación particular).


### Probabilidad conjunta y factorizaciones  {-}

<div class="caja">
Siempre es posible representar a una distribución conjunta como un
producto de condicionales de una sola variable. Dado un ordenamiento
$X_1,X_2,\ldots, X_k$, podemos escribir (por la regla del producto)
$$p(x_1,\ldots, x_k)=p(x_1)p(x_2|x_1)p(x_3|x_1,x_2)\cdots p(x_k|x_1,\ldots, x_{k-1}).$$
</div>

<br/>
Por ejemplo, si tenemos tres variables $X_1,X_2,X_3$ podemos usar la regla del
producto para obtener

$$p(x_1,x_2,x_3)= p(x_1)p(x_2|x_1)p(x_3|x_1,x_2),$$

también podemos ordenar las variables de manera distinta y escribir:

$$p(x_1,x_2,x_3)= p(x_3)p(x_1|x_3)p(x_2|x_1,x_3).$$

Estas son representaciones válidas para la conjunta de $X_1,X_2,X_3$. 
Para modelar $X_1,X_2,X_3$ podríamos entonces estimar primero la marginal
de $X_3$, después entender la condicional de $X_1$ dada $X_3$ y finalmente
la condicional de $X_2$ dado $X_1$ y $X_3$. Algunas representaciones
son más fáciles para trabajar, calcular y entender que otras.

**Ejemplo.** Si sacamos sucesivamente tres cartas de una baraja y registramos
si son rojas o negras, lo más fácil es definir $X_i$ = color de la $i$-ésima 
carta, y entonces si buscamos calcular 
$$p(X_1=roja, X_2=roja, X_3=negra),$$
simplemente calculamos: 
$$P(X_1=roja)=26/52, P(X_2=roja|X_1=roja)=25/51$$ 
y finalmente 
$$P(X_3=negra|X_1=roja,X_2=roja)=25/50,$$ 
de modo que la probabilidad que nos interesa es 
$$\frac{26\cdot 25\cdot 26}{52\cdot 51\cdot 50}.$$

Otro caso en que la factorización que escogemos es importante, es cuando existen
independencias condicionales, la factorización puede resultar en un modelo más
compacto o más conveniente.

**Ejemplo.** Si $X_2$ y $X_3$ son independentes y $X_2$ es condicionalmente
independiente de $X_1$ dado $X_3$, podemos comenzar con la segunda factorización

$$p(x_1,x_2,x_3)= p(x_3)p(x_1)p(x_2|x_1,x_3),$$ 

y finalmente 

$$p(x_1,x_2,x_3)=p(x_3)p(x_1)p(x_2|x_3)$$

el cual es un modelo considerablemente más simple que el original pues
incluye dos marginales y sólo es necesario modelar cómo depende $x_2$ de $x_3$. 
Esto lo expresamos en el siguiente resultado:

<div class="caja">
Una factorización de la conjunta puede ser entendida como una parametrización
particular de la conjunta a través de sus distribuciones condicionales.
</div>

<br/>

**Ejemplo.** Supongamos la factorización $p(x,y)=p(x)p(y|x)$, y que $x$ y $y$ 
son variables binarias que toman los valores $0$ y $1$. La parametrización usual
para $p(x,y)$ está dada por $p_{00},p_{01},p_{10},p_{11}$ donde
$p(x,y)=p_{xy}$ y $p_{00} +p_{01}+p_{10}+p_{11}=1$ (3 parámetros en total). De 
esta forma tenemos que especificar, por ejemplo, los parámetros 
$p_{00},p_{01},p_{10}$.

Por otra parte, la factorización sugiere los parámetros $p_0,p_{0|1},p_{0|0},$
donde $p_0=p(x=0)$, $p_{0|1}=p(y=0|x=1)$ y $p_{0|0}=p(y=0|x=0)$. Los otros 
parámetros están dados por $p_1=1-p_0$, $p_{1|0}=1-p_{0|0}$ y 
$p_{1|1}=1-p_{0|1}$.

<br/>

<div class="caja">
Nótese que la idea general es 

1. Usar la regla de la cadena, lo que siempre nos da una expresión válida para 
la conjunta, y en la cual aparece la condicional de cada variable una sola vez 
para una ordenamiento adecuado de las variables.  

2. Simplificar la expresión obtenida usando las independencias condicionales
que suponemos.  

3. Hacer los cálculos/inferencia, etc. usando la parametrización de 
condicionales.
</div>


### Factorizaciones de la conjunta y gráficas dirigidas.

<div class="clicker">
<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-7-1.png" width="672" />

3. ¿Qué factorización crees que es apropiada para la distribución conjunta 
$p(d, i, c, g, r)$?

a) $p(d)p(i)p(c|i)p(c|d)$
b) $p(d)p(i)p(c|i,d)p(g|i)p(r|c)$
c) $p(d)p(i)p(c)p(g)p(r)$
d) $p(d|c)p(i|c,g)p(c|r)p(g)p(r)$  
e) Ninguna de las anteriores.
</div>

<br/>

En primer lugar, las _gráficas dirigidas acíclicas_ asociadas a una distribución
conjunta dan una factorización particular $p$ para la conjunta. 

Sea ${\mathcal G}$ una gráfica dirigida con vértices $X_1,X_2,...,X_k$, 
denotamos por $Pa(x_i)$ a todos los padres de $X_i$ en ${\mathcal G}$.

<br/>

<div class="caja">
Sea $p$ una distribución conjunta para $X_1,X_2,\ldots, X_k$. Decimos que
${\mathcal G}$ **representa** a $p$ cuando la conjunta se factoriza como
$$p(x_1,x_2,\ldots, x_n)=\prod_{i=1}^k p(x_i|Pa(x_i)).$$ 

El conjunto de distribuciones que son representadas por ${\mathcal G}$ lo 
denotamos por $M({\mathcal G})$ (llamadas distribuciones markovianas con 
respecto a $\mathcal G$).
</div>

<div class="caja">
Nótese que una gráfica acíclica no dirigida (GAD) *no* establece una 
distribución particular, sino un conjunto de posibles distribuciones: todas 
las distribuciones que se factorizan bajo ${\mathcal G}$.
</div>

<br/>

**Nota.** La factorización del lado derecho del resultado
$$p(x_1,x_2,\ldots, x_n)=\prod_{i=1}^k p(x_i|Pa(x_i))$$
siempre es una distribución de probabilidad. Por ejemplo, si consideramos
la siguiente factorización de $p(x,u,d,f,e,y,t)$:

$$p(x)p(u)p(d)p(f|d)p(e|f)p(y|f)p(t|d,u).$$ 

Veremos que es una distribución de probabilidad como sigue: en primer lugar,
este producto es no negativo, pues todas son distribuciones condicionales. Basta
demostrar que si sumamos sobre todos los posibles valores de $x,u,d,f,e,y,t$,
entonces esta expresión suma 1:
$$\sum_{x,u,d,f,e,y,t}p(x)p(u)p(d)p(f|d)p(e|f)p(y|f)p(t|d,u) $$
$$\left (\sum_{u,d,f,e,y,t}p(u)p(d)p(f|d)p(y|f)p(t|d,u)\right)\left(\sum_{x}p(x)\right) $$
$$\sum_{u,d,f,t}\left \{ p(u)p(d)p(f|d)p(t|d,u)\sum_y p(y|f)\sum_e p(e|f) \right\}$$
$$\sum_{u,d,f,t}p(u)p(d)p(f|d)p(t|d,u)$$
$$\sum_{u,d,t}\left \{ p(u)p(d)p(t|d,u)\sum_f p(f|d)\right \}$$
$$\sum_{u,d,t}p(u)p(d)p(t|d,u)$$
$$\sum_{u,d}p(u)p(d)$$
$$\sum_{d}p(d)\sum_u p(u)=1$$

**Discusión.** Ordenamiento topológico de vértices en un gráfica dirigida 
acíclica.

En este último ejemplo vimos que el cálculo de la suma total se hace 
_empujando_ primero dentro de la suma los índices de las variables que no tienen
descendientes (o que no aparecen como condicionadoras), y trabajando hacia 
arriba. En términos de la gráfica, trabajamos de los _últimos vértices_ hasta 
los _primeros_.

De hecho, una GAD siempre da un ordenamiento (topológico) de los vértices, 
módulo variables que están al mismo _nivel_. Por ejemplo, en la gráfica de la 
figura anterior, los ordenamientos son $D,I,C,G,R$ o $I,D,C,G,R$. 
¿Qué ordenamiento da la siguiente gráfica?


```r
 gr <- graph(c(1, 2, 1, 3, 3, 2, 2, 4))
 plot(gr,
  vertex.label=c('X','Y','Z','W'), 
  layout = matrix(c(0, 0.5, 0.5, 0, 0, -0.5, 1, 0), byrow = TRUE, ncol = 2),
  vertex.size = 20, vertex.color = 'salmon', vertex.label.cex = 1.2,
  vertex.label.color = 'gray40', vertex.frame.color = NA, asp = 0.5, 
  edge.arrow.size = 1)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-8-1.png" width="480" />

**Ejemplo: Gráficas cíclicas.** Cuando hay ciclos en una gráfica, no hay una 
manera clara de entender qué factorización produce. Por ejemplo, si tenemos 
tres variables $X$, $Y$,$Z$ asociados con un ciclo $X\rightarrow Y\rightarrow Z\rightarrow X$, esto quizá sugiere una factorización $p(y|x)p(z|y)p(x|z)$. Pero
se puede ver  que esta expresión en general no es una distribución de 
probabilidad.  


```r
library(dplyr)
# x: inteligencia, y: examen, z: trabajo
# y|x 
mar_1 <- expand.grid(x = c("i_0", "i_1"), y = c("e_0", "e_1"))
mar_1$p1 <- c(0.95, 0.2, 0.05, 0.8)
# z|y 
mar_2 <- expand.grid(y = c("e_0", "e_1"), z = c("t_0", "t_1"))
mar_2$p2 <- c(0.8, 0.4, 0.2, 0.6) 
# x|z
mar_3 <- expand.grid(z = c("t_0", "t_1"), x = c("i_0", "i_1"))
mar_3$p3 <- c(0.8, 0.4, 0.2, 0.6) 

tab_1 <- inner_join(mar_1, mar_2)
#> Joining, by = "y"
tab_2 <- inner_join(tab_1, mar_3)
#> Joining, by = c("x", "z")
tab_2$p <- tab_2$p1 * tab_2$p2 * tab_2$p3
sum(tab_2$p)
#> [1] 1.12
```

En el ejemplo anterior vemos que $p(y|x)p(z|y)p(x|z)$ no suma uno. Por otra
parte $p(x)p(y|x)p(z|y,x)$ si suma uno:


```r
# x: inteligencia, y: examen, z: trabajo
# x 
mar_1 <- data.frame(x = c("i_0", "i_1"), p1 = c(0.6, 0.4))
# y|x
mar_2 <- expand.grid(x = c("i_0", "i_1"), y = c("e_0", "e_1"))
mar_2$p2 <- c(0.95, 0.2, 0.05, 0.8)
# z|x,y 
mar_3 <- expand.grid(y = c("e_0", "e_1"), x = c("i_0", "i_1"),
                     z = c("t_0", "t_1"))
mar_3$p3 <- c(0.8, 0.6, 0.5, 0.1, 0.2, 0.4, 0.5, 0.9) 

tab_1 <- inner_join(mar_1, mar_2)
#> Joining, by = "x"
tab_2 <- inner_join(tab_1, mar_3)
#> Joining, by = c("x", "y")
tab_2$p <- tab_2$p1 * tab_2$p2 * tab_2$p3
sum(tab_2$p)
#> [1] 1
```

### Redes bayesianas

Ahora podemos definir _red bayesiana_: 

<div class="caja">
Una **red bayesiana** es una gráfica GAD ${\mathcal G}$ junto con una 
distribución de probabilidad particular que se factoriza sobre $G$.
</div>

<br/>

Dado que $p$ se factoriza sobre $\mathcal G$, podemos usar la factorización
para evitar dar explícitamente la conjunta sobre todas las posibles 
combinaciones de las variables. Es decir, podemos usar la parametrización dada 
por la factorización en condicionales.

**Ejemplo.** Sea ${\mathcal G}$ la siguiente gráfica


```r
library(igraph)
gr <- graph( c(1,2,3,2,2,4)  )
plot(gr,
  vertex.label=c('llueve', 'mojado', 'regar', 'piso'), 
  layout = matrix(c(0, 1, 1, 0, 0, -1, 2, 0), byrow = TRUE, ncol = 2),
  vertex.size = 20, vertex.color = 'salmon', vertex.label.cex = 1.2,
  vertex.label.color = 'gray40', vertex.frame.color = NA, asp = 0.5, 
  edge.arrow.size = 1)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-11-1.png" width="672" />

La conjunta $p(m,l,r,z)$ ($z$ es piso resbaloso) se factoriza como
$$p(l)p(r)p(m|l,r)p(z|m)$$

En este ejemplo construiremos la red como si fuéramos los expertos. Esta
es una manera de construir redes que ha resultado útil y exitosa en varias 
áreas (por ejemplo diagnóstico).

De forma que podemos construir una red bayesiana simplemente dando los
valores de cada factor. En nuestro ejemplo, empezamos por las marginales de $l$ 
y $r$:


```r
llueve <- c('No', 'Sí')
p_llueve <- data.frame(llueve = factor(llueve, levels= c("No", "Sí")), 
  prob_l = c(0.9, 0.1))
p_llueve
#>   llueve prob_l
#> 1     No    0.9
#> 2     Sí    0.1
regar <- c('Apagado', 'Prendido')
p_regar <- data.frame(regar = factor(regar, levels = c('Apagado', 'Prendido')),
  prob_r = c(0.7, 0.3))
p_regar
#>      regar prob_r
#> 1  Apagado    0.7
#> 2 Prendido    0.3
```

Ahora establecemos la condicional de mojado dado lluvia y regar:


```r
mojado <- c('Mojado','Seco')
# los niveles son todas las combinaciones de los valores de las variables
niveles <- expand.grid(llueve = llueve, regar = regar, mojado = mojado)
# mojado|lluve,regar
p_mojado_lr <- data.frame(niveles, prob_m = NA)
p_mojado_lr$prob_m[1:4] <- c(0.02, 0.6, 0.7, 0.9)
p_mojado_lr$prob_m[5:8]<- 1 - p_mojado_lr$prob_m[1:4]
p_mojado_lr
#>   llueve    regar mojado prob_m
#> 1     No  Apagado Mojado   0.02
#> 2     Sí  Apagado Mojado   0.60
#> 3     No Prendido Mojado   0.70
#> 4     Sí Prendido Mojado   0.90
#> 5     No  Apagado   Seco   0.98
#> 6     Sí  Apagado   Seco   0.40
#> 7     No Prendido   Seco   0.30
#> 8     Sí Prendido   Seco   0.10
```

Y finalmente la condicional de piso resbaloso dado piso mojado:


```r
p_piso_mojado <- data.frame(expand.grid(
  piso = c('Muy.resbaladizo', 'Resbaladizo', 'Normal'), 
  mojado=c('Mojado','Seco')))
p_piso_mojado
#>              piso mojado
#> 1 Muy.resbaladizo Mojado
#> 2     Resbaladizo Mojado
#> 3          Normal Mojado
#> 4 Muy.resbaladizo   Seco
#> 5     Resbaladizo   Seco
#> 6          Normal   Seco
p_piso_mojado$prob_p <- c(0.3, 0.6, 0.1, 0.02, 0.3, 0.68)
p_piso_mojado
#>              piso mojado prob_p
#> 1 Muy.resbaladizo Mojado   0.30
#> 2     Resbaladizo Mojado   0.60
#> 3          Normal Mojado   0.10
#> 4 Muy.resbaladizo   Seco   0.02
#> 5     Resbaladizo   Seco   0.30
#> 6          Normal   Seco   0.68
```

Con esta información podemos calcular la conjunta. En este caso, como el 
problema es relativamente chico, podemos hacerlo explícitamente para todos los
niveles:


```r
library(dplyr)
p_1 <- inner_join(p_piso_mojado, p_mojado_lr)
#> Joining, by = "mojado"
p_2 <- inner_join(p_1, p_llueve)
#> Joining, by = "llueve"
p_conj <- inner_join(p_2, p_regar)
#> Joining, by = "regar"
p_conj$prob <- p_conj$prob_p * p_conj$prob_m * p_conj$prob_l * p_conj$prob_r
p_conj
#>               piso mojado prob_p llueve    regar prob_m prob_l prob_r
#> 1  Muy.resbaladizo Mojado   0.30     No  Apagado   0.02    0.9    0.7
#> 2  Muy.resbaladizo Mojado   0.30     Sí  Apagado   0.60    0.1    0.7
#> 3  Muy.resbaladizo Mojado   0.30     No Prendido   0.70    0.9    0.3
#> 4  Muy.resbaladizo Mojado   0.30     Sí Prendido   0.90    0.1    0.3
#> 5      Resbaladizo Mojado   0.60     No  Apagado   0.02    0.9    0.7
#> 6      Resbaladizo Mojado   0.60     Sí  Apagado   0.60    0.1    0.7
#> 7      Resbaladizo Mojado   0.60     No Prendido   0.70    0.9    0.3
#> 8      Resbaladizo Mojado   0.60     Sí Prendido   0.90    0.1    0.3
#> 9           Normal Mojado   0.10     No  Apagado   0.02    0.9    0.7
#> 10          Normal Mojado   0.10     Sí  Apagado   0.60    0.1    0.7
#> 11          Normal Mojado   0.10     No Prendido   0.70    0.9    0.3
#> 12          Normal Mojado   0.10     Sí Prendido   0.90    0.1    0.3
#> 13 Muy.resbaladizo   Seco   0.02     No  Apagado   0.98    0.9    0.7
#> 14 Muy.resbaladizo   Seco   0.02     Sí  Apagado   0.40    0.1    0.7
#> 15 Muy.resbaladizo   Seco   0.02     No Prendido   0.30    0.9    0.3
#> 16 Muy.resbaladizo   Seco   0.02     Sí Prendido   0.10    0.1    0.3
#> 17     Resbaladizo   Seco   0.30     No  Apagado   0.98    0.9    0.7
#> 18     Resbaladizo   Seco   0.30     Sí  Apagado   0.40    0.1    0.7
#> 19     Resbaladizo   Seco   0.30     No Prendido   0.30    0.9    0.3
#> 20     Resbaladizo   Seco   0.30     Sí Prendido   0.10    0.1    0.3
#> 21          Normal   Seco   0.68     No  Apagado   0.98    0.9    0.7
#> 22          Normal   Seco   0.68     Sí  Apagado   0.40    0.1    0.7
#> 23          Normal   Seco   0.68     No Prendido   0.30    0.9    0.3
#> 24          Normal   Seco   0.68     Sí Prendido   0.10    0.1    0.3
#>       prob
#> 1  0.00378
#> 2  0.01260
#> 3  0.05670
#> 4  0.00810
#> 5  0.00756
#> 6  0.02520
#> 7  0.11340
#> 8  0.01620
#> 9  0.00126
#> 10 0.00420
#> 11 0.01890
#> 12 0.00270
#> 13 0.01235
#> 14 0.00056
#> 15 0.00162
#> 16 0.00006
#> 17 0.18522
#> 18 0.00840
#> 19 0.02430
#> 20 0.00090
#> 21 0.41983
#> 22 0.01904
#> 23 0.05508
#> 24 0.00204
sum(p_conj$prob)
#> [1] 1
```

Usamos el paquete **bnlearn** para construir el objeto que corresponde a
esta red bayesiana:


```r
library(bnlearn)
# nodos
graf_jardin <- empty.graph(c('llueve', 'regar', 'mojado', 'piso'))
# arcos
arcs(graf_jardin) <- matrix(c('llueve', 'mojado', 'regar', 'mojado', 'mojado',
  'piso'), ncol = 2, byrow = T)
node.ordering(graf_jardin) 
#> [1] "llueve" "regar"  "mojado" "piso"
plot(graf_jardin)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-16-1.png" width="672" />



```r
modelo_jardin <- bn.fit(graf_jardin, 
  data = data.frame(p_conj[, c('llueve', 'regar', 'mojado', 'piso')]))
```

Y este es el objeto que representa nuestra red (aunque falta corregir las
probabilidades):


```r
str(modelo_jardin)
#> List of 4
#>  $ llueve:List of 4
#>   ..$ node    : chr "llueve"
#>   ..$ parents : chr(0) 
#>   ..$ children: chr "mojado"
#>   ..$ prob    : 'table' num [1:2(1d)] 0.5 0.5
#>   .. ..- attr(*, "dimnames")=List of 1
#>   .. .. ..$ : chr [1:2] "No" "Sí"
#>   ..- attr(*, "class")= chr "bn.fit.dnode"
#>  $ regar :List of 4
#>   ..$ node    : chr "regar"
#>   ..$ parents : chr(0) 
#>   ..$ children: chr "mojado"
#>   ..$ prob    : 'table' num [1:2(1d)] 0.5 0.5
#>   .. ..- attr(*, "dimnames")=List of 1
#>   .. .. ..$ : chr [1:2] "Apagado" "Prendido"
#>   ..- attr(*, "class")= chr "bn.fit.dnode"
#>  $ mojado:List of 4
#>   ..$ node    : chr "mojado"
#>   ..$ parents : chr [1:2] "llueve" "regar"
#>   ..$ children: chr "piso"
#>   ..$ prob    : 'table' num [1:2, 1:2, 1:2] 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5
#>   .. ..- attr(*, "dimnames")=List of 3
#>   .. .. ..$ mojado: chr [1:2] "Mojado" "Seco"
#>   .. .. ..$ llueve: chr [1:2] "No" "Sí"
#>   .. .. ..$ regar : chr [1:2] "Apagado" "Prendido"
#>   ..- attr(*, "class")= chr "bn.fit.dnode"
#>  $ piso  :List of 4
#>   ..$ node    : chr "piso"
#>   ..$ parents : chr "mojado"
#>   ..$ children: chr(0) 
#>   ..$ prob    : 'table' num [1:3, 1:2] 0.333 0.333 0.333 0.333 0.333 ...
#>   .. ..- attr(*, "dimnames")=List of 2
#>   .. .. ..$ piso  : chr [1:3] "Muy.resbaladizo" "Resbaladizo" "Normal"
#>   .. .. ..$ mojado: chr [1:2] "Mojado" "Seco"
#>   ..- attr(*, "class")= chr "bn.fit.dnode"
#>  - attr(*, "class")= chr [1:2] "bn.fit" "bn.fit.dnet"
```

Ahora pondremos las probabilidades condicionales correctas (también llamados 
modelos locales):


```r
tab_1 <- table(p_conj$llueve)
tab_1[c(1, 2)] <- p_llueve[, 2]
tab_1
#> 
#>  No  Sí 
#> 0.9 0.1
modelo_jardin$llueve <- tab_1

tab_2 <- table(p_conj$regar)
tab_2[c(1,2)] <- p_regar[,2]
tab_2
#> 
#>  Apagado Prendido 
#>      0.7      0.3
modelo_jardin$regar <- tab_2

tab_3 <- xtabs(prob_m ~ mojado + llueve + regar, data = p_mojado_lr)
tab_3
#> , , regar = Apagado
#> 
#>         llueve
#> mojado     No   Sí
#>   Mojado 0.02 0.60
#>   Seco   0.98 0.40
#> 
#> , , regar = Prendido
#> 
#>         llueve
#> mojado     No   Sí
#>   Mojado 0.70 0.90
#>   Seco   0.30 0.10
modelo_jardin$mojado <- tab_3

tab_4 <- xtabs(prob_p ~ piso + mojado, data = p_piso_mojado)
tab_4
#>                  mojado
#> piso              Mojado Seco
#>   Muy.resbaladizo   0.30 0.02
#>   Resbaladizo       0.60 0.30
#>   Normal            0.10 0.68
modelo_jardin$piso <- tab_4

modelo_jardin
#> 
#>   Bayesian network parameters
#> 
#>   Parameters of node llueve (multinomial distribution)
#> 
#> Conditional probability table:
#>  
#>  No  Sí 
#> 0.9 0.1 
#> 
#>   Parameters of node regar (multinomial distribution)
#> 
#> Conditional probability table:
#>  
#>  Apagado Prendido 
#>      0.7      0.3 
#> 
#>   Parameters of node mojado (multinomial distribution)
#> 
#> Conditional probability table:
#>  
#> , , regar = Apagado
#> 
#>         llueve
#> mojado     No   Sí
#>   Mojado 0.02 0.60
#>   Seco   0.98 0.40
#> 
#> , , regar = Prendido
#> 
#>         llueve
#> mojado     No   Sí
#>   Mojado 0.70 0.90
#>   Seco   0.30 0.10
#> 
#> 
#>   Parameters of node piso (multinomial distribution)
#> 
#> Conditional probability table:
#>  
#>                  mojado
#> piso              Mojado Seco
#>   Muy.resbaladizo   0.30 0.02
#>   Resbaladizo       0.60 0.30
#>   Normal            0.10 0.68
```


Finalmente, para hacer inferencia en la red (es decir, calcular probabilidades
dado cierto conocimiento), necesitamos usar un algoritmo eficiente (por ejemplo 
en [SAMIAM](http://reasoning.cs.ucla.edu/samiam/) o [GeNIe](https://www.bayesfusion.com/)). Aquí usamos el paquete **gRain**. Los _query_ que hacemos son 
la inferencia, pero también se llaman así en la literatura de modelos gráficos. 
En este caso, podemos examinar las marginales condicionales a toda la evidencia
(información) que tenemos.

Por ejemplo, ¿cómo se ven las marginales cuando sabemos que el piso está muy resbaladizo?


```r

library(gRain)
#> Loading required package: gRbase
#> 
#> Attaching package: 'gRbase'
#> The following objects are masked from 'package:bnlearn':
#> 
#>     ancestors, children, parents
comp_jardin <- compile(as.grain(modelo_jardin))
querygrain(comp_jardin)
#> $llueve
#> llueve
#>  No  Sí 
#> 0.9 0.1 
#> 
#> $regar
#> regar
#>  Apagado Prendido 
#>      0.7      0.3 
#> 
#> $mojado
#> mojado
#> Mojado   Seco 
#>  0.271  0.729 
#> 
#> $piso
#> piso
#> Muy.resbaladizo     Resbaladizo          Normal 
#>          0.0958          0.3812          0.5231
query_1 <- setEvidence(comp_jardin, nodes = c('piso'), 
  states = c('Muy.resbaladizo'))
querygrain(query_1)
#> $llueve
#> llueve
#>    No    Sí 
#> 0.777 0.223 
#> 
#> $regar
#> regar
#>  Apagado Prendido 
#>    0.306    0.694 
#> 
#> $mojado
#> mojado
#> Mojado   Seco 
#>  0.848  0.152
```

Podemos ver que llueve y mojado son independientes (sin condicionar).


```r
query_2 <- setEvidence(comp_jardin, nodes = c('llueve'), states = c('Sí'))
querygrain(query_2)$regar
#> regar
#>  Apagado Prendido 
#>      0.7      0.3
query_3 <- setEvidence(comp_jardin, nodes = c('llueve'), states = c('No'))
querygrain(query_2)$regar
#> regar
#>  Apagado Prendido 
#>      0.7      0.3
```

Y ahora vemos la dependencia entre llueve y regar si condicionamos a piso 
resbaladizo:


```r
query_4 <- setEvidence(comp_jardin, nodes = c('piso', 'regar'), 
  states = c('Muy.resbaladizo', 'Apagado'))
querygrain(query_4)$llueve
#> llueve
#>    No    Sí 
#> 0.551 0.449
query_5 <- setEvidence(comp_jardin, nodes=c('piso', 'regar'), 
  states = c('Muy.resbaladizo','Prendido'))
querygrain(query_5)$llueve
#> llueve
#>    No    Sí 
#> 0.877 0.123
```

![](imagenes/manicule2.jpg)  Abrir esta red en samiam, y 
repetir los queries.

### Independencia condicional y redes bayesianas

Ahora abordamos el segundo enfoque de las redes bayesianas. En este, leemos 
directamente independencias condicionales a partir de la estructura de la 
gráfica (es esencialmente equivalente al criterio de factorización).


<div class="caja"> 
**Independencias condicionales locales**

Una distribución de probabilidad $p\in M({\mathcal G})$ (es decir, se factoriza
en $\mathcal G$) si y sólo si para toda variable $W$, $W$ es condicionalmente
independiente de cualquier variable que no sea su padre o descendiente dados los
padres $Pa(W)$. Es decir $$W \bot Z|Pa(W)$$ para cualquier $Z$ que no sea 
descendiente o padre de $W$. Otra manera de decir esto es que dados los padres, 
un nodo sólo puede transmitir información probabilística a sus descendientes y 
a ningún otro nodo.
</div>
<br/>


Por ejemplo, en la siguiente gráfica, el nodo rojo, dado los nodos azules, es
condicionalmente independiente de los nodos grises:


```r
gr <- graph(c(1, 4, 2, 5, 3, 5, 4, 6, 5, 6, 7, 8, 6, 8, 8, 9, 8, 10))
plot(gr,  
  vertex.size = 20,  
  vertex.color=c(rep('gray80', 3), rep('blue', 2), 'red', 'gray80', 'salmon',
    'salmon', 'salmon'), 
  vertex.label.cex = 1.2, vertex.label.color = 'gray50', vertex.frame.color = NA, 
  asp = 0.7, edge.arrow.size = 1)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-23-1.png" width="672" />

#### Discusión de demostración.

Supongamos que las independencias locales se satisfacen según el enunciado 
anterior. Si tomamos las variables según el orden topológico de 
$\mathcal G$, dado por $X_1,\ldots, X_k$, entonces por la regla del producto:

$$p(x)=\prod_{i=1}^k p(x_i|x_1,\ldots, x_{i-1}).$$

Ahora, nótese que 1) para cada $X_i$, ninguna de las variables 
$X_1,\ldots, X_{i-1}$ es descendiente de $X_i$ y 2) que $Pa(X_i)$ está contenido
en $X_1,\ldots, X_{i-1}$. Por lo tanto, por el supuesto de las independencias
locales, vemos que
$$p(x_i|x_1,\ldots, x_{i-1})=p(x_i|Pa(x_i)),$$
y así hemos demostrado que $p$ se factoriza en $\mathcal G$. 

El otro sentido de la demostración es más difícil, veamos un ejemplo. En la
siguiente gráfica, describimos una factorización para la conjunta de
varias variables: inteligencia de un alumno, dificultad del curso,
calificación obtenida en el curso, calificación obtenida en el examen GRE y
si el alumno recibe o no una carta de recomendación de su profesor:



```r
library(igraph)
gr <- graph( c(1,3,2,3,2,4,3,5)  )
plot(gr,
  vertex.label=c('Dificultad','Inteligencia','Calificación','GRE',
                 'Recomendación'), 
  layout = matrix(c(-1,2,1,2,0,1,2,1,0,0), byrow = TRUE, ncol = 2),
  vertex.size = 20, vertex.color = 'salmon', vertex.label.cex = 1.2,
  vertex.label.color = 'gray40', vertex.frame.color = NA, asp = 0.5, 
  edge.arrow.size = 1)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-24-1.png" width="672" />

La conjunta se factoriza como
$$p(i,d,c,g,r)=p(i)p(d)p(c|d,i)p(g|i)p(r|c).$$

Queremos demostrar que dada la inteligencia, la calificación del GRE es 
condicionalmente independiente del resto de las variables (pues el resto no son 
ni padres ni descendientes de GRE), es decir, busamos demostrar que

$$p(g|i,d,c,r)=p(g|i).$$

Comenzamos por la factorización de arriba:
$$p(i,d,c,g,r)=p(i)p(d)p(c|d,i)p(g|i)p(r|c).$$
Necesitamos calcular
$$p(g|i,d,c,r)=\frac{p(g,i,d,c,r)}{p(i,d,c,r)}.$$
Así que comenzamos con la factorización y sumamos sobre $s$ para obtener
$$p(i,d,c,r)=\sum_g p(i)p(d)p(c|d,i)p(g|i)p(r|c),$$
$$p(i,d,c,r)=p(i)p(d)p(c|d,i)p(r|c),$$
y dividiendo obtenemos que
$$p(g|i,d,c,r)=p(g|i),$$
que era lo que queríamos demostrar.

De acuerdo a la gráfica, la calificación en el GRE es independiente de la dificultad una vez que conocemos la inteligencia, es decir 
$p(g | i, d) = p(g | i)$, veamos la factorización. Usando el teorema de Bayes
podemos calcular la densidad condicional como,

$$p(g|i,d) = \frac{p(g,i,d)}{p(i,d)}$$

Ahora, comencemos calculando la densidad marginal $p(g,i,d)$:
\begin{align}
  \nonumber
  p(g,i,d) &= \sum_c \sum_r p(i,d,c,r)
  \nonumber
  &= \sum_c \sum_r p(i)p(d)p(c|d,i)p(g|i)p(r|c)
  \nonumber 
  &= \sum_c  p(i)p(d)p(c|d,i)p(g|i)\sum_r p(r|c)
  \nonumber
  &=  p(i)p(d)p(g|i) \sum_c p(c|d,i)
  \nonumber
  &= p(i)p(d)p(g|i)
\end{align}
Calculemos ahora el denominador en la regla de Bayes,  
\begin{align}
  \nonumber
  p(i,d) &= \sum_g  p(g,i,d)
  \nonumber
  &= \sum_g p(i)p(d)p(g|i)
  \nonumber 
  &= p(i)p(d)\sum_g p(g|i)
  \nonumber
  &=  p(i)p(d) \mbox{   (inteligencia y dificultad son indep.)}
\end{align}
Por lo tanto, la densidad condicional es 
$$p(g|i,d) = \frac{p(g,i,d)}{p(i,d)} = \frac{p(i)p(d)p(g|i)}{p(i)p(d)} = p(g|i),$$
esto es, la calificación es independiente de la dificultad condicional a la
inteligencia del alumno.


![](imagenes/manicule2.jpg) Repetir para $p(c|d,i)$.


Este último resultado explica cuáles son las independencias condicionales 
necesarias y suficientes para que una distribución se factorice según la gráfica
${\mathcal G}$. Ahora la pregunta que queremos resolver es:
¿hay otras independencias condicionales representadas en la gráfica? Buscamos
independencias condicionales **no locales**. La respuesta es sí, pero 
necesitamos conceptos adicionales a los que hemos visto hasta ahora 
(d-separación).

**Ejemplo.** Antes de continuar, podemos ver un ejemplo de independencias no
locales implicadas por la estructura gráfica. Si tenemos:

$$X \rightarrow Y \rightarrow Z \rightarrow W$$

es fácil ver que $X$ es independiente de $W$, dada $Y$, aunque esta 
independencia no es de la forma del resultado anterior, pues no estamos 
condicionando a los padres de ningún vértice.


### Flujo de información probabilística

En esta parte entenderemos primero como se comunica localmente la información 
probabilística a lo largo de los nodos cuando tenemos información acerca de 
alguno de ellos. Utilizaremos las factorizaciones implicadas por las gráficas
asociadas.

**¿En cuáles de los siguientes casos información sobre $X$ puede 
potencialmente cambiar la distribución sobre $Y$?**

1. **Razonamiento causal**: $X\rightarrow Z \rightarrow Y$

  * Si no tenemos información acerca de $Z$,  $X$ y $Y$ pueden estar asociadas.
  En este caso tenemos $p(x,y,z)=p(x)p(z|x)p(y|z)$, de forma que, haciendo un
  cálculo simple:
  $$p(x,y)= p(x) \sum_z p(y|z)p(z|x).$$ Como siempre es cierto que 
  $p(x,y)=p(x)p(y|x)$, tenemos
  $$p(y|x)=\sum_z p(y|z)p(z|x),$$ 
  donde vemos que cuando cambia $x$, puede cambiar también $p(y|x)$.
  
    En el ejemplo  $Edad \to Riesgo \to Accidente$, si alguien es más joven, 
    entonces es más probable que sea arriesgado, y esto hace más probable que 
    tenga un accidente.

  * Si sabemos el valor de $Z$, sin embargo, $X$ no nos da información de $Y$.
  En este caso tenemos $p(x,y)=p(x)p(z|x)p(y|z)$, como $z$ está fija
  tenemos que $p(x,y)=p(x)h(x)g(y)$, donde $h$ y $g$ son funciones fijas. Como 
  la conjunta se factoriza, $X$ y $Y$ son independientes dada $Z$.

    En nuestro ejemplo, si conociemos la aversión al riesgo, la edad del 
    asegurado no da información adicional acerca de la probabilidad de tener un
    accidente.

2. **Razonamiento evidencial**: $Y\rightarrow Z \rightarrow X.$ 
  
  * Si no sabemos acerca de $Z$, sí, por un argumento similar al del inciso
  anterior. Es un argumento de probabilidad inversa en
  $Edad \to Riesgo \to Accidente$. Si alguien tuvo un accidente, entonces
  es más probable que sea arriesgado, y por tanto es más probable que sea joven.

  * Si sabemos el valor que toma $Z$, entonces $X$ no puede influenciar a $Y$,
  por un argumento similar.

3. **Razonamiento de causa común**: $X\leftarrow Z \rightarrow Y$. 
  * Sí, pues en este caso: $$p(x,y,z)=p(z)p(y|z)p(x|z),$$
  Sumando sobre $z$ tenemos 
  $$p(x,y)=\sum_z p(y|z)p(x,z),$$
  así que $p(y|x)=\sum_z p(y|z)p(z|x).$ 
  
    En el ejemplo podríamos tener 
    $Tiempo manejando \leftarrow Edad \rightarrow Riesgo$. 
    Una persona que lleva mucha tiempo manejando es más probablemente mayor, lo 
    cual hace más probable que sea aversa al riesgo. 
  
  * No. Si conocemos el valor de $Z$, entonces $X$ y $Y$ son condicionalmente
  independientes, pues $p(x,y,z)=p(z)p(y|z)p(x|z)$, donde vemos que una vez que
  está dada la $z$ $x$ y $y$ no interactuán (están en factores distintos).

4. **Razonamiento intercausal**: Colisionador o estructura-v: $X\rightarrow Z \leftarrow Y$.
  * Si no tenemos información acerca de $Z$, __no__. Esto es porque tenemos
  $$p(x,y,z)=p(x)p(y)p(z|x,y),$$ de donde vemos que la conjunta de $X$ y $Y$
  satisface $p(x,y)=p(x)p(y)$ (sumando sobre $z$).
  
    Podríamos tener que 
    $Calidad de conductor \rightarrow Accidente \leftarrow Condicion de calle$. 
    Que alguien vaya por una calle en mal estado no cambia las probabilidades de 
    ser un mal conductor (en nuestro modelo).

  * Si sabemos el valor de $Z$, __sí__ conocimiento de $X$ puede cambiar
  probabilidades de $Y$. Como tenemos $$p(x,y,z)=p(x)p(y)p(z|x,y),$$
  el término (z está fijo) $p(z|x,y)=h(x,y)$ puede incluir interacciones entre 
  $x$ y $y$.
  
    En nuestro ejemplo, si sabemos que hubo un accidente, las condiciones de la
    calle si nos da información acerca de la calidad del conductor: por ejemplo, 
    si la calle está en buen estado, se hace más probable que se trate de un
    conductor malo.

<div class="clicker">
<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-25-1.png" width="672" />

Si sabemos que la clase es difícil y que el estudiante obtuvo 6, ¿como cambia
la probabilidad posterior de inteligencia alta?
a) sube
b) baja
c) no cambia
d) No se puede saber?

<div/>

### Caminos: pelota de Bayes
Un camino (no dirigido) esta activo si una pelota de Bayes que viaja a través del camino NO se topa con un símbolo de bloqueo (->|). En los esquemas los nodos sombreados indican que se tiene información de esas variables (ya no son aleatorios).

 <img src="imagenes/bayes_ball.png" width="600px" />
 <!-- ![](imagenes/bayes_ball.png) -->

En la figura de la izquierda (abajo) notamos que (siguiendo las reglas de la pelota de Bayes) la pelota no puede llegar del nodo $X$ al nodo $Y$, esto es no existe un camino activo que conecte $X$ y $Y$. Por otra parte, la figura del lado derecho muestra que al condicionar en el conjunto $\{X, W\}$ se _activa_ un camino que permite que la pelota de Bayes viaje de $X$ a $Y$.

 <img src="imagenes/bayes_ball_1.png" width="500px" />
<!-- ![](imagenes/bayes_ball_1.png) -->

Ahora veamos alegbráicamente que si condicionamos únicamente a $Z$, entonces $X \perp Y | Z$, esto es lo que vemos en la figura de la izquierda. Para esto escribamos la densidad conjunta:
$$p(z,a,y,x,b,c) = p(z)p(a|z)p(y|z)p(x|a)p(b|a,y)p(c|b)$$
Y la utilizamos para obtener la densidad marginal $p(x,y,z)$:
\begin{align}
  \nonumber
  p(x,y,z) &= \sum_a \sum_b \sum_c p(z,a,y,x,b,c)
  \nonumber
  &= \sum_a \sum_b \sum_c p(z)p(a|z)p(y|z)p(x|a)p(b|a,y)p(c|b)
  \nonumber
  &= \sum_a \sum_b p(z)p(a|z)p(y|z)p(x|a)p(b|a,y)\sum_c p(c|b)
  \nonumber
  &= \sum_a p(z)p(a|z)p(y|z)p(x|a) \sum_b p(b|a,y)
  \nonumber
  &= p(z)p(y|z) \sum_a p(a|z) p(x|a)
  \nonumber
  &= g(y,z)h(x,z)
\end{align}
donde $g(y,z) = p(z)p(y|z)$ y $h(y,z) = \sum_a p(a|z) p(x|a)$.
Por lo tanto $X \perp Y | Z$.


![](../../computo/imagenes/manicule2.jpg) Utilizando la gráfica del lado 
derecho demuestra algebráicamente que dados $Z,W$, $X$ no es necesariamente
independiente de $Y$.


## Flujo de probabilidad y d-Separación

De la discusión anterior, definimos **caminos activos** en una
gráfica los que, dada cierta evidencia $Z$, pueden potencialmente transmitir
información probabilística.

<div class="caja">
Sea $U$ un camino no dirigido en una gráfica ${\mathcal G}$. Decimos que el 
**camino es activo** dada evidencia $W$ si:

* Todos los colisionadores en el camino $U$ están o tienen un descendiente en 
$W$.

* Ningún otro vértice de el camino está en $W$.
</div>

<br/>

Un caso adicional interesante  es cuando los
descendiente de un colisionador activan un camino.

 <img src="imagenes/bayes_ball_2.png" width="250px" />
<!-- ![](imagenes/bayes_ball_2.png) -->


<div class="clicker">
<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-26-1.png" width="672" />

4. ¿Cuáles de los siguientes son caminos activos si observamos Calificación?  
a) $Coh \rightarrow Dif \rightarrow Calif \leftarrow Int \rightarrow GRE$  
b) $Int \rightarrow Cal \rightarrow Rec \leftarrow Tra \rightarrow Fel$
c) $Int \rightarrow GRE \rightarrow Tra \rightarrow Fel$
d) $Coh \rightarrow Dif \rightarrow Cal \leftarrow Int \rightarrow GRE \rightarrow Tra \leftarrow Rec$
</div>

</br>

Volviendo al ejemplo anterior

<img src="imagenes/bayes_ball_2.png" width="250px" />
<!-- ![](imagenes/bayes_ball_2.png) -->

**Algebráicamente:**
La distribución conjunta se factoriza como:
$$p(z,a,y,x,b,w)=p(z)p(a|z)p(y|z)p(x|a)p(b|a,y)p(w|b)$$
Por lo que la marginal $p(x,y,w,z)$ se obtiene de la siguiente manera:
  $$p(x,y,w,z) = \sum_a \sum_b p(z,a,y,x,b,w)$$

  $$= \sum_a \sum_b p(z)p(a|z)p(y|z)p(x|a)p(b|a,y)p(w|b)$$
  $$= p(z)p(y|z) \sum_a p(a|z)p(x|a) \sum_b p(b|a,y)p(w|b)$$

Notamos que $X$ y $Y$ interactúan a través de $A$ y $B$, por lo que no es posible encontrar dos funciones $g$, $h$, tales que $p(x,y,w,z) \propto g(x,w,z) h(y,w,z)$ y concluímos que $X \not \perp Y | W$.

<br/>
<div class="caja">
Sean $X$ y $Y$ vértices distintos y $W$ un conjunto de vértices que no contiene 
a $X$ o $Y$. Decimos que $X$ y $Y$ están **d-separados dada** $W$ si no existen
caminos activos dada $W$ entre $X$ y $Y$. 
</div>

<br/>

Es decir, la $d$-separación desaparece cuando hay información condicionada en
colisionadores o descendientes de colisionadores.

Este concepto de $d$-separación es precisamente el que funciona para encontrar
todas las independencias condicionales:

<div class="caja">
Supongamos que $p$ se factoriza sobre $\mathcal G$. Sean $A$, $B$ y $C$ conjuntos disjuntos de vértices de ${\mathcal G}$. Si $A$ y $B$ están $d$-separados por $C$
entonces $A\bot B | C$ bajo $p$ .
</div>

<br/>

#### Discusión

El resultado anterior no caracteriza la independencia condicional de una
distribución $p$ por una razón simple, que podemos entender como sigue: si agregamos
aristas a una gráfica ${\mathcal G}$ sobre la que se factoriza $p$, entonces
$p$ se factoriza también sobre la nueva gráfica ${\mathcal G}'$. Esto reduce
el número de independencias de $p$ que representa ${\mathcal G}$. 

Un ejemplo trivial son dos variables aleatorias independientes $X$ y $Y$ bajo 
$p$. $p$ claramente se factoriza en $X\to Y$, pero de esta gráfica no se puede
leer la independencia de $X$ y $Y$.

¿Qué es lo malo de esto?
En primer lugar,  si usamos ${\mathcal G}'$ en lugar de ${\mathcal G}$,  no
reducimos la complejidad del modelo al usar las independencias condicionales
gráficas que desaparecen al agregar aristas. En segundo lugar, la independencia
condicional no mostrada en la gráfica es más difícil de descubrir: tendríamos 
que ver directamente la conjunta particular de nuestro problema, en lugar de
leerla directamente de la gráfica.

Finalmente, estos argumentos también sugieren que quisiéramos encontrar mapeos
que no sólo sean *mínimos* (no se pueden eliminar aristas), sino también
*perfectos* en el sentido de que representan exactamente las independencias
condicionales. Veremos estos temas más adelante.

Algo que sí podemos establecer es cómo se comporta la familia de distribuciones
que se factorizan sobre una gráfica $\mathcal G$:

<br/>
<div class="caja">
Sea $\mathcal G$ una DAG. Si $X$ y $Y$ no están $d$-separadas en $\mathcal G$,
entonces existe **alguna** distribución $q$ (que se factoriza sobre 
${\mathcal G}$) tal que $X$ y $Y$ **no** son independientes bajo $q$.
</div>
<br/>

Para que existan independencias que no están asociadas a $d$-separación los
parámetros deben tomar valores paticulares. Este conjunto de valores es 
relativamente chico en el espacio de parámetros (son superficies), por lo tanto
podemos hacer más fuerte este resultado:

<br/>

<div class="caja">
Sea $\mathcal G$ una DAG. Excepto en un conjunto de "medida cero" en el espacio
de distribuciones $M({\mathcal G})$ que se factorizan sobre $\mathcal G$, 
tenemos que $d$-separación es equivalente a independencia condicional. Es decir, 
$d$-separación caracteriza precisamente las independencias condicionales de cada
$p\in M(\mathcal G)$, excepto para un conjunto relativamente chico de $p \in M({\mathcal G})$ .
</div>


### Equivalencia Markoviana

En esta parte trataremos el problema de la unicidad de la representación gráfica
dada un conjunto de independencias condicionales. La respuesta corta es que
las representaciones no son únicas, pues algunas flechas pueden
reorientarse sin que haya cambios en términos de la conjunta representada. 

<div class="caja">
Decimos que dos  gráficas  ${\mathcal G}_1$ y ${\mathcal G}_2$ son **Markov
equivalentes** cuando el conjunto de independencias implicadas de ambas es el
mismo. Otra manera de decir esto, es que ambas gráficas tienen exactamente la
misma estructura de $d-$separación.
</div>

La equivalencia Markoviana limita nuestra capacidad de inferir la dirección de
las flechas únicamente de las probabilidades, esto implica que dos gráficas
Markov equivalentes no se pueden distinguir usando solamente una base de datos.
Por ejemplo, en la siguiente gráfica, cambiar la dirección del arco que une 
$X_1$ y $X_2$ genera una gráfica Markov equivalente, esto es, la dirección del
arco que une a $X_1$ y $X_2$ no se puede inferir de información probabilística.


```r
library(igraph)
gr <- graph( c(1,2,1,3,2,4,3,4,4,5)  )
plot(gr, vertex.label=c('X1','X2','X3','X4','X5'), 
  layout = matrix(c(-0.3,0,0,-0.3,0, 0.3,0.3,0,0.6,0), byrow = TRUE, ncol = 2),
  vertex.size = 20, vertex.color = 'salmon', vertex.label.cex = 1.2,
  vertex.label.color = 'gray40', vertex.frame.color = NA, asp = 0.5, 
  edge.arrow.size = 1)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-27-1.png" width="672" />


Decimos que un colisionador *no está protegido* cuando las variables que apuntan
a la colisión no tienen vértice entre ellas. Definimos adicionalmente el *esqueleto*
de una GAD como la versión no dirigida de $\mathcal G$. El siguiente resultado establece
que la distribución sólo puede determinar la dirección de las flechas
en presencia de un colisionador no protegido:


<div class="caja">
Dos gráficas ${\mathcal G}_1$ y ${\mathcal G}_2$ son Markov equivalentes si y sólo si

* Sus esqueletos son iguales y  

* ${\mathcal G}_1$ y ${\mathcal G}_2$ tienen los mismos colisionadores no protegidos.
</div>

<br/>

Las equivalencias que señala este teorema son importantes. Por ejemplo,
las gráficas $X\rightarrow Y \rightarrow Z$ y $X\leftarrow Y \leftarrow Z$ son
equivalentes, lo que implica que representan a las mismas distribuciones condicionales.
Solamente usando datos (o el modelo), **no podemos distinguir estas dos estructuras**, sin embargo,
puede ser que tengamos información adicional para preferir una sobre otra (por ejemplo,
si es una serie de tiempo).

Una estructura que sí podemos identificar de manera dirigida es el colisionador. El resto
de las direcciones pueden establecerse por facilidad de interpretación o razones causales.

Regresando a la gráfica anterior, notamos que al revertir el sentido del arco que une a $X_1$ con $X_2$ no se crea ni se destruye ningun colisionador y por tanto la gráfica resultante del cambio de sentido es efectivamente Markov equivalente. Consideremos ahora los arcos dirigidos que unen a $X_2$ con $X_4$ y a $X_4$ con $X_5$, notamos que no hay manera de revertir la dirección de estos arcos sin crear un nuevo colisionador, esto implica que algunas funciones de probabilidad $p$ restringen la dirección de éstas flechas en la gráfica.

En el siguiente ejemplo, mostramos la clase de equivalencia
de una red de ejemplo. Ahí vemos cuáles son las aristas que se pueden orientar
de distinta manera, y cuáles pertenecen a colisionadores en los cuales las direcciones están identificadas:


```r
library(bnlearn)
grafica.1 <- gs(insurance[c('Age', 'RiskAversion', 'Accident', 'DrivQuality',
  'Antilock', 'VehicleYear')], alpha = 0.01)
graphviz.plot(grafica.1)
```

<img src="23_redes_bayesianas_files/figure-html/unnamed-chunk-28-1.png" width="432" />

<div class = "clicker">

<img src="imagenes/markov_equivalencia.png" width="600px"/>

¿Cuáles de las gráficas anteriores son Markov equivalentes?

a) 1 y 2
b) 1 y 3
c) 2 y 4
d) 2 y 4
e) Ninguna

</div>

### Resumen
* Dada una gráfica $G$ podemos encontrar las as independencias condicionales que
establece, $I(G)$.  
* Dada una distribución $p$ podemos encontrar las independencias que implica, 
$I(p)$ (en teoría).
* Las independencias condicionales definidas por la red bayesiana son un 
subconjunto de las independencias en $p$, esto es $I(G) \subset I(p)$.  
* Equivalencia Markoviana se expresa como: $I(G) = I(G')$.

### Ejemlos

* [Repositorio de redes](http://www.cs.huji.ac.il/~galel/Repository/)

* [Universidad de Utrecht](http://bndg.cs.aau.dk/html/bayesian_networks.html)

* [Genie y Smile](https://dslpitt.org/genie/index.php/network-repository)

* [Librería de Norsys (Netica)](http://www.norsys.com/netlibrary/index.htm)

* [Casos de Hugin](http://www.hugin.com/case-stories)

