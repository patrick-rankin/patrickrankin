###############################################################################
# MLB — TEAM DATA INGESTION SCRIPT
# Purpose: Pull ONE team's season game log from Baseball Reference (via
# baseballr) and save it as a CSV. This file does NOT include individual
# player stats — only team-level results, one row per game. Use
# 02_ingest_mlb_player.R for player-level stats.
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
# This is the only section you need to touch for a new team/season pull.
###############################################################################

# Which team do you want? Use the Baseball Reference 3-letter team code.
# Examples: "NYY", "BOS", "LAD", "HOU", "ATL", "CHC", "SFG", "NYM"
# IMPORTANT: spelling needs to match how Baseball Reference lists the team.
# Not sure of yours? Run the NAME CHECK code near the bottom of this script
# first — it will print a known-good team code so you can confirm the
# format, then swap in the team you want.
my_team <- "NYY"

# Which season? Use the calendar year.
# Example: the 2024 season is written as 2024.
season_year <- 2024

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Use a FULL path with forward slashes, e.g. "C:/Users/you/Documents/mlb_data"
output_folder <- "C:/Users/Pat/Desktop/website/baseball_scripts/team_data"


###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON GAME LOG FOR YOUR TEAM
# -----------------------------------------------------------------------------
# Unlike hoopR, Baseball Reference is scraped one team at a time, so we go
# straight to your team instead of pulling the whole league first.
###############################################################################

team_games <- baseballr::bref_team_results(Tm = my_team, year = season_year)


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure your team code is right, remove the # from the line
# below and run it with a team you KNOW is correct (e.g. "NYY") to confirm
# the format Baseball Reference expects, then update my_team above.
# -----------------------------------------------------------------------------

# baseballr::bref_team_results(Tm = "NYY", yr = season_year) %>% head()


###############################################################################
# STEP 6: SAFETY CHECK
###############################################################################
# If nothing matched, stop here with a clear message instead of saving an
# empty file.

if (is.null(team_games) || nrow(team_games) == 0) {
  stop("No games found for '", my_team, "' in ", season_year, ". Double check ",
       "the 3-letter Baseball Reference code and the season year.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the team and season, e.g.
# mlb_team_NYY_2024.csv
###############################################################################

team_name_clean <- gsub(" ", "_", my_team)
team_filename <- file.path(output_folder, paste0("mlb_team_", team_name_clean, "_", season_year, ".csv"))

write_csv(team_games, team_filename)

cat("Saved:", team_filename, "\n")
cat("Games found:", nrow(team_games), "\n")


###############################################################################
# DONE
# You now have one CSV file with this team's full season game log (one row
# per game — result, runs scored, runs allowed, etc.).
#
# You (or your client) can open this directly in Excel to look around.
#
# The grade_mlb_team.qmd report can read this CSV as a starting point.
###############################################################################
