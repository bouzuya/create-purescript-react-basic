module Main (main) where

import Data.Either (either)
import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Aff (Aff, runAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Exception (throw, throwException)
import Foreign (Foreign)
import Node.ChildProcess as ChildProcess
import Node.Encoding as Encoding
import Node.FS.Aff as Fs
import Node.Globals (__dirname)
import Node.Path as Path
import Prelude (Unit, bind, discard, pure, unit, void)
import Simple.JSON as SimpleJSON

exec :: String -> Array String -> Aff Unit
exec file args =
  void
    (liftEffect
      (ChildProcess.execFileSync file args ChildProcess.defaultExecSyncOptions))

addLicenseAndUpdateReadme :: Aff Unit
addLicenseAndUpdateReadme = do
  dir <- pure (Path.concat [__dirname, "templates"])
  license <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "LICENSE"])
  _ <- Fs.writeTextFile Encoding.UTF8 "LICENSE" license
  readme <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "README.md"])
  _ <- Fs.appendTextFile Encoding.UTF8 "README.md" readme
  pure unit

type PackageJson =
  { name :: String
  , description :: String
  , verison :: String
  , author :: String
  , bugs :: { url :: String }
  , devDependencies :: Foreign
  , homepage :: String
  , keywords :: Array String
  , license :: String
  , main :: String
  , repository :: { type :: String, url :: String }
  , scripts :: Foreign
  }

initPackageJson :: { name :: String, description :: String } -> Aff Unit
initPackageJson { name, description } = do
  exec "npm" ["init", "--yes"]
  exec "npm" ["install", "--save-dev", "npm-run-all", "psc-package-bin-simple", "purescript"]
  packageJsonText <- Fs.readTextFile Encoding.UTF8 "package.json"
  packageJsonRecord <-
    liftEffect
      (maybe
        (throw "invalid package.json")
        pure
        (SimpleJSON.readJSON_ packageJsonText :: Maybe PackageJson))
  let
    jsonText =
      SimpleJSON.writeJSON
        (packageJsonRecord
          {
            -- TODO: fix author format
            -- author =
            --   { email: "m@bouzuya.net"
            --   , name: "bouzuya"
            --   , url: "https://bouzuya.net/"
            --   }
            scripts =
              SimpleJSON.write
              { build: "psc-package sources | xargs purs compile 'src/**/*.purs' 'test/**/*.purs'"
              , bundle: "purs bundle 'output/**/*.js' --main Main --module Main --output index.js"
              , "install:psc-package": "psc-package install"
              , prepare: "npm-run-all -s 'install:psc-package' build bundle"
              , "psc-package": "psc-package"
              , purs: "purs"
              , repl: "psc-package repl -- 'test/**/*.purs'"
              , start: "node --eval \"require('./output/Main').main();\""
              , test: "node --eval \"require('./output/Test.Main').main();\""
              }
          })
  Fs.writeTextFile Encoding.UTF8 "package.json" jsonText

initPscPackageJson :: Aff Unit
initPscPackageJson = do
  log "initialize psc-package.json..."
  exec "npm" ["run", "psc-package", "--", "init"]
  exec "npm" ["run", "psc-package", "--", "install", "psci-support"]
  exec "npm" ["run", "psc-package", "--", "install", "test-unit"]

addDummyCodes :: Aff Unit
addDummyCodes = do
  dir <- pure (Path.concat [__dirname, "templates"])
  Fs.mkdir "src"
  src <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "src", "Main.purs"])
  _ <- Fs.writeTextFile Encoding.UTF8 (Path.concat ["src", "Main.purs"]) src
  Fs.mkdir "test"
  test <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "test", "Main.purs"])
  _ <- Fs.appendTextFile Encoding.UTF8 (Path.concat ["test", "Main.purs"]) test
  pure unit

addReactBasic :: Aff Unit
addReactBasic = do
  log "add react-basic deps..."
  exec "npm" ["install", "react", "react-dom"]
  exec "npm" ["run", "psc-package", "--", "install", "react-basic"]

main :: Effect Unit
main = do
  runAff_ (either (throwException) pure) do
    addLicenseAndUpdateReadme
    initPackageJson { name: "NAME", description: "DESCRIPTION" }
    addDummyCodes
    initPscPackageJson
    addReactBasic
