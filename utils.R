post_authorisation_code <- function(authorisation_code) {
  # post authorisation code
  response <- POST(url = 'https://www.strava.com/oauth/token',
                   body = list(
                     client_id = Sys.getenv('strava_app_client_id'),
                     client_secret = Sys.getenv('strava_app_secret'),
                     code = authorisation_code
                   )
  )
  # returns json/list containing basic athlete information including the access token
  return(content(response))
}

