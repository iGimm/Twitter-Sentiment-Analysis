install.packages(c("twitteR","ROAuth","plyr","stringr","ggplot2"),dependencies=T)

# Authenticating with twitter API
library(twitteR)
library(ROAuth)
library(plyr)
library(stringr)
library(ggplot2)

# Accessing the twitter API
requestURL <- "https://api.twitter.com/oauth/request_token"
accessURL  =  "http://api.twitter.com/oauth/access_token"
authURL    =  "http://api.twitter.com/oauth/authorize"

consumerKey    = "L1xbk85CKbvtZpuI6DC9L3c3U"
consumerSecret = "tjmq76hWIgpw7ZaYaMOzVpFq7RRxcfpWpf11ZFZCybYbth5LLx"
Cred <- OAuthFactory$new(consumerKey    = consumerKey,
                         consumerSecret = consumerSecret,
                         requestURL     = requestURL,
                         accessURL      = accessURL,
                         authURL        = authURL)
Cred$handshake(cainfo = system.file("CurlSSL","cacert.pem",package = "RCurl"))

# Save these credentials and register
save(Cred, file="twitter authentication.Rdata")
load("twitter authentication.Rdata")
registerTwitterOAuth(Cred)


# As SSL is required I'll proceed with the next way of conection between apps
api_key             = "L1xbk85CKbvtZpuI6DC9L3c3U"
api_secret          = "tjmq76hWIgpw7ZaYaMOzVpFq7RRxcfpWpf11ZFZCybYbth5LLx"
access_token        = "158590874-WG6Bo3wi09Tzj6yZWxo8QtTm4C4FeLNhujndXjTh"
access_token_secret = "YvV3KsomGL8QmqaqkoVlLsjBYS0AzgbQ03EJZbcPRNYE5"
setup_twitter_oauth(api_key,api_secret,access_token,access_token_secret)

#getting tweets from Twitter
EPN.list = searchTwitter('#EPN', n=50)
EPN.list
EPN.df = twListToDF(EPN.list)

# writting info to csv file
write.csv(EPN.df,file="epn.csv",row.names=F)

## Algorithm - prev
library(plyr)
library(stringr)
#pos.words = c("good","nice")
#neg.words = c("bad","no","not","unlike","dislike")
score.sentiment = function(sentences, pos.words, neg.words, .progress='none'){
  
  require(plyr)
  require(stringr)
  
  scores = laply(sentences, function(sentence, pos.words, neg.words){
    sentence = gsub('[[:punct:]]','', sentence)
    sentence = gsub('[[:cntrl:]]','', sentence)
    sentence = gsub('\\d+','', sentence)
    sentences = tolower(sentence)    
    
    word.list = str_split(sentence, '\\s+')
    words.list = unlist(word.list)
    
    pos.matches = match(words, pos.words)
    neg.matches = match(words, neg.words)
    
    pos.matches = !is.na(pos.matches)
    pos.matches = |is.na(neg.matches)
    
    score = sum(pos.matches) - sum(neg.matches)
    return(score)
  }, pos.words, neg.words, .progress=.progress)
  
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
    
  })
}

#load sentiment words lists
hu.liu.pos = scan('positive-words.txt', what='character',comment.char=';')
hu.liu.neg = scan('negative-words.txt', what='character',comment.char=';')

pos.words = c(hu.liu.pos,'update')
neg.words = c(hu.liu.neg, 'wtf','wait','waiting','epicfail','mechanical')

