module GitHUD (
    githud
    ) where

import Control.Monad (when)
import Control.Monad.Reader
import System.Environment (getArgs)

import GitHUD.Terminal.Types
import GitHUD.Terminal.Base (showStrInColor)
import GitHUD.Git.Types
import GitHUD.Git.Parse.Base
import GitHUD.Git.Command (checkInGitDirectory)

githud :: IO ()
githud = do
  shell <- processArguments getArgs

  isGit <- checkInGitDirectory
  when isGit $ do
    repoState <- getGitRepoState

    runReaderT (buildOutput repoState) shell

    -- Necessary to properly terminate the output
    putStrLn ""

processArguments :: IO [String]
                 -> IO Shell
processArguments args = do
  arguments <- args
  if (not (null arguments)) && ((head arguments) == "zsh")
    then return ZSH
    else return Other

buildOutput :: GitRepoState
            -> ShellOutput
buildOutput repoState = do
  outputGitRepoIndicator
  outputRCommits (gitRemoteCommitsToPull repoState) (gitRemoteCommitsToPush repoState)
  outputLocalBranchName (gitLocalBranch repoState)
  outputCommitsToPullPush (gitCommitsToPull repoState) (gitCommitsToPush repoState)
  outputRepoState (gitLocalRepoChanges repoState)
  outputStashCount (gitStashCount repoState)

-- | Requires patched fonts for Powerline (Monaco Powerline)
outputGitRepoIndicator :: ShellOutput
outputGitRepoIndicator = do
  liftIO . putChar $ '\57504'
  liftIO . putChar $ ' '

outputLocalBranchName :: String -> ShellOutput
outputLocalBranchName localBranchName = do
  liftIO . putStr $ "["
  liftIO $ mapM_ putStr (lines localBranchName)
  liftIO . putStr $ "]"
  liftIO . putStr $ " "

outputcommitsToPush :: Int
                    -> ShellOutput
outputcommitsToPush commitCount = do
  when (commitCount > 0) $ do
    liftIO . putStr . show $ commitCount
    showStrInColor Green Vivid "\8593"

outputcommitsToPull :: Int
                    -> ShellOutput
outputcommitsToPull commitCount = do
  when (commitCount > 0) $ do
    liftIO . putStr . show $ commitCount
    showStrInColor Red Vivid "\8595"

outputRCommits :: Int          -- ^ commits to pull
               -> Int          -- ^ commits to push
               -> ShellOutput
outputRCommits pull push = do
  if (pull > 0) && (push > 0)
    then do
      liftIO . putStr $ "m "
      liftIO . putStr . show $ pull
      showStrInColor Green Vivid "\8644"
      liftIO . putStr . show $ push
    else (
      if (pull > 0)
        then do
          liftIO . putStr $ "m "
          showStrInColor Green Vivid "\8594"
          liftIO . putStr $ " "
          liftIO . putStr . show $ pull
        else (
          when (push > 0) $ do
            liftIO . putStr $ "m "
            showStrInColor Green Vivid "\8592"
            liftIO . putStr $ " "
            liftIO . putStr . show $ push
        )
    )

  when ((pull > 0) || (push > 0)) . liftIO . putStr $ " "

outputCommitsToPullPush :: Int          -- ^ commits to pull
                        -> Int          -- ^ commits to push
                        -> ShellOutput
outputCommitsToPullPush pull push = do
  if (pull > 0) && (push > 0)
    then do
      liftIO . putStr . show $ pull
      showStrInColor Green Vivid "\8645"
      liftIO . putStr . show $ push
    else
      if (pull > 0)
        then outputcommitsToPull pull
        else
          when (push > 0) $ outputcommitsToPush push

  when ((pull > 0) || (push > 0)) . liftIO . putStr $ " "

outputStashCount :: Int
                 -> ShellOutput
outputStashCount stashCount = do
  when (stashCount /= 0) $ do
    liftIO . putStr . show $ stashCount
    showStrInColor Green Vivid "≡ "

outputRepoState :: GitLocalRepoChanges
                -> ShellOutput
outputRepoState repoState = do
  showElem indexAdd repoState Green Vivid "A"
  showElem indexDel repoState Green Vivid "D"
  showElem indexMod repoState Green Vivid "M"
  when ((indexAdd repoState > 0) || (indexDel repoState > 0) || (indexMod repoState > 0)) . liftIO . putStr $ " "

  showElem localDel repoState Red Vivid "D"
  showElem localMod repoState Red Vivid "M"
  when ((localDel repoState > 0) || (localMod repoState > 0)) . liftIO . putStr $ " "

  showElem localAdd repoState White Vivid "A"
  when (localAdd repoState > 0) . liftIO . putStr $ " "

  showElem conflict repoState Green Vivid "C"
  when (conflict repoState > 0) . liftIO . putStr $ " "

showElem :: (GitLocalRepoChanges -> Int)
         -> GitLocalRepoChanges
         -> Color
         -> ColorIntensity
         -> String
         -> ShellOutput
showElem elemFunc repoState color intensity letter = do
  let num = elemFunc repoState
  when (num > 0) $ showNumState num color intensity letter

showNumState :: Int
         -> Color
         -> ColorIntensity
         -> String
         -> ShellOutput
showNumState num color intensity letter = do
    liftIO . putStr . show $ num
    showStrInColor color intensity letter
