{-# Language FlexibleContexts #-}

module GitHUD.Terminal.Types (
  Color(..)
  , ColorIntensity(..)
  , Shell(..)
  , OutputConfig(..)
  , buildOutputConfig
  , Prompt
  , TerminalState
  , ShellOutput
  , getShell
  , getRepoState
  , getConfig
  ) where

import Control.Monad.Reader (Reader, MonadReader, ask, liftM)
import Control.Monad.Writer (WriterT)

import GitHUD.Config.Types
import GitHUD.Git.Types

data Color = Black | Red | Green | Yellow | Blue | Magenta | Cyan | White
data ColorIntensity = Dull | Vivid
data Shell = ZSH | Other deriving (Eq, Show)
data OutputConfig = OutputConfig {
  _shell :: Shell
  , _repoState :: GitRepoState
  , _config :: Config
}

buildOutputConfig :: Shell
                  -> GitRepoState
                  -> Config
                  -> OutputConfig
buildOutputConfig shell repoState config = OutputConfig {
  _shell = shell
  , _repoState = repoState
  , _config = config
}

getShell :: MonadReader OutputConfig m => m Shell
getShell = liftM _shell $ ask

getRepoState :: MonadReader OutputConfig m => m GitRepoState
getRepoState = liftM _repoState $ ask

getConfig :: MonadReader OutputConfig m => m Config
getConfig = liftM _config $ ask

type Prompt = String

type TerminalState = Reader OutputConfig String

type ShellOutput = WriterT Prompt (Reader OutputConfig) ()

