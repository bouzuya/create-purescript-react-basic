module Main (main) where

import Data.Array as Array
import Data.Array.NonEmpty as NonEmptyArray
import Data.Either (either, hush)
import Data.Maybe (Maybe, maybe)
import Data.String.Regex as Regex
import Data.String.Regex.Flags as RegexFlags
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
import Prelude (Unit, bind, discard, join, map, pure, void)
import Simple.JSON as SimpleJSON

type PackageJson =
  { name :: String
  , description :: String
  , version :: String
  , author :: Maybe Foreign
  , bugs :: { url :: String }
  , devDependencies :: Foreign
  , homepage :: String
  , keywords :: Array String
  , license :: String
  , main :: String
  , repository :: { type :: String, url :: String }
  , scripts :: Foreign
  }

copyTextFile :: String -> String -> Aff Unit
copyTextFile src dst = do
  d <- Fs.readTextFile Encoding.UTF8 src
  Fs.writeTextFile Encoding.UTF8 dst d

exec :: String -> Array String -> Aff Unit
exec file args =
  void
    (liftEffect
      (ChildProcess.execFileSync file args ChildProcess.defaultExecSyncOptions))

addLicenseAndUpdateReadme :: Aff Unit
addLicenseAndUpdateReadme = do
  log "add license and update readme..."
  dir <- pure (Path.concat [__dirname, "templates"])
  copyTextFile (Path.concat [dir, "LICENSE"]) "LICENSE"
  copyTextFile (Path.concat [dir, "README.md"]) "README.md"

toAuthorRecord :: String -> Maybe { email :: String, name :: String, url :: String }
toAuthorRecord s = do
  regex <- hush (Regex.regex "^(.+)\\s+<(.+?)>\\s+\\((.+?)\\)$" RegexFlags.noFlags)
  matches <- map NonEmptyArray.toArray (Regex.match regex s)
  name <- join (Array.index matches 1)
  email <- join (Array.index matches 2)
  url <- join (Array.index matches 3)
  pure { email, name, url }

initPackageJson :: Aff Unit
initPackageJson = do
  log "initialize package.json..."
  exec "npm" ["init", "--yes"]
  exec "npm" ["install", "--save-dev", "npm-run-all", "parcel-bundler", "psc-package", "purescript"]
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
            author = do
              authorForeign <- packageJsonRecord.author
              authorString <- SimpleJSON.read_ authorForeign :: Maybe String
              authorRecord <- toAuthorRecord authorString
              pure (SimpleJSON.write authorRecord)
          , scripts =
              SimpleJSON.write
              { build: "psc-package sources | xargs purs compile 'src/**/*.purs' 'test/**/*.purs'"
              , bundle: "npm-run-all -s 'bundle:purs' 'bundle:parcel'"
              , "bundle:parcel": "parcel build ./index.html"
              , "bundle:purs": "purs bundle 'output/**/*.js' --main Main --module Main --output bundle.js"
              , "install:purs": "psc-package install"
              , prepare: "npm-run-all -s 'install:purs' build"
              , "psc-package": "psc-package"
              , purs: "purs"
              , repl: "psc-package repl -- 'test/**/*.purs'"
              , serve: "parcel ./index.html"
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
  log "add dummy codes..."
  dir <- pure (Path.concat [__dirname, "templates"])
  Fs.mkdir "src"
  copyTextFile
    (Path.concat [dir, "src", "Main.purs_"])
    (Path.concat ["src", "Main.purs"])
  copyTextFile
    (Path.concat [dir, "src", "Component.purs_"])
    (Path.concat ["src", "Component.purs"])
  Fs.mkdir "src/Component"
  copyTextFile
    (Path.concat [dir, "src", "Component", "App.purs_"])
    (Path.concat ["src", "Component", "App.purs"])
  Fs.mkdir "test"
  copyTextFile
    (Path.concat [dir, "test", "Main.purs_"])
    (Path.concat ["test", "Main.purs"])

addReactBasic :: Aff Unit
addReactBasic = do
  log "add react-basic deps..."
  exec "npm" ["install", "react", "react-dom"]
  exec "npm" ["run", "psc-package", "--", "install", "react-basic"]

addGitIgnore :: Aff Unit
addGitIgnore = do
  log "add .gitignore..."
  dir <- pure (Path.concat [__dirname, "templates"])
  copyTextFile (Path.concat [dir, "_gitignore"]) ".gitignore"

addIndexHtml :: Aff Unit
addIndexHtml = do
  log "add index.html and index.js"
  dir <- pure (Path.concat [__dirname, "templates"])
  copyTextFile (Path.concat [dir, "index.html"]) "index.html"
  copyTextFile (Path.concat [dir, "index.js"]) "index.js"

main :: Effect Unit
main = do
  runAff_ (either (throwException) pure) do
    addLicenseAndUpdateReadme
    initPackageJson
    addDummyCodes
    initPscPackageJson
    addReactBasic
    addGitIgnore
    addIndexHtml
