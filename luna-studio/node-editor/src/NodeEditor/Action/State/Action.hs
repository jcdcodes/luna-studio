module NodeEditor.Action.State.Action where

import           Common.Prelude
import qualified Data.Map                             as Map
import qualified Data.Set                             as Set
import           NodeEditor.Action.Command            (Command)
import           NodeEditor.React.Model.Visualization (VisualizationMode (FullScreen))
import           NodeEditor.State.Action              (Action (end, update), ActionRep, SomeAction,
                                                       VisualizationActive (VisualizationActive), fromSomeAction, overlappingActions,
                                                       someAction)
import           NodeEditor.State.Global              (State, actions, currentActions)


checkSomeAction :: ActionRep -> Command State (Maybe (SomeAction (Command State)))
checkSomeAction actionRep = Map.lookup actionRep <$> use (actions . currentActions)

checkAction :: Action (Command State) a => ActionRep -> Command State (Maybe a)
checkAction actionRep = do
    maySomeAction <- checkSomeAction actionRep
    return $ join $ fromSomeAction <$> maySomeAction

checkIfActionPerfoming :: ActionRep -> Command State Bool
checkIfActionPerfoming actionRep = Map.member actionRep <$> use (actions . currentActions)

runningActions :: Command State [ActionRep]
runningActions = Map.keys <$> use (actions . currentActions)

getCurrentOverlappingActions :: ActionRep -> Command State [SomeAction (Command State)]
getCurrentOverlappingActions a = do
    let checkOverlap :: ActionRep -> ActionRep -> Bool
        checkOverlap a1 a2 = any (Set.isSubsetOf (Set.fromList [a1, a2])) overlappingActions
        overlappingActionReps = filter (checkOverlap a) <$> runningActions
    ca <- use (actions . currentActions)
    catMaybes <$> map (flip Map.lookup ca) <$> overlappingActionReps

beginActionWithKey :: Action (Command State) a => ActionRep -> a -> Command State ()
beginActionWithKey key action = do
    currentOverlappingActions <- getCurrentOverlappingActions key
    mapM_ end currentOverlappingActions
    update action

continueActionWithKey :: Action (Command State) a => ActionRep -> (a -> Command State ()) -> Command State ()
continueActionWithKey key run = do
    maySomeAction <- use $ actions . currentActions . at key
    mapM_ run $ maySomeAction >>= fromSomeAction

updateActionWithKey :: Action (Command State) a => ActionRep -> a -> Command State ()
updateActionWithKey key action = actions . currentActions . at key ?= someAction action

removeActionFromState :: ActionRep -> Command State ()
removeActionFromState key = actions . currentActions %= Map.delete key

endAll :: Command State ()
endAll = mapM_ end =<< use (actions . currentActions)

endAllButVisualizationZoomed :: Command State ()
endAllButVisualizationZoomed = mapM_ endAction =<< use (actions . currentActions) where
    endAction action = case fromSomeAction action of
        Just (VisualizationActive _ _ FullScreen) -> return ()
        _                                         -> end action