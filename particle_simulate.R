library(dplyr)
library(ggplot2)
library(gridExtra)

inregion = function(x,y) {
return ((x^2+y^2 < 1) | (abs(x) < 0.5 & y > -2.0 & y < 0.0))
} 


N = 1000000

# Initialize the dataframe
partdf = data.frame(active = rep(T,N),
                      x = rnorm(n=N, mean = 0, sd = 0.1),
                      y = rnorm(n=N, mean = 0, sd = 0.1),
                      E  = rexp(n=N, rate = 1.0))
  
n_active = sum(partdf$active)
n_count = 0

while (n_active > 0) {
  print(paste(n_active, sum(partdf$E)))
  # print(n_active)
  # Move the active particles
  partdf = partdf %>% 
    mutate(
      x = x + active*rnorm(n=N, mean=0, sd=0.1),
      y = y + active*rnorm(n=N, mean=0, sd=0.1),
    )
  
  samp1 = sample(which(partdf$active)) # index of active particles in random order
  samp2 = sample(which(partdf$active))
  rand = runif(n=length(samp1)) 
  radiate = samp1[rand >= 0.5]  # some particles lose energy by radiation.
  partdf$E[radiate] = 0.9*partdf$E
  
  transfer_from = samp1[rand < 0.5] # some particles transfer energy to others
  transfer_to = samp2[rand < 0.5]
  e_to_transfer = 0.1*partdf$E[transfer_from]
  partdf$E[transfer_to] = partdf$E[transfer_to] + e_to_transfer
  partdf$E[transfer_from] = partdf$E[transfer_from] - e_to_transfer
  
  partdf$active[!inregion(partdf$x, partdf$y)] = F
  n_active = sum(partdf$active)
}

p1 = ggplot(partdf, aes(x=x,y=y)) + geom_point(aes(color=E))
p2 = ggplot(partdf) + geom_histogram(aes(x = E )) + scale_x_log10()

grid.arrange(p1, p2, nrow = 1)

print(paste("Total energy is", sum(partdf$E)))
print(paste("99.95 percentile of energy is:", quantile(partdf$E,0.9995)))
