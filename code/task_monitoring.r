library("sevenbridges")

project = "tcga-kirc-germline"

a <- Auth(token = "", url = "https://cgc-api.sbgenomics.com/v2/")
p <- a$project(id = paste("tdelhomme/", project, sep=""))

###########################################

all_tasks = p$task(complete = T)

for (i in 1:length(all_tasks)){
  all_tasks[[i]]$update()
}

all_prices = unlist(lapply(1:length(all_tasks), function(i){
  as.numeric(all_tasks[[i]]$price$amount)
}))
names(all_prices) = c(1:length(all_prices))

all_prices_storage = unlist(lapply(1:length(all_tasks), function(i){
  as.numeric(all_tasks[[i]]$price$breakdown$storage)
}))
names(all_prices_storage) = c(1:length(all_prices_storage))

all_prices_computation = unlist(lapply(1:length(all_tasks), function(i){
  as.numeric(all_tasks[[i]]$price$breakdown$computation)
}))
names(all_prices_computation) = c(1:length(all_prices_computation))

par(mfrow=c(1,2))
plot(sort(all_prices), type = "l", col="darkgrey", lwd=3, xlab="task index", ylab="price ($)",
     main=paste(project, "  (n=", length(all_prices), ")", sep=""), ylim=c(0,max(all_prices)))
lines(all_prices_computation[names(sort(all_prices))], col="blueviolet")
lines(all_prices_storage[names(sort(all_prices))], col="dodgerblue3")
text(x=length(all_prices)/8, y=max(all_prices)-0.1*max(all_prices), paste("median = ", median(all_prices)))
text(x=length(all_prices)/8, y=max(all_prices)-0.15*max(all_prices), paste("min = ", min(all_prices)))
text(x=length(all_prices)/8, y=max(all_prices)-0.2*max(all_prices), paste("max = ", max(all_prices)))
text(x=length(all_prices)/8, y=max(all_prices)-0.25*max(all_prices), paste("total = ", sum(all_prices)))
legend(x=length(all_prices)/4, y=max(all_prices)-0.05*max(all_prices), col=c("darkgrey", "blueviolet", "dodgerblue3"),
       legend=c("total", "computing", "storage"), bty='n', lty=1, lwd=2, y.intersp = 0.6)

# durations = unlist(lapply(1:length(all_tasks), function(i){
#   tsk = all_tasks[[i]]
#   date = tsk$start_time
#   pos = as.numeric(gregexpr(":", date)[[1]])
#   start = c(as.numeric(substr(date, pos[1]-2, pos[1]-1)), as.numeric(substr(date, pos[1]+1, pos[1]+2)), as.numeric(substr(date, pos[2]+1, pos[2]+2)))
#   date = tsk$end_time
#   pos = as.numeric(gregexpr(":", date)[[1]])
#   end = c(as.numeric(substr(date, pos[1]-2, pos[1]-1)), as.numeric(substr(date, pos[1]+1, pos[1]+2)), as.numeric(substr(date, pos[2]+1, pos[2]+2)))
#   ((end[1]*3600 + end[2]*60 + end[3]) - (start[1]*3600 + start[2]*60 + start[3])) / 60
# }))

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
