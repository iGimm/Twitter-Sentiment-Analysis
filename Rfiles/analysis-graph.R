########################################################################################################################################
#connect all libraries
library(twitteR)
library(ROAuth)
library(plyr)
library(dplyr)
library(stringr)
library(ggplot2)

########################################################################################################################################

#Claves para autentificar el acceso a la aplicacion
api_key             = "L1xbk85CKbvtZpuI6DC9L3c3U"
api_secret          = "tjmq76hWIgpw7ZaYaMOzVpFq7RRxcfpWpf11ZFZCybYbth5LLx"
access_token        = "158590874-WG6Bo3wi09Tzj6yZWxo8QtTm4C4FeLNhujndXjTh"
access_token_secret = "YvV3KsomGL8QmqaqkoVlLsjBYS0AzgbQ03EJZbcPRNYE5"
setup_twitter_oauth(api_key,api_secret,access_token,access_token_secret)

########################################################################################################################################
search <- function(searchterm){
  #access tweets and create cumulative file
  list = searchTwitter(searchterm, cainfo='cacert.pem', n=30)
  df   = twListToDF(list)
  df   = df[, order(names(df))]
  df$created = strftime(df$created, '%Y-%m-%d')
  
  if (file.exists(paste(searchterm, '_stack.csv'))==FALSE) write.csv(df, file=paste(searchterm, '_stack.csv'), row.names=F)
  #merge last access with cumulative file and remove duplicates
  stack <- read.csv(file=paste(searchterm, '_stack.csv'))
  stack <- rbind(stack, df)
  stack <- subset(stack, !duplicated(stack$text))
  write.csv(stack, file=paste(searchterm, '_stack.csv'), row.names=F)
  
  #evaluation tweets function
  score.sentiment <- function(sentences, pos.words, neg.words, .progress='none'){
    require(plyr)
    require(stringr)
    scores <- laply(sentences, function(sentence, pos.words, neg.words){
      sentence <- gsub('[[:punct:]]', "", sentence)
      sentence <- gsub('[[:cntrl:]]', "", sentence)
      #sentence <- gsub('\d+', "", sentence)
      sentence <- tolower(sentence)
      word.list <- str_split(sentence, '\s+')
      words <- unlist(word.list)
      pos.matches <- match(words, pos.words)
      neg.matches <- match(words, neg.words)
      pos.matches <- !is.na(pos.matches)
      neg.matches <- !is.na(neg.matches)
      score <- sum(pos.matches) - sum(neg.matches)
      return(score)
    }, pos.words, neg.words, .progress=.progress)
    scores.df <- data.frame(score=scores, text=sentences)
    return(scores.df)
  }
  
  pos <- scan('/Users/iGimm/Developer/outer_files/negative-words.txt', what='character', comment.char=';') #folder with positive dictionary
  neg <- scan('/Users/iGimm/Developer/outer_files/positive-words.txt', comment.char=';') #folder with negative dictionary
  #pos.words <- c(pos, 'upgrade')
  #neg.words <- c(neg, 'wtf', 'wait', 'waiting', 'epicfail')
  Dataset <- stack
  Dataset$text <- as.factor(Dataset$text)
  scores <- score.sentiment(Dataset$text, pos.words, neg.words, .progress='text')
  write.csv(scores, file=paste(searchterm, '_scores.csv'), row.names=TRUE) #save evaluation results into the file
  #total evaluation: positive / negative / neutral
  stat <- scores
  stat$created <- stack$created
  stat$created <- as.Date(stat$created)
  stat <- mutate(stat, tweet=ifelse(stat$score > 0, 'positive', ifelse(stat$score < 0, 'negative', 'neutral')))
  by.tweet <- group_by(stat, tweet, created)
  by.tweet <- summarise(by.tweet, number=n())
  write.csv(by.tweet, file=paste(searchterm, '_opin.csv'), row.names=TRUE)
  #create chart
  ggplot(by.tweet, aes(created, number)) + geom_line(aes(group=tweet, color=tweet), size=2) +
    geom_point(aes(group=tweet, color=tweet), size=4) +
    theme(text = element_text(size=18), axis.text.x = element_text(angle=90, vjust=1)) +
    #stat_summary(fun.y = 'sum', fun.ymin='sum', fun.ymax='sum', colour = 'yellow', size=2, geom = 'line') +
    ggtitle(searchterm)
  ggsave(file=paste(searchterm, '_plot.jpeg'))
}
search("______") #enter keyword
