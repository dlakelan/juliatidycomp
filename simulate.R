library(dplyr, warn.conflicts = FALSE)
library(ggplot2)
## library(wordspace)

simulate <- function (n) {
    df <- data.frame(
        x = rnorm(n, sd = 0.1),
        y = rnorm(n, sd = 0.1),
        E = rexp(n)
    )

    ## When a particle is frozen, we retrieve its final x and y position.
    df_frozen <- data.frame(
        x = double(),
        y = double(),
        E = double()
    )

    while (nrow(df) > 0) {
        print("len")
        print(nrow(df))
        print("cur_e")
        print(df$E)
        print("pos")
        print(df[c("x", "y")])
        df <- df |>
            mutate(
                x = x + rnorm(n(), sd = 0.1),
                y = y + rnorm(n(), sd = 0.1),
                ## If energy is transferred, it is 10% of the current value.
                ee = E * 0.1,
                ## Energy always reduces by 10% each iteration, transfer or not.
                E = E * 0.9
            )
        print("p2")
        print(df[c("x", "y")])

        ## Determine the cumulative energy transferred to any other particles.
        e_updates <- df |>
            select(ee) |>
            ## 50% chance to radiate energy to another active particle.
            filter(sample(c(T, F), n(), replace = TRUE)) |>
            ## Sample all the other active particles, one for each radiating one.
            mutate(p = sample(1:nrow(df), n(), replace = TRUE)) |>
            ## Sum the ee results over all duplicates of the target particle, producing a table with
            ## exactly one entry for each distinct target.
            summarize(sum_ee = sum(ee), .by = p)
        print("ee")
        print(e_updates)
        df <- df |>
            select(!ee) |>
            ## dplyr makes joining against row number more efficient than any manual iteration.
            mutate(p = row_number()) |>
            ## Joins produce NA for non-matching rows.
            left_join(e_updates, by = "p") |>
            ## Add the ee sum if available, or 0.
            mutate(E = E + if_else(!is.na(sum_ee), sum_ee, 0)) |>
            ## p's work here is done.
            select(x:E)

        ## NB: dplyr claims group_split() is unstable and proposes nest(), but that's ridiculously
        ## slower here so we don't use it: https://dplyr.tidyverse.org/reference/group_split.html#lifecycle
        by_frozen <- df |>
            ## mutate(xy = rowNorms(matrix(c(x, y), ncol=2)) ^ 2) |>
            mutate(xy = (x^2 + y^2)) |>
            mutate(inregion = (xy < 1) | (abs(x) < 0.5 & y > -2.0 & y < 0.0)) |>
            ## NB: this is by far the slowest line
            group_split(inregion)
        print("xy")
        print(by_frozen)
        stopifnot(length(by_frozen) <= 2)

        ## Clear out the data frame variable we check against for iteration now. If there are no
        ## remaining values, there will be no group returned by group_split() where inregion == TRUE
        ## (a length 1 result), and we indeed wish to return in that case.
        df <- data.frame()

        first_in_region <- by_frozen[[1]]$inregion[1]
        first_value <- by_frozen[[1]] |> select(x:E)
        if (first_in_region) {
            df <- first_value
        } else {
            df_frozen <- df_frozen |> bind_rows(first_value)
        }

        if (length(by_frozen) == 1) {
            next;
        }

        second_in_region <- by_frozen[[2]]$inregion[1]
        stopifnot(second_in_region == !first_in_region)
        second_value <- by_frozen[[2]] |> select(x:E)
        if (second_in_region) {
            df <- second_value
        } else {
            df_frozen <- df_frozen |> bind_rows(second_value)
        }
    }

    df_frozen
}

if (!interactive()) {
    df_done <- simulate(1000000)

    p1 <- ggplot(df_done, aes(log(E))) +
        geom_histogram(binwidth = 0.01) +
        labs(x = NULL, y = NULL, title = "Log(E) at exit")

    ggsave("particles-r1.png", p1)


    p2 <- ggplot(df_done, aes(x, y, color = log(E))) +
        geom_point(alpha = 0.05, size = 2) +
        scale_color_gradient(low = "#042333", high = "#E8FA5B") +
        labs(title = "Final Position with color from log(E)")

    ggsave("particles-r2.png", p2)
}
