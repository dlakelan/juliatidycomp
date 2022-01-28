using CSV,DataFrames,StatsPlots,DataFramesMeta,DataStructures,Distributions
using Pkg
Pkg.activate(".")

mutable struct Particle
    n::Int64
    x::Float64
    y::Float64
    E::Float64
end

function inregion(x,y)
    return x^2+y^2 < 1 || (abs(x) < 0.5 && y > -2.0 && y < 0.0);
end


function simulate(N)
    active = Set{Particle}()
    sizehint!(active,N)
    for i in 1:N
        union!(active,(Particle(i,rand(Normal(0,0.1)),rand(Normal(0,0.1)),rand(Exponential(1.0))),))
    end 
    frozen = Set{Particle}()
    sizehint!(frozen,N)
    while ! isempty(active)
        for i in active
            i.x = i.x + rand(Normal(0,0.1))
            i.y = i.y + rand(Normal(0,0.1))
            if rand() < 0.5
                i.E = i.E * 0.9 ## 50% chance to lose 10% to radiation
            else
                # 50% chance to radiate energy to another active particle
                # select a random active particle and give it 10% of the energy via radiation
                ee = i.E * 0.1
                i.E *= 0.9
                p = rand(active)
                p.E = p.E + ee
            end
            if !inregion(i.x,i.y)
                union!(frozen,(i,))
            end
        end
        active = setdiff(active,frozen)
    end
    return frozen
end




parts = @time simulate(1_000_000)


colors = cgrad(:thermal)
p1 = histogram([log(part.E) for part in parts],label=false,title="Log(E) at exit");
p2 = scatter([(p.x,p.y) for p in parts],alpha=0.05,pointsize=2,marker_z=[log(p.E) for p in parts],
    color=colors,label=false,title="Final Position with color from log(E)");

plot(p1,p2,layout=(2,1),size=(400,800))
println("The 99.95% quantile of energy was: $(quantile([p.E for p in parts],.9995))")


