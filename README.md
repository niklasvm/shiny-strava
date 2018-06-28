# shiny-strava
A project to showcase Strava data using the R package rStrava and Shiny

## Instructions

1. Pull the repo
1. Ensure global.R can be sourced (all packages are available)
1. Run the app locally in RStudio and note the URL it is running in (something of the form ```http://127.0.0.1:6365```)
1. Exit the running app and explicitly specify the ```strava_app_url``` environment variable.
1. Now run the app.
1. Once you authenticate you will be redirected to the app and it will start downloading your activities and display them in a data.table.