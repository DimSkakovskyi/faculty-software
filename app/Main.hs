{-# LANGUAGE OverloadedStrings #-}

module Main where

import Database.MySQL.Base
import qualified System.IO.Streams as Streams

import Database

main :: IO ()
main = do
    conn <- openConnection

    (_, stream) <- query_ conn
        "SELECT package_id, name, version, package_status \
        \FROM software_packages"

    rows <- Streams.toList stream
    mapM_ print rows

    close conn