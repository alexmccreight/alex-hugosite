library(tidycensus)
library(tidyverse)
library(sf)
options(tigris_use_cache = TRUE)
#census_api_key("FILL IN") # to get your own data, you need a Census API key (https://walker-data.com/tidycensus/articles/basic-usage.html)

v19<-load_variables(2019, "acs5", cache = TRUE)  
View(v19)

VARS <- c(Income = "B19013_001", Pop = 'B01003_001', Age = "B01002_001", HouseValue = "B25077_001",HouseholdSize = "B25010_001",NumHouse = "B25003_001")

ramsey_quant <- get_acs(state = "MN", county = "Ramsey", geography = "tract", 
                  variables = VARS, geometry = TRUE, output='wide')

ramsey_quant <- ramsey_quant %>% select(-ends_with('M'))

#BirthPlace: B06001_001
#Industry: 	C24070_001
#Renter/Owner: B25010_001
#Race: B02001_001
get_ramsey_data <- function(V,V1,NAMES){
  ramsey_cat <- get_acs(state = "MN", county = "Ramsey", geography = "tract", 
                        variables = V, geometry = FALSE, output='wide',summary_var = V1)
 
  ramsey_cat %>% 
    select(-ends_with('M')) %>%
    mutate(Total = select(.,-c(GEOID,NAME,summary_est,summary_moe)) %>% rowSums(na.rm=TRUE)) %>%
    mutate(across(-c(GEOID,NAME,summary_est,summary_moe), ~.x/ramsey_cat$summary_est)) %>%
    select(-c(summary_est,summary_moe,Total))
}


V1 <- "C24070_001"
V <- paste0("C24070_0",str_pad(c(2:14),2,"0",side='left'))
NAMES <- v19 %>% filter(name %in% V) %>% pull(label) %>% str_replace('Estimate\\!\\!Total\\:\\!\\!','')
industry = get_ramsey_data(V,V1,NAMES)
names(industry) = c('GEOID','NAME',paste0('Industry_',str_sub(NAMES,0,5)))
NMS <- c(VARS,V)

V1 <- "B06001_001"
V <- paste0("B06001_0",str_pad(c(13,25,37,49),2,"0",side='left'))
NAMES <- v19 %>% filter(name %in% V) %>% pull(label) %>% str_replace('Estimate\\!\\!Total\\:\\!\\!','')
birthplace = get_ramsey_data(V,V1,NAMES)
names(birthplace) = c('GEOID','NAME',trimws(paste0('BirthPlace_',str_sub(NAMES,0,20))))
NMS <- c(NMS,V)

V1 <- "B25003_001"
V <- paste0("B25003_0",str_pad(c(2:3),2,"0",side='left'))
NAMES <- v19 %>% filter(name %in% V) %>% pull(label) %>% str_replace('Estimate\\!\\!Total\\:\\!\\!','')
housetype = get_ramsey_data(V,V1,NAMES)
names(housetype) = c('GEOID','NAME',trimws(paste0('HouseType_',str_sub(NAMES,0,20))))
NMS <- c(NMS,V)


V1 <- "B02001_001"
V <- paste0("B02001_0",str_pad(c(2:8),2,"0",side='left'))
NAMES <- v19 %>% filter(name %in% V) %>% pull(label) %>% str_replace('Estimate\\!\\!Total\\:\\!\\!','')
race = get_ramsey_data(V,V1,NAMES)
names(race) = c('GEOID','NAME',trimws(paste0('Race_',str_sub(NAMES,0,26))))
NMS <- c(NMS,V)

ramsey_data <- ramsey_quant %>% left_join(birthplace) %>% left_join(industry) %>% left_join(housetype) %>% left_join(race)


colleges <- read_csv('hd2020.csv')
colleges <- sf::st_as_sf(colleges,coords = c('LONGITUD','LATITUDE'))
st_crs(colleges) <- ramsey_data %>% st_crs()

col_coord <- data.frame(st_coordinates(colleges))

colleges_sub <- colleges[col_coord$X > st_bbox(ramsey_data)$xmin &  col_coord$X < st_bbox(ramsey_data)$xmax & col_coord$Y > st_bbox(ramsey_data)$ymin &  col_coord$Y < st_bbox(ramsey_data)$ymax,]

#Approx 1/2 mile radius
ramsey_data$NumColleges <- st_intersects(ramsey_data,st_buffer(colleges_sub,dist=800)) %>% lengths()

