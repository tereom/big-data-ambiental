# Función para analizar volados con Bayes

bayes_moneda <- function(heads, tails, alpha=2, beta=2, ax=None)
{
    x <- seq(from = 0, to = 1,  length.out = 1000)
    y <- dbeta(x, heads+alpha, tails+beta)
    
    plot(x, y, type = "l", main = paste("Posterior after ", heads, 
                                        "heads, and ", tails, " tails"),
         xlab = expression(theta), 
         ylab = expression(paste("P(", theta, "|D)")))
}

bayes_moneda(50, 25)


           
           