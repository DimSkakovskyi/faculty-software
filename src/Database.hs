{-# LANGUAGE OverloadedStrings #-}

module Database (openConnection) where

import Control.Exception (bracket_)
import qualified Data.Text as Text
import Data.Text.Encoding (encodeUtf8)
import Database.MySQL.Base
import System.Environment (lookupEnv)
import System.IO (hFlush, hGetEcho, hSetEcho, stdin, stdout)

openConnection :: IO MySQLConn
openConnection = do
    envUser <- lookupEnv "FACULTY_DB_USER"
    envPassword <- lookupEnv "FACULTY_DB_PASSWORD"
    user <- case envUser of
        Just value -> pure value
        Nothing -> do
            putStr "MySQL користувач [lab_user]: "
            hFlush stdout
            value <- getLine
            pure (if null value then "lab_user" else value)
    password <- case envPassword of
        Just value -> pure value
        Nothing -> do
            putStr "MySQL пароль: "
            hFlush stdout
            previousEcho <- hGetEcho stdin
            value <- bracket_
                (hSetEcho stdin False)
                (hSetEcho stdin previousEcho)
                getLine
            putStrLn ""
            pure value
    connect defaultConnectInfoMB4
        { ciHost = "127.0.0.1"
        , ciPort = 3306
        , ciUser = encodeUtf8 (Text.pack user)
        , ciPassword = encodeUtf8 (Text.pack password)
        , ciDatabase = "faculty_software"
        }
