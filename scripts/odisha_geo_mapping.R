source("scripts/libraries.R")

# Import and standardise input files --------------------------------------

# Rules for standardising scheme data 
# 1 - Filter selected cols
# 2 - Rename cols
# 3 - Remove extra spaces from cols and convert all cols to lowercase 
# 4 - Remove unwanted rows by filtering values from the GP col
# 5 - Assign unique ID to each row


# scheme_file_path <- "data/scheme/MNREGA/odisha/2019-20/raw/csv/MGNREGA-Odisha-2019-20_040621.csv"
# scheme_file_path <- "data/scheme/MNREGA/odisha/2018-19/raw/csv/MGNREGA_Odisha_2018-19_040621.csv"
# scheme_file_path <- "data/scheme/PMAGY/odisha/2018-19/raw/csv/PMAYG-Odisha 2018-19_040621.csv"
# scheme_file_path <- "data/scheme/PMAGY/odisha/2019-20/raw/csv/PMAYG-Odisha 2019-20_040621.csv"
# scheme_file_path <- "data/scheme/NSAP/odisha/2019-20/raw/csv/nsap_IGNDPS.csv"
# scheme_file_path <- "data/scheme/NSAP/odisha/2019-20/raw/csv/nsap_IGNOAPS.csv"
# scheme_file_path <- "data/scheme/NSAP/odisha/2019-20/raw/csv/nsap_IGNWPS.csv"
# scheme_file_path <- "data/scheme/NSAP/odisha/2019-20/raw/csv/nsap_IGNDPS_urban.csv"
# scheme_file_path <- "data/scheme/NSAP/odisha/2019-20/raw/csv/nsap_IGNOAPS_urban.csv"

scheme_file_path <- "data/scheme/NSAP/odisha/2019-20/raw/csv/nsap_IGNWPS_urban.csv"
scheme_data <- read_csv(scheme_file_path)

scheme_type <- ifelse(grepl(scheme_file_path,pattern = "urban",ignore.case = TRUE),"urban","rural")
scheme_nsap <- grepl(scheme_file_path, pattern = "nsap", ignore.case = TRUE)

if(scheme_nsap){
  # For NSAP schemes
  names(scheme_data)[c(1,2,3,4,5)] <- c("s_state","s_district","s_ulb","s_block","s_gp") 
  
} else {
  # For non NSAP schemes
  names(scheme_data)[c(1,2,3,5)] <- c("s_state","s_district","s_block","s_gp") 
  
}

scheme_data <- scheme_data %>% mutate_all(funs(str_replace_all(., "�", "")))
scheme_data <- scheme_data %>% mutate_all(funs(str_trim(str_to_lower(.))))
scheme_data <- scheme_data %>% filter(!s_gp %in% c('total','block level line deptt.','po','grand total',NA_character_))
scheme_data <- scheme_data[!is.na(scheme_data$s_state),]

if(scheme_type == "urban"){
  scheme_data$s_block <- scheme_data$s_ulb
} 
  
scheme_data <- scheme_data[!is.na(scheme_data$s_block),]  

scheme_data$s_id <- 1:nrow(scheme_data)


# Rules for standardising geography data 
# 1 - Filter selected cols
# 2 - Rename cols
# 3 - Remove extra spaces from cols and convert all cols to lowercase 
# 4 - Remove unwanted rows by filtering values from the GP col
# 5 - Remove rows where block is NA
# 6 - Remove duplicates
# 7 - Assign ID to rows


if(scheme_type=="urban"){
  geo_mapping <- read_csv("data/geography/raw/csv/OdishaUrban.csv",col_types = cols(.default = "c")) %>% data.frame(check.names = FALSE)
} else {
  geo_mapping <- read_csv("data/geography/raw/csv/Odisha_040621.csv")
}

# geo_mapping <- geo_mapping[!is.na(geo_mapping$`SL NO. for AC`),]

