---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Luna.Data.HAST.Expr where

import           Flowbox.Luna.Data.HAST.Extension (Extension)
import qualified Flowbox.Luna.Data.HAST.Lit       as Lit
import           Flowbox.Prelude

type Lit = Lit.Lit

data Expr = Assignment { src       :: Expr     , dst       :: Expr                                }
          | Arrow      { src       :: Expr     , dst       :: Expr                                }
          | Tuple      { items :: [Expr]                                                      }
          | TupleP     { items :: [Expr]                                                      }
          | ListE      { items :: [Expr]                                                      }
          | StringLit  { val :: String                                                      }
          | Var        { name :: String                                                      }
          | VarE       { name :: String                                                      }
          | VarT       { name :: String                                                      }
          | LitT       { lval :: Lit                                                         }
          | Typed      { cls       :: Expr     , expr      :: Expr                                }
          | TypedP     { cls       :: Expr     , expr      :: Expr                                }
          | TypedE     { cls       :: Expr     , expr      :: Expr                                }
          | Function   { name      :: String   , pats      :: [Expr]      , expr      :: Expr     }
          | Lambda     { paths     :: [Expr]   , expr      :: Expr                                }
          | LetBlock   { exprs     :: [Expr]   , result    :: Expr                                }
          | DoBlock    { exprs :: [Expr]                                                      }
          | DataD      { name      :: String   , params    :: [String]    , cons      :: [Expr] , derivings :: [String]   }
          | NewTypeD   { name      :: String   , params    :: [String]    , con       :: Expr     }
          | InstanceD  { tp        :: Expr     , decs      :: [Expr]                              }
          | Con        { name      :: String   , fields    :: [Expr]                              }
          | ConE       { qname :: [String]                                                    }
          | ConT       { name :: String                                                      }
          -- | Module     { path      :: [String] , ext       :: [Extension] , imports   :: [Expr]   , newtypes  :: [Expr]       , datatypes :: [Expr]  , methods :: [Expr] , thexpressions :: [Expr] }
          | Module     { path      :: [String] , ext       :: [Extension] , imports   :: [Expr]   , body  :: [Expr]}
          | Import     { qualified :: Bool     , segments  :: [String]    , rename    :: Maybe String                           }
          | AppE       { src       :: Expr     , dst       :: Expr                                }
          | AppT       { src       :: Expr     , dst       :: Expr                                }
          | Infix      { name      :: String   , src       :: Expr        , dst          :: Expr  }
          | Lit        { lval :: Lit                                                         }
          | Native     { code :: String                                                      }
          | WildP
          | NOP
          | Undefined
          | Bang Expr
          deriving (Show)

