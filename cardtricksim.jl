using Random, StatsBase

suit = [collect(1:9); [1, 1, 1, 1]]
deck = repeat(suit,4)

function walk(deck,start)
    while start + deck[start] <= length(deck)
        start = start + deck[start]
    end
    return start
end

function couples!(deck)
    shuffle!(deck)
    starts = sample(1:5,2; replace=false)
    end1 = walk(deck,starts[1])
    end2 = walk(deck,starts[2])
    return end1 == end2
end


function sim(N,deck)
    successes = 0.0
    for i in 1:N
        successes += couples!(deck)
    end
    rate = successes / N
    v = rate * (1-rate)*N
    s = sqrt(v)
    se = s/N
    return (lb = rate - 1.96*se, p = rate, ub=rate+1.96*se)
end

sim(10,deck)
@time sim(1_000_000,deck)


