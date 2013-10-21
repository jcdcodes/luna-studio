---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Batch.Samples.Std where

import           Flowbox.Prelude                       
import qualified Flowbox.Batch.Project.Project       as Project
import           Flowbox.Batch.Project.Project         (Project)
import qualified Flowbox.Luna.Network.Def.DefManager as DefManager
import           Flowbox.Luna.Network.Def.DefManager   (DefManager)
import qualified Flowbox.Luna.Network.Def.Definition as Definition
import           Flowbox.Luna.Network.Def.Definition   (Definition)
import qualified Flowbox.Luna.Network.Graph.Graph    as Graph
import qualified Flowbox.Luna.Lib.LibManager         as LibManager
import           Flowbox.Luna.Lib.LibManager           (LibManager)
import qualified Flowbox.Luna.Lib.Library            as Library
import           Flowbox.Luna.Lib.Library              (Library)
import           Flowbox.Luna.XOLD.Type.Type           (Type)
import qualified Flowbox.Luna.XOLD.Type.Type         as Type
import qualified Flowbox.System.UniPath              as UniPath
import           Flowbox.System.UniPath                (UniPath)



mkDefinition :: Type -> Definition
mkDefinition acls = Definition.empty { Definition.cls = acls
                                     , Definition.graph = Graph.empty
                                     }

mkModule :: String -> Definition
mkModule name = mkDefinition (Type.mkModule name ) 


mkClass :: String -> Definition
mkClass name  = mkDefinition (Type.mkClass name)


mkFunction :: String -> [Type] -> [Type] -> Definition
mkFunction name inputs outputs = mkDefinition $ Type.Function name (Type.Tuple inputs) (Type.Tuple outputs)


listToDefs :: [String] -> Definition.ID -> Definition.ID -> (String -> Definition)
           -> [(Definition.ID, Definition.ID, Definition)]
listToDefs l start parentID mk = map (\(i, n)-> (parentID, i, mk n)) $ zip [start..] l


types :: [String]
types = ["Int", "Float", "String", "Char"]


cls_console :: Definition
cls_console = Definition.empty { Definition.cls   = Type.Class "Console" [] []
                               , Definition.graph = Graph.empty
                               }


addSomeDefs :: DefManager -> DefManager
addSomeDefs defs = DefManager.addToParent (0, 12, mkFunction "at"        [ Type.Named "self"    $ Type.TypeName "String"
                                                                         , Type.Named "index"   $ Type.TypeName "Int"] 
                                                                         [ Type.Named "element" $ Type.TypeName "Char"])
                 $ DefManager.addToParent (0, 11, mkFunction "contains"  [ Type.Named "self"    $ Type.TypeName "String"
                                                                         , Type.Named "element" $ Type.TypeName "Char"] 
                                                                         [ Type.Named "contains"$ Type.TypeName "Bool"])
                 $ DefManager.addToParent (0, 10, mkFunction "length"    [ Type.Named "self"    $ Type.TypeName "String"]
                                                                         [ Type.Named "length"  $ Type.TypeName "Int"])
                 $ DefManager.addToParent (0, 9 , mkFunction "add"       [ Type.Named "self"    $ Type.TypeName "Int"
                                                                         , Type.Named "value"   $ Type.TypeName "Int" ] 
                                                                         [ Type.Named "result"  $ Type.TypeName "Int"])
                 $ DefManager.addToParent (0, 8 , mkFunction "sub"       [ Type.Named "self"    $ Type.TypeName "Int"
                                                                         , Type.Named "value"   $ Type.TypeName "Int" ] 
                                                                         [ Type.Named "result"  $ Type.TypeName "Int"])
                 $ DefManager.addToParent (0, 7 , mkFunction "mul"       [ Type.Named "self"    $ Type.TypeName "Int"
                                                                         , Type.Named "value"   $ Type.TypeName "Int" ] 
                                                                         [ Type.Named "result"  $ Type.TypeName "Int"])
                 $ DefManager.addToParent (4, 5 , mkFunction "print"     [ Type.Named "self"    $ Type.TypeName "Console"
                                                                         , Type.Named "obj"     $ Type.TypeName "String" ] 
                                                                         [ Type.Named "console" $ Type.TypeName "Console"])
                 $ DefManager.addToParent (0, 4 , mkClass    "Console")
                 $ DefManager.addToParent (1, 3 , mkFunction "writeFile" [ Type.Named "self"    $ Type.TypeName "File"
                                                                         , Type.Named "name"    $ Type.TypeName "String" 
                                                                         , Type.Named "content" $ Type.TypeName "String" ]
                                                                         [ ])
                 $ DefManager.addToParent (1, 2 , mkFunction "readFile"  [ Type.Named "self"    $ Type.TypeName "File"
                                                                         , Type.Named "name"    $ Type.TypeName "String" ]
                                                                         [ Type.Named "content" $ Type.TypeName "String" ])
                 $ DefManager.addToParent (0, 1 , mkClass    "File")
                 -- $ DefManager.addToParentMany (listToDefs types 1000 0 mkClass)
                 $ defs


emptyStdLibrary :: UniPath -> Library
emptyStdLibrary rootpath = Library.make "std" $ UniPath.append "stdlib.lunalib" rootpath
    
     
userLibrary :: UniPath -> Library
userLibrary rootpath = Library.make "workspace" $ UniPath.append "workspace.lunalib" rootpath


stdLibrary :: UniPath -> Library
stdLibrary rootpath = lib{Library.defs = addSomeDefs $ Library.defs lib} where
    lib = emptyStdLibrary rootpath


libManager :: UniPath -> LibManager
libManager rootpath = LibManager.insNode (1, userLibrary rootpath)
                    $ LibManager.insNode (0, stdLibrary  rootpath)
                    $ LibManager.empty


project :: Project
project = addDefaultLibraries 
        $ Project.empty { Project.name = "test project"
                        , Project.path = UniPath.fromUnixString "luna"
                        , Project.libs = LibManager.empty
                        } where


addDefaultLibraries :: Project -> Project
addDefaultLibraries proj = proj {Project.libs = libManager rootpath} where
    rootpath = Project.path proj