geo_mapping$g_match_id <- NULL
names(geo_mapping)[1:6] <- c("g_ac_id","g_ac","g_block","g_gp","g_district","g_pc")
geo_mapping <- geo_mapping %>% mutate_all(funs(str_replace_all(., "�", "")))
geo_mapping <- geo_mapping %>% mutate_all(funs(str_trim(str_to_lower(.))))
geo_mapping <- geo_mapping[!is.na(geo_mapping$g_block),]
geo_mapping <- unique(geo_mapping)
geo_mapping$g_match_id <- 1:nrow(geo_mapping)
# readr::write_csv(geo_mapping, file = "data/geography/updated/geo-odisha-updated.csv")
# readr::write_csv(geo_mapping, file = "data/geography/updated/geo-odisha-urban-updated.csv")

# District match ----------------------------------------------------------

all_districts <- unique(c(unique(scheme_data$s_district), unique(geo_mapping$g_district)))
district_in_scheme <- ifelse(all_districts %in% unique(scheme_data$s_district), 1, 0)
district_in_map <- ifelse(all_districts %in% unique(geo_mapping$g_district), 1, 0)
district_match_df <- data.frame("district_name"=all_districts, "district_in_scheme"=district_in_scheme,"district_in_map"=district_in_map)
district_match_df <- district_match_df %>% arrange(district_name)
district_match_df$updated_district_name <- ""
# readr::write_csv(district_match_df, file = "data/geography/raw/csv/2019-20/odisha-districts.csv")
# readr::write_csv(district_match_df, file = "data/geography/raw/csv/2018-19/odisha-districts.csv")
# readr::write_csv(district_match_df, file = "data/geography/raw/csv/2018-19/pmagy-odisha-districts.csv")
# readr::write_csv(district_match_df, file = "data/geography/raw/csv/2019-20/pmagy-odisha-districts.csv")
# readr::write_csv(district_match_df, file = "data/geography/raw/csv/2019-20/nsap-odisha-districts_IGNDPS.csv")
# readr::write_csv(district_match_df, file = "data/geography/raw/csv/2019-20/nsap-odisha-districts_IGNOAPS.csv")
# readr::write_csv(district_match_df, file = "data/geography/raw/csv/2019-20/nsap-odisha-districts_IGNWPS.csv")

# Read Odisha districts file with updated district names

# For districts that did not match becuase of a spelling error, 
# we have considered the spelling in the scheme file as the primary name 
# and replaced the corresponding districts in the geography file

# "nabrangpur" This district is present in the geography file but not in the scheme file

# odisha_districts <- readr::read_csv("data/geography/raw/csv/2019-20/odisha-districts.csv")
# odisha_districts <- readr::read_csv("data/geography/raw/csv/2018-19/odisha-districts.csv")
# odisha_districts <- readr::read_csv("data/geography/raw/csv/2018-19/pmagy-odisha-districts.csv")
# odisha_districts <- readr::read_csv("data/geography/raw/csv/2019-20/pmagy-odisha-districts.csv")
# odisha_districts <- readr::read_csv("data/geography/raw/csv/2019-20/nsap-odisha-districts_IGNDPS.csv")
# odisha_districts <- readr::read_csv("data/geography/raw/csv/2019-20/nsap-odisha-districts_IGNOAPS.csv")
odisha_districts <- readr::read_csv("data/geography/raw/csv/2019-20/nsap-odisha-districts_IGNWPS.csv")

# Update districts in the scheme file
odisha_districts_to_update <- odisha_districts[odisha_districts$district_in_map == 0,c('district_name','updated_district_name')] 
scheme_data <- left_join(scheme_data, odisha_districts_to_update, by=c('s_district'='district_name'))
scheme_data$updated_district_name[is.na(scheme_data$updated_district_name)] <- scheme_data$s_district[is.na(scheme_data$updated_district_name)]


# Block match -------------------------------------------------------------

