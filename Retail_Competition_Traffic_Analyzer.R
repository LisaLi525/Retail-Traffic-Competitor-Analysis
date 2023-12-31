# Function to load store lists
load_store_lists <- function() {
  m_store_list <- read.csv("~/R/Projects/R-DCM/Clients/Clients/Assets/Inputs/Clients_Store List.csv")
  comp_store_list <- read.csv("~/R/Projects/R-DCM/Clients/Clients/Assets/Inputs/Clients_CompSet.csv")

  tbl_vars(comp_store_list)
  tbl_vars(m_store_list)

  comp_store_list_Joann <- comp_store_list %>% filter(Company.Name == "Competitor1" & Verified.Record %in% "Yes")
  comp_store_list_Hobby <- comp_store_list %>% filter(Company.Name == "Competitor2" & Verified.Record %in% "Yes")
  comp_store_list_AC <- comp_store_list %>% filter(Company.Name == "Competitor3" & Verified.Record %in% "Yes")

  comp_store <- rbind(comp_store_list_AC, comp_store_list_Hobby, comp_store_list_Joann)

  return(list(m_store_list = m_store_list, comp_store = comp_store))
}

# Function to load traffic data
load_traffic_data <- function() {
  m_traffic <- read.csv("~/R/Projects/R-DCM/Clients/Clients/Assets/Inputs/Clients Conquesting by Zip Code.csv")
  m_sales <- read.csv("~/R/Projects/R-DCM/Clients/Clients/Assets/Inputs/L52wk_sales.csv")
  m_sales_tl <- read.csv("~/R/Projects/R-DCM/Clients/Clients/Assets/Inputs/total_sales.csv")

  comp_sale <- m_sales %>% select(store)

  month_store_check <- m_traffic %>% group_by(MONTH) %>% summarise(nstore = n(), traffic = sum(VISITS))
  total_traffic <- m_traffic %>% group_by(LOCATION_BRAND) %>% summarise(nstore = n() / 12, traffic = sum(VISITS))

  comp_tl <- m_sales_tl %>% summarise(
    ty = sum(comp_sales),
    ly = sum(comp_sales_ly),
    yoy = round((ty - ly) / ty, 2)
  )

  return(list(m_traffic = m_traffic, m_sales = m_sales, m_sales_tl = m_sales_tl, comp_sale = comp_sale, comp_tl = comp_tl))
}

# Function to merge traffic data with store information
merge_traffic_store_info <- function(m_traffic, m_store_list, comp_store) {
  m_traffic$LOCATION_ZIPCODE_5 <- as.character(m_traffic$LOCATION_ZIPCODE_5)
  m_store_list$ZIP.CODE <- as.character(m_store_list$ZIP.CODE)
  m_store_list$ZIP.CODE <- gsub("\\-.*", "", m_store_list$ZIP.CODE)

  m_traffic_filter <- m_traffic %>%
    filter(LOCATION_BRAND %in% "Clients") %>%
    inner_join(m_store_list, by = c("LOCATION_ZIPCODE_5" = "ZIP.CODE")) %>%
    group_by(STORE.NUMBER, MARKET, STATE, DMA, ADDRESS., LOCATION_ZIPCODE_5, LATITUDE, LONGITUDE) %>%
    summarise(m_visit = sum(VISITS))

  missing_store_zip <- m_traffic %>%
    filter(LOCATION_BRAND %in% "Clients") %>%
    full_join(m_store_list, by = c("LOCATION_ZIPCODE_5" = "ZIP.CODE")) %>%
    group_by(STORE.NUMBER, `X7.15.Print`) %>%
    summarise(traffic = sum(VISITS)) %>%
    filter(is.na(traffic)) %>%
    group_by(`X7.15.Print`) %>%
    summarise(nstore = n())

  colnames(m_traffic_filter) <- c(
    "m_store_num", "m_store_market", "m_store_state", "m_store_dma",
    "m_store_address", "m_store_zip", "m_store_latitude", "m_store_longitude", "m_store_visit"
  )

  return(list(m_traffic_filter = m_traffic_filter, missing_store_zip = missing_store_zip))
}

