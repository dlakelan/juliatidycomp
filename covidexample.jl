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
end

if !isfile("data/covid-nodownload")
    downloadfiles()
end

function readallcsv(files)
    dfall = DataFrame()
    for f in files
        df = CSV.read(f,DataFrame)
        dfall = [dfall ; df]
    end
    dfall
end

dfall = @time readallcsv(filter(x -> occursin(r"cc-est",x),readdir("data",join=true)))
## year == 12 means 7/1/2019 estimate according to census data key
dfall = dfall[dfall.YEAR .== 12,:]
dfall.YEAR .= 2019;
covd = CSV.read("data/federalCOVIDdeaths.csv",DataFrame)
covd = covd[occursin.(r"Distribution of COVID",covd.Indicator),:]

## Task: join dfall and covd, calculate a new column deathfrac = deaths/population, 
## and also for each age group the fraction of the total population in that age group

dfj = leftjoin(dfall,covd, on = [:STATE => Symbol("FIPS State"), :COUNTY => Symbol("FIPS County")])

## create the new columns that are fractional values:

ourdf = @select(dfj,:STNAME,:CTYNAME,:YEAR,:POPESTIMATE,
    :u5frac = :UNDER5_TOT ./ :POPESTIMATE,
    :age513frac = :AGE513_TOT ./ :POPESTIMATE, 
    :age1519frac = :AGE1519_TOT ./ :POPESTIMATE,
    :age2024frac = :AGE2024_TOT ./ :POPESTIMATE,
    :age2529frac = :AGE2529_TOT ./ :POPESTIMATE,
    :age3034frac = :AGE3034_TOT ./ :POPESTIMATE,
    :age3539frac = :AGE3539_TOT ./ :POPESTIMATE,
    :age4044frac = :AGE4044_TOT ./ :POPESTIMATE,
    :age4549frac = :AGE4549_TOT ./ :POPESTIMATE,
    :age5054frac = :AGE5054_TOT ./ :POPESTIMATE,
    :age5559frac = :AGE5559_TOT ./ :POPESTIMATE,
    :age6064frac = :AGE6064_TOT ./ :POPESTIMATE,
    :age6569frac = :AGE6569_TOT ./ :POPESTIMATE,
    :age7074frac = :AGE7074_TOT ./ :POPESTIMATE,
    :age7579frac = :AGE7579_TOT ./ :POPESTIMATE,
    :age8084frac = :AGE8084_TOT ./ :POPESTIMATE,
    :age85plusfrac = :AGE85PLUS_TOT ./ :POPESTIMATE,
    :totdeathfrac = $"Total deaths" ./ :POPESTIMATE,
    :covdeathfrac = $"COVID-19 Deaths" ./ :POPESTIMATE)

## run a regression on each state, with covid death fraction ~ each of the age fractions

function regressdata(df)
    outdf = DataFrame(ST=[], con = [], #=
     u5frac=[],age513frac=[],
    age1519frac =[], age2024frac =[], age2529frac = [],
    age3034frac = [], age3539frac = [], age4044frac = [],
    age4549frac = [], age5054frac = [], age5559frac = [],
    age6064frac = [], age6569frac = [],=# age7074frac = [],
    age7579frac = [], age8084frac = [], age85plusfrac = [])
    for state in unique(df.STNAME)
        dfstate = df[df.STNAME .== state,:]
        model = lm(@formula(log(covdeathfrac) ~  age7074frac + age7579frac + age8084frac + age85plusfrac),dfstate)
        #@show coef(model)
        push!(outdf,[state ; coef(model)])
    end
    return outdf
end
regres = regressdata(ourdf)

@df regres plot(:ST,:con)

#:age8084frac)

