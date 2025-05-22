using DataStructures, Distributions, Random, LinearAlgebra

const POSITION_COORDINATES = 2

function squash_scratch_space(scratch_matrix::Matrix{T}, remaining_entries)::Matrix{T} where T
    @boundscheck remaining_entries > 0

    # If we have fewer active particles than we did last iteration, this will take a contiguous
    # subset of the underlying memory from the start of the allocation region, then reinterpret
    # this so we maintain the same number of columns.
    scratch_matrix = @views reshape(
        scratch_matrix[1:(remaining_entries * POSITION_COORDINATES)],
        :,
        POSITION_COORDINATES
    )
    # This doesn't matter to us since we are about to completely clobber the data anyway, but
    # this will result in data sliding across consecutive columns. This ensures we conform to
    # julia's column-major encoding: https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-column-major
    @assert size(scratch_matrix) == (remaining_entries, POSITION_COORDINATES)

    scratch_matrix
end


# This indirection appears necessary in order to get explicit type parameters that aren't inferred
# away: https://docs.julialang.org/en/v1/manual/constructors/#Case-Study:-Rational
struct uninit_array_alloc{T}
end
function uninit_array_alloc{T}(len) where {T}
    local ret = Array{T}(undef, len)
    resize!(ret, 0)
    ret
end

function simulate(N)
    Random.seed!(111)

    local positions = rand(Normal(0, 0.1), N, POSITION_COORDINATES)
    local energies = rand(Exponential(1.0), N)
    # very surprised there's no b-tree for sparse orderable inputs!
    local active = BitSet(1:N)

    local cur_indices = uninit_array_alloc{UInt}(N)

    local radiated_energy = uninit_array_alloc{Float64}(N)
    local cur_energies = uninit_array_alloc{Float64}(N)

    local radiation_updates::Array{Float64} = zeros(N)

    local interaction_targets = uninit_array_alloc{UInt}(N)

    # This is our scratch space to cover the current position indices.
    local cur_positions = Matrix{Float64}(undef, N, POSITION_COORDINATES)
    # This is also scratch space, but for random position perturbations as opposed to the
    # position array.
    local rand_offsets = Matrix{Float64}(undef, N, POSITION_COORDINATES)

    while ! isempty(active)
        resize!(cur_indices, 0)
        for i in active
            push!(cur_indices, i)
        end

        # Squash our scratch spaces down to size.
        cur_positions = squash_scratch_space(cur_positions, length(cur_indices))
        rand_offsets = squash_scratch_space(rand_offsets, length(cur_indices))

        # Copy the possibly-noncontiguous position data from the main array into our scratch space.
        cur_positions .= positions[cur_indices,:]

        # Perturb x and y positions of all remaining points.
        rand!(Normal(0, 0.1), rand_offsets)
        cur_positions .+= rand_offsets

        # Radiation targets receive 10% of current energy.
        resize!(radiated_energy, length(cur_indices))
        resize!(cur_energies, length(cur_indices))
        # Copy over non-contiguous energies from persistent memory.
        cur_energies .= energies[cur_indices]
        # In case radiation occurs, record in a separate scratch space for the next step.
        radiated_energy .= cur_energies .* 0.1
        # Energy decreases by 10% upon each step.
        energies[cur_indices] = cur_energies .* 0.9

        # Calculate any particle interactions from this iteration.
        local interacts_with = bitrand(length(cur_indices))
        local radiated_interactions = @view radiated_energy[interacts_with]
        resize!(interaction_targets, length(radiated_interactions))
        rand!(interaction_targets, cur_indices)

        # Calculate x^2 + y^2 by squaring the euclidean norm.
        local xy = norm.(eachrow(cur_positions)) .^ 2

        local val_x = @view cur_positions[:,1]
        local val_y = @view cur_positions[:,2]

        local xy_valid = xy .< 1
        local x_valid = abs.(val_x) .< 0.5
        local y_valid = -2.0 .< val_y .< 0.0
        # Calculate region boundary check in a vectorized way.
        local in_region = xy_valid .| (x_valid .& y_valid)

        # Write our modified position data back to the main array.
        positions[cur_indices,:] = cur_positions

        # Update active particles for next iteration.
        local newly_frozen = cur_indices[.~in_region]
        setdiff!(active, newly_frozen)

        # Calculate cumulative radiation interaction updates.
        radiation_updates .= 0
        # Coalesce all energy updates over potentially-duplicated targets:
        for (new_energy, cur_target) in zip(radiated_interactions, interaction_targets)
            # get!(radiation_updates, cur_target, 0.0)
            radiation_updates[cur_target] += new_energy
        end

        energies .+= radiation_updates
    end

    (positions, energies)
end

function execute()
    local positions, energies = @time simulate(1_000_000)
    local log_e = log.(energies)

    local colors = cgrad(:thermal)
    local p1 = histogram(log_e, label=false, title="Log(E) at exit")
    local p2 = scatter(
        # NB: for some reason eachrow() alone or even collecting it causes a hang.
        # collect(eachrow(positions)),
        [(x, y) for (x,y) in eachrow(positions)],
        marker_z=log_e,
        alpha=0.05, pointsize=2, color=colors, label=false,
        title="Final Position with color from log(E)",
    )

    plot(
        p1, p2,
        layout=(2,1),
        size=(400,800),
    )
    savefig("particles.png")
    println("The 99.95% quantile of energy was: $(quantile(energies, .9995))")
end

if !isinteractive()
    using StatsPlots
    execute()
end
