

from TatSyncSequences import SyncSequences

def syncNetwork( twoWay ) :
    localPath   = 'D:/Argonautes/LayoutLocal'
    networkPath = 'R:/08_LAYOUT'
    sequences = SyncSequences(localPath, networkPath, twoWay )
    sequences.sync( )
    return True

syncNetwork( True )

