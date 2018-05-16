{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE OverloadedStrings #-}
module NodeEditor.Action.Visualization where

import           Common.Action.Command                      (Command)
import           Common.Prelude
import qualified Data.Map                                   as Map
import           JS.Visualizers                             (notifyStreamRestart, registerVisualizerFrame, sendVisualizationData)
import           LunaStudio.Data.TypeRep                    (toConstructorRep)
import           NodeEditor.Action.Basic                    (selectNode, setNodeMeta)
import           NodeEditor.Action.State.Action             (beginActionWithKey, checkAction, checkIfActionPerfoming, continueActionWithKey,
                                                             removeActionFromState, updateActionWithKey)
import qualified NodeEditor.Action.State.NodeEditor as NodeEditor
import           NodeEditor.Action.State.NodeEditor         (setVisualizationMode, getExpressionNode, getExpressionNodeType, getNodeMeta, getNodeVisualizations,
                                                             getSelectedNodes, getVisualizationBackup, modifyExpressionNode, modifyNodeEditor,
                                                             modifySearcher)
import           NodeEditor.Action.UUID                     (getUUID)
import           NodeEditor.React.Model.Node.ExpressionNode (nodeLoc, visualizationsEnabled)
import           NodeEditor.React.Model.NodeEditor          (VisualizationBackup (StreamBackup, ValueBackup),
                                                             nodeVisualizations)
import qualified NodeEditor.React.Model.Searcher            as Searcher
import           NodeEditor.React.Model.Visualization       (Visualization (Visualization), VisualizationId,
                                                             Mode (Focused, FullScreen, Preview),
                                                             Parent (Node, Searcher),
                                                             Visualizer (Visualizer), VisualizerId,
                                                             visualizer, selectedVisualizerId, visualizationId, mode,
                                                             visualizations, visualizers)
import qualified NodeEditor.React.Model.Visualization       as Vis
import           NodeEditor.State.Action                    (Action (begin, continue, end, update),
                                                             DocVisualizationActive (DocVisualizationActive),
                                                             VisualizationActive (VisualizationActive), docVisualizationActiveAction,
                                                             docVisualizationActiveSelectedMode, docVisualizationActiveTriggeredByVis,
                                                             searcherAction, visualizationActiveAction, visualizationActiveNodeLoc,
                                                             visualizationActiveSelectedMode, visualizationActiveTriggeredByVis,
                                                             visualizationActiveVisualizationId)
import           NodeEditor.State.Global                    (State)


instance Action (Command State) VisualizationActive where
    begin action = do
        let nl    = action ^. visualizationActiveNodeLoc
            visId = action ^. visualizationActiveVisualizationId
        beginActionWithKey visualizationActiveAction action
        selectNode nl
        setVisualizationMode nl visId $ action ^. visualizationActiveSelectedMode
    continue     = continueActionWithKey visualizationActiveAction
    update       = updateActionWithKey   visualizationActiveAction
    end action   = do
        let nl    = action ^. visualizationActiveNodeLoc
            visId = action ^. visualizationActiveVisualizationId
        setVisualizationMode nl visId def
        removeActionFromState visualizationActiveAction
        when (action ^. visualizationActiveTriggeredByVis) $ begin $ action
            & visualizationActiveSelectedMode   .~ Focused
            & visualizationActiveTriggeredByVis .~ False

instance Action (Command State) DocVisualizationActive where
    begin action = do
        beginActionWithKey docVisualizationActiveAction action
        modifySearcher $ Searcher.mode . Searcher._Node . _2
            . Searcher.docVisInfo . _Just . mode
                .= action ^. docVisualizationActiveSelectedMode
    continue     = continueActionWithKey docVisualizationActiveAction
    update       = updateActionWithKey   docVisualizationActiveAction
    end action   = do
        modifySearcher $ Searcher.mode . Searcher._Node . _2
            . Searcher.docVisInfo . _Just . mode .= def
        removeActionFromState docVisualizationActiveAction
        when (action ^. docVisualizationActiveTriggeredByVis) $ begin $ action
            & docVisualizationActiveSelectedMode   .~ Focused
            & docVisualizationActiveTriggeredByVis .~ False


focusVisualization :: Parent -> VisualizationId -> Command State ()
focusVisualization (Node nl) visId
    = begin $ VisualizationActive nl visId Focused False
focusVisualization Searcher  _
    = begin $ DocVisualizationActive Focused False

exitVisualizationMode :: VisualizationActive -> Command State ()
exitVisualizationMode = end

exitDocVisualizationMode :: DocVisualizationActive -> Command State ()
exitDocVisualizationMode = end


selectVisualizer :: Parent -> VisualizationId -> VisualizerId
    -> Command State ()
selectVisualizer (Node nl) visId visualizerId = do
    continue (end :: VisualizationActive -> Command State ())
    NodeEditor.selectVisualizer nl visId visualizerId
selectVisualizer Searcher _ _ = $notImplemented


handleZoomVisualization :: Command State ()
handleZoomVisualization = do
    searcherActive <- checkIfActionPerfoming searcherAction
    let handleZoomVis = do
            mayMode <- view visualizationActiveSelectedMode
                `fmap2` checkAction visualizationActiveAction
            if mayMode == Just FullScreen
                then continue exitVisualizationMode
                else enterVisualizationMode FullScreen
        -- handleZoomDocVis = do
        --     mayDocMode <- view docVisualizationActiveSelectedMode
        --         `fmap2` checkAction docVisualizationActiveAction
        --     if mayDocMode == Just FullScreen
        --         then continue exitDocVisualizationMode
        --         else enterVisualizationMode FullScreen
    if searcherActive then return () else handleZoomVis

exitPreviewMode :: VisualizationActive -> Command State ()
exitPreviewMode action
    = when (Preview == action ^. visualizationActiveSelectedMode) $
        exitVisualizationMode action

exitDocPreviewMode :: DocVisualizationActive -> Command State ()
exitDocPreviewMode action
    = when (Preview == action ^. docVisualizationActiveSelectedMode) $
        exitDocVisualizationMode action

enterVisualizationMode :: Mode -> Command State ()
enterVisualizationMode visMode = do
    searcherActive <- checkIfActionPerfoming searcherAction
    -- let enterDocVisMode = do
    --         fromDocVis <- maybe False (\action -> action ^. docVisualizationActiveSelectedMode == Focused || action ^. docVisualizationActiveTriggeredByVis) <$> checkAction docVisualizationActiveAction
    --         begin $ DocVisualizationActive visMode fromDocVis
    let enterVisMode = do
            visLoc <- getSelectedNodes >>= \case
                [n] -> let nl = n ^. nodeLoc in
                    fmap (nl,) . maybe
                        def
                        (listToMaybe . Map.keys . view visualizations)
                        <$> getNodeVisualizations nl
                _   -> return Nothing
            fromVis <- maybe
                False
                (\action ->
                    action ^. visualizationActiveSelectedMode == Focused
                    || action ^. visualizationActiveTriggeredByVis
                )
                <$> checkAction visualizationActiveAction
            withJust visLoc $ \(nl, visId) -> begin
                $ VisualizationActive nl visId visMode fromVis
    if searcherActive then return () else enterVisMode

toggleVisualizations :: Parent -> Command State ()
toggleVisualizations (Node nl) = do
    modifyExpressionNode nl $ visualizationsEnabled %= not
    mayNodeMeta <- getNodeMeta nl
    withJust mayNodeMeta $ setNodeMeta nl
    stopVisualizationsForNode nl
    showVis <- maybe False (view visualizationsEnabled) <$> getExpressionNode nl
    when showVis $ startReadyVisualizations nl
toggleVisualizations Searcher = $notImplemented

-- instance Action (Command State) VisualizationDrag where
--     begin    = beginActionWithKey    visualizationDragAction
--     continue = continueActionWithKey visualizationDragAction
--     update   = updateActionWithKey   visualizationDragAction
--     end _    = removeActionFromState visualizationDragAction
--
-- pin :: NodeLoc -> Int -> Command State ()
-- pin nl visIx = do
--     mayNode <- getExpressionNode nl
--     withJust mayNode $ \node ->
--         modifyNodeEditor $
--             visualizations %= ((nl, visIx, node ^. position) :)
--
-- unpin :: NodeLoc -> Int -> Position -> Command State ()
-- unpin nl visIx pos =
--     modifyNodeEditor $ visualizations %= delete (nl, visIx, pos)
--
-- startDrag :: NodeLoc -> Int -> Position -> MouseEvent -> Command State ()
-- startDrag nl visIx pos evt = do
--     begin $ VisualizationDrag nl visIx pos
--     moveTo evt nl visIx pos
--
-- drag :: MouseEvent -> VisualizationDrag -> Command State ()
-- drag evt (VisualizationDrag nl visIx pos) = moveTo evt nl visIx pos
--
-- stopDrag :: MouseEvent -> VisualizationDrag ->  Command State ()
-- stopDrag evt (VisualizationDrag nl visIx pos) = do
--     moveTo evt nl visIx pos
--     removeActionFromState visualizationDragAction
--
-- moveTo :: MouseEvent -> NodeLoc -> Int -> Position -> Command State ()
-- moveTo evt nl visIx oldPos = do
--     pos <- workspacePosition evt
--     update $ VisualizationDrag nl visIx pos
--     modifyNodeEditor $ do
--         visualizations %= delete (nl, visIx, oldPos)
--         visualizations %= ((nl, visIx, pos) :)
