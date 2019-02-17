module FS
  ( appendTextFile
  , copyTextFile
  , makeDirectory
  , readTextFile
  , writeTextFile
  ) where

import Effect.Aff (Aff)
import Node.Encoding as Encoding
import Node.FS.Aff as Fs
import Node.Path as Path
import Prelude (Unit, bind, discard, pure, unit)

appendTextFile :: String -> String -> Aff Unit
appendTextFile src dst = do
  d <- readTextFile src
  makeDirectory (Path.dirname dst)
  Fs.appendTextFile Encoding.UTF8 dst d

copyTextFile :: String -> String -> Aff Unit
copyTextFile src dst = do
  d <- readTextFile src
  writeTextFile dst d

makeDirectory :: String -> Aff Unit
makeDirectory dir = do
  dirExists <- Fs.exists dir
  if dirExists then pure unit else Fs.mkdir dir

readTextFile :: String -> Aff String
readTextFile = Fs.readTextFile Encoding.UTF8

writeTextFile :: String -> String -> Aff Unit
writeTextFile file text = do
  makeDirectory (Path.dirname file)
  Fs.writeTextFile Encoding.UTF8 file text
