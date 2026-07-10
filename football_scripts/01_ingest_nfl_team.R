###############################################################################
# NFL — TEAM DATA INGESTION SCRIPT
# Purpose: Pull ONE team's season schedule/results from nflreadr and save it
# as a CSV. This file does NOT include individual player stats — only
# team-level game results, one row per game. Use 02_ingest_nfl_player.R for
# player-level stats.
###############################################################################

# -----------------------------------------------------------------------------
# STEP 1: INSTALL PACKAGES (only run this section the FIRST time)
# -----------------------------------------------------------------------------
# Remove the # in front of each line below and run it once. After that, you
# can leave these lines commented out (with the # in front) since the
# packages will already be installed on your computer.

# install.packages("nflreadr")
# install.packages("dplyr")
# install.packages("readr")


# -----------------------------------------------------------------------------
# STEP 2: LOAD PACKAGES (run this every time you use the script)
# -----------------------------------------------------------------------------
library(nflreadr)
library(dplyr)
library(readr)


###############################################################################
# STEP 3: VARIABLES YOU CAN CHANGE
# This is the only section you need to touch for a new team/season pull.
###############################################################################

# Which team do you want? Use the 2-3 letter team abbreviation.
# Examples: "NE", "KC", "DAL", "SF", "BUF", "PHI", "MIA", "LAR"
# IMPORTANT: capitalization and spelling need to match how nflreadr lists
# the team. If you're not sure, run the NAME CHECK code near the bottom of
# this script first, and it will print all the team abbreviations
# available so you can copy/paste the exact one you want.
my_team <- "KC"

# Which season? NFL uses the year the season STARTS.
# Example: the 2024-25 season is written as 2024.
season_year <- 2024

# Include playoffs? TRUE = regular season + playoffs, FALSE = regular season only
include_playoffs <- FALSE

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Use a FULL path with forward slashes, e.g. "C:/Users/you/Documents/nfl_data"
output_folder <- "C:/Users/Pat/Desktop/website/football_scripts/team_data"


###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON OF GAME RESULTS
# -----------------------------------------------------------------------------
# nflreadr downloads the whole season's schedule at once (there's no way to
# ask it for just one team upfront). We filter down to your team right after.
###############################################################################

schedules <- nflreadr::load_schedules(seasons = season_year)

if (!include_playoffs) {
  schedules <- schedules %>% filter(game_type == "REG")
}


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure how your team's abbreviation is spelled in this data,
# remove the # from the line below and run it. It will print a list of
# every team abbreviation available, so you can copy the exact spelling
# into my_team above.
# -----------------------------------------------------------------------------

# nflreadr::load_teams() %>% select(team_abbr, team_name) %>% print(n = 40)


###############################################################################
# STEP 6: FILTER DOWN TO YOUR TEAM (combine home + away games)
###############################################################################

home_games <- schedules %>%
  filter(home_team == my_team, !is.na(home_score)) %>%
  transmute(
    game_id, week,
    opponent   = away_team,
    team_score = home_score,
    opp_score  = away_score,
    won        = home_score > away_score,
    home_away  = "Home"
  )

away_games <- schedules %>%
  filter(away_team == my_team, !is.na(away_score)) %>%
  transmute(
    game_id, week,
    opponent   = home_team,
    team_score = away_score,
    opp_score  = home_score,
    won        = away_score > home_score,
    home_away  = "Away"
  )

team_games <- bind_rows(home_games, away_games) %>% arrange(week)

# Safety check: if nothing matched, stop here with a clear message instead
# of saving an empty file.
if (nrow(team_games) == 0) {
  stop("No games found for '", my_team, "'. Run the NAME CHECK code above ",
       "to see the exact abbreviation nflreadr uses for your team, then ",
       "update my_team to match.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the team and season, e.g.
# nfl_team_KC_2024.csv
###############################################################################

team_name_clean <- gsub(" ", "_", my_team)
team_filename <- file.path(output_folder, paste0("nfl_team_", team_name_clean, "_", season_year, ".csv"))

write_csv(team_games, team_filename)

cat("Saved:", team_filename, "\n")
cat("Games found:", nrow(team_games), "\n")


###############################################################################
# DONE
# You now have one CSV file with this team's full season game-by-game
# results (one row per game, no individual player breakdown).
#
# You (or your client) can open this directly in Excel to look around.
#
# The grade_nfl_team.qmd report can read this CSV as a starting point.
###############################################################################
