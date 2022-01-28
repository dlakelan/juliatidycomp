using CSV, DataFrames, StatsPlots, DataFramesMeta

dat = CSV.read("data/olympicsdata.csv",DataFrame)

datst = @orderby(stack(dat,5:8),:Year)

datst.mpersec = datst.distance ./ datst.value

plots = []
for sex in ("F","M")
    for dist in unique(datst.distance)
        dfsub = filter(row -> row.Sex == sex && row.distance == dist,datst)
        push!(plots, plot(dfsub.Year,dfsub.mpersec,group=dfsub.variable,xlim=(2012,2021),ylim=(7,11),
        linewidth=2,legend=false, title = "$dist m Sex $sex"))
    end
end
pl = plot(plots...,layout=(2,3),size=(600,900))

savefig(pl,"Olympics.png")

