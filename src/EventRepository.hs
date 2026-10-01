{-# LANGUAGE OverloadedStrings #-}

module EventRepository
    ( listSeminars
    , addSeminar
    , updateSeminar
    , deleteSeminar
    , listSeminarParticipants
    , addSeminarParticipant
    , removeSeminarParticipant
    , listDemonstrations
    , addDemonstration
    , updateDemonstration
    , deleteDemonstration
    , listTrials
    , addTrial
    , updateTrial
    , deleteTrial
    ) where

import Data.Text (Text)
import Database.MySQL.Base
import DbUtil (runCommand, runQuery)

intValue :: Int -> MySQLValue
intValue = MySQLInt32 . fromIntegral

listSeminars :: MySQLConn -> Int -> IO [[MySQLValue]]
listSeminars conn packageId =
    runQuery conn
        "SELECT seminar_id, topic, scheduled_at, location \
        \FROM seminars WHERE package_id = ? ORDER BY scheduled_at"
        [intValue packageId]

addSeminar :: MySQLConn -> Int -> Text -> Text -> Text -> IO ()
addSeminar conn packageId topic scheduledAt location =
    runCommand conn
        "INSERT INTO seminars (package_id, topic, scheduled_at, location) \
        \VALUES (?, ?, ?, ?)"
        [intValue packageId, MySQLText topic, MySQLText scheduledAt, MySQLText location]

updateSeminar :: MySQLConn -> Int -> Text -> Text -> Text -> IO ()
updateSeminar conn seminarId topic scheduledAt location =
    runCommand conn
        "UPDATE seminars SET topic = ?, scheduled_at = ?, location = ? \
        \WHERE seminar_id = ?"
        [MySQLText topic, MySQLText scheduledAt, MySQLText location, intValue seminarId]

deleteSeminar :: MySQLConn -> Int -> IO ()
deleteSeminar conn seminarId =
    runCommand conn "DELETE FROM seminars WHERE seminar_id = ?" [intValue seminarId]

listSeminarParticipants :: MySQLConn -> Int -> IO [[MySQLValue]]
listSeminarParticipants conn seminarId =
    runQuery conn
        "SELECT p.person_id, p.full_name, p.person_type \
        \FROM seminar_participants sp \
        \JOIN persons p ON p.person_id = sp.person_id \
        \WHERE sp.seminar_id = ? ORDER BY p.full_name"
        [intValue seminarId]

addSeminarParticipant :: MySQLConn -> Int -> Int -> IO ()
addSeminarParticipant conn seminarId personId =
    runCommand conn
        "INSERT INTO seminar_participants (seminar_id, person_id) \
        \VALUES (?, ?)"
        [intValue seminarId, intValue personId]

removeSeminarParticipant :: MySQLConn -> Int -> Int -> IO ()
removeSeminarParticipant conn seminarId personId =
    runCommand conn
        "DELETE FROM seminar_participants WHERE seminar_id = ? AND person_id = ?"
        [intValue seminarId, intValue personId]

listDemonstrations :: MySQLConn -> Int -> IO [[MySQLValue]]
listDemonstrations conn packageId =
    runQuery conn
        "SELECT demonstration_id, scheduled_at, location, description \
        \FROM demonstrations WHERE package_id = ? ORDER BY scheduled_at"
        [intValue packageId]

addDemonstration :: MySQLConn -> Int -> Text -> Text -> Text -> IO ()
addDemonstration conn packageId scheduledAt location description =
    runCommand conn
        "INSERT INTO demonstrations \
        \(package_id, scheduled_at, location, description) VALUES (?, ?, ?, ?)"
        [ intValue packageId, MySQLText scheduledAt
        , MySQLText location, MySQLText description
        ]

updateDemonstration :: MySQLConn -> Int -> Text -> Text -> Text -> IO ()
updateDemonstration conn demonstrationId scheduledAt location description =
    runCommand conn
        "UPDATE demonstrations SET scheduled_at = ?, location = ?, \
        \description = ? WHERE demonstration_id = ?"
        [ MySQLText scheduledAt, MySQLText location
        , MySQLText description, intValue demonstrationId
        ]

deleteDemonstration :: MySQLConn -> Int -> IO ()
deleteDemonstration conn demonstrationId =
    runCommand conn
        "DELETE FROM demonstrations WHERE demonstration_id = ?"
        [intValue demonstrationId]

listTrials :: MySQLConn -> Int -> IO [[MySQLValue]]
listTrials conn packageId =
    runQuery conn
        "SELECT trial_id, scheduled_at, test_type, trial_status, result \
        \FROM test_trials WHERE package_id = ? ORDER BY scheduled_at"
        [intValue packageId]

addTrial :: MySQLConn -> Int -> Text -> Text -> IO ()
addTrial conn packageId scheduledAt testType =
    runCommand conn
        "INSERT INTO test_trials (package_id, scheduled_at, test_type) \
        \VALUES (?, ?, ?)"
        [intValue packageId, MySQLText scheduledAt, MySQLText testType]

updateTrial :: MySQLConn -> Int -> Text -> Text -> Text -> Text -> IO ()
updateTrial conn trialId scheduledAt testType status result =
    runCommand conn
        "UPDATE test_trials SET scheduled_at = ?, test_type = ?, \
        \trial_status = ?, result = ? WHERE trial_id = ?"
        [ MySQLText scheduledAt, MySQLText testType
        , MySQLText status, MySQLText result, intValue trialId
        ]

deleteTrial :: MySQLConn -> Int -> IO ()
deleteTrial conn trialId =
    runCommand conn "DELETE FROM test_trials WHERE trial_id = ?" [intValue trialId]