scheme_blocks <- unique(scheme_data[,c("updated_district_name", "s_block")])
geo_blocks <- unique(geo_mapping[,c("g_district", "g_block")])


all_geo_districts <- unique(geo_blocks$g_district)
odisha_block_match <- data.frame()

for(i in 1:length(all_geo_districts)){
  geo_block_df <- geo_blocks[geo_blocks$g_district == all_geo_districts[[i]],]  
  scheme_block_df <- scheme_blocks[scheme_blocks$updated_district_name == all_geo_districts[[i]],]  

  geo_block_df <-
    geo_block_df %>% stringdist_left_join(scheme_block_df,
                                         by = c('g_block' = 's_block'),
                                         max_dist = 1,distance_col = 'distance_block' )

  geo_block_df$final_match <- 1
  geo_block_df$final_match[is.na(geo_block_df$s_block)] <- 0

  blocks_distance_0 <- geo_block_df %>% filter(distance_block == 0) %>% select(g_block) %>% pull() %>% unique()
  blocks_distance_gt0 <- geo_block_df %>% filter(distance_block > 0) %>% select(g_block) %>% pull() %>% unique()
  
  common_blocks <- dplyr::intersect(blocks_distance_0, blocks_distance_gt0)
  
  geo_block_df$final_match[geo_block_df$g_block %in% common_blocks & geo_block_df$distance_block>0] <- 0    
  
  
  blocks_one_to_many <- geo_block_df %>% filter(final_match==1) %>% group_by(g_block) %>% summarise(total_count=length(g_district)) %>% filter(total_count>1) %>% select(g_block) 
  blocks_one_to_many <- blocks_one_to_many$g_block[!is.na(blocks_one_to_many$g_block)]
  geo_block_df$final_match[geo_block_df$g_block %in% blocks_one_to_many] <- 0
  
  blocks_many_to_one <- geo_block_df %>% filter(final_match==1) %>%  group_by(s_block) %>% summarise(total_count=length(g_district)) %>% filter(total_count>1) %>% select(s_block) 
  blocks_many_to_one <- blocks_many_to_one$s_block[!is.na(blocks_many_to_one$s_block)]
  geo_block_df$final_match[geo_block_df$s_block %in% blocks_many_to_one] <- 0


odisha_block_match <- bind_rows(odisha_block_match, geo_block_df)
}

# Update blocks in the geography file
odisha_blocks_to_update <- odisha_block_match[odisha_block_match$final_match == 1,]
odisha_blocks_to_update$s_block_mapping <- odisha_blocks_to_update$s_block
odisha_blocks_to_update$s_block_mapping[odisha_blocks_to_update$distance == 1] <- odisha_blocks_to_update$g_block[odisha_blocks_to_update$distance == 1]


scheme_data <-
  left_join(
    scheme_data,
    odisha_blocks_to_update[, c("g_district", "s_block","s_block_mapping")],
    by = c("updated_district_name" = "g_district", "s_block" = "s_block")
  )
names(scheme_data)[which(names(scheme_data)=='s_block_mapping')] <- 'updated_block_name'

# GP match ----------------------------------------------------------------

odisha_gp_match <- data.frame()

