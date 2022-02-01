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
  

dat = left_join(demog_dat, covid_dat, by = 'fips' ) 
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
  totdeathfrac = Total.deaths / POPESTIMATE,
  covdeathfrac = COVID.19.Deaths / POPESTIMATE,
  covdeathpct = 100*covdeathfrac
)

plot_usmap(data = dat, values = 'covdeathpct', regions='counties') +  
  scale_fill_continuous(low = 'white', high = 'red', name = "Pct of pop. killed by COVID", label = scales::comma)


plot_usmap(data = dat, values = 'COVID.19.Deaths', regions='counties') +  
  scale_fill_continuous(low = 'white', high = 'red', name = "Number killed by COVID", label = scales::comma)







