
require(dplyr)
require(tidyr)
require(ggplot2)

dat_orig = read.csv("data/olympicsdata.csv")

dat = pivot_longer(dat_orig, c("place_1", "place_2", "place_3", "place_4"),
names_to = "place", names_prefix = "place_")
dat$"m_per_sec" = dat$distance/dat$value

ggplot(dat, aes(x = Year, y = m_per_sec)) +
geom_point(aes(color = factor(place), shape = factor(Event))) +
geom_line(aes(color = factor(place))) +
facet_grid(Sex ~ distance)