for(i in 1:length(all_geo_districts)){
  all_geo_blocks <- unique(geo_mapping$g_block[geo_mapping$g_district == all_geo_districts[[i]]])
  # j <- 6
  for(j in 1:length(all_geo_blocks)){
    
    geo_gp_df <- unique(geo_mapping[geo_mapping$g_district == all_geo_districts[[i]] & geo_mapping$g_block == all_geo_blocks[[j]],c("g_district","g_block","g_gp")])
    scheme_gp_df <- scheme_data[scheme_data$updated_district_name == all_geo_districts[[i]] & scheme_data$updated_block_name == all_geo_blocks[[j]],]
    scheme_gp_df <- scheme_gp_df[!is.na(scheme_gp_df$s_gp),]
    
    geo_gp_df <-
      geo_gp_df %>% stringdist_left_join(scheme_gp_df[,c("updated_district_name", "updated_block_name", "s_gp")],
                                        by = c('g_gp' = 's_gp'),
                                        max_dist = 1,distance_col = 'distance')
    
  
    geo_gp_df$final_match <- 1
    geo_gp_df$final_match[is.na(geo_gp_df$s_gp)] <- 0
  
    gps_distance_0 <- geo_gp_df %>% filter(distance == 0) %>% select(g_gp) %>% pull() %>% unique()
    gps_distance_gt0 <- geo_gp_df %>% filter(distance > 0) %>% select(g_gp) %>% pull() %>% unique()
    
    common_gps <- dplyr::intersect(gps_distance_0, gps_distance_gt0)
    
    geo_gp_df$final_match[geo_gp_df$g_gp %in% common_gps & geo_gp_df$distance>0] <- 0    
      
    gps_one_to_many <- geo_gp_df %>% filter(final_match==1) %>% group_by(g_gp) %>% summarise(total_count=length(g_district)) %>% filter(total_count>1) %>% select(g_gp)
    gps_one_to_many <- gps_one_to_many$g_gp[!is.na(gps_one_to_many$g_gp)]
    geo_gp_df$final_match[geo_gp_df$g_gp %in% gps_one_to_many] <- 0
    
    gps_many_to_one <- geo_gp_df %>% filter(final_match==1) %>% group_by(s_gp) %>% summarise(total_count=length(g_district)) %>% filter(total_count>1) %>% select(s_gp)
    gps_many_to_one <- gps_many_to_one$s_gp[!is.na(gps_many_to_one$s_gp)]
    geo_gp_df$final_match[geo_gp_df$s_gp %in% gps_many_to_one] <- 0
    
    
    odisha_gp_match <- bind_rows(odisha_gp_match, geo_gp_df)
    
  }
}

# What matched directly or fuzzy within a distance of 1

odisha_gp_match_result <- odisha_gp_match[odisha_gp_match$final_match == 1,]
odisha_gp_match_result$s_gp_mapping <- odisha_gp_match_result$s_gp
odisha_gp_match_result$s_gp_mapping[odisha_gp_match_result$distance == 1] <- odisha_gp_match_result$g_gp[odisha_gp_match_result$distance == 1]

scheme_data <-
  left_join(
    scheme_data,
    odisha_gp_match_result[, c("g_district","g_block","s_gp","s_gp_mapping")],
    by = c("updated_district_name" = "g_district", "updated_block_name" = "g_block","s_gp"="s_gp")
  )

names(scheme_data)[which(names(scheme_data)=='s_gp_mapping')] <- 'updated_gp_name'


# Updating scheme files - Write to disk -----------------------------------

# readr::write_csv(scheme_data, "data/scheme/MNREGA/odisha/2019-20/updated/odisha-mnrega-2019-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/MNREGA/odisha/2018-19/updated/odisha-mnrega-2018-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/PMAGY/odisha/2018-19/updated/odisha-pmagy-2018-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/PMAGY/odisha/2019-20/updated/odisha-pmagy-2019-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/NSAP/odisha/2019-20/updated/odisha-nsap-IGNDPS-2019-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/NSAP/odisha/2019-20/updated/odisha-nsap-IGNOAPS-2019-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/NSAP/odisha/2019-20/updated/odisha-nsap-IGNWPS-2019-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/NSAP/odisha/2019-20/updated/odisha-nsap-IGNDPS-urban-2019-updated.csv")
# readr::write_csv(scheme_data, "data/scheme/NSAP/odisha/2019-20/updated/odisha-nsap-IGNOAPS-urban-2019-updated.csv")
readr::write_csv(scheme_data, "data/scheme/NSAP/odisha/2019-20/updated/odisha-nsap-IGNWPS-urban-2019-updated.csv")
