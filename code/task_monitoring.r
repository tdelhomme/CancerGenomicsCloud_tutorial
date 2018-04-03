library("sevenbridges")

# set the project name (get it from url on the CGC)
project = "tcga-kirc-germline"

# create authentification and project objects (get the token on the developer part on the CGC)
a <- Auth(token = "", url = "https://cgc-api.sbgenomics.com/v2/")
p <- a$project(id = paste("tdelhomme/", project, sep=""))

###########################################

all_tasks = p$task(complete = T)

# here we need to update the task to retrieve all the informations
for (i in 1:length(all_tasks)){
  all_tasks[[i]]$update()
}

# create a vector of the total prices of each tasks
all_prices = unlist(lapply(1:length(all_tasks), function(i){
  as.numeric(all_tasks[[i]]$price$amount)
}))
names(all_prices) = c(1:length(all_prices))

# create a vector of the prices of storage of each tasks
all_prices_storage = unlist(lapply(1:length(all_tasks), function(i){
  as.numeric(all_tasks[[i]]$price$breakdown$storage)
}))
names(all_prices_storage) = c(1:length(all_prices_storage))

# create a vector of the prices of computing of each tasks
all_prices_computation = unlist(lapply(1:length(all_tasks), function(i){
  as.numeric(all_tasks[[i]]$price$breakdown$computation)
}))
names(all_prices_computation) = c(1:length(all_prices_computation))

all_durations = sapply(all_tasks, function(x) c(x$execution_status$queued_duration, x$execution_status$running_duration , x$execution_status$execution_duration,  
                                                 x$execution_status$duration))/1000/60

ntest = 106-86 #to separate test and production runs; to change depending on your values
nprod = 86

svg("Price_duration.svg",h=5,w=5*2)
par(mfrow=c(1,2),family="Times",las=1)
plot(-1,-1, type = "l", col="darkgrey", lwd=3, xlab="Task index", ylab="Price ($)", main=paste(project, "  (n=", length(all_prices[((ntest+nprod)-85):(ntest+nprod)]), ")", sep=""), ylim=c(0,max(all_prices)),xlim=c(1,nprod))
polygon(c(1,1:nprod,nprod:1,1),c(0,(all_prices)[names(sort(all_prices[((ntest+nprod)-(nprod-1)):(ntest+nprod)]))],rep(0,nprod),0), col=rgb(0.1,0.3,0.5,0.7),border = NA)
polygon(c(1,1:nprod,nprod:1,1),c(0,all_prices_storage[names(sort(all_prices[((ntest+nprod)-(nprod-1)):(ntest+nprod)]))],rep(0,nprod),0), col=rgb(0.3,0.3,0.5,0.7),border = NA)
text(x=1, y=max(all_prices)*0.95, paste("median = $", median(all_prices[((ntest+nprod)-(nprod-1)):(ntest+nprod)])),adj = 0)
text(x=1, y=max(all_prices)*0.9, paste("min = $", min(all_prices[((ntest+nprod)-(nprod-1)):(ntest+nprod)])),adj = 0)
text(x=1, y=max(all_prices)*0.85, paste("max = $", max(all_prices[((ntest+nprod)-(nprod-1)):(ntest+nprod)])),adj = 0)
text(x=1, y=max(all_prices)*0.80, paste("total = $", sum(all_prices[((ntest+nprod)-(nprod-1)):(ntest+nprod)])),adj = 0)
text(x=1, y=max(all_prices)*0.75, paste("test = $", sum(all_prices[1:((ntest+nprod)-(nprod-1)-1)])),adj = 0)
legend(x=length(all_prices)/3, y=max(all_prices), fill=c(rgb(0.1,0.3,0.5,0.7), rgb(0.3,0.3,0.5,0.7)),legend=c("computing", "storage"), bty='n', y.intersp = 0.8)

ord_dur = order(all_durations[4,((ntest+nprod)-(nprod-1)):(ntest+nprod)])
plot(-1,-1, type = "l", col="darkgrey", lwd=3, xlab="Task index", ylab="Duration (min)", main="", ylim=c(0,max(all_durations)),xlim=c(1,nprod))
polygon(c(1,1:nprod,nprod:1,1),c(0,(all_durations[4,((ntest+nprod)-(nprod-1)):(ntest+nprod)])[ord_dur],rep(0,nprod),0), col=rgb(0.1,0.3,0.5,0.7),border = NA)
polygon(c(1,1:nprod,nprod:1,1),c(0,all_durations[1,((ntest+nprod)-(nprod-1)):(ntest+nprod)][ord_dur],rep(0,nprod),0), col=rgb(0.3,0.3,0.5,0.7),border = NA)
polygon(c(1,1:nprod,nprod:1,1),c(0,colSums(all_durations[c(1,3),((ntest+nprod)-(nprod-1)):(ntest+nprod)][,ord_dur]),rep(0,nprod),0), col=rgb(0.3,0.3,0.5,0.7),border = NA)
text(x=1, y=max(all_durations)*0.95, paste("median = ", format(median(all_durations[4,((ntest+nprod)-(nprod-1)):(ntest+nprod)]),digits = 2),"min"),adj = 0)
text(x=1, y=max(all_durations)*0.9, paste("min = ", format(min(all_durations[4,((ntest+nprod)-(nprod-1)):(ntest+nprod)]),digits = 2),"min"),adj = 0)
text(x=1, y=max(all_durations)*0.85, paste("max = ", format(max(all_durations[4,((ntest+nprod)-(nprod-1)):(ntest+nprod)]),digits = 2),"min"),adj = 0)
legend(x=ncol(all_durations)/3, y=max(all_durations), fill=c(rgb(0.1,0.3,0.5,0.7), rgb(0.3,0.3,0.5,0.7)),legend=c("initialization","execution"), bty='n', y.intersp = 0.8)
dev.off()

running = unlist(lapply(1:length(all_tasks), function(i){
  tsk = all_tasks[[i]]
  tsk$execution_status$running_duration / 60000
}))
names(running) = c(1:length(running))

queued = unlist(lapply(1:length(all_tasks), function(i){
  tsk = all_tasks[[i]]
  tsk$execution_status$queued_duration / 60000
}))
names(queued) = c(1:length(queued))

plot(sort(queued), type = "l", col="darkgrey", lwd=3, xlab="task index", ylab="duration (min)", ylim=c(0,max(c(queued,running))))
lines(running[names(sort(queued))], col="darkred")
legend(x=length(queued)/4, y=max(queued)-0.05*max(queued), col=c("darkgrey", "darkred"),
       legend=c("queued", "running"), bty='n', lty=1, lwd=2, y.intersp = 0.6)

}
