---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

{-# LANGUAGE ConstraintKinds           #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE Rank2Types                #-}
{-# LANGUAGE TemplateHaskell           #-}
{-# LANGUAGE TupleSections             #-}

module Luna.DEP.Pass.Transform.AST.TxtParser.TxtParser where

import           Flowbox.System.Log.Logger
import           Luna.DEP.AST.Module          (Module)
import           Luna.DEP.Data.ASTInfo        (ASTInfo)
import           Luna.DEP.Data.Source         (Source (..))
import           Luna.DEP.Data.SourceMap      (SourceMap)
import qualified Luna.DEP.Parser.Parser       as Parser
import qualified Luna.DEP.Parser.State        as State
import           Luna.DEP.Pass.Pass           (Pass)
import qualified Luna.DEP.Pass.Pass           as Pass
import           Text.PrettyPrint.ANSI.Leijen (displayS)

import Control.Monad.State
import Flowbox.Prelude     hiding (error)



logger :: Logger
logger = getLogger $moduleName


type ParserPass m = Pass Pass.NoState m


run :: Source -> Pass.Result (Module, SourceMap, ASTInfo)
run = (Pass.run_ (Pass.Info "Luna Parser") Pass.NoState) . parse


parse :: Source -> ParserPass (Module, SourceMap, ASTInfo)
parse (Source modpath txt) = case Parser.parseString txt $ Parser.moduleParser modpath Parser.defState of
    Left  e -> Pass.fail $ displayS (Parser.renderErr e) "" -- FIXME[wd]: poprawic wyswietlanie bledow
    Right a -> return (fst a, view State.sourceMap $ snd a, view State.info $ snd a)



