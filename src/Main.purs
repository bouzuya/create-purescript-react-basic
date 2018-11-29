module Main (main) where

import Data.Either (either)
import Effect (Effect)
import Effect.Aff (Aff, runAff_)
import Effect.Exception (throwException)
import Node.Encoding as Encoding
import Node.FS.Aff as Fs
import Node.Globals (__dirname)
import Node.Path as Path
import Prelude (Unit, bind, pure, unit)

addLicenseAndUpdateReadme :: Aff Unit
addLicenseAndUpdateReadme = do
  dir <- pure (Path.concat [__dirname, "templates"])
  license <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "LICENSE"])
  _ <- Fs.writeTextFile Encoding.UTF8 "LICENSE" license
  readme <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "README.md"])
  _ <- Fs.appendTextFile Encoding.UTF8 "README.md" readme
  pure unit

main :: Effect Unit
main = do
  runAff_ (either (throwException) pure) do
    addLicenseAndUpdateReadme
