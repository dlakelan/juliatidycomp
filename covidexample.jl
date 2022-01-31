using CSV,DataFrames,DataFramesMeta,GLM,Printf,StatsPlots

function downloadfiles()
    baseurl = Printf.format"https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/asrh/cc-est2019-agesex-%02d.csv"

    for i in 1:56
        url = Printf.format(baseurl,i)
        try 
            download(url,Printf.format(Printf.format"data/cc-est2019-agesex-%02d.csv",i))
        catch e
            println(e)
        end
    end

    download("https://data.cdc.gov/api/views/k8wy-p9cg/rows.csv?accessType=DOWNLOAD","data/federalCOVIDdeaths.csv")
    download("https://data.cdc.gov/api/views/ypxr-mz8e/rows.csv?accessType=DOWNLOAD","data/federalcoviddeathsbycountyage.csv")
    touch("data/covid-nodownload") ## prevent re-download until this file is removed
end

if !isfile("data/covid-nodownload")
    downloadfiles()
end

function readallcountycsv(files)
    dfall = DataFrame()
    for f in files
        df = CSV.read(f,DataFrame)
        dfall = [dfall ; df]
    end
    dfall
end

dfall = @time readallcountycsv(filter(x -> occursin(r"cc-est",x),readdir("data",join=true)))
## year == 12 means 7/1/2019 estimate according to census data key, this is the last available one
dfall = dfall[dfall.YEAR .== 12,:]
dfall.YEAR .= 2019;
covd = CSV.read("data/federalCOVIDdeaths.csv",DataFrame)
covd = covd[occursin.(r"Distribution of COVID",covd.Indicator),:]

covdbyage = CSV.read("data/federalcoviddeathsbycountyage.csv",DataFrame)

## Task: join dfall and covd, calculate a new column deathfrac = deaths/population, 
## and also for each age group the fraction of the total population in that age group

dfj = leftjoin(dfall,covd, on = [:STATE => Symbol("FIPS State"), :COUNTY => Symbol("FIPS County")])


print(filter(x->occursin("_TOT",x),names(dfall)))) # for copy and paste
print(unique(covdbyage[:,"Age Group"]))

# this table defines which age groups in the covdbyage correspond to which member groups in dfall, we can then join
# and aggregate by agegroup1 to get the sums
jointable = DataFrame(agegroup1 = 
["0-17 years", "0-17 years", "0-17 years", 
"18-29 years","18-29 years",
"30-39 years", "30-39 years",
"40-49 years","40-49 years",
"50-64 years","50-64 years","50-64 years",
"65-74 years","65-74 years",
"75-84 years", "75-84 years", 
"85 years and over"]

agegroup2 = ["UNDER5_TOT", "AGE513_TOT", "AGE1417_TOT", 
"AGE1824_TOT", "AGE2529_TOT", 
"AGE3034_TOT", "AGE3539_TOT", 
"AGE4044_TOT", "AGE4549_TOT", 
"AGE5054_TOT", "AGE5559_TOT", "AGE6064_TOT",
"AGE6569_TOT", "AGE7074_TOT",
"AGE7579_TOT", "AGE8084_TOT", 
"AGE85PLUS_TOT"])


