source("scripts/libraries.R")

## Import and Process files (Standaridse geography vars)

scheme_data <- read_csv("data/scheme-data/csv/MGNREGA-Odisha-2019-20.csv")
scheme_data <- scheme_data[,c(1,2,3,5)]
names(scheme_data)[] <- c("s_state","s_district","s_block","s_gp") 
scheme_data <- scheme_data %>% mutate_all(funs(str_replace_all(., "�", "")))
scheme_data <- scheme_data %>% mutate_all(funs(str_trim(str_to_lower(.))))


geo_mapping <- read_csv("data/geography-mapping-cbga/csv/Odisha.csv", 
                   col_types = cols(`Notified Area Council (NAC)` = col_skip(), 
                                    `Municipality (M)` = col_skip(), 
                                    `Municipal Corporation (MC)` = col_skip(), 
                                    `Outgrowth (OG)` = col_skip(), `Wards of ULBs` = col_skip(), 
                                    `Sl. No. of PCs` = col_skip(), REMARKS = col_skip()))
geo_mapping <- geo_mapping[!is.na(geo_mapping$`SL NO. for AC`),]
names(geo_mapping) <- c("g_ac_id","g_ac","g_block","g_gp","g_district","g_pc")
geo_mapping <- geo_mapping %>% mutate_all(funs(str_replace_all(., "�", "")))
geo_mapping <- geo_mapping %>% mutate_all(funs(str_trim(str_to_lower(.))))
geo_mapping <- geo_mapping[!is.na(geo_mapping$g_block),]

# District match

all_districts <- unique(c(unique(scheme_data$s_district), unique(geo_mapping$g_district)))
district_in_scheme <- ifelse(all_districts %in% unique(scheme_data$s_district), 1, 0)
district_in_map <- ifelse(all_districts %in% unique(geo_mapping$g_district), 1, 0)
district_match_df <- data.frame("district_name"=all_districts, "district_in_scheme"=district_in_scheme,"district_in_map"=district_in_map)
district_match_df <- district_match_df %>% arrange(district_name)
district_match_df$updated_district_name <- ""
readr::write_csv(district_match_df, file = "data/geography-mapping-cbga/csv/odisha-districts.csv")

# Read Odisha districts file with updated district names

# For districts that did not match becuase of a spelling error, 
# we have considered the spelling in the scheme file as the primary name 
# and replaced the corresponding districts in the geography file

# "nabrangpur" This district is present in the geography file but not in the scheme file

odisha_districts <- readr::read_csv("data/geography-mapping-cbga/csv/odisha-districts.csv")

# Update districts in the geography file
odisha_districts_to_update <- odisha_districts[odisha_districts$district_in_scheme == 0,c('district_name','updated_district_name')] 
geo_mapping <- left_join(geo_mapping, odisha_districts_to_update, by=c('g_district'='district_name'))
geo_mapping$updated_district_name[is.na(geo_mapping$updated_district_name)] <- geo_mapping$g_district[is.na(geo_mapping$updated_district_name)]


# Block match
scheme_blocks <- unique(scheme_data[,c("s_district", "s_block")])
geo_blocks <- unique(geo_mapping[,c("updated_district_name", "g_block")])
odisha_blocks <- left_join(scheme_blocks, geo_blocks, by=c('s_district'='updated_district_name', 's_block'='g_block'),keep = T)


# Fuzzy Match

all_scheme_districts <- unique(odisha_blocks$s_district)
odisha_block_match <- data.frame()
block_original_rows <- 0
for(i in 1:length(all_scheme_districts)){
block_df <- odisha_blocks[odisha_blocks$s_district == all_scheme_districts[[i]],]  
block_original_rows <- block_original_rows + nrow(block_df)
geo_df <- geo_blocks[geo_blocks$updated_district_name == all_scheme_districts[[i]],]
block_df <-
  block_df %>% stringdist_left_join(geo_df[,"g_block"],
                                         by = c('s_block' = 'g_block'),
                                         max_dist = 1)
names(block_df)[which(names(block_df)=='g_block.x')] <- 'block_direct_match'
names(block_df)[which(names(block_df)=='g_block.y')] <- 'block_fuzzy_match'
odisha_block_match <- bind_rows(odisha_block_match, block_df)
}

# Update blocks in the geography file
odisha_blocks_to_update <- odisha_block_match[!is.na(odisha_block_match$block_fuzzy_match),]
geo_mapping <-
  left_join(
    geo_mapping,
    odisha_blocks_to_update[, c("s_district", "block_fuzzy_match", "s_block")],
    by = c("updated_district_name" = "s_district", "g_block" = "block_fuzzy_match")
  )
names(geo_mapping)[which(names(geo_mapping)=='s_block')] <- 'updated_block_name'

# GP match

x <- unique(geo_mapping[,c("g_district", "g_block", "updated_district_name", "updated_block_name")])



