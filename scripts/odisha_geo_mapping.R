source("scripts/libraries.R")

## Import and Process files (Standaridse geography vars)

scheme_data <- read_csv("data/scheme-data/csv/MGNREGA-Odisha-2019-20.csv")
scheme_data <- scheme_data[,c(1,2,3,5)]
names(scheme_data)[] <- c("s_state","s_district","s_block","s_gp") 
scheme_data <- scheme_data %>% mutate_all(funs(str_replace_all(., "�", "")))
scheme_data <- scheme_data %>% mutate_all(funs(str_trim(str_to_lower(.))))

# Remove unwanted rows
scheme_data <- scheme_data %>% filter(!s_gp %in% c('total','block level line deptt.','po','grand total'))

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
geo_mapping <- unique(geo_mapping)
geo_mapping$g_match_id <- 1:nrow(geo_mapping)


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


all_scheme_districts <- unique(scheme_blocks$s_district)
odisha_block_match <- data.frame()
for(i in 1:length(all_scheme_districts)){
geo_block_df <- geo_blocks[geo_blocks$updated_district_name == all_scheme_districts[[i]],]  

scheme_block_df <- scheme_blocks[scheme_blocks$s_district == all_scheme_districts[[i]],]
scheme_block_df <-
  scheme_block_df %>% stringdist_left_join(geo_block_df,
                                         by = c('s_block' = 'g_block'),
                                         max_dist = 1,distance_col = 'distance_block' )

scheme_block_df$final_match <- 1
scheme_block_df$final_match[is.na(scheme_block_df$g_block)] <- 0

blocks_one_to_many <- scheme_block_df %>% group_by(s_block) %>% summarise(total_count=length(s_district)) %>% filter(total_count>1) %>% select(s_block) 
blocks_one_to_many <- blocks_one_to_many$s_block[!is.na(blocks_one_to_many$s_block)]
scheme_block_df$final_match[scheme_block_df$s_block %in% blocks_one_to_many] <- 0

blocks_many_to_one <- scheme_block_df %>% group_by(g_block) %>% summarise(total_count=length(s_district)) %>% filter(total_count>1) %>% select(g_block) 
blocks_many_to_one <- blocks_many_to_one$g_block[!is.na(blocks_many_to_one$g_block)]
scheme_block_df$final_match[scheme_block_df$s_block %in% blocks_many_to_one] <- 0


odisha_block_match <- bind_rows(odisha_block_match, scheme_block_df)
}

# Update blocks in the geography file
odisha_blocks_to_update <- odisha_block_match[odisha_block_match$final_match == 1,]
odisha_blocks_to_update$g_block_mapping <- odisha_blocks_to_update$g_block
odisha_blocks_to_update$g_block_mapping[odisha_blocks_to_update$distance == 1] <- odisha_blocks_to_update$s_block[odisha_blocks_to_update$distance == 1]


geo_mapping <-
  left_join(
    geo_mapping,
    odisha_blocks_to_update[, c("s_district", "g_block","g_block_mapping")],
    by = c("updated_district_name" = "s_district", "g_block" = "g_block")
  )
names(geo_mapping)[which(names(geo_mapping)=='g_block_mapping')] <- 'updated_block_name'

# GP match

odisha_gp_match <- data.frame()

# which(all_scheme_districts == "bhadrak")
# i <- 22

