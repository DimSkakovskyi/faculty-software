{-# LANGUAGE OverloadedStrings #-}

module PersonRepository
    ( listPersons
    , addPerson
    , updatePerson
    , deletePerson
    ) where

import Data.Text (Text)
import Database.MySQL.Base
import DbUtil (runCommand, runQuery)

listPersons :: MySQLConn -> IO [[MySQLValue]]
listPersons conn =
    runQuery conn
        "SELECT person_id, full_name, person_type, department, email \
        \FROM persons ORDER BY person_id"
        []

addPerson :: MySQLConn -> Text -> Text -> Text -> Text -> IO ()
addPerson conn name personType department email =
    runCommand conn
        "INSERT INTO persons (full_name, person_type, department, email) \
        \VALUES (?, ?, ?, ?)"
        [ MySQLText name, MySQLText personType
        , MySQLText department, MySQLText email
        ]

updatePerson :: MySQLConn -> Int -> Text -> Text -> Text -> Text -> IO ()
updatePerson conn personId name personType department email =
    runCommand conn
        "UPDATE persons SET full_name = ?, person_type = ?, \
        \department = ?, email = ? WHERE person_id = ?"
        [ MySQLText name, MySQLText personType
        , MySQLText department, MySQLText email
        , MySQLInt32 (fromIntegral personId)
        ]

deletePerson :: MySQLConn -> Int -> IO ()
deletePerson conn personId =
    runCommand conn
        "DELETE FROM persons WHERE person_id = ?"
        [MySQLInt32 (fromIntegral personId)]
