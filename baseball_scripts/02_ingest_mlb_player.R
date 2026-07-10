###############################################################################
# MLB — PLAYER DATA INGESTION SCRIPT
# Purpose: Pull ONE player's season leaderboard stats from FanGraphs (via
# baseballr) and save it as a CSV. This file pulls one row of season totals
# for a single player only. Use 01_ingest_mlb_team.R for team-level stats.
###############################################################################

# -----------------------------------------------------------------------------
# STEP 1: INSTALL PACKAGES (only run this section the FIRST time)
# -----------------------------------------------------------------------------
# Remove the # in front of each line below and run it once. After that, you
# can leave these lines commented out (with the # in front) since the
# packages will already be installed on your computer.

# install.packages("baseballr")
# install.packages("dplyr")
# install.packages("readr")


# -----------------------------------------------------------------------------
# STEP 2: LOAD PACKAGES (run this every time you use the script)
# -----------------------------------------------------------------------------
library(baseballr)
library(dplyr)
library(readr)


###############################################################################
# STEP 3: VARIABLES YOU CAN CHANGE
# This is the only section you need to touch for a new player/season pull.
###############################################################################

# Which season do you want? Use the calendar year.
# Example: the 2024 season is written as 2024.
season_year <- 2024

# Which player do you want? Use the player's full name exactly as
# FanGraphs displays it (First Last).
# IMPORTANT: capitalization and spelling need to match how FanGraphs lists
# the player. If you're not sure, run the NAME CHECK code near the bottom
# of this script first, and it will print player names that partially
# match what you typed, so you can copy/paste the exact one you want.
my_player <- "Aaron Judge"

# Player type — determines which leaderboard is pulled:
# "Batter"  for position players
# "Pitcher" for starting and relief pitchers
player_type <- "Batter"

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Use a FULL path with forward slashes, e.g. "C:/Users/you/Documents/mlb_data"
output_folder <- "C:/Users/Pat/Desktop/website/baseball_scripts/player_data"


###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON LEADERBOARD
# -----------------------------------------------------------------------------
# FanGraphs leaderboards come back for every qualified player at once (there's
# no way to ask for just one player upfront). We filter down to your player
# right after. Using qual = 1 makes sure players who didn't hit the normal
# plate-appearance/innings minimum still show up.
###############################################################################

if (player_type == "Batter") {
  leaders <- baseballr::fg_batter_leaders(
    startseason = as.character(season_year),
    endseason   = as.character(season_year),
    qual        = 1
  )
} else {
  leaders <- baseballr::fg_pitcher_leaders(
    startseason = as.character(season_year),
    endseason   = as.character(season_year),
    qual        = 1
  )
}


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure how your player's name is spelled in this data, remove
# the # from the line below and run it. It will print every player name
# that PARTIALLY matches what you typed in my_player, so you don't have to
# scroll through the whole league.
# -----------------------------------------------------------------------------

# leaders %>% filter(grepl(my_player, playerName, ignore.case = TRUE)) %>%
#   distinct(playerName, team) %>% print(n = 100)


###############################################################################
# STEP 6: FILTER DOWN TO YOUR PLAYER
###############################################################################

player_season <- leaders %>%
  filter(tolower(playerName) == tolower(my_player))

# Safety check: if nothing matched, stop here with a clear message instead
# of saving an empty file.
if (nrow(player_season) == 0) {
  player_season <- leaders %>%
    filter(grepl(my_player, playerName, ignore.case = TRUE))
}

if (nrow(player_season) == 0) {
  stop("No stats found for '", my_player, "' (", player_type, ") in ",
       season_year, ". Run the NAME CHECK code above to see player names ",
       "that partially match, then update my_player to the exact spelling. ",
       "Also double check player_type — a batter won't show up on the ",
       "pitcher leaderboard and vice versa.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the player and season, e.g.
# mlb_player_Aaron_Judge_2024.csv
###############################################################################

player_name_clean <- gsub(" ", "_", my_player)
player_filename <- file.path(output_folder, paste0("mlb_player_", player_name_clean, "_", season_year, ".csv"))

write_csv(player_season, player_filename)

cat("Saved:", player_filename, "\n")
cat("Rows found:", nrow(player_season), "\n")


###############################################################################
# DONE
# You now have one CSV file with this player's full season leaderboard
# stats (batting or pitching, depending on player_type).
#
# You (or your client) can open this directly in Excel to look around.
#
# The grade_mlb_player.qmd report can read this CSV as a starting point.
###############################################################################