# Function to merge competitors' store data with traffic data
merge_comp_store_traffic <- function(m_traffic, comp_store) {
  comp_store_AC <- m_traffic %>%
    filter(LOCATION_BRAND %in% "Competitor3") %>%
    inner_join(comp_store$comp_store_list_AC, by = c("LOCATION_ZIPCODE_5" = "Location.ZIP.Code")) %>%
    group_by(Location.Address, Location.City, Location.State, LOCATION_ZIPCODE_5, Latitude, Longitude, Company.Name) %>%
    summarise(
      employee.size = sum(Location.Employee.Size.Actual),
      sale.amount = sum(Location.Sales.Volume.Actual),
      traffic.total = sum(VISITS)
    )

  comp_store_Joann <- m_traffic %>%
    filter(LOCATION_BRAND %in% "JoAnnFabrics") %>%
    inner_join(comp_store$comp_store_list_Joann, by = c("LOCATION_ZIPCODE_5" = "Location.ZIP.Code")) %>%
    group_by(Location.Address, Location.City, Location.State, LOCATION_ZIPCODE_5, Latitude, Longitude, Company.Name) %>%
    summarise(
      employee.size = sum(Location.Employee.Size.Actual),
      sale.amount = sum(Location.Sales.Volume.Actual),
      traffic.total = sum(VISITS)
    )

  comp_store_Hobby <- m_traffic %>%
    filter(LOCATION_BRAND %in% "Competitor2") %>%
    inner_join(comp_store$comp_store_list_Hobby, by = c("LOCATION_ZIPCODE_5" = "Location.ZIP.Code")) %>%
    group_by(Location.Address, Location.City, Location.State, LOCATION_ZIPCODE_5, Latitude, Longitude, Company.Name) %>%
    summarise(
      employee.size = sum(Location.Employee.Size.Actual),
      sale.amount = sum(Location.Sales.Volume.Actual),
      traffic.total = sum(VISITS)
    )

  comp_store_total <- rbind(comp_store_AC, comp_store_Hobby, comp_store_Joann)

  colnames(comp_store_total) <- c(
    "c_store_address", "c_store_city", "c_store_state", "c_store_zip",
    "c_store_latitude", "c_store_longitude", "c_store_company", "c_store_employee_size",
    "c_store_sales", "c_store_traffic"
  )

  comp_store_traffic_total <- comp_store_total %>%
    group_by(c_store_company) %>%
    summarise(visit = sum(c_store_traffic))

  return(list(comp_store_total = comp_store_total, comp_store_traffic_total = comp_store_traffic_total))
}

# Function to calculate distances between Clients stores and competitors' stores
calculate_distances <- function(m_traffic_filter, comp_store_total, b = 10) {
  storelist <- data.frame()

  for (i in 1:length(m_traffic_filter$m_store_num)) {
    a <- as.character(m_traffic_filter$m_store_num[i])

    ab <- m_traffic_filter[i, c("m_store_longitude", "m_store_latitude")]

    ab2 <- comp_store_total[, c("c_store_longitude", "c_store_latitude")]

    d <- distVincentySphere(ab, ab2)

    storelist <- rbind(storelist, cbind(a, ab, ab2, d))
  }

  colnames(storelist) <- c("store.num", "m_store_longitude", "m_store_latitude", "c_store_longitude", "c_store_latitude", "distance")

  storelist$store.num <- as.character(storelist$store.num)
  storelist$distance <- storelist$distance / 1609.34

  storelist <- storelist %>%
    filter(distance < b) %>%
    filter(!duplicated(store.num)) %>%
    filter(!duplicated(c_store_longitude))

  return(storelist)
}

# Function to calculate the traffic market share
calculate_traffic_market_share <- function(m_traffic_filter, comp_store_traffic_total) {
  total_traffic <- sum(comp_store_traffic_total$visit)
  m_traffic_filter <- m_traffic_filter %>%
    mutate(market_share = m_store_visit / total_traffic)

  return(m_traffic_filter)
}

# Main function
main <- function() {
  # Load store lists
  store_lists <- load_store_lists()
  m_store_list <- store_lists$m_store_list
  comp_store <- store_lists$comp_store

  # Load traffic data
  traffic_data <- load_traffic_data()
  m_traffic <- traffic_data$m_traffic
  m_sales <- traffic_data$m_sales
  m_sales_tl <- traffic_data$m_sales_tl
  comp_sale <- traffic_data$comp_sale
  comp_tl <- traffic_data$comp_tl

  # Merge traffic data with store information
  merged_traffic_store_info <- merge_traffic_store_info(m_traffic, m_store_list, comp_store)
  m_traffic_filter <- merged_traffic_store_info$m_traffic_filter
  missing_store_zip <- merged_traffic_store_info$missing_store_zip

  # Merge competitors' store data with traffic data
  comp_store_traffic <- merge_comp_store_traffic(m_traffic, comp_store)
  comp_store_total <- comp_store_traffic$comp_store_total
  comp_store_traffic_total <- comp_store_traffic$comp_store_traffic_total

  # Calculate distances between Clients stores and competitors' stores
  storelist <- calculate_distances(m_traffic_filter, comp_store_total, b = 10)

  # Calculate traffic market share
  m_traffic_filter <- calculate_traffic_market_share(m_traffic_filter, comp_store_traffic_total)

  # Print results
  print("Merged Traffic and Store Information:")
  print(m_traffic_filter)

  print("Competitors' Store Information:")
  print(comp_store_total)

  print("Distances between Clients stores and Competitors' stores:")
  print(storelist)

  print("Traffic Market Share:")
  print(m_traffic_filter)
}

# Run the main function
main()
