###############################################################################
# NCAA MEN'S BASKETBALL STATS SCRIPT
# Built for: pulling team and player stats to use in a Quarto blog post
# Package used: hoopR (free, no API key required)
###############################################################################

# -----------------------------------------------------------------------------
# STEP 1: INSTALL PACKAGES (only run this section the FIRST time)
# -----------------------------------------------------------------------------
# Remove the # in front of each line below and run it once. After that, you
# can leave these lines commented out (with the # in front) since the
# packages will already be installed on your computer.

# install.packages("pak")
# pak::pak("sportsdataverse/hoopR")
# install.packages("dplyr")
# install.packages("ggplot2")
# install.packages("gt")


# -----------------------------------------------------------------------------
# STEP 2: LOAD PACKAGES (run this every time you use the script)
# -----------------------------------------------------------------------------
library(hoopR)
library(dplyr)
library(ggplot2)
library(gt)


###############################################################################
# STEP 3: VARIABLES YOU CAN CHANGE
# This is the only section you need to touch for a new blog post.
# Change the values on the right side of each <- arrow.
###############################################################################

# Which season do you want? hoopR uses the YEAR THE SEASON ENDS.
# Example: the 2025-26 season is written as 2026.
season_year <- 2026

# Which team do you want to focus on? Use the school's common name.
# Examples: "Duke", "Kansas", "Saint Louis", "Houston", "Gonzaga"
# IMPORTANT: capitalization and spelling need to match how ESPN lists the
# team. If you are not sure, run the "name check" code near the bottom of
# this script first, and it will print all the team names available so you
# can copy/paste the exact one you want.
my_team <- "Saint Louis"

# How many of the team's top scorers do you want to show in the chart?
top_n_players <- 10

# Where do you want the chart image saved? (Quarto will use this file.)
chart_filename <- "team_scoring_chart.png"


###############################################################################
# STEP 4: PULL THE DATA (you usually do not need to change anything below)
###############################################################################

# Pulls box scores for every player, every game, for the season you picked.
# The first time you run this for a new season it can take a minute or two.
player_box <- hoopR::load_mbb_player_box(seasons = season_year)

# Pulls box scores for every team, every game, for the season you picked.
team_box <- hoopR::load_mbb_team_box(seasons = season_year)


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you are not sure how your team's name is spelled in this data, remove
# the # from the line below and run it. It will print a list of every team
# name available, so you can copy the exact spelling into my_team above.
# -----------------------------------------------------------------------------

# team_box %>% distinct(team_location) %>% arrange(team_location) %>% print(n = 400)


# -----------------------------------------------------------------------------
# STEP 5: FILTER DOWN TO YOUR TEAM
# -----------------------------------------------------------------------------
# We check a few different name columns since ESPN sometimes lists a team by
# its city/school (team_location), its full name (team_name), or a shorter
# version (team_short_display_name). Checking all three makes this more
# likely to work on the first try.

team_games <- team_box %>%
  filter(team_location == my_team |
           team_name == my_team |
           team_short_display_name == my_team)

team_players <- player_box %>%
  filter(team_location == my_team |
           team_name == my_team |
           team_short_display_name == my_team)

# Safety check: if nothing matched, stop here with a clear message instead
# of running into confusing errors further down.
if (nrow(team_games) == 0) {
  stop("No games found for '", my_team, "'. Run the NAME CHECK code above ",
       "to see the exact spelling hoopR uses for your team, then update ",
       "my_team to match.")
}


# -----------------------------------------------------------------------------
# STEP 6: BUILD A SEASON SUMMARY TABLE FOR THE TEAM
# -----------------------------------------------------------------------------
# Each game shows up as two rows in team_box, one row for each team in that
# game. To find out how many points the OTHER team scored, we match every
# row to its game's other row using game_id, then grab that row's score.

# -----------------------------------------------------------------------------
# STEP 6: BUILD A SEASON SUMMARY TABLE FOR THE TEAM
# -----------------------------------------------------------------------------
# Each game shows up as two rows in team_box, one row for each team in that
# game. To find out how many points the OTHER team scored, we match every
# row to its game's other row using game_id, then grab that row's score.

opponent_scores <- team_box %>%
  select(game_id, team_id, team_score)

team_games <- team_games %>%
  left_join(opponent_scores, by = "game_id", suffix = c("", "_opp")) %>%
  filter(team_id_opp != team_id) %>%        # drops the team's own row from the match
  rename(opponent_points = team_score_opp)

team_summary <- team_games %>%
  summarise(
    games_played   = n(),
    avg_points     = round(mean(team_score, na.rm = TRUE), 1),
    avg_opp_points = round(mean(opponent_points, na.rm = TRUE), 1),
    point_diff     = round(avg_points - avg_opp_points, 1)
  )

# Prints a one-row summary: games played, scoring average, opponent's
# scoring average, and average point differential (margin of victory/loss).
print(team_summary)


# -----------------------------------------------------------------------------
# STEP 7: BUILD A TOP SCORERS TABLE FOR THE TEAM
# -----------------------------------------------------------------------------

top_scorers <- team_players %>%
  group_by(athlete_display_name) %>%
  summarise(
    games_played = n(),
    total_points = sum(points, na.rm = TRUE),
    avg_points   = round(mean(points, na.rm = TRUE), 1),
    avg_rebounds = round(mean(rebounds, na.rm = TRUE), 1),
    avg_assists  = round(mean(assists, na.rm = TRUE), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_points)) %>%
  slice_head(n = top_n_players)

print(top_scorers)


# -----------------------------------------------------------------------------
# STEP 8: MAKE A NICE TABLE FOR THE BLOG (using the gt package)
# -----------------------------------------------------------------------------

top_scorers_table <- top_scorers %>%
  gt() %>%
  tab_header(
    title    = paste(my_team, "Top Scorers"),
    subtitle = paste(season_year - 1, "-", season_year, "Season")
  ) %>%
  cols_label(
    athlete_display_name = "Player",
    games_played          = "Games",
    total_points          = "Total Points",
    avg_points            = "Points / Game",
    avg_rebounds          = "Rebounds / Game",
    avg_assists           = "Assists / Game"
  )

# This prints the table when you run the script in RStudio.
# When you put this script inside a Quarto document, this same table
# will render automatically as a nice looking table on the blog page.
top_scorers_table


# -----------------------------------------------------------------------------
# STEP 9: MAKE A CHART FOR THE BLOG (using ggplot2)
# -----------------------------------------------------------------------------

scoring_chart <- top_scorers %>%
  ggplot(aes(x = reorder(athlete_display_name, avg_points), y = avg_points)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title    = paste(my_team, "- Points Per Game"),
    subtitle = paste(season_year - 1, "-", season_year, "Season"),
    x        = NULL,
    y        = "Average Points Per Game"
  ) +
  theme_minimal(base_size = 13)

# Shows the chart in RStudio.
print(scoring_chart)

# Saves the chart as an image file so it can also be used outside of Quarto.
ggsave(chart_filename, plot = scoring_chart, width = 8, height = 5, dpi = 150)


###############################################################################
# DONE
# You now have three things ready for a blog post:
#   1. team_summary      - a one-row summary of the team's season
#   2. top_scorers_table - a nice looking table of the top players
#   3. scoring_chart      - a bar chart of points per game
#
# In your Quarto (.qmd) file, just put this whole script (or the parts you
# want) inside an R code chunk, and Quarto will render the table and chart
# directly on the page when you click Render.
###############################################################################
