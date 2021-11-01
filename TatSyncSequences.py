import os, shutil
from os.path import isfile, join, exists, split
from datetime import date
from copy import copy
import re

_regexPlan  = re.compile( r"(s[0-9]{2}[A-Za-z]?p[0-9]{4}[A-Za-z]?.layout)(.[A-Z])?.v([0-9]{3})?")
_regexEstab = re.compile( r"(s[0-9]{2}[A-Za-z]?e[0-9]{2}.layout[A-Z]?)(.[A-Z])?.v([0-9]{3})?")
_regexEstab = re.compile( r"(s[0-9]{2}[A-Za-z]?e[0-9]{2}.layout[A-Z]?)(.[A-Z])?.v([0-9]{3})?")

class fileLayout :

    def __init__(self , file):
        self.path, self.name  = split(file) 
        self.isLocal = True if os.path.splitdrive(self.path)[0] == "D:" else False
        self.pathFormat = "Local" if self.isLocal else "Network"
        self.file = file 
        self.plan = ""
        self.increment = 0
        self.abc = ""
        self.isPlan = False
        self.isEstab = False

        matchPlan  = _regexPlan.match(self.name) 

        if matchPlan :
            self.isPlan = True
            self.plan = matchPlan.group(1)
            if matchPlan.group(2) != None:
                self.abc = matchPlan.group(2)
            self.increment = int (matchPlan.group(3))
        else :
            matchEstab = _regexEstab.match(self.name)

            if matchEstab :
                self.isEstab = True
                self.plan = matchEstab.group(1) 
                if matchEstab.group(2) != None:
                    self.abc = matchEstab.group(2)
                self.increment = int(matchEstab.group(3)) 

        self.planAbc = self.plan +  self.abc
        self.isAbc = True if self.abc != "" else  False  

    def setPath (self, newpath):
        self.path = newpath
        self.file = join (self.path, self.name)

    def copyToDir ( self , dstDir, logInfo = "" ):
        log = "ToDir, {0}".format(logInfo)
        dstFile = join ( dstDir , self.name )
        self.copyTo ( dstFile, log )

    def copyTo ( self,  dstFile, logInfo = ""):
       
        shutil.copy2( self.file , dstFile )
        dstPath, dstFName = split(dstFile)
        log = " > copyTo\n\t{0}, from {1}, to {2}".format( self.name, self.path , dstPath )
        log += "\t[ Info : {0} ]".format( logInfo )
        print ( log )

    def moveToBackup (self , logInfo = "", createDateFolder = False  ):

        dstPath =  join (self.path, "old") 
        if not exists( dstPath ):
            os.mkdir( dstPath)

        if createDateFolder :
            today = date.today()
            logDate = today.strftime("%d_%m_%Y")

            dstPath =  join (dstPath, logDate) 
            if not exists( dstPath ):
                os.mkdir( dstPath)

        backupFile = join ( dstPath, self.name)
        shutil.move( self.file , backupFile )

        log = " > moveToBackup\n\t{0}, from {1}, to {2} ".format( self.name, self.path , dstPath )
        log += "\t[ Info : {0} ]".format( logInfo )
        print ( log )

    def copyMostRecent ( self, dstDir , twoWay = True , logInfo = "" ):
        dstF = copy ( self )
        dstF.setPath ( dstDir )
        
        if exists(dstF.file):

            if self.compareDate(dstF) > 0:
                log = "mostRecent, {0} {1}".format(self.file, logInfo )
                dstF.moveToBackup(log)
                self.copyTo( dstF.file, log)

            elif self.compareDate(dstF) < 0 and twoWay:
                log = "mostRecent, {0} {1}".format(dstF.file, logInfo )
                self.moveToBackup(log)
                dstF.copyTo(  self.file, log )
            else : 
                pass

    
    def compareDate ( self , dstF ) :
        return ( os.stat(self.file ).st_mtime - os.stat(dstF.file).st_mtime)

    def isMostRecent ( self , dstF ) :
        return  True if self.compareDate(dstF) > 0 else False


