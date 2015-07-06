module JS.Utils where

import JS.Bindings



screenToGl :: (Double, Double) -> IO (Double, Double)
screenToGl (x, y) = do
    screenSizeX <- getScreenSizeX
    screenSizeY <- getScreenSizeY
    return (x - screenSizeX / 2.0, - y + screenSizeY / 2.0)


screenToNormalizedGl :: (Double, Double) -> IO (Double, Double)
screenToNormalizedGl (x, y) = do
    screenSizeX <- getScreenSizeX
    screenSizeY <- getScreenSizeY
    return (x / screenSizeX * 2.0 - 1.0, -(y / screenSizeY) * 2.0 + 1.0)


glToWorkspace :: (Double, Double) -> IO (Double, Double)
glToWorkspace (x, y) = do
    camFactor <- getCamFactor
    camPanX   <- getCamPanX
    camPanY   <- getCamPanY
    return (x / camFactor + camPanX, y / camFactor + camPanY)


screenToWorkspace :: (Double, Double) -> IO (Double, Double)
screenToWorkspace (x, y) = glToWorkspace =<< screenToGl (x, y)


workspaceToScreen :: (Double, Double) -> IO (Double, Double)
workspaceToScreen (x, y) = do
    camFactor <- getCamFactor
    camPanX   <- getCamPanX
    camPanY   <- getCamPanY
    return (x / camFactor + camPanX, y / camFactor + camPanY)

