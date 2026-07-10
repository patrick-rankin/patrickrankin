###############################################################################
# NHL — PLAYER DATA INGESTION SCRIPT
# Purpose: Pull ONE player's season stats from Hockey Reference (via
# hockeyR) and save it as a CSV. This file pulls one row of season totals
# for a single player only. Use 01_ingest_nhl_team.R for team-level stats.
###############################################################################

# -----------------------------------------------------------------------------
# STEP 1: INSTALL PACKAGES (only run this section the FIRST time)
# -----------------------------------------------------------------------------
# Remove the # in front of each line below and run it once. After that, you
# can leave these lines commented out (with the # in front) since the
# packages will already be installed on your computer.

# install.packages("pak")
# pak::pak("sportsdataverse/hockeyR")
# install.packages("dplyr")
# install.packages("readr")


# -----------------------------------------------------------------------------
# STEP 2: LOAD PACKAGES (run this every time you use the script)
# -----------------------------------------------------------------------------
library(hockeyR)
library(dplyr)
library(readr)


###############################################################################
# STEP 3: VARIABLES YOU CAN CHANGE
# This is the only section you need to touch for a new player/season pull.
###############################################################################

# Which season? Use the FULL season string in Hockey Reference format.
# Example: the 2024-25 season is "20242025"
season_str <- "20242025"

# Which player do you want? Use the player's full name as Hockey Reference
# lists it (First Last).
# IMPORTANT: capitalization and spelling need to match how Hockey Reference
# lists the player. If you're not sure, run the NAME CHECK code near the
# bottom of this script first, and it will print player names that
# partially match what you typed, so you can copy/paste the exact one you
# want.
my_player <- "Nathan MacKinnon"

# Player type — determines which leaderboard is pulled:
# "Skater" for forwards and defensemen
# "Goalie" for goaltenders
player_type <- "Skater"

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Use a FULL path with forward slashes, e.g. "C:/Users/you/Documents/nhl_data"
output_folder <- "C:/Users/Pat/Desktop/website/hockey_scripts/player_data"


###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON LEADERBOARD
# -----------------------------------------------------------------------------
# hockeyR downloads the whole season's leaderboard at once (there's no way
# to ask it for just one player upfront). We filter down to your player
# right after.
###############################################################################

if (player_type == "Skater") {
  season_leaders <- hockeyR::get_skater_stats_hr(season = season_str, type = "regular")
} else {
  season_leaders <- hockeyR::get_goalie_stats_hr(season = season_str, type = "regular")
}


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure how your player's name is spelled in this data, remove
# the # from the line below and run it. It will print every player name
# that PARTIALLY matches what you typed in my_player, so you don't have to
# scroll through the whole league.
# -----------------------------------------------------------------------------

# season_leaders %>% filter(grepl(my_player, player, ignore.case = TRUE)) %>%
#   distinct(player, team) %>% print(n = 100)


###############################################################################
# STEP 6: FILTER DOWN TO YOUR PLAYER
###############################################################################

player_season <- season_leaders %>%
  filter(tolower(player) == tolower(my_player))

if (nrow(player_season) == 0) {
  player_season <- season_leaders %>%
    filter(grepl(my_player, player, ignore.case = TRUE))
}

# Safety check: if nothing matched, stop here with a clear message instead
# of saving an empty file.
if (nrow(player_season) == 0) {
  stop("No stats found for '", my_player, "' (", player_type, ") in ",
       season_str, ". Run the NAME CHECK code above to see player names ",
       "that partially match, then update my_player to the exact spelling. ",
       "Also double check player_type — a skater won't show up on the ",
       "goalie leaderboard and vice versa.")
}

# Safety check: if the name matches players on MORE THAN ONE team, warn
# instead of silently combining two different people's stats together.
# (This can legitimately happen mid-season after a trade, too.)
n_teams_matched <- player_season %>% distinct(team) %>% nrow()

if (n_teams_matched > 1) {
  warning("'", my_player, "' matched players on ", n_teams_matched,
          " different teams this season. The saved CSV includes ALL of ",
          "them. This can happen legitimately if a player was traded ",
          "mid-season — check the data before assuming it's an error.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the player and season, e.g.
# nhl_player_Nathan_MacKinnon_20242025.csv
###############################################################################

player_name_clean <- gsub(" ", "_", my_player)
player_filename <- file.path(output_folder, paste0("nhl_player_", player_name_clean, "_", season_str, ".csv"))

write_csv(player_season, player_filename)

cat("Saved:", player_filename, "\n")
cat("Rows found:", nrow(player_season), "\n")


###############################################################################
# DONE
# You now have one CSV file with this player's full season leaderboard
# stats (skater or goalie, depending on player_type).
#
# You (or your client) can open this directly in Excel to look around.
#
# The grade_nhl_player.qmd report can read this CSV as a starting point.
###############################################################################