class Sequences :

    def __init__(self, name, path):
        self.name = name
        self.dir =  os.path.join( path, name ) 
     
    def _get_subNames (self):
        return   ["_PREPA" , join ("_PREPA", "Previs_JPG" ),"Animatique","establishing_max","establishing_previews","MAX","PREVIEWS"]

    def _set_subNames (self):
        pass
    
    subNames = property (_get_subNames , _set_subNames)
    
    def _get_subDirs (self):
        return [ join( self.dir,  sub ) for sub in self.subNames]

    def _set_subDirs (self):
        pass
    
    subDirs = property (_get_subDirs , _set_subDirs)

    def sync(self , dst , twoWay = True) :
        print("--{0}".format(self.name))

        if exists( self.dir) and exists (dst.dir) :
            for i , sub in enumerate (self.subDirs) :
                Sequences.removeConflictFile( sub )

                print("---{0}".format( self.subNames[i]))
                srcDir = self.subDirs[i]
                dstSubDir = dst.subDirs[i]

                if exists( dstSubDir) :

                    scrDict = self.getDictionaryFiles(  os.listdir(srcDir)  , srcDir) 
                    destDict = self.getDictionaryFiles(  os.listdir(dstSubDir)  , dstSubDir )
                    Sequences.backupVersionFiles( scrDict )
                    Sequences.backupVersionFiles( destDict )

                    left, right, common = Sequences.compareFiles( srcDir, dstSubDir)    

                    commonDict = self.getDictionaryMatch( scrDict , common)
                    leftDict = self.getDictionaryMatch( scrDict , left)
                
                    Sequences.udpateFiles( commonDict, dstSubDir, twoWay)
                    Sequences.copyNewFiles( leftDict, destDict, dstSubDir)

                    if twoWay :
                        rightDict = self.getDictionaryMatch( destDict , right)
                        Sequences.copyNewFiles( rightDict, scrDict, srcDir)
             
        elif not exists (dst.dir) :
            print ("copyTo {0} -> {1}".format(self.dir, dst.dir))
            shutil.copytree( self.dir , dst.dir )
        else :
            pass 

    @staticmethod
    def backupVersionFiles (  dictFiles  ):
        #backup versionned files except the most recent i = 0
        context = "backupVersionFiles"
        for key, files in dictFiles.items():
            if key != "noGroup" :
                versionFiles = dictFiles[key]
                # most versionned file at index 0  
                recentF = versionFiles[0]
                # old versionned files begin at 1 
                i = 1
                while i < len(versionFiles):
                    oldF =  versionFiles[i] 
                    if recentF.isMostRecent( oldF ) :
                        #most versionned file is most recent then backup oldfile and remove from list
                        oldF.moveToBackup(context)
                        versionFiles.pop(i)
                    else :
                        #keep old file and increment index otherwise wile will became infinite!
                        Sequences.logConflict( recentF , oldF, context)
                        i += 1

    @staticmethod
    def removeConflictFile (subDir):

        conflictFile = Sequences.getConflictFile(subDir)
        if exists(conflictFile):
            os.remove( conflictFile )

    @staticmethod
    def getConflictFile( subDir ):
        subPath, subName = split (subDir)
        seqName = split (subPath)[1] 
        conflictName  = "Sync_Conflict_{0}_{1}.txt".format(seqName, subName )
        return join( subDir, conflictName ) 
    
    @staticmethod
    def logConflict( f , oldF , logInfo ):
        conflictFile = Sequences.getConflictFile( f.path )
        log = " > Conflict files \n\t[ {0} ][ {1} ] has been modified after [ {2} ][ {3} ]\n".format(oldF.name, oldF.pathFormat , f.name, f.pathFormat)
        file = open(conflictFile, "a") 
        file.write( log ) 
        file.close() 
        os.startfile(f.path)
        log += "\t[ Info : {0} ]".format( logInfo )
        print(log)

    @staticmethod
    def copyNewFiles (  srcDict , dstDict , dstDir ):
        context = "copyNew"
        for key, files in srcDict.items() :
            if key == "noGroup" :
                log = "{0}, noGroup".format(context)
                for f in files :
                    f.copyToDir( dstDir , log)

            elif key in dstDict  :
                f = files[0] 
                dstF =  dstDict[key][0]

                if f.increment > dstF.increment :
                    log = "{0}, incr > dstIncr".format(context)
                    if f.isMostRecent( dstF ) :
                        dstF.moveToBackup( log )
                    else :
                        Sequences.logConflict( f , dstF, context)
                    f.copyToDir( dstDir, log )
                    
            else  :
                f = files[0] 
                if f.isAbc and f.plan in dstDict:
                    log = "{0}, version {1} is obsolete".format(context, f.abc )
                    f.moveToBackup( log )
                else :
                    log = "{0}, key {1} not found".format(context,key) 
                    f.copyToDir( dstDir , log )


    @staticmethod
    def udpateFiles ( toUpdate , dstDir, twoWay = True ):
        for key, files in toUpdate.items() :
            for f in files :
                f.copyMostRecent( dstDir, twoWay, "udpate")

    @staticmethod
    def compareFiles (srcDir, dstDir):
        left = list()
        right = list()
        common = list()
        scrFiles = os.listdir(srcDir) 
        dstFiles =  os.listdir(dstDir)

        for scrName in  scrFiles :
            isUnique = True
            for dstName in dstFiles :
                if dstName == scrName :
                    common.append(scrName)
                    isUnique = False
            if isUnique :
                left.append(scrName) 

        right = [ dstName for dstName in dstFiles if not dstName in common ]
    
        return left, right, common

    @staticmethod
    def getDictionaryFiles( filenames , subDir ):
        dictionary = {}
        for fname in filenames :
            file = join( subDir, fname)

            if isfile( file ) and not re.match(r".+\.(db)|(txt)", fname) :
                f = fileLayout( file )
                if f.isPlan or f.isEstab :
                    #here, plan and plan.A have their own key
                    Sequences.appendInDictionary (dictionary, f.planAbc  , f )
                else :
                    Sequences.appendInDictionary (dictionary, "noGroup" , f )

        for k, files in dictionary.items() :
            dictionary[k] = sorted ( files, key = lambda x : x.increment, reverse = True )

        return dictionary

    @staticmethod
    def getDictionaryMatch (dictionary, matchFilenames):
        matchDict = {}

        for key, files in dictionary.items() :
            for f in  files :
                for matchFname in matchFilenames :
                    if matchFname == f.name :
                        Sequences.appendInDictionary ( matchDict, key , f )
                        break
    
        return matchDict

    @staticmethod
    def appendInDictionary ( dictionary, key , val ):
        if key in dictionary :
            dictionary[key].append(val)
        else :
            dictionary[key] = [val] 
    


class SyncSequences :

    def __init__( self, srcPath , dstPath, twoWay = True ) :
        self.scrPath = srcPath
        self.dstPath = dstPath
        self.twoWay = twoWay

    def sync ( self ) :

        print ("\n-LayoutTool SyncNetwork begin-\n")
        sourceDirs =  os.listdir( self.scrPath)
        for sDir in sourceDirs :
            if re.match(r"^s[0-9]{2}[A-Z]?$", sDir) :
                sSeq = Sequences( sDir ,  self.scrPath )
                dSeq = Sequences( sDir ,  self.dstPath )

                sSeq.sync(dSeq, self.twoWay)
        print ("\n-LayoutTool SyncNetwork end-\n")
        return True