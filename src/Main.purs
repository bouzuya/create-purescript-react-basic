module Main (main) where

import Data.Either (either)
import Effect (Effect)
import Effect.Aff (Aff, runAff_)
import Effect.Exception (throwException)
import Node.Encoding as Encoding
import Node.FS.Aff as Fs
import Node.Globals (__dirname)
import Node.Path as Path
import Prelude (Unit, bind, discard, pure, unit, (<>))
import Simple.JSON (writeJSON)

addLicenseAndUpdateReadme :: Aff Unit
addLicenseAndUpdateReadme = do
  dir <- pure (Path.concat [__dirname, "templates"])
  license <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "LICENSE"])
  _ <- Fs.writeTextFile Encoding.UTF8 "LICENSE" license
  readme <- Fs.readTextFile Encoding.UTF8 (Path.concat [dir, "README.md"])
  _ <- Fs.appendTextFile Encoding.UTF8 "README.md" readme
  pure unit

initPackageJson :: { name :: String, description :: String } -> Aff Unit
initPackageJson { name, description }= do
  let
    pkg =
      { name
      , description
      , verison: "0.0.0"
      , author:
        { email: "m@bouzuya.net"
        , name: "bouzuya"
        , url: "https://bouzuya.net/"
        }
      , bugs:
        { url: "https://github.com/bouzuya/" <> name <> "/issues"
        }
      , devDependencies:
        {
          "npm-run-all": "^4.1.5",
          "psc-package-bin-simple": "^2.0.1",
          "purescript": "^0.12.1"
        }
      , homepage: "https://github.com/bouzuya/" <> name <> "#readme"
      , keywords: [] :: Array String
      , license: "MIT"
      , main: "index.js"
      , repository:
        { type: "git"
        , url: "git+https://github.com/bouzuya/" <> name <> ".git"
        }
      , scripts:
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
      }
    jsonText = writeJSON pkg
  Fs.writeTextFile Encoding.UTF8 "package.json" jsonText

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

main :: Effect Unit
main = do
  runAff_ (either (throwException) pure) do
    addLicenseAndUpdateReadme
    initPackageJson { name: "NAME", description: "DESCRIPTION" }
    addDummyCodes
