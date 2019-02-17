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
import Prelude (Unit, bind)

appendTextFile :: String -> String -> Aff Unit
appendTextFile src dst = do
  d <- Fs.readTextFile Encoding.UTF8 src
  Fs.appendTextFile Encoding.UTF8 dst d

copyTextFile :: String -> String -> Aff Unit
copyTextFile src dst = do
  d <- Fs.readTextFile Encoding.UTF8 src
  Fs.writeTextFile Encoding.UTF8 dst d

makeDirectory :: String -> Aff Unit
makeDirectory = Fs.mkdir

readTextFile :: String -> Aff String
readTextFile = Fs.readTextFile Encoding.UTF8

writeTextFile :: String -> String -> Aff Unit
writeTextFile = Fs.writeTextFile Encoding.UTF8
