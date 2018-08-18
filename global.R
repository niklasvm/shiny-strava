# global.R is sourced when the application is lauched

# dependencies
library(shiny)
library(rStrava)
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)
library(DT)
library(leaflet)
library(shinydashboard)
library(shinythemes)

# Load credentials if available ----

# the following environment variables must be set in credentials.R
# Sys.setenv(
#   strava_app_client_id  = 'xxxx',
#   strava_app_secret = 'xxxx'
# )

if (file.exists('./credentials.R')) source('./credentials.R')

# Application options ----

# application url (where the user is redirected after authentication)
strava_app_url  <-  glue('http://127.0.0.1:1234')
Sys.setenv(strava_app_url = strava_app_url) # set as environment variable

# check if api credentials need to be captured from the user
if (Sys.getenv('strava_app_client_id')=='' & Sys.getenv('strava_app_secret') == '') {
  message('No credentials found in environment, displaying api credentials form')
  ask_api_credentials <- T 
} else {
  ask_api_credentials <- F
}

cache <- F # whether to load cached data (must have authenticated before)

# file dependencies ----
source('./utils.R')
source("./dplyr_verbs.R")
