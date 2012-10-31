
# FitNesse Startup script
PORT = 8080
ROOT_PAGE = ./FitNesseRoot
LOGGER = none
AUTHENTICATOR = fitnesse.authentication.PromiscuousAuthenticator


start:
	java -jar fitnesse.jar -p $(PORT)&

stop:
	killall java