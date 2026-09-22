{-# LANGUAGE OverloadedStrings #-}

module Database
    ( openConnection
    ) where

import Database.MySQL.Base

openConnection :: IO MySQLConn
openConnection =
    connect defaultConnectInfoMB4
        { ciHost = "127.0.0.1"
        , ciPort = 3306
        , ciUser = "lab_user"
        , ciPassword = "20051210Dskuz2*"
        , ciDatabase = "faculty_software"
        }