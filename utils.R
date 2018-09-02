
parse_authorisation_code <- function(session) {
  pars <- parseQueryString(session$clientData$url_search)
  return(pars$code)
}

load_application_config <- function() {
  
  filename <- 'config.yml'
  
  if (!file.exists(filename)) stop('No config.yml file found')
  
  # read credentials
  config <- yaml::read_yaml(filename)
  
  # load as environment variables
  config %>% 
    walk2(
      names(config),
      function(value,key) {
        value <- list(value)
        names(value) <- key
        do.call(Sys.setenv, value)
      }
    )
  
}

parse_application_url <- function(session) {
  paste0(session$clientData$url_protocol,
                    "//",
                    session$clientData$url_hostname, 
                    ifelse(
                      session$clientData$url_hostname == "127.0.0.1", 
                      ":",
                      session$clientData$url_pathname
                    ),
                    session$clientData$url_port
  )
}

logerror_stop <- function(msg,logger) {
  logerror(msg,logger=logger)
  stop(msg)
}

validate_credentials <- function(authorisation_code) {
  if (nchar(Sys.getenv('strava_app_client_id')) == 0) logerror_stop('strava_app_client_id is blank',logger='authentication')
  if (nchar(Sys.getenv('strava_app_secret')) == 0) logerror_stop('strava_app_secret is blank',logger='authentication')
  
  loginfo(glue('Using client id: {Sys.getenv(\'strava_app_client_id\')}'),
          logger = 'authentication')
  loginfo(glue('Using secret: {Sys.getenv(\'strava_app_secret\')}'),
          logger =
            'authentication')
  loginfo(glue('Using auth code: {authorisation_code}'),
          logger = 'authentication')
}

post_authorisation_code <- function(
  authorisation_code,
  strava_app_client_id,
  strava_app_secret
) {
    
  # post authorisation code
  response <- POST(url = 'https://www.strava.com/oauth/token',
                   body = list(
                     client_id = strava_app_client_id,
                     client_secret = strava_app_secret,
                     code = authorisation_code
                   )
  )
  # returns json/list containing basic athlete information including the access token
  return(content(response))
}

#' Tidy activity list into a nested tibble
#'
#' @param .data a list
#'
#' @return a tibble
#' @export
#'
tidy_activities <- function(.data) {
  
  # compile list into data frame
  .data <- .data %>% 
    compile_activities() %>% 
    as.tibble
  
  # cast dates
  date_cols <- str_subset(colnames(.data),'date')
  .data[date_cols] <-  .data[date_cols] %>% 
    map(~strptime(.x,'%Y-%m-%dT%H:%M:%SZ')) %>% 
    map(as.POSIXct)
  
  # create date strings
  .data <- .data %>% 
    mutate(start_date_string=strftime(start_date,'%Y-%m-%d'))
  
  # create title: date + name combination
  .data <- .data %>% 
    mutate(title = paste(start_date_string,' - ',name,sep=''))
  
  # calculate route coordinates from polyline
  .data <- .data %>% 
    mutate(route = map.summary_polyline %>% 
             map(function(polyline) {
               if (!is.na(polyline)) {
                 # polyline %>%  decode_Polyline() %>% 
                 #   separate(latlon,into=c('lat','lon'),sep = ',') %>% 
                 #   # cast to numeric
                 #   mutate(lat=as.numeric(lat)) %>% 
                 #   mutate(lon=as.numeric(lon))
                 polyline %>% decode %>% as.data.frame
               } else {
                 NA
               }
             })
    )
  
  # make numeric
  .data <- .data %>% 
    mutate_at(vars(average_heartrate),as.numeric)
  
  # replace start coordinates with higher precision coords from decoded polyline
  .data <- .data %>% 
    mutate(start_latitude=route %>% map('lat') %>% map(1) %>% map_dbl(~ ifelse(is.null(.x),NA,.x) )) %>% 
    mutate(start_longitude=route %>% map('lon') %>% map(1) %>% map_dbl(~ ifelse(is.null(.x),NA,.x) ))
  
  return(.data)
}

#' Filter a list of activities by distance radius
#'
#' Filter activities by distance from particular starting lat/lon
#'
#' @param lon start longitude
#' @param lat start latitude
#' @param radius radius in meters
#'
#' @return
#' @export
#'
filter_within_radius <- function(data,lon,lat,radius) {
  if (!require(geosphere)) library(geosphere)
  
  # validate
  if (!all(c('start_latitude','start_longitude') %in% colnames(data))) stop('data must contain columns start_latitude and start_longitude')
  
  # calculate distance matrix
  distance_matrix <- distm(
    data %>% select(start_longitude,start_latitude),
    c(lon,lat)
  ) %>% 
    as.tibble %>% 
    mutate(id=data$id) %>% 
    select(id,everything()) %>% 
    set_names(c('id','distance')) %>% 
    filter(distance<=radius)
  
  # filter existing
  data <- data %>% 
    filter(id %in% distance_matrix$id)
  
  return(data)
}


#' Render leaflet map
#'
#' @param data a actframe object
#' @param urlTemplate url template from which to fetch map tiles
#' @param opacity line opacity
#' @param weight line weight
#' @param colour line colour
#'
#' @return
#' @export
#'
get_leaflet_heat_map <- function(
  data,
  urlTemplate = "http://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png",
  opacity = 0.01,
  weight = 3,
  colour = 'blue',
  markers=F
) {
  # extract non NA routes
  routes <- data %>% 
    select(id,title,route) %>% 
    filter(!is.na(route)) %>% 
    unnest()
  
  routes <- routes %>% split(.$id)
  
  # Plot map
  map <- leaflet() %>% 
    addTiles(urlTemplate = urlTemplate)
  
  for (r in routes) {
    map <- map %>% addPolylines(
      lng = r$lon,
      lat = r$lat,
      layerId = r$id,
      color=colour,
      opacity = opacity,
      weight = weight
    )
    
    if (markers) {
      map <- map %>%
        addMarkers(
          lng = r$lon[1],
          lat = r$lat[1],
          layerId = r$id[1],
          popup = r$title
        )
    }
    
  }
  map
}

get_activity_list_by_page <- function(stoken,per_page=200,pages=1) {
  get_pages(url_ = url_activities(),
            stoken=stoken,
            per_page=per_page,
            page_max=pages
  )
}


