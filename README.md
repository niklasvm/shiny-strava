# shiny-strava
A project to showcase Strava data using the R package rStrava and Shiny

## Instructions

1. Pull the repo
1. Ensure global.R can be sourced (all packages are available)
1. Use run_app.R to launch the app on port 5443. This will ensure the app runs on the port and is available at the redirect url. When deploying the app to shinyapps.io or a shiny server you will need to specify the exact app URL.
1. Click the link **Click to Authorise Strava access**
1. Once you authenticate you will be redirected to the app and it will start downloading your activities and display them in a data.table.