for(i in 1:length(all_scheme_districts)){
  all_scheme_blocks <- unique(scheme_data$s_block[scheme_data$s_district == all_scheme_districts[[i]]])
  # j <- 6
  for(j in 1:length(all_scheme_blocks)){
    scheme_gp_df <- scheme_data[scheme_data$s_district == all_scheme_districts[[i]] & scheme_data$s_block == all_scheme_blocks[[j]],]  
    geo_gp_df <- unique(geo_mapping[geo_mapping$updated_district_name == all_scheme_districts[[i]] & geo_mapping$updated_block_name == all_scheme_blocks[[j]],c("g_district","g_block","g_gp")])
    geo_gp_df <- geo_gp_df[!is.na(geo_gp_df$g_gp),]
    scheme_gp_df <-
      scheme_gp_df %>% stringdist_left_join(geo_gp_df[,c("g_district", "g_block", "g_gp")],
                                        by = c('s_gp' = 'g_gp'),
                                        max_dist = 1,distance_col = 'distance')
    
    scheme_gp_df$final_match <- 1
    scheme_gp_df$final_match[is.na(scheme_gp_df$g_gp)] <- 0
    gps_one_to_many <- scheme_gp_df %>% group_by(s_gp) %>% summarise(total_count=length(s_state)) %>% filter(total_count>1) %>% select(s_gp)
    gps_one_to_many <- gps_one_to_many$s_gp[!is.na(gps_one_to_many$s_gp)]
    scheme_gp_df$final_match[scheme_gp_df$s_gp %in% gps_one_to_many] <- 0
    gps_many_to_one <- scheme_gp_df %>% group_by(g_gp) %>% summarise(total_count=length(s_state)) %>% filter(total_count>1) %>% select(g_gp)
    gps_many_to_one <- gps_many_to_one$g_gp[!is.na(gps_many_to_one$g_gp)]
    scheme_gp_df$final_match[scheme_gp_df$g_gp %in% gps_many_to_one] <- 0
    
    
    odisha_gp_match <- bind_rows(odisha_gp_match, scheme_gp_df)
    
  }
}

# What matched directly or fuzzy within a distance of 1

odisha_gp_match_result <- odisha_gp_match[odisha_gp_match$final_match == 1,]
odisha_gp_match_result$g_gp_mapping <- odisha_gp_match_result$g_gp
odisha_gp_match_result$g_gp_mapping[odisha_gp_match_result$distance == 1] <- odisha_gp_match_result$s_gp[odisha_gp_match_result$distance == 1]

geo_mapping <-
  left_join(
    geo_mapping,
    odisha_gp_match_result[, c("s_district","s_block","g_gp","g_gp_mapping")],
    by = c("updated_district_name" = "s_district", "updated_block_name" = "s_block","g_gp"="g_gp")
  )

names(geo_mapping)[which(names(geo_mapping)=='g_gp_mapping')] <- 'updated_gp_name'

# Summary of the mapping exercise

state_mapping_summary <- data.frame()
all_districts <- unique(scheme_data$s_district) 
p <- progress::progress_bar$new(total = length(all_districts))
for(i in 1:length(all_districts)){
  p$tick()
  district_summary <- data.frame()
  select_district <- all_districts[[i]]
  district_mapped <- ifelse(select_district %in% unique(geo_mapping$updated_district_name),"yes","no")
  blocks <- unique(scheme_data$s_block[scheme_data$s_district == select_district])
  total_blocks <- length(blocks)
  total_blocks_mapped <- unique(geo_mapping$updated_block_name[geo_mapping$updated_district_name == select_district & !is.na(geo_mapping$updated_block_name)]) %>% length()
  for(j in 1:length(blocks)){
    select_block <- blocks[j]
    block_mapped <- ifelse(select_block %in% unique(geo_mapping$updated_block_name),"yes","no")
    total_gps <- scheme_data %>% filter(s_district==select_district, s_block==select_block) %>% select(s_gp) %>% unique() %>% nrow()
    total_gps_mapped <- geo_mapping %>%  filter(updated_district_name==select_district, updated_block_name==select_block, !is.na(updated_gp_name)) %>% select(updated_gp_name) %>% nrow()
    block_df <- data.frame('district'=select_district, 'district_mapped'=district_mapped,'block'=select_block, 'block_mapped'=block_mapped,'total_gps' = total_gps, 'total_gps_mapped'=total_gps_mapped)
    district_summary <- bind_rows(district_summary, block_df)
  }
  state_mapping_summary <- bind_rows(state_mapping_summary, district_summary)
}

state_mapping_summary <- state_mapping_summary %>% mutate(gp_mapping_percent=round(total_gps_mapped/total_gps*100)) 
readr::write_csv(state_mapping_summary, "data/Results/odisha.csv")
