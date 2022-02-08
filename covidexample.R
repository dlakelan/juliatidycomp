library(dplyr)
library(maps)
library(usmap)
library(ggplot2)

download_files = function() {
  baseurl = "https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/asrh/cc-est2019-agesex-XX.csv"

  dat_list = NULL
  Out = NULL
  j = 1
  for (i in 1:56){
    print(i)
    url = gsub('XX',sprintf('%02d',i),baseurl)
    
    dat = tryCatch(
      read.csv(url, header = T, as.is = T),
      error= function(cond) {return(NULL)},
      finally = print("Done")
      )
    if (!is.null(dat)){
      dat_list[[j]] = dat
      j = j+1
    }
  }
  
  Out = dat_list[[1]]
  for (i in 2:length(dat_list)) {
    Out = bind_rows(Out, dat_list[[i]])
  }
  return(Out)
}   
    
demog_dat = download_files()
# Just keep 2019 (which is YEAR == 12)
demog_dat = demog_dat %>% filter(YEAR == 12)
demog_dat$YEAR == 2019
demog_dat = demog_dat %>% mutate(fips = 1000*STATE + COUNTY)


covid_dat = read.csv("https://data.cdc.gov/api/views/k8wy-p9cg/rows.csv",
                     header=T, as.is=T)
covid_dat = covid_dat %>% 
  mutate(fips = 1000*FIPS.State+FIPS.County) %>%
  filter(Indicator %in% 'Distribution of COVID-19 deaths (%)')
  
cov_dat_2 = read.csv('./data/Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv', 
                     header = T, as.is=T)
cov_dat_2 = cov_dat_2 %>% mutate(fips = FIPS.County.Code)

dat = left_join(demog_dat, cov_dat_2, by = 'fips' ) 
dat = dat %>% mutate(
  u5frac = UNDER5_TOT / POPESTIMATE,
  age513frac = AGE513_TOT / POPESTIMATE, 
  age1519frac = AGE1519_TOT / POPESTIMATE,
  age2024frac = AGE2024_TOT / POPESTIMATE,
  age2529frac = AGE2529_TOT / POPESTIMATE,
  age3034frac = AGE3034_TOT / POPESTIMATE,
  age3539frac = AGE3539_TOT / POPESTIMATE,
  age4044frac = AGE4044_TOT / POPESTIMATE,
  age4549frac = AGE4549_TOT / POPESTIMATE,
  age5054frac = AGE5054_TOT / POPESTIMATE,
  age5559frac = AGE5559_TOT / POPESTIMATE,
  age6064frac = AGE6064_TOT / POPESTIMATE,
  age6569frac = AGE6569_TOT / POPESTIMATE,
  age7074frac = AGE7074_TOT / POPESTIMATE,
  age7579frac = AGE7579_TOT / POPESTIMATE,
  age8084frac = AGE8084_TOT / POPESTIMATE,
  age85plusfrac = AGE85PLUS_TOT / POPESTIMATE,
  totdeathfrac = Deaths.from.All.Causes / POPESTIMATE,
  covdeathfrac = Deaths.involving.COVID.19 / POPESTIMATE,
  covdeathpct = 100*covdeathfrac
)

# One county is an outlier, with a COVID death rate of 3.8% of the population, almost double the 
# second-highest county (1.98%). Next after that are 1.8%, 1.7%, 1.2%.  Those four counties over 1.2%
# really throw off the color scale of the map. Create another variable that chops those down to
# lower values.
dat$covdeathpcttrunc = ifelse(dat$covdeathpct > 1.2, 1.3, dat$covdeathpct)


plot_usmap(data = dat, values = 'covdeathpcttrunc', regions='counties') +  
  #scale_fill_continuous(low = 'white', high = 'red', name = "Pct of pop. killed by COVID", label = scales::comma)
  scale_colour_gradient(
    low = "white",
    high = "red",
    space = "Lab",
    na.value = "grey50",
    guide = "colourbar",
    aesthetics = "fill"
  )



plot_usmap(data = dat, values = 'COVID.19.Deaths', regions='counties') +  
  scale_fill_continuous(low = 'white', high = 'red', name = "Number killed by COVID", label = scales::comma)







