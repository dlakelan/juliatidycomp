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


function sim!(N,deck)
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

sim!(10,deck)
@time sim!(1_000_000,deck)

@profview sim!(1_000_000,deck)


# we can eke out a few percent from cutting the loop short as soon as the 
# two positions are the same ... but it doesn't help much. Almost all the time is spent
# in the shuffle! function, and generating random numbers
function sim2(N)
    deck = repeat([collect(1:9); [1,1,1,1]],4)
    successes = 0.0
    l = length(deck)
    for i in 1:N
        shuffle!(deck)
        pos = sample(1:5,2)
        end1 = false; end2=false;
        while pos[1] != pos[2] && (!end1 || !end2)
            if pos[1] + deck[pos[1]] <= l 
                pos[1] += deck[pos[1]]
            else
               end1 = true
            end
            if pos[2] + deck[pos[2]] <= l
                pos[2] += deck[pos[2]]
            else
                end2 = true
            end
        end
        if pos[1] == pos[2]
            successes += 1.0
        end
    end
    rate = successes / N
    v = rate * (1.0-rate)*N
    s = sqrt(v)
    se = s/N
    return (lb = rate - 1.96*se, p = rate, ub=rate+1.96*se)
end

sim2(10)
@time sim2(10_000_000)

@profview sim2(1_000_000)

