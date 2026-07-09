###############################################################################
# NBA — TEAM DATA INGESTION SCRIPT
# Purpose: Pull ONE team's season data from hoopR and save it as a CSV.
# This file does NOT include individual player stats — only team-level
# totals, one row per game. Use 02_ingest_nba_player.R for player-level stats.
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
# install.packages("readr")


# -----------------------------------------------------------------------------
# STEP 2: LOAD PACKAGES (run this every time you use the script)
# -----------------------------------------------------------------------------
library(hoopR)
library(dplyr)
library(readr)


###############################################################################
# STEP 3: VARIABLES YOU CAN CHANGE
# This is the only section you need to touch for a new team/season pull.
###############################################################################

# Which season do you want? hoopR uses the YEAR THE SEASON ENDS.
# Example: the 2025-26 NBA season is written as 2026.
season_year <- 2026

# Which team do you want? Use the team's common name.
# Examples: "Lakers", "Celtics", "Warriors", "Knicks"
# IMPORTANT: capitalization and spelling need to match how ESPN lists the
# team. If you're not sure, run the NAME CHECK code near the bottom of this
# script first, and it will print all the team names available so you can
# copy/paste the exact one you want.
my_team <- 'Celtics'

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Use a FULL path with forward slashes, e.g. "C:/Users/you/Documents/nba_data"
output_folder <- "C:/Users/Pat/Desktop/nba_data/team_stats"


###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON OF TEAM DATA
# -----------------------------------------------------------------------------
# hoopR downloads the whole season's team data at once (there's no way to
# ask it for just one team upfront). We filter down to your team right after.
###############################################################################

team_box <- hoopR::load_nba_team_box(seasons = season_year)


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure how your team's name is spelled in this data, remove
# the # from the line below and run it. It will print a list of every team
# name available, so you can copy the exact spelling into my_team above.
# -----------------------------------------------------------------------------

# team_box %>% distinct(team_location, team_name) %>% arrange(team_location) %>% print(n = 100)


###############################################################################
# STEP 6: FILTER DOWN TO YOUR TEAM
###############################################################################
# We check a few different name columns since ESPN sometimes lists a team by
# its city (team_location), its full name (team_name), or a shorter
# version (team_short_display_name). Checking all three makes this more
# likely to work on the first try.

team_games <- team_box %>%
  filter(team_location == my_team |
           team_name == my_team |
           team_short_display_name == my_team)

# Safety check: if nothing matched, stop here with a clear message instead
# of saving an empty file.
if (nrow(team_games) == 0) {
  stop("No games found for '", my_team, "'. Run the NAME CHECK code above ",
       "to see the exact spelling hoopR uses for your team, then update ",
       "my_team to match.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the team and season, e.g.
# nba_team_Lakers_2026.csv
###############################################################################

team_name_clean <- gsub(" ", "_", my_team)
team_filename <- file.path(output_folder, paste0("nba_team_", team_name_clean, "_", season_year, ".csv"))

write_csv(team_games, team_filename)

cat("Saved:", team_filename, "\n")
cat("Games found:", nrow(team_games), "\n")


###############################################################################
# DONE
# You now have one CSV file with this team's full season, team-level stats
# (one row per game, no individual player breakdown).
#
# You (or your client) can open this directly in Excel to look around.
#
# The blog post .qmd files can read this CSV as their starting point.
###############################################################################
