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

appendTextFile :: String -> String -> Aff Unit
appendTextFile src dst = do
  d <- Fs.readTextFile Encoding.UTF8 src
  Fs.appendTextFile Encoding.UTF8 dst d

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
  appendTextFile (Path.concat [dir, "README.md"]) "README.md"

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
  exec "npm" ["install", "--save-dev", "npm-run-all", "parcel-bundler", "purescript", "purescript-spago"]
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
              { build: "spago build"
              , bundle: "npm-run-all -s 'bundle:purs' 'bundle:parcel'"
              , "bundle:parcel": "parcel build ./index.html"
              , "bundle:purs": "purs bundle 'output/**/*.js' --main Main --module Main --output bundle.js"
              , "docs": "spago sources | xargs purs docs --format html 'src/**/*.purs'"
              , "install:purs": "spago install"
              , prepare: "npm-run-all -s 'install:purs' build"
              , purs: "purs"
              , repl: "spago repl"
              , serve: "parcel ./index.html"
              , spago: "spago"
              , start: "node --eval \"require('./output/Main').main();\""
              , test: "node --eval \"require('./output/Test.Main').main();\""
              }
          })
  Fs.writeTextFile Encoding.UTF8 "package.json" jsonText

initSpagoDhall :: Aff Unit
initSpagoDhall = do
  log "initialize spago.dhall..."
  dir <- pure (Path.concat [__dirname, "templates"])
  copyTextFile
    (Path.concat [dir, "spago.dhall"])
    (Path.concat ["spago.dhall"])
  -- exec "npm" ["run", "spago", "--", "init"]
  exec "npm" ["run", "spago" , "--", "install", "psci-support", "test-unit"]

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

addPackagesDhall :: Aff Unit
addPackagesDhall = do
  log "add packages.dhall..."
  dir <- pure (Path.concat [__dirname, "templates"])
  copyTextFile
    (Path.concat [dir, "packages.dhall"])
    (Path.concat ["packages.dhall"])

addReactBasic :: Aff Unit
addReactBasic = do
  log "add react-basic deps..."
  exec "npm" ["install", "react", "react-dom"]
  exec "npm" ["run", "spago", "--", "install", "react-basic"]

addGitIgnore :: Aff Unit
addGitIgnore = do
  log "add .gitignore..."
  dir <- pure (Path.concat [__dirname, "templates"])
  copyTextFile (Path.concat [dir, "_gitignore"]) ".gitignore"

addTravisYml :: Aff Unit
addTravisYml = do
  log "add .travis.yml..."
  dir <- pure (Path.concat [__dirname, "templates"])
  copyTextFile (Path.concat [dir, "_travis.yml"]) ".travis.yml"

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
    initSpagoDhall
    addPackagesDhall
    addReactBasic
    addGitIgnore
    addTravisYml
    addIndexHtml
