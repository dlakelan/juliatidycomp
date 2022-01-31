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
## year == 12 means 7/1/2019 estimate according to census data key
dfall = dfall[dfall.YEAR .== 12,:]
dfall.YEAR .= 2019;
covd = CSV.read("data/federalCOVIDdeaths.csv",DataFrame)
covd = covd[occursin.(r"Distribution of COVID",covd.Indicator),:]

covdbyage = CSV.read("data/federalcoviddeathsbycountyage.csv",DataFrame)

## Task: join dfall and covd, calculate a new column deathfrac = deaths/population, 
## and also for each age group the fraction of the total population in that age group

dfj = leftjoin(dfall,covd, on = [:STATE => Symbol("FIPS State"), :COUNTY => Symbol("FIPS County")])

