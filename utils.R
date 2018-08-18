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
  colour = 'blue'
) {
  routes <- data %>% 
    select(id,map.summary_polyline) %>% 
    split(.$id) %>% 
    map_df(function(row) {
      row$map.summary_polyline[1] %>% 
        decode_Polyline() %>% 
        separate(latlon,into=c('lat','lon'),sep = ',') %>% 
        # add id
        mutate(id=row$id) %>% 
        # cast to numeric
        mutate(lat=as.numeric(lat)) %>% 
        mutate(lon=as.numeric(lon)) %>% 
        select(id,everything())
    }) %>% 
    as.tibble
  
  routes <- routes %>% 
    left_join(data %>% select(id,title),by='id') %>% 
    mutate(label=title)
  
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
  }
  map
}
