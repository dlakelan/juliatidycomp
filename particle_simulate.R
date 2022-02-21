library(dplyr)
library(ggplot2)
library(gridExtra)

inregion = function(x,y) {
return ((x^2+y^2 < 1) | (abs(x) < 0.5 & y > -2.0 & y < 0.0))
} 


N = 10000

# Initialize the dataframe
partdf = data.frame(active = rep(T,N),
                      x = rnorm(n=N, mean = 0, sd = 0.1),
                      y = rnorm(n=N, mean = 0, sd = 0.1),
                      E  = rexp(n=N, rate = 1.0))
  
n_active = sum(partdf$active)
n_count = 0

while (n_active > 0) {
  print(paste(n_active, sum(partdf$E)))
  for (i in 1:NROW(partdf)){
    if (!partdf[i,"active"])
      next;
    partdf[i,"x"] = partdf[i,"x"] + rnorm(1,0,0.1)
    partdf[i,"y"] = partdf[i,"y"] + rnorm(1,0,0.1)    
    if(runif(1) < 0.5){
      partdf[i,"E"] = partdf[i,"E"]*0.9
    }else{
      ee = partdf[i,"E"] *0.1
      p = sample(which(partdf$active),1)
      partdf[p,"E"] = partdf[p,"E"] + ee
      partdf[i,"E"] = partdf[i,"E"] * 0.9
    }
    if (!inregion(partdf[i,"x"],partdf[i,"y"]))
      partdf[i,"active"] = FALSE
  }
  n_active = sum(partdf[,"active"])
}

png("particle_simulate_R.png",width=600,height=1200)
p1 = ggplot(partdf, aes(x=x,y=y)) + geom_point(aes(color=E))
p2 = ggplot(partdf) + geom_histogram(aes(x = log(E)),bins=1000)

grid.arrange(p1, p2, nrow = 2)
dev.off()

print(paste("Total energy is", sum(partdf$E)))
print(paste("99.95 percentile of energy is:", quantile(partdf$E,0.9995)))
