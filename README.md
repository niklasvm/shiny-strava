# shiny-strava
A project to showcase Strava data using the R package rStrava and Shiny

## Instructions

1. Pull the repo
1. Ensure global.R can be sourced (all packages are available)
1. Set all the environment variables appropriately in global.R
1. NOTE: To specify the **strava_app_url** environment variable you can just click `Run App` in RStudio and it will be the URL in the address bar (see example below). When deploying the app to shinyapps.io or a shiny server you will need to specify the exact app URL.
![](./www/urlex.JPG)
1. Click the link **Click to Authorise Strava access**
1. Once you authenticate you will be redirected to the app and it will start downloading your activities and display them in a data.table.

## To Do

* Modularise code
  * AUthentication
  * Per logical part of app
* Organise code structure
* Better logging
  * Activity download
  * Activity Tidying
  * Map/calculations
* Merge into master

* Activity filter ideas
  * Date range 
  * Last x days
  * Distance
  
* Dashboard
  * List of activities
    * Inputs
      * Date
      * Type
      * Workout type
    * Output
      * Boxes
        * Number of activities
        * Distance
        * Time
        * Pace
        * Heart rate
        * Ascent
      * List of activities
      * Map
      * Graphs
        * Histogram values
        * Cumulative values 
    
  