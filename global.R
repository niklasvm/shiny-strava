# global.R is sourced when the application is lauched

# Load package dependencies ----
library(shiny)
library(rStrava)
library(tidyverse)
library(httr)
library(lubridate)
library(jsonlite)
library(glue)
library(DT)
library(leaflet)
library(shinydashboard)
library(shinythemes)

# Load file dependencies ----

source('./utils.R')
source("./dplyr_verbs.R")

# Set application options ----

# application url
strava_app_url  <-  glue('http://127.0.0.1:1234')
#strava_app_url = '192.168.0.94:3838/shiny-strava'
# set as environment variable
Sys.setenv(
  strava_app_url = strava_app_url
)

# show application api inputs
ask_api_credentials <- T

# load cached data (must have authenticated before)
cache <- F

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
periods <- list(
  'This week' = c(floor_date(Sys.Date()-1,unit = 'week')+1,as.Date(strftime(Sys.Date(),'%Y-%m-%d'))),
  'Last 7 days' = c(Sys.Date()-6,Sys.Date()),
  'This month' = c(floor_date(Sys.Date(),unit = 'month'),as.Date(strftime(Sys.Date(),'%Y-%m-%d'))),
  'This year' = c(floor_date(Sys.Date(),unit = 'year'),Sys.Date()),
  'Last week' = c(floor_date(Sys.Date()-1-7,unit = 'week')+1,floor_date(Sys.Date()-1,unit = 'week')),
  'Last month' = c(floor_date(Sys.Date(),unit = 'month') - months(1),floor_date(Sys.Date(),'month')-1)
)
