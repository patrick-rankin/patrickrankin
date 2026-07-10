###############################################################################
# NFL — PLAYER DATA INGESTION SCRIPT
# Purpose: Pull ONE player's season stats from nflreadr and save it as a CSV.
# This file pulls individual, week-by-week stats for a single player only.
# Use 01_ingest_nfl_team.R for team-level stats instead.
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
# This is the only section you need to touch for a new player/season pull.
###############################################################################

# Which season do you want? NFL uses the year the season STARTS.
# Example: the 2024-25 season is written as 2024.
season_year <- 2024

# Which player do you want? Use the player's full name exactly as NFL
# rosters list it (First Last).
# IMPORTANT: capitalization and spelling need to match how nflreadr lists
# the player. If you're not sure, run the NAME CHECK code near the bottom
# of this script first, and it will print player names that partially
# match what you typed, so you can copy/paste the exact one you want.
my_player <- "Patrick Mahomes"

# Include playoffs? TRUE = regular season + playoffs, FALSE = regular season only
include_playoffs <- FALSE

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Use a FULL path with forward slashes, e.g. "C:/Users/you/Documents/nfl_data"
output_folder <- "C:/Users/Pat/Desktop/website/football_scripts/player_data"


###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON OF PLAYER DATA
# -----------------------------------------------------------------------------
# nflreadr downloads the whole season's player data at once (there's no way
# to ask it for just one player upfront). We filter down to your player
# right after. This is a big file — the first run for a new season can take
# a couple of minutes.
###############################################################################

player_stats <- nflreadr::load_player_stats(seasons = season_year, stat_type = "offense")

if (!include_playoffs) {
  player_stats <- player_stats %>% filter(season_type == "REG")
}


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure how your player's name is spelled in this data, remove
# the # from the lines below and run them. It prints every player name that
# PARTIALLY matches what you typed in my_player, so you don't have to
# scroll through every player in the league.
# -----------------------------------------------------------------------------

# player_stats %>%
#   filter(grepl(my_player, player_display_name, ignore.case = TRUE)) %>%
#   distinct(player_display_name, recent_team) %>%
#   arrange(player_display_name) %>%
#   print(n = 100)


###############################################################################
# STEP 6: FILTER DOWN TO YOUR PLAYER
###############################################################################

player_games <- player_stats %>%
  filter(tolower(player_display_name) == tolower(my_player))

if (nrow(player_games) == 0) {
  player_games <- player_stats %>%
    filter(grepl(my_player, player_display_name, ignore.case = TRUE))
}

# Safety check: if nothing matched, stop here with a clear message instead
# of saving an empty file.
if (nrow(player_games) == 0) {
  stop("No games found for '", my_player, "'. Run the NAME CHECK code above ",
       "to see player names that partially match, then update my_player ",
       "to the exact spelling. Also double check season_year — a player ",
       "who was traded, injured all season, or not yet in the league that ",
       "year will return zero rows even with perfect spelling.")
}

# Safety check: if the name matches players on MORE THAN ONE team, warn
# instead of silently combining two different people's stats together.
# (This can legitimately happen mid-season after a trade, too.)
n_teams_matched <- player_games %>% distinct(recent_team) %>% nrow()

if (n_teams_matched > 1) {
  warning("'", my_player, "' matched players on ", n_teams_matched,
          " different teams this season. The saved CSV includes ALL of ",
          "them. This can happen legitimately if a player was traded ",
          "mid-season — check the data before assuming it's an error.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the player and season, e.g.
# nfl_player_Patrick_Mahomes_2024.csv
###############################################################################

player_name_clean <- gsub(" ", "_", my_player)
player_filename <- file.path(output_folder, paste0("nfl_player_", player_name_clean, "_", season_year, ".csv"))

write_csv(player_games, player_filename)

cat("Saved:", player_filename, "\n")
cat("Games found:", nrow(player_games), "\n")


###############################################################################
# DONE
# You now have one CSV file with this player's full season, week-by-week
# stats (passing, rushing, receiving, etc. for each individual game).
#
# You (or your client) can open this directly in Excel to look around.
#
# The grade_nfl_player.qmd report can read this CSV as a starting point.
###############################################################################
