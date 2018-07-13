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

# tidy compiled activities
tidy_activities <- function(.data) {
  
  # cast dates
  date_cols <- str_subset(colnames(.data),'date')
  .data[date_cols] <-  .data[date_cols] %>% 
    map(~strptime(.x,'%Y-%m-%dT%H:%M:%SZ')) %>% 
    map(as.POSIXct)
  
  # create date strings
  .data <- .data %>% 
    mutate(start_date_string=strftime(start_date,'%Y-%m-%d'))
  
  .data <- .data %>% 
    mutate(title = paste(start_date_string,' - ',name,sep=''))
  
  return(.data)
}

