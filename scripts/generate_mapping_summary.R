
# Source Libraries --------------------------------------------------------

source("scripts/libraries.R")

# Read Files --------------------------------------------------------------

geo_mapping <- readr::read_csv(file = "data/geography/updated/geo-odisha-updated.csv")

# scheme_data <- readr::read_csv(file="data/scheme/MNREGA/odisha/2018-19/updated/odisha-mnrega-2018-updated.csv")
# scheme_data <- readr::read_csv(file="data/scheme/MNREGA/odisha/2019-20/updated/odisha-mnrega-2019-updated.csv")
# scheme_data <- readr::read_csv(file="data/scheme/PMAGY/odisha/2018-19/updated/odisha-pmagy-2018-updated.csv")
scheme_data <- readr::read_csv(file="data/scheme/PMAGY/odisha/2019-20/updated/odisha-pmagy-2019-updated.csv")

# Export mapping results --------------------------------------------------

state_mapping_summary <- data.frame()
p <- progress::progress_bar$new(total = nrow(geo_mapping))
for (i in 1:nrow(geo_mapping)) {
  p$tick()
  # print(i)
  map_id <- geo_mapping$g_match_id[i]
  scheme_geo_entity_id <- ""
  select_district <- geo_mapping$g_district[[i]]
  district_mapped <-
    ifelse(select_district %in% unique(scheme_data$updated_district_name),
           "yes",
           "no")
  if (district_mapped == "yes") {
    scheme_data_sub <-
      scheme_data[scheme_data$updated_district_name == select_district,]
    select_block <- geo_mapping$g_block[i]
    block_mapped <-
      ifelse(select_block %in% unique(scheme_data_sub$updated_block_name),
             "yes",
             "no")
    if (block_mapped == "yes") {
      scheme_data_sub_sub <-
        scheme_data_sub[scheme_data_sub$updated_block_name == select_block,]
      select_gp <- geo_mapping$g_gp[i]
      gp_mapped <-
        ifelse(select_gp %in% unique(scheme_data_sub_sub$updated_gp_name),
               "yes",
               "no")
      scheme_geo_entity_id <- scheme_data_sub_sub$s_id[scheme_data_sub_sub$updated_gp_name == select_gp]
    } else {
      gp_mapped <- "no"
    }
  } else {
    block_mapped <-  "no"
    gp_mapped <- "no"
  }
  state_mapping_summary <-
    bind_rows(
      state_mapping_summary,data.frame(
      "g_match_id" = map_id,
      "district_mapped" = district_mapped,
      "block_mapped" = block_mapped,
      "gp_mapped" = gp_mapped,
      "s_id" = scheme_geo_entity_id
    ))
}

state_mapping_summary <- left_join(state_mapping_summary, geo_mapping, by='g_match_id')
state_mapping_summary <-
  state_mapping_summary[, c(
    "g_match_id",
    "s_id",
    "g_district",
    "district_mapped",
    "g_block",
    "block_mapped",
    "g_gp",
    "gp_mapped",
    "g_ac_id",
    "g_ac",
    "g_pc"
  )]

# readr::write_csv(state_mapping_summary, "data/results/mnrega-2018-19-geography-mapping-summary.csv")
# readr::write_csv(state_mapping_summary, "data/results/mnrega-2019-20-geography-mapping-summary.csv")
# readr::write_csv(state_mapping_summary, "data/results/pmagy-2018-19-geography-mapping-summary.csv")
readr::write_csv(state_mapping_summary, "data/results/pmagy-2019-20-geography-mapping-summary.csv")
