{-# LANGUAGE OverloadedStrings #-}

module PackageRepository
    ( listPackages
    , findPackagesByName
    , addPackage
    , updatePackage
    , deletePackage
    , listDevelopers
    , assignDeveloper
    , removeDeveloper
    ) where

import Data.Text (Text)
import Database.MySQL.Base
import DbUtil (runCommand, runQuery)

listPackages :: MySQLConn -> IO [[MySQLValue]]
listPackages conn =
    runQuery conn
        "SELECT package_id, name, version, package_status \
        \FROM software_packages ORDER BY package_id"
        []

findPackagesByName :: MySQLConn -> Text -> IO [[MySQLValue]]
findPackagesByName conn name =
    runQuery conn
        "SELECT package_id, name, version, package_status \
        \FROM software_packages WHERE name LIKE ? ORDER BY name"
        [MySQLText ("%" <> name <> "%")]

addPackage :: MySQLConn -> Text -> Text -> Text -> IO ()
addPackage conn name description version =
    runCommand conn
        "INSERT INTO software_packages (name, description, version) \
        \VALUES (?, ?, ?)"
        [MySQLText name, MySQLText description, MySQLText version]

updatePackage :: MySQLConn -> Int -> Text -> Text -> Text -> Text -> IO ()
updatePackage conn packageId name description version status =
    runCommand conn
        "UPDATE software_packages SET name = ?, description = ?, \
        \version = ?, package_status = ? WHERE package_id = ?"
        [ MySQLText name, MySQLText description, MySQLText version
        , MySQLText status, MySQLInt32 (fromIntegral packageId)
        ]

deletePackage :: MySQLConn -> Int -> IO ()
deletePackage conn packageId =
    runCommand conn
        "DELETE FROM software_packages WHERE package_id = ?"
        [MySQLInt32 (fromIntegral packageId)]

listDevelopers :: MySQLConn -> Int -> IO [[MySQLValue]]
listDevelopers conn packageId =
    runQuery conn
        "SELECT p.person_id, p.full_name, pd.developer_role \
        \FROM package_developers pd \
        \JOIN persons p ON p.person_id = pd.person_id \
        \WHERE pd.package_id = ? ORDER BY p.full_name"
        [MySQLInt32 (fromIntegral packageId)]

assignDeveloper :: MySQLConn -> Int -> Int -> Text -> IO ()
assignDeveloper conn packageId personId role =
    runCommand conn
        "INSERT INTO package_developers \
        \(package_id, person_id, developer_role) VALUES (?, ?, ?) \
        \ON DUPLICATE KEY UPDATE developer_role = ?"
        [ MySQLInt32 (fromIntegral packageId)
        , MySQLInt32 (fromIntegral personId)
        , MySQLText role
        , MySQLText role
        ]

removeDeveloper :: MySQLConn -> Int -> Int -> IO ()
removeDeveloper conn packageId personId =
    runCommand conn
        "DELETE FROM package_developers \
        \WHERE package_id = ? AND person_id = ?"
        [ MySQLInt32 (fromIntegral packageId)
        , MySQLInt32 (fromIntegral personId)
        ]
