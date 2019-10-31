Eagle2019 <- c("Annika","Helena","Larissa","Luisa","Jakob","Marius","James","Nils","Kevin","Kemeng","Diego", "Chris",
               "Sofia","Antonio","Waldi","Sanaz")
length(Eagle2019)

for (i in 1:length(Eagle2019)) {
  volunteer<-sample(Eagle2019,1)
  Eagle2019 <-Eagle2019 [Eagle2019  != volunteer]
  print(paste("It's your turn,", volunteer)) 
  }



