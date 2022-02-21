library(dplyr)
library(gridExtra)

inregion = function(x,y) {
return ((x^2+y^2 < 1) | (abs(x) < 0.5 & y > -2.0 & y < 0.0))
} 


N = 100000

# Initialize the dataframe
partdf = data.frame(active = rep(T,N),
                      x = rnorm(n=N, mean = 0, sd = 0.1),
                      y = rnorm(n=N, mean = 0, sd = 0.1),
                      E  = rexp(n=N, rate = 1.0))
  
n_active = sum(partdf$active)
while (n_active > 0) {
  print(n_active)
  # Move the active particles
  partdf = partdf %>% 
    mutate(
      x = x + active*rnorm(n=N, mean=0, sd=0.1),
      y = y + active*rnorm(n=N, mean=0, sd=0.1),
    )
  
  # For each particle: if this particle is selected to lose energy,
  # which active particle will we transfer the energy to?
  transfer_to = sample(which(partdf$active), N, replace = T)
  
  # Transfer energy from some particles to others.
  ok_transfer = partdf$active & (runif(n=N) < 0.5)
  e_to_transfer = 0.1*partdf$E[ok_transfer]
  partdf$E[transfer_to[ok_transfer]] = partdf$E[transfer_to[ok_transfer]] + e_to_transfer
  partdf$E[ok_transfer] = partdf$E[ok_transfer] - e_to_transfer
  
  partdf$active[!inregion(partdf$x, partdf$y)] = F
  n_active = sum(partdf$active)
}

p1 = ggplot(partdf, aes(x=x,y=y)) + geom_point()
p2 = ggplot(partdf) + geom_histogram(aes(x = E )) + scale_x_log10()

grid.arrange(p1, p2, nrow = 1)

print(paste("99.95 percentile of energy is:", quantile(partdf$E,0.9995)))
