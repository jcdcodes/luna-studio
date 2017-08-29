{-# LANGUAGE Rank2Types #-}
module TextEditor.Event.Preprocessor.Batch (process) where

import           Common.Prelude                    hiding (cons)
import           Data.Binary                            (Binary, decode)
import           Data.ByteString.Lazy.Char8             (ByteString)
import qualified Data.Map.Lazy                          as Map
import qualified GZip

import qualified LunaStudio.API.Topic                       as Topic
import           Common.Batch.Connector.Connection (ControlCode (ConnectionTakeover, Welcome), WebMessage (ControlMessage, WebMessage))
import           TextEditor.Event.Batch                as Batch
import           TextEditor.Event.Connection           as Connection
import qualified TextEditor.Event.Event                as Event


process :: Event.Event -> Maybe Event.Event
process (Event.Connection (Message msg)) = Just $ Event.Batch $ processMessage msg
process _                                = Nothing

handle :: forall a. (Binary a, Topic.MessageTopic a) => (a -> Batch.Event) -> (String, ByteString -> Batch.Event)
handle cons = (Topic.topic (undefined :: a), cons . decode . GZip.decompress)

handlers :: Map.Map String (ByteString -> Batch.Event)
handlers = Map.fromList [ handle BufferGetResponse
                        , handle EmpireStarted
                        , handle CopyResponse
                        , handle FileClosed
                        , handle FileOpened
                        , handle FileSaved
                        , handle ProjectSet
                        , handle SubstituteResponse
                        , handle SubstituteUpdate
                        ]

processMessage :: WebMessage -> Batch.Event
processMessage (WebMessage topic bytes) = handler bytes where
    handler      = Map.findWithDefault defHandler topic handlers
    defHandler _ = UnknownEvent topic
processMessage (ControlMessage ConnectionTakeover) = ConnectionDropped
processMessage (ControlMessage Welcome)            = ConnectionOpened
