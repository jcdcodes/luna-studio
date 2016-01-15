{-# LANGUAGE BangPatterns     #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TemplateHaskell  #-}

module Empire.Logger where

import           Flowbox.Prelude
import           Control.Monad                          (forever)
import           Control.Monad.State                    (StateT, evalStateT)
import qualified Data.Binary                            as Bin
import           Data.ByteString                        (ByteString)
import           Data.ByteString.Char8                  (unpack)
import           Data.ByteString.Lazy                   (fromStrict, toStrict)
import           Data.Map.Strict                        (Map)
import qualified Data.Map.Strict                        as Map
import qualified Empire.Env                             as Env
import           Empire.Env                             (Env)
import qualified Flowbox.Bus.Bus                        as Bus
import           Flowbox.Bus.BusT                       (BusT (..))
import qualified Flowbox.Bus.BusT                       as Bus
import qualified Flowbox.Bus.Data.Message               as Message
import           Flowbox.Bus.Data.MessageFrame          (MessageFrame (MessageFrame))
import           Flowbox.Bus.Data.Topic                 (Topic)
import           Flowbox.Bus.EndPoint                   (BusEndPoints)
import qualified Flowbox.System.Log.Logger              as Logger
import qualified Empire.Utils                           as Utils
import qualified Empire.Handlers                        as Handlers
import qualified Empire.Commands.Library                as Library
import qualified Empire.Commands.Project                as Project
import qualified Empire.Empire                          as Empire
import qualified Empire.Server.Server                   as Server
import qualified Empire.API.Topic                       as Topic
import qualified Empire.API.Graph.AddNode               as AddNode
import qualified Empire.API.Graph.RemoveNode            as RemoveNode
import qualified Empire.API.Graph.UpdateNodeMeta        as UpdateNodeMeta
import qualified Empire.API.Graph.Connect               as Connect
import qualified Empire.API.Graph.Disconnect            as Disconnect
import qualified Empire.API.Graph.GetProgram            as GetProgram
import qualified Empire.API.Graph.CodeUpdate            as CodeUpdate
import qualified Empire.API.Graph.NodeUpdate            as NodeUpdate
import qualified Empire.API.Graph.SetDefaultValue       as SetDefaultValue
import qualified Empire.API.Project.CreateProject       as CreateProject
import qualified Empire.API.Project.ListProjects        as ListProjects
import qualified Empire.API.Library.CreateLibrary       as CreateLibrary
import qualified Empire.API.Library.ListLibraries       as ListLibraries


logger :: Logger.LoggerIO
logger = Logger.getLoggerIO $(Logger.moduleName)

run :: BusEndPoints -> [Topic] -> IO (Either Bus.Error ())
run endPoints topics = Bus.runBus endPoints $ do
    logger Logger.info $ "Subscribing to topics: " <> show topics
    logger Logger.info $ show endPoints
    mapM_ Bus.subscribe topics
    Bus.runBusT $ evalStateT runBus def

runBus :: StateT Env BusT ()
runBus = forever handleMessage

handleMessage :: StateT Env BusT ()
handleMessage = do
    msgFrame <- lift $ BusT Bus.receive'
    case msgFrame of
        Left err -> logger Logger.error $ "Unparseable message: " <> err
        Right (MessageFrame msg crlID senderID lastFrame) -> do
            let topic = msg ^. Message.topic
                logMsg =  show senderID <> " -> (last = " <> show lastFrame <> ")\t:: " <> topic
                content = msg ^. Message.message
                errorMsg = show content
            case Utils.lastPart '.' topic of
                "update"   -> logMessage logMsg topic content
                "status"   -> logMessage logMsg topic content
                "request"  -> logMessage logMsg topic content
                _          -> do logger Logger.error logMsg
                                 logger Logger.error errorMsg

type LogFormatter = ByteString -> String

logMessage :: String -> String -> ByteString -> StateT Env BusT ()
logMessage logMsg topic content = do
    logger Logger.info logMsg
    let logFormatter = Map.findWithDefault defaultLogFormatter topic loggFormattersMap
    logger Logger.debug $ logFormatter content

loggFormattersMap :: Map String LogFormatter
loggFormattersMap = Map.fromList
    [ (Topic.addNodeRequest,        \content -> show (Bin.decode . fromStrict $ content :: AddNode.Request))
    , (Topic.addNodeUpdate,         \content -> show (Bin.decode . fromStrict $ content :: AddNode.Update))
    , (Topic.removeNodeRequest,     \content -> show (Bin.decode . fromStrict $ content :: RemoveNode.Request))
    , (Topic.removeNodeUpdate,      \content -> show (Bin.decode . fromStrict $ content :: RemoveNode.Update))
    , (Topic.updateNodeMetaRequest, \content -> show (Bin.decode . fromStrict $ content :: UpdateNodeMeta.Request))
    , (Topic.updateNodeMetaUpdate,  \content -> show (Bin.decode . fromStrict $ content :: UpdateNodeMeta.Update))
    , (Topic.connectRequest,        \content -> show (Bin.decode . fromStrict $ content :: Connect.Request))
    , (Topic.connectUpdate,         \content -> show (Bin.decode . fromStrict $ content :: Connect.Update))
    , (Topic.disconnectRequest,     \content -> show (Bin.decode . fromStrict $ content :: Disconnect.Request))
    , (Topic.disconnectUpdate,      \content -> show (Bin.decode . fromStrict $ content :: Disconnect.Update))
    , (Topic.programRequest,        \content -> show (Bin.decode . fromStrict $ content :: GetProgram.Request))
    , (Topic.programStatus,         \content -> show (Bin.decode . fromStrict $ content :: GetProgram.Update))
    , (Topic.nodeUpdate,            \content -> show (Bin.decode . fromStrict $ content :: NodeUpdate.Update))
    , (Topic.codeUpdate,            \content -> show (Bin.decode . fromStrict $ content :: CodeUpdate.Update))
    , (Topic.graphUpdate,           const "graphUpdate - not implemented yet")
    , (Topic.createProjectRequest,  \content -> show (Bin.decode . fromStrict $ content :: CreateProject.Request))
    , (Topic.createProjectUpdate,   \content -> show (Bin.decode . fromStrict $ content :: CreateProject.Update))
    , (Topic.listProjectsRequest,   \content -> show (Bin.decode . fromStrict $ content :: ListProjects.Request))
    , (Topic.listProjectsStatus,    \content -> show (Bin.decode . fromStrict $ content :: ListProjects.Update))
    , (Topic.createLibraryRequest,  \content -> show (Bin.decode . fromStrict $ content :: CreateLibrary.Request))
    , (Topic.createLibraryUpdate,   \content -> show (Bin.decode . fromStrict $ content :: CreateLibrary.Update))
    , (Topic.listLibrariesRequest,  \content -> show (Bin.decode . fromStrict $ content :: ListLibraries.Request))
    , (Topic.listLibrariesStatus,   \content -> show (Bin.decode . fromStrict $ content :: ListLibraries.Update))
    , (Topic.setDefaultValueRequest,\content -> show (Bin.decode . fromStrict $ content :: SetDefaultValue.Request))
    ]

defaultLogFormatter :: LogFormatter
defaultLogFormatter = const "Not recognized message"
