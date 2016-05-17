module Text.ScopeSearcher.Item where

import           Control.Lens
import           Data.Aeson.Types (FromJSON, ToJSON, toJSON)
import           Data.Binary      (Binary)
import           Data.Map.Lazy    as Map
import           Data.Text.Lazy   (Text)
import           GHC.Generics     (Generic)


type Items = Map Text Item

data Item = Element
          | Group   { _items :: Items }
          deriving (Show, Eq, Generic)

instance Binary Item

instance ToJSON Item

makeLenses ''Item
makePrisms ''Item