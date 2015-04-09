########################################################################################################################################

library(twitteR)   #Este paquete provee una interfaz entre R y el web API de Twitter
library(RCurl)     #Permite hacer las peticiones http para analizar las URL de Twitter
library(stringr)   #Ayuda con el manejo de string para tokenizar los tweets
library(RJSONIO)   #install.packages('RJSONIO', dependencies = TRUE)  #Permite la creacion/conversion de objetos javascript
library(tm)        #install.packages('RJSONIO', dependencies = TRUE)  #Ayuda a realizar el analisis de texto
library(wordcloud) #install.packages('RJSONIO', dependencies = TRUE)  #Genera graficos con texto

########################################################################################################################################

#Claves para autentificar el acceso a la aplicacion
api_key             = "L1xbk85CKbvtZpuI6DC9L3c3U"
api_secret          = "tjmq76hWIgpw7ZaYaMOzVpFq7RRxcfpWpf11ZFZCybYbth5LLx"
access_token        = "158590874-WG6Bo3wi09Tzj6yZWxo8QtTm4C4FeLNhujndXjTh"
access_token_secret = "YvV3KsomGL8QmqaqkoVlLsjBYS0AzgbQ03EJZbcPRNYE5"
setup_twitter_oauth(api_key,api_secret,access_token,access_token_secret)

db_key = c("a993d2f87264397216f3f0dd212f1033")
########################################################################################################################################
#Funcion que hace la peticion de datos y mandar llamar a datumbox.

getSentiment <- function (text, key){
  text <- URLencode(text);
  #Tokenizo el texto y elimino los caracteres que el API no identifica (no ASCII) y al final vuelvo a armar un codigo URL añadiendo espacios
  text <- str_replace_all(text, "%20", " "); # ----> uniform resource locator %20 == " " en base de datos
  text <- str_replace_all(text, "%\\d\\d", "");
  text <- str_replace_all(text, " ", "%20");
  
  
  if (str_length(text) > 360){
    text <- substr(text, 0, 359);
  }
  ##########################################
  data <- getURL(paste("http://api.datumbox.com/1.0/TwitterSentimentAnalysis.json?api_key=", key, "&text=",text, sep=""))
  js <- fromJSON(data, asText=TRUE); #notación de objetos de JavaScript
  
  # Obtengo la probabilidad del sentimiento
  sentiment = js$output$result
  #########################################
  
  return(list(sentiment=sentiment))
}


########################################################################################################################################

clean.text <- function(str){
  #Se eliminan caracteres y cadenas de caracteres que no funcionan para el analisis
  str = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", str)
  str = gsub("@\\w+", "", str)
  str = gsub("[[:punct:]]", "", str)
  str = gsub("[[:digit:]]", "", str)
  str = gsub("http\\w+", "", str)
  str = gsub("[ \t]{2,}", "", str)
  str = gsub("^\\s+|\\s+$", "", str)
  str = gsub("amp", "", str)
  
  # utilizo la funcion "tolower" para el manejo de errores cuando no se pueden mapear caracteres unicode " ✈\ud83d\ "
  try.tolower = function(x){
    y = NA
    try_error = tryCatch(tolower(x), error=function(e) e)
    if (!inherits(try_error, "error"))
      y = tolower(x)
    return(y)
  }
  
  str = sapply(str, try.tolower)
  str = str[str != ""]
  names(str) = NULL
  return(str)
}

########################################################################################################################################



print("Obteniendo tweets...")
# searchTwitter busca un total de N tweets que contengan la palabra especifica en cierto idioma
tweets = searchTwitter("obama", 30, lang="en")
# Se convierten los tweets obtenidos
tweet_txt = sapply(tweets, function(x) x$getText())

# Se limpia el texto para analizar solo las palabras reales
tweet_clean = clean.text(tweet_txt)
tweet_num   = length(tweet_clean)
# data frame (text, sentiment)
tweet_df = data.frame(text=tweet_clean, sentiment=rep("", tweet_num),stringsAsFactors=FALSE)

print("Obteniendo analisis de sentimento...")
# Aplico la función 'getSentiment'
sentiment = rep(0, tweet_num)
for (i in 1:tweet_num){
  tmp = getSentiment(tweet_clean[i], db_key)
  tweet_df$sentiment[i] = tmp$sentiment
  #Debug
  print(paste(i," of ", tweet_num))
}

# Borra los renglones que tuvieron palabras excluidas
tweet_df <- tweet_df[tweet_df$sentiment!="",]


#Separo text por sentimientos
sents = levels(factor(tweet_df$sentiment))
#ems_label <- ems


# Obtiene las etiquetas y porcentajes de las emociones
labels <-  lapply(sents, function(x) paste(x,format(round((length((tweet_df[tweet_df$sentiment ==x,])$text)/length(tweet_df$sentiment)*100),2),nsmall=2),"%"))

num_em = length(sents)
em.docs = rep("", num_em)

for (i in 1:num_em){
  tmp = tweet_df[tweet_df$sentiment == sents[i],]$text
  em.docs[i] = paste(tmp,collapse=" ")
}

# eliminar stopwords (palabras en otro idioma)
em.docs = removeWords(em.docs, stopwords("german"))
em.docs = removeWords(em.docs, stopwords("spanish"))
corpus = Corpus(VectorSource(em.docs))  #obtiene repeticiones de cada palabra y de aqui en adelante guardo la información en una matriz
tdm = TermDocumentMatrix(corpus)
tdm = as.matrix(tdm)  
colnames(tdm) = labels

# comparison.cloud obtiene el numero de columnas en la matriz e imprime las palabras de acuerdo a las propiedades
comparison.cloud(tdm, colors = brewer.pal(num_em, "Dark2"), scale = c(3,.5), random.order = FALSE, title.size = 1.5)