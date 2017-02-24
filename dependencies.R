###
# load dependencies
###

pkgs <- c(
	"dplyr",
	"ggplot2",
	"tidyr",
	"stringr",
	"xgboost",
	"magrittr",
	"Matrix",
	"caret",
	"assertthat"
	)

req_pkgs <- pkgs[!(pkgs %in% names(installed.packages()[,1]))]
if (length(req_pkgs) != 0){
	install.packages(req_pkgs, repos='http://cran.us.r-project.org')
}

lapply(pkgs, require, character.only=TRUE)
