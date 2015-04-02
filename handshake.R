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
#api_key             = ""
#api_secret          = ""
#access_token        = ""
#access_token_secret = ""
#setup_twitter_oauth(api_key,api_secret,access_token,access_token_secret)

api_key             = "L1xbk85CKbvtZpuI6DC9L3c3U"
api_secret          = "tjmq76hWIgpw7ZaYaMOzVpFq7RRxcfpWpf11ZFZCybYbth5LLx"
access_token        = "158590874-WG6Bo3wi09Tzj6yZWxo8QtTm4C4FeLNhujndXjTh"
access_token_secret = "YvV3KsomGL8QmqaqkoVlLsjBYS0AzgbQ03EJZbcPRNYE5"
setup_twitter_oauth(api_key,api_secret,access_token,access_token_secret)

#getting tweets from Twitter
iPhone.list = searchTwitter('#Apple', n=100, cainfo="cacert.pem")
iPhone.list = searchTwitter('#Apple', n=5)
iPhone.list