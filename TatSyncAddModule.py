import sys
import os

def addModule(logInfo = False):
    modulePath, filename = os.path.split ( os.path.realpath(__file__))
    modulePath = os.path.normpath(modulePath)

    if logInfo :
        for p in sys.path :
            print (p)

    if not modulePath in sys.path :
        sys.path.append(modulePath)
        if logInfo :
        	print ("sys.path, append {0}".format(modulePath))
    else :
    	if logInfo :
    		print ("sys.path, exists {0}".format(modulePath))

addModule(False)

