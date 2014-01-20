{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE TypeOperators             #-}

{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE CPP           #-}

module Flowbox.Graphics.Mockup (
    module Flowbox.Graphics.Mockup,
    writeImageToBMP,
) where

import Control.Applicative

--import qualified Canny      as Canny
--import qualified Config     as Cfg
--import qualified Monitoring as Monitoring
--import qualified ParseArgs  as ParseArgs
--import qualified Wildfire   as Wildfire

import           Criterion.Main     (bench, bgroup, defaultMainWith, whnf)
import qualified Data.Label         as Label
import           Flowbox.Prelude    as P
import qualified System.Environment as Env
import qualified System.Exit        as Exit

import           Data.Array.Accelerate        ((:.) (..), Acc, Exp)
import qualified Data.Array.Accelerate        as A
import qualified Data.Array.Accelerate.IO     as A
import qualified Data.Array.Repa              as R
import qualified Data.Array.Repa.IO.BMP       as R
import qualified Data.Array.Repa.IO.DevIL     as DevIL
import qualified Data.Array.Repa.Repr.Unboxed as R
import           Data.Map                     (Map)
import qualified Data.Map                     as Map
import           Data.Monoid                  (Monoid, mempty)
import qualified Data.Fixed                   as F
import qualified Debug.Trace                  as D

import System.TimeIt (timeIt)

import Data.Array.Repa.Eval (Target)
import Data.Word            (Word8)

import           Flowbox.Graphics.Raster.Channel   (Channel)
import qualified Flowbox.Graphics.Raster.Channel   as Channel
import           Flowbox.Graphics.Raster.Image     (Image)
import qualified Flowbox.Graphics.Raster.Image     as Image
import qualified Flowbox.Graphics.Raster.IO        as Image
import           Flowbox.Graphics.Raster.IO        (writeImageToBMP)
import qualified Flowbox.Graphics.Raster.Repr.RGBA as RGBA
import           Flowbox.Graphics.Algorithms

--import           Control.Monad

import qualified Data.Array.Accelerate.Interpreter      as Interp

import qualified Data.Array.Repa.Eval as R
import Luna.Target.HS.Core hiding(print, return)

import Data.Bits ((.&.))


--import qualified Data.Array.Accelerate.CUDA             as CUDA

import Control.Monad.Trans.Either (hoistEither, runEitherT)

import           Flowbox.Prelude

testm x = x*3

readImage :: String -> IO (Safe(Image Float))
readImage fileIn = do
    print "Reading"
    img <- either (\_ -> mempty) id `fmap` Image.readImageFromBMP fileIn
    let Right img' = RGBA.decompose img
        rgba = Image.reprFloat img'
    return (Safe rgba)

writeImage :: FilePath -> Image Float -> IO (Safe())
writeImage file img = do
    let Right img' = RGBA.compose $ Image.reprWord8 img
    x <- writeImageToBMP (Interp.run) file img'
    print' x
    return $ Safe ()

--adjustCB :: A.Exp Float -> A.Exp Float -> Image Float -> IO (Safe(Image Float))
--adjustCB contrast brightness img = do
    --let Right img' = adjustCB_RGB contrast brightness img
    --return (Safe img')
