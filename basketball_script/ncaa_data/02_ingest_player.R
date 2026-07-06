###############################################################################
# NCAA MEN'S BASKETBALL — PLAYER DATA INGESTION SCRIPT
# Purpose: Pull ONE player's season stats from hoopR and save it as a CSV.
# This file pulls individual, game-by-game stats for a single player only.
# Use 01_ingest_team.R for team-level stats instead.
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
# This is the only section you need to touch for a new player/season pull.
###############################################################################

# Which season do you want? hoopR uses the YEAR THE SEASON ENDS.
# Example: the 2025-26 season is written as 2026.
season_year <- 2025

# Which player do you want? Use the player's full name exactly as ESPN
# displays it. Examples: "Caitlin Clark" style format (First Last).
# IMPORTANT: capitalization and spelling need to match how ESPN lists the
# player. If you're not sure, run the NAME CHECK code near the bottom of
# this script first, and it will print player names that partially match
# what you typed, so you can copy/paste the exact one you want.
my_player <- "Cooper Flagg"

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Example: "ncaa_data"
output_folder <- "C:/Users/tabea/OneDrive/Desktop/Clients/patrickr/player_stats"

###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON OF PLAYER DATA
# -----------------------------------------------------------------------------
# hoopR downloads the whole season's player data at once (there's no way to
# ask it for just one player upfront). We filter down to your player right
# after. This is a big file — the first run for a new season can take a
# couple of minutes.
###############################################################################

player_box <- hoopR::load_mbb_player_box(seasons = season_year)


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure how your player's name is spelled in this data, remove
# the # from the lines below and run them. The first line prints every
# player name that PARTIALLY matches what you typed in my_player, so you
# don't have to scroll through every player in the country.
# -----------------------------------------------------------------------------

# player_box %>%
#   filter(grepl(my_player, athlete_display_name, ignore.case = TRUE)) %>%
#   distinct(athlete_display_name, team_location) %>%
#   arrange(athlete_display_name) %>%
#   print(n = 100)


###############################################################################
# STEP 6: FILTER DOWN TO YOUR PLAYER
###############################################################################

player_games <- player_box %>%
  filter(athlete_display_name == my_player)

# Safety check: if nothing matched, stop here with a clear message instead
# of saving an empty file.
if (nrow(player_games) == 0) {
  stop("No games found for '", my_player, "'. Run the NAME CHECK code above ",
       "to see player names that partially match, then update my_player ",
       "to the exact spelling.")
}

# Safety check: if the name matches players on MORE THAN ONE team, warn
# instead of silently combining two different people's stats together.
n_teams_matched <- player_games %>% distinct(team_location) %>% nrow()

if (n_teams_matched > 1) {
  warning("'", my_player, "' matched players on ", n_teams_matched,
          " different teams. The saved CSV includes ALL of them. Check the ",
          "NAME CHECK output above and consider using the full, exact name ",
          "to narrow this down to one player.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the player and season, e.g.
# player_Caitlin_Clark_2026.csv
###############################################################################

player_name_clean <- gsub(" ", "_", my_player)
player_filename <- file.path(output_folder, paste0("player_", player_name_clean, "_", season_year, ".csv"))

write_csv(player_games, player_filename)

cat("Saved:", player_filename, "\n")
cat("Games found:", nrow(player_games), "\n")


###############################################################################
# DONE
# You now have one CSV file with this player's full season, game-by-game
# stats (points, rebounds, assists, etc. for each individual game).
#
# You (or your client) can open this directly in Excel to look around.
#
# The blog post .qmd files can read this CSV as their starting point.
###############################################################################