areawater <- read_sf('areawater') 
roads <- read_sf('roads')
roads <- st_transform(roads,crs = st_crs(ramsey_data))
roads_sub <- roads %>% filter( (st_intersects(roads,ramsey_data) %>% lengths()) > 0)

#library(crsuggest)
#suggest_crs(ramsey_data)

colleges_sub <- st_transform(colleges_sub,crs = 6505)
ramsey_data <- st_transform(ramsey_data,crs = 6505)
ramsey_data$AREA = st_area(ramsey_data) %>% as.vector()
areawater <- st_transform(areawater,crs=6505) %>% filter(AWATER > 65000)
roads_sub <- st_transform(roads_sub,crs=6505) %>% filter(RTTYP %in% c('U','I'))
roads_sub <- st_crop(roads_sub,st_bbox(ramsey_data))

ramsey_data$DistToRiver = st_distance(ramsey_data,areawater %>% filter(FULLNAME == 'Mississippi Riv')) %>% as.vector()

distToRoads <- st_distance(ramsey_data,roads_sub) %>% units::drop_units() %>% as.matrix() 

ramsey_data$MinDistToHwy = distToRoads %>% apply(1,min)
ramsey_data$NumHwys = distToRoads %>% apply(1,function(v) length(unique(roads_sub$FULLNAME[v == 0])))
ramsey_data$AnyHwys = ramsey_data$NumHwys > 0

ramsey_data <- ramsey_data %>% filter(!is.na(HouseValueE))

CodeBook <- v19 %>% filter(name %in% NMS)

save(colleges_sub,ramsey_data,areawater,roads_sub,CodeBook,file = 'SpatialData.RData')





## Plotting

ramsey_data %>%
  ggplot() + 
  geom_sf(aes(fill = `Race_White alone`),alpha=.7,color='white',size = .2) + 
  geom_sf(data=colleges_sub,color = 'black') + 
  geom_sf(data=areawater,color='lightblue',fill='lightblue')+
  geom_sf(data=roads_sub, color = 'yellow')+
  scale_fill_viridis_c(option = "magma") + 
  coord_sf(xlim = st_bbox(ramsey_data)[c(1,3)], # min & max of x values
           ylim = st_bbox(ramsey_data)[c(2,4)]) +
  labs(fill = 'Percent White Only', title='2015-2019 ACS Data') +
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = AgeE)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = DistToRiver)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = HouseValueE)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = AREA)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = NumHouseE)) + #Number of Households 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = NumHouseE/AREA)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = PopE/AREA)) +  #population density
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = PopE/NumHouseE)) + #Population per Household
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = HouseholdSizeE)) + #Average Household Size
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = `HouseType_Owner occupied`)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = `HouseType_Renter occupied`)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = PopE)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = IncomeE)) + #Median Income
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()


ramsey_data %>%
  ggplot(aes(fill = `BirthPlace_Born in state of res`)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = `BirthPlace_Born in other state`)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()


ramsey_data %>%
  ggplot(aes(fill = `BirthPlace_Foreign born:`)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>%
  ggplot(aes(fill = `BirthPlace_Native; born outside`)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()


ramsey_data %>%
  ggplot(aes(fill = `Industry_Publi`)) + 
  geom_sf(color = NA) + 
  scale_fill_viridis_c(option = "magma") + 
  theme_classic()

ramsey_data %>% ggplot()+
  geom_boxplot(aes(y = AgeE, x = factor(NumColleges)))

ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = IncomeE, color = factor(NumColleges))) +
  theme_classic()

ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = HouseholdSizeE, color = factor(NumColleges))) +
  theme_classic()

ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = `BirthPlace_Born in state of res`, color = factor(NumColleges))) +
  theme_classic()

ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = `BirthPlace_Born in other state`, color = factor(NumColleges))) +
  theme_classic()

ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = `BirthPlace_Foreign born:`, color = factor(NumColleges))) +
  theme_classic()

ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = `Industry_Const`, color = factor(NumColleges))) +
  theme_classic()


ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = `Industry_Manuf`, color = factor(NumColleges))) +
  theme_classic()

ramsey_data %>% ggplot()+
  geom_point(aes(y = HouseValueE, x = `Industry_Educa`, color = factor(NumColleges))) +
  theme_classic()

ramsey_data %>% ggplot(aes(y = HouseValueE, x = `Industry_Profe`))+
  geom_point() +
  geom_smooth(se = FALSE)+
  theme_classic()
