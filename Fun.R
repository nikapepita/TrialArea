##Fun and Stuff from Twitter:


#plot landscape (by Andrew Heiss)
#library(tidyverse)

beach_picture <- tribble(
  ~slice, ~angle,
  "Sky", 160,
  "Mountains", 20,
  "Grass", 25,
  "Road", 50,
  "Sidewalk", 20,
  "Beach", 60,
  "Ocean", 25
) %>% 
  mutate(slice=fct_inorder(slice),
         angle=angle/360)

ggplot(beach_picture, aes(x = "",y = angle, fill = slice))+
  geom_bar(width = 1, stat = "identity")+
  scale_fill_manual(values = c("#7292CB","#168A46","#22B34A","grey20", "grey80","#FFCE05","#3E69B2"),
                    name = NULL) +
  coord_polar(theta = "y", start = pi / 2, direction = -1)+
  theme_void()