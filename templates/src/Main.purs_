module Main
  ( main
  ) where

import Component as Component
import Data.Maybe (maybe)
import Effect (Effect)
import Effect.Exception (throw)
import Prelude (Unit, bind, pure)
import React.Basic.DOM as H
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Web.HTML.Window (document)

main :: Effect Unit
main = do
  w <- window
  d <- document w
  containerMaybe <- getElementById "container" (toNonElementParentNode d)
  container <- maybe (throw "container not found") pure containerMaybe
  H.render Component.app container
