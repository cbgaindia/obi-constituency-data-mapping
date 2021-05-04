check_geo_mapping <- function(){
  x <- geo_mapping %>% group_by(g_match_id) %>% summarise(n()) %>% filter(`n()`>1) %>% select(1)
  return(x)
}
