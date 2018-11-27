module Main (main) where

import Data.Either (either)
import Effect (Effect)
import Effect.Aff (runAff_)
import Effect.Exception (throwException)
import Node.Encoding as Encoding
import Node.FS.Aff as Fs
import Prelude (Unit, bind, pure, unit)

main :: Effect Unit
main = do
  runAff_ (either (throwException) pure) do
    license <- Fs.readTextFile Encoding.UTF8 "templates/LICENSE"
    _ <- Fs.writeTextFile Encoding.UTF8 "LICENSE" license
    readme <- Fs.readTextFile Encoding.UTF8 "templates/README.md"
    _ <- Fs.appendTextFile Encoding.UTF8 "README.md" readme
    pure unit
