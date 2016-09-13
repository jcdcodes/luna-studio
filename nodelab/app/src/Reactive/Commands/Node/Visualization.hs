{-# LANGUAGE OverloadedStrings #-}
module Reactive.Commands.Node.Visualization
    ( removeVisualization
    , visualizeNodeValueReprs
    , visualizeError
    ) where

import           Utils.PreludePlus
import           Utils.Vector

import           Data.List.Split                 (wordsBy)
import qualified Data.Text.Lazy                  as Text

import Control.Arrow ((***))

import           Object.UITypes                  (WidgetId)
import           Object.Widget                   (DisplayObjectClass, CompositeWidget)
import qualified Object.Widget.Label             as Label
import           Object.Widget.DataFrame         (DataFrame)
import qualified Object.Widget.DataFrame         as DataFrame
import qualified Object.Widget.Graphics          as Graphics
import qualified Object.Widget.LongText          as LongText
import qualified Object.Widget.Plots.Image       as Image
import qualified UI.Handlers.Node                as Node
import qualified UI.Instances                    ()

import           Reactive.Commands.Command       (Command, performIO)
import qualified Reactive.Commands.UIRegistry    as UICmd
import qualified Reactive.State.UIRegistry       as UIRegistry

import qualified Style.Node                      as Style

import           Empire.API.Data.DefaultValue    (Value (..))
import qualified Empire.API.Data.DefaultValue    as DefaultValue
import qualified Empire.API.Data.Error           as LunaError
import           Empire.API.Data.TypeRep         (TypeRep)

import qualified Graphics.API                    as GR
import qualified Utils.Shader                    as Shader

visualizeError :: WidgetId -> LunaError.Error TypeRep -> Command UIRegistry.State ()
visualizeError id err = do
    removeVisualization id
    groupId <- Node.valueGroupId id
    let msg  = case err of
            LunaError.ImportError   name     -> "Cannot find symbol \"" <> name        <> "\""
            LunaError.NoMethodError name tpe -> "Cannot find method \"" <> name        <> "\" for type \"" <> toString tpe <> "\""
            LunaError.TypeError     t1   t2  -> "Cannot match type  \"" <> toString t1 <> "\" with \""     <> toString t2  <> "\""
            LunaError.RuntimeError  msg      -> "Runtime error: " <> msg
        widget = LongText.create (Vector2 200 200) (Text.pack msg) LongText.Left LongText.Code
    UICmd.register_ groupId widget def

removeVisualization :: WidgetId -> Command UIRegistry.State ()
removeVisualization id = do
    groupId <- Node.valueGroupId id
    widgets <- UICmd.children groupId
    void $ mapM UICmd.removeWidget widgets


listTable :: [Text] -> DataFrame
listTable col = DataFrame.create Style.plotSize ["Index", "Value"] rows where
    idxs = Text.pack . show <$> take (length col) [1..]
    cols = [idxs, col]
    rows = transpose cols

mapTuple = join (***)

listTablePairs :: [(Text, Text)] -> DataFrame
listTablePairs rows = DataFrame.create Style.plotSize ["fst", "snd"] $ (\(f,s) -> [f,s]) <$> rows

visualize :: (Eq a, CompositeWidget a, DisplayObjectClass a) => Int -> WidgetId -> (WidgetId -> Command UIRegistry.State ()) -> (a -> a) -> Command UIRegistry.State ()
visualize visIx id create update = do
    groupId <- Node.valueGroupId id
    currentVisualizations <- UICmd.children groupId
    let currentVisualization = currentVisualizations ^? ix visIx
        cleanup = do
            widgets <- UICmd.children groupId
            void $ mapM UICmd.removeWidget widgets

    case currentVisualization of
        Nothing -> do
            -- cleanup
            -- performIO $ putStrLn "Not found"
            create groupId
        Just currentVis -> do
            status <- UICmd.tryUpdate currentVis update
            -- performIO $ putStrLn $ "update " <> (show status) <> " " <> (show visIx) <> " " <> (show currentVisualization) <> " " <> (show currentVisualizations)
            when (status == False) $ do
                UICmd.removeWidget currentVis
                create groupId

visualizeNodeValueReprs :: WidgetId -> [Value] -> Command UIRegistry.State ()
visualizeNodeValueReprs id values = mapM_ (uncurry $ visualizeNodeValue id) (zip [0..] values)

visualizeNodeValue :: WidgetId -> Int -> Value -> Command UIRegistry.State ()
visualizeNodeValue id visIx (StringList v) = do
    let widget = listTable $ Text.pack <$> v
        create groupId = UICmd.registerIx_ visIx groupId widget def
        update         = DataFrame.rows .~ (widget ^. DataFrame.rows)
    visualize visIx id create update

visualizeNodeValue id visIx (IntList v) = do
    let widget = listTable $ Text.pack . show <$> v
        create groupId = UICmd.registerIx_ visIx groupId widget def
        update         = DataFrame.rows .~ (widget ^. DataFrame.rows)
    visualize visIx id create update

visualizeNodeValue id visIx (DoubleList v) = do
    let widget = listTable $ Text.pack . show <$> v
        create groupId = UICmd.registerIx_ visIx groupId widget def
        update         = DataFrame.rows .~ (widget ^. DataFrame.rows)
    visualize visIx id create update

visualizeNodeValue id visIx (StringMaybeList v) = do
    let widget = listTable $ Text.pack . show <$> v
        create groupId = UICmd.registerIx_ visIx groupId widget def
        update         = DataFrame.rows .~ (widget ^. DataFrame.rows)
    visualize visIx id create update

visualizeNodeValue id visIx (StringStringMap v) = do
    let widget = listTablePairs $ (mapTuple Text.pack) <$> v
        create groupId = UICmd.registerIx_ visIx groupId widget def
        update         = DataFrame.rows .~ (widget ^. DataFrame.rows)
    visualize visIx id create update

visualizeNodeValue id visIx (IntPairList v) = do
    let widget = listTablePairs $ (mapTuple $ Text.pack . show) <$> v
        create groupId = UICmd.registerIx_ visIx groupId widget def
        update         = DataFrame.rows .~ (widget ^. DataFrame.rows)
    visualize visIx id create update

visualizeNodeValue id visIx (DoublePairList v) = do
    let widget = listTablePairs $ (mapTuple $ Text.pack . show) <$> v
        create groupId = UICmd.registerIx_ visIx groupId widget def
        update         = DataFrame.rows .~ (widget ^. DataFrame.rows)
    visualize visIx id create update

visualizeNodeValue id visIx (Image url w h) = do
    let create groupId = do
            let widget = Image.create (Vector2 w h) $ Text.pack url
            UICmd.registerIx_ visIx groupId widget def
        update = (Image.size . x .~ w)
               . (Image.size . y .~ h)
               . (Image.image  .~ (Text.pack url))
    visualize visIx id create update

visualizeNodeValue id visIx (StringValue str) = do
    let normalize = intercalate "<br />" . wordsBy (== '\n')
        create groupId = do
            let widget = LongText.create (Vector2 200 200) (Text.pack $ normalize str) LongText.Left LongText.Text
            UICmd.registerIx_ visIx groupId widget def
        update = LongText.value .~ (Text.pack $ normalize str)
    visualize visIx id create update

visualizeNodeValue id visIx (Lambda str) = do
    let normalize = intercalate "<br />" . wordsBy (== '\n')
        create groupId = do
            let widget = LongText.create (Vector2 200 200) (Text.pack $ normalize str) LongText.Left LongText.Code
            UICmd.registerIx_ visIx groupId widget def
        update = LongText.value .~ (Text.pack $ normalize str)
    visualize visIx id create update

visualizeNodeValue id visIx (DataFrame cols) = do
    let heads = Text.pack <$> fst <$> cols
        cols' = (fmap DefaultValue.stringify) <$> snd <$> cols
        rows = transpose cols'

    let create groupId = do
            let widget = DataFrame.create (Vector2 400 200) heads rows
            UICmd.registerIx_ visIx groupId widget def
        update      = (DataFrame.headers .~ heads)
                    . (DataFrame.rows    .~ rows )
    visualize visIx id create update

visualizeNodeValue id visIx (Graphics (GR.Graphics layers)) = do
    -- timer <- use
    let items  = fromLayers layers
    -- let items  = createItem <$> layers
        labels = createLabels =<< layers
        create groupId = do
            let widget = Graphics.create (Vector2 200 200) items labels
            UICmd.registerIx_ visIx groupId widget def
        update = (Graphics.items  .~ items )
               . (Graphics.labels .~ labels)
    visualize visIx id create update
    where
        createLabels (GR.Layer _ _ labels) = createLabel <$> labels
        createLabel  (GR.Label (GR.Point x y) fontSize align text) = Graphics.Label (Vector2 x y) fontSize (labelAlign align) $ Text.pack text
        labelAlign GR.Left   = Label.Left
        labelAlign GR.Center = Label.Center
        labelAlign GR.Right  = Label.Right

visualizeNodeValue _ _ _ = return ()


fromLayers :: [GR.Layer] -> [Graphics.Item]
fromLayers [l1, l2, l3] = [fromLayer1 l1, fromLayer2 l2, fromLayer3 l3]
fromLayers layers = createItem <$> layers where
    createItem (GR.Layer geometry trans _) = Graphics.Item (Text.pack shaderTxt) boxes size offset where
        Shader.ShaderBox shaderTxt (Shader.Location size offset) = Shader.createShaderBox geometry
        boxes = createBox <$> trans
        createBox (GR.Transformation sx sy dx dy rot refl) = Graphics.Box (Vector2 dx dy)

fromLayer1 :: GR.Layer -> Graphics.Item
fromLayer1 (GR.Layer geometry trans _) = Graphics.Item (Text.pack shaderTxt) boxes size offset where
    Shader.ShaderBox shaderTxt (Shader.Location size offset) = Shader.ShaderBox "s1" (Shader.Location (Vector2 0.848 0.008) (Vector2 0.0 0.0))
    boxes = createBox <$> trans
    createBox (GR.Transformation sx sy dx dy rot refl) = Graphics.Box (Vector2 dx dy)

fromLayer2 :: GR.Layer -> Graphics.Item
fromLayer2 (GR.Layer geometry trans _) = Graphics.Item (Text.pack shaderTxt) boxes size offset where
    Shader.ShaderBox shaderTxt (Shader.Location size offset) = Shader.ShaderBox "s2" (Shader.Location (Vector2 0.008 0.848) (Vector2 0.0 0.0))
    boxes = createBox <$> trans
    createBox (GR.Transformation sx sy dx dy rot refl) = Graphics.Box (Vector2 dx dy)

fromLayer3 :: GR.Layer -> Graphics.Item
fromLayer3 (GR.Layer geometry trans _) = Graphics.Item (Text.pack shaderTxt) boxes size offset where
    Shader.ShaderBox shaderTxt (Shader.Location size offset) = Shader.ShaderBox "s3" (Shader.Location (Vector2 0.032 0.032) (Vector2 0.0 0.0))
    boxes = createBox <$> trans
    createBox (GR.Transformation sx sy dx dy rot refl) = Graphics.Box (Vector2 dx dy)
