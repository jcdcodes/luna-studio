module Test.Luna.Typechecker.Internal.HasKindSpec (spec) where

import qualified Luna.Typechecker.Internal.AST.Alternatives as Alt
import qualified Luna.Typechecker.Internal.AST.Common       as Cmm
import qualified Luna.Typechecker.Internal.AST.Expr         as Exp
import qualified Luna.Typechecker.Internal.AST.Lit          as Lit
import qualified Luna.Typechecker.Internal.AST.Module       as Mod
import qualified Luna.Typechecker.Internal.AST.Pat          as Pat
import qualified Luna.Typechecker.Internal.AST.Scheme       as Sch
import qualified Luna.Typechecker.Internal.AST.TID          as TID
import qualified Luna.Typechecker.Internal.AST.Type         as Ty

import           Luna.Typechecker.Internal.AST.Kind         (Kind(..))

import qualified Luna.Typechecker.Internal.Ambiguity        as Amb
import qualified Luna.Typechecker.Internal.Assumptions      as Ass
import qualified Luna.Typechecker.Internal.BindingGroups    as Bnd
import qualified Luna.Typechecker.Internal.ContextReduction as CxR
import qualified Luna.Typechecker.Internal.Substitutions    as Sub
import qualified Luna.Typechecker.Internal.TIMonad          as TIM
import qualified Luna.Typechecker.Internal.Typeclasses      as Tcl
import qualified Luna.Typechecker.Internal.TypeInference    as Inf
import qualified Luna.Typechecker.Internal.Unification      as Uni
import qualified Luna.Typechecker                           as Typechecker

import           Luna.Typechecker.Internal.HasKind          (kind)


import           Test.Hspec
import           Test.QuickCheck
import           Control.Exception                          (evaluate)


spec :: Spec
spec = do
  describe "class HasKind t" $ do
    describe "instance HasKind Tyvar" $ do
      it "kind :: t -> Kind" $ do
        kind (Ty.Tyvar undefined Star)             `shouldBe` Star
        kind (Ty.Tyvar undefined (Kfun Star Star)) `shouldBe` (Kfun Star Star)
    describe "instance HasKind Tycon" $ do
      it "kind :: t -> Kind" $ do
        kind (Ty.Tycon undefined Star)             `shouldBe` Star
        kind (Ty.Tycon undefined (Kfun Star Star)) `shouldBe` (Kfun Star Star)
    describe "instance HasKind Type" $ do
      it "kind :: t -> Kind" $ do
        kind Ty.tUnit                              `shouldBe` Star
        kind Ty.tChar                              `shouldBe` Star
        kind Ty.tInt                               `shouldBe` Star
        kind Ty.tInteger                           `shouldBe` Star
        kind Ty.tFloat                             `shouldBe` Star
        kind Ty.tDouble                            `shouldBe` Star

        kind Ty.tList                              `shouldBe` Kfun Star Star
        kind Ty.tArrow                             `shouldBe` Kfun Star (Kfun Star Star)
        kind Ty.tTuple2                            `shouldBe` Kfun Star (Kfun Star Star)

        kind Ty.tString                            `shouldBe` Star

        kind (Ty.TVar $ Ty.Tyvar undefined Star)   `shouldBe` Star
        kind (Ty.TCon $ Ty.Tycon undefined Star)   `shouldBe` Star
        kind (Ty.TAp Ty.tList Ty.tInt)             `shouldBe` Star
        evaluate (kind (Ty.TAp Ty.tList Ty.tList)) `shouldThrow` errorCall "kind mismatch"
        evaluate (kind (Ty.TGen undefined))        `shouldThrow` anyErrorCall
