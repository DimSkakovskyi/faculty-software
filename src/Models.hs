{-# LANGUAGE OverloadedStrings #-}

module Models where

import Data.Text (Text)

data PersonType
    = Student
    | Teacher
    deriving (Show, Eq)

data Person = Person
    { personId         :: Int
    , personName       :: Text
    , personType       :: PersonType
    , personDepartment :: Text
    , personEmail      :: Text
    } deriving (Show, Eq)

data SoftwarePackage = SoftwarePackage
    { packageId          :: Int
    , packageName        :: Text
    , packageDescription :: Text
    , packageVersion     :: Text
    , packageStatus      :: Text
    } deriving (Show, Eq)

class DbEntity a where
    entityId :: a -> Int
    displayName :: a -> Text

instance DbEntity Person where
    entityId = personId
    displayName = personName

instance DbEntity SoftwarePackage where
    entityId = packageId
    displayName = packageName