---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# LANGUAGE DeriveGeneric             #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

import qualified Flowbox.Data.Version            as Version
import           Flowbox.Generics.Deriving.FShow
import           Flowbox.System.Log.Logger       as Logger
import           GHC.Generics
import           Prelude                         hiding (error)

data Test = Test Int Int deriving(Show, Generic)

instance FShow Test

logger :: Logger
logger   = getLogger "MyApp.BuggyComponent"

loggerIO :: LoggerIO
loggerIO = getLoggerIO "MyApp.BuggyComponent"

test_logger :: IO ()
test_logger = runLogger $ do
    logger debug      "debug"
    logger info       "info"
    logger notice     "notice"
    logger warning    "warning"
    logger error      "error"
    logger critical   "critical"
    logger alert      "alert"
    logger emergency  "emergency"


f :: String -> String
f x = x

main :: IO ()
main = do
    let t = Test 5 5
    putStrLn $ fshow f t

    logger setLevel DEBUG
    test_logger
    let
        v1 = Version.Version 0 1 0 Version.Alpha
        v2 = Version.mk { Version.minor = 1
                        , Version.stage = Version.Alpha
                        }
    print v1
    print $ Version.str v1
    print v2
    loggerIO error "IO error"
