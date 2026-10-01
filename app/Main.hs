{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Exception (IOException, SomeException, bracket, displayException, fromException, try)
import Data.List (dropWhileEnd, intercalate)
import Data.Text (Text)
import qualified Data.Text as Text
import Data.Text.Encoding (decodeUtf8With)
import Data.Text.Encoding.Error (lenientDecode)
import Data.Time (LocalTime)
import Data.Time.Format (defaultTimeLocale, formatTime, parseTimeM)
import Database.MySQL.Base (MySQLConn, MySQLValue (..), close)
import System.IO (hFlush, stdout)
import System.IO.Error (isEOFError)
import Text.Read (readMaybe)

import Database (openConnection)
import qualified EventRepository as Events
import Models (DbEntity (displayName), Person (..), PersonType (..), SoftwarePackage (..))
import qualified PackageRepository as Packages
import qualified PersonRepository as Persons

main :: IO ()
main = bracket openConnection close menu

menu :: MySQLConn -> IO ()
menu conn = do
    putStrLn "\n=== Пакети прикладних програм факультету ==="
    putStrLn " 1  Переглянути пакети       2  Пошук пакета"
    putStrLn " 3  Додати пакет            4  Редагувати пакет"
    putStrLn " 5  Видалити пакет         6  Переглянути людей"
    putStrLn " 7  Додати людину          8  Редагувати людину"
    putStrLn " 9  Видалити людину       10  Розробники пакета"
    putStrLn "11  Призначити розробника 12  Прибрати розробника"
    putStrLn "13  Заходи пакета         14  Додати семінар"
    putStrLn "15  Редагувати семінар    16  Видалити семінар"
    putStrLn "17  Учасники семінару     18  Додати учасника"
    putStrLn "19  Прибрати учасника     20  Додати демонстрацію"
    putStrLn "21  Редагувати демонстрацію 22 Видалити демонстрацію"
    putStrLn "23  Додати випробування   24  Редагувати випробування"
    putStrLn "25  Видалити випробування  0  Вихід"
    choiceResult <- try (promptText "Номер дії (0–25; після номера натисніть Enter):")
        :: IO (Either IOException Text)
    case choiceResult of
        Left err
            | isEOFError err -> putStrLn "\nВвід завершено. Роботу програми завершено."
            | otherwise -> ioError err
        Right "0" -> putStrLn "Роботу завершено."
        Right choice -> case actionName choice of
            Nothing -> putStrLn "Невідомий номер дії. Введіть число від 0 до 25." >> menu conn
            Just action -> do
                putStrLn ("\n=== Дія " ++ Text.unpack choice ++ ": " ++ action ++ " ===")
                putStrLn "Вводьте кожне значення після знака > і натискайте Enter."
                result <- try (dispatch conn choice) :: IO (Either SomeException ())
                case result of
                    Left err
                        | isInputClosed err ->
                            putStrLn "\nВвід завершено. Роботу програми завершено."
                        | otherwise -> do
                            putStrLn ("Помилка: " ++ displayException err)
                            menu conn
                    Right () -> menu conn

isInputClosed :: SomeException -> Bool
isInputClosed err = maybe False isEOFError (fromException err :: Maybe IOException)

actionName :: Text -> Maybe String
actionName choice = lookup choice
    [ ("1", "Переглянути пакети")
    , ("2", "Пошук пакета")
    , ("3", "Додати пакет")
    , ("4", "Редагувати пакет")
    , ("5", "Видалити пакет")
    , ("6", "Переглянути людей")
    , ("7", "Додати людину")
    , ("8", "Редагувати людину")
    , ("9", "Видалити людину")
    , ("10", "Розробники пакета")
    , ("11", "Призначити розробника")
    , ("12", "Прибрати розробника")
    , ("13", "Заходи пакета")
    , ("14", "Додати семінар")
    , ("15", "Редагувати семінар")
    , ("16", "Видалити семінар")
    , ("17", "Учасники семінару")
    , ("18", "Додати учасника")
    , ("19", "Прибрати учасника")
    , ("20", "Додати демонстрацію")
    , ("21", "Редагувати демонстрацію")
    , ("22", "Видалити демонстрацію")
    , ("23", "Додати випробування")
    , ("24", "Редагувати випробування")
    , ("25", "Видалити випробування")
    ]

dispatch :: MySQLConn -> Text -> IO ()
dispatch conn choice = case choice of
    "1"  -> Packages.listPackages conn >>= showRows "ID | Назва | Версія | Статус"
    "2"  -> do
        name <- promptRequired "Назва або її частина: "
        Packages.findPackagesByName conn name >>= showRows "ID | Назва | Версія | Статус"
    "3"  -> do
        name <- promptRequired "Назва: "
        description <- promptOptional "Опис: "
        version <- promptRequired "Версія: "
        Packages.addPackage conn name description version
        let package = SoftwarePackage 0 name description version "development"
        putStrLn ("Додано пакет: " ++ Text.unpack (displayName package))
    "4"  -> do
        packageId <- promptId "ID пакета: "
        name <- promptRequired "Нова назва: "
        description <- promptOptional "Новий опис: "
        version <- promptRequired "Нова версія: "
        status <- promptOneOf "Статус" ["development", "testing", "released", "archived"]
        Packages.updatePackage conn packageId name description version status
        putStrLn "SQL-запит виконано."
    "5"  -> do
        packageId <- promptId "ID пакета: "
        confirmed <- confirmDelete
        if confirmed
            then Packages.deletePackage conn packageId >> putStrLn "SQL-запит виконано."
            else putStrLn "Скасовано."
    "6"  -> Persons.listPersons conn >>= showRows "ID | Ім'я | Тип | Кафедра | Email"
    "7"  -> do
        name <- promptRequired "ПІБ: "
        role <- promptOneOf "Тип особи" ["student", "teacher"]
        department <- promptRequired "Кафедра: "
        email <- promptRequired "Email: "
        Persons.addPerson conn name role department email
        let roleValue = if role == "student" then Student else Teacher
            person = Person 0 name roleValue department email
        putStrLn ("Додано: " ++ Text.unpack (displayName person))
    "8"  -> do
        personId <- promptId "ID особи: "
        name <- promptRequired "Нове ПІБ: "
        role <- promptOneOf "Тип особи" ["student", "teacher"]
        department <- promptRequired "Нова кафедра: "
        email <- promptRequired "Новий email: "
        Persons.updatePerson conn personId name role department email
        putStrLn "SQL-запит виконано."
    "9"  -> do
        personId <- promptId "ID особи: "
        confirmed <- confirmDelete
        if confirmed
            then Persons.deletePerson conn personId >> putStrLn "SQL-запит виконано."
            else putStrLn "Скасовано."
    "10" -> do
        packageId <- promptId "ID пакета: "
        Packages.listDevelopers conn packageId >>= showRows "ID | ПІБ | Роль"
    "11" -> do
        packageId <- promptId "ID пакета: "
        personId <- promptId "ID особи: "
        role <- promptRequired "Роль у розробці: "
        Packages.assignDeveloper conn packageId personId role
        putStrLn "Зв'язок розробника з пакетом збережено."
    "12" -> do
        packageId <- promptId "ID пакета: "
        personId <- promptId "ID особи: "
        Packages.removeDeveloper conn packageId personId
        putStrLn "SQL-запит виконано."
    "13" -> do
        packageId <- promptId "ID пакета: "
        Events.listSeminars conn packageId >>= showRows "Семінари: ID | Тема | Дата | Місце"
        Events.listDemonstrations conn packageId >>= showRows "Демонстрації: ID | Дата | Місце | Опис"
        Events.listTrials conn packageId >>= showRows "Випробування: ID | Дата | Тип | Статус | Результат"
    "14" -> do
        packageId <- promptId "ID пакета: "
        topic <- promptRequired "Тема семінару: "
        date <- promptDateTime
        location <- promptOptional "Місце: "
        Events.addSeminar conn packageId topic date location
        putStrLn "Семінар додано."
    "15" -> do
        seminarId <- promptId "ID семінару: "
        topic <- promptRequired "Нова тема: "
        date <- promptDateTime
        location <- promptOptional "Нове місце: "
        Events.updateSeminar conn seminarId topic date location
        putStrLn "SQL-запит виконано."
    "16" -> do
        seminarId <- promptId "ID семінару: "
        confirmed <- confirmDelete
        if confirmed
            then Events.deleteSeminar conn seminarId >> putStrLn "SQL-запит виконано."
            else putStrLn "Скасовано."
    "17" -> do
        seminarId <- promptId "ID семінару: "
        Events.listSeminarParticipants conn seminarId >>= showRows "ID | ПІБ | Тип"
    "18" -> do
        seminarId <- promptId "ID семінару: "
        personId <- promptId "ID особи: "
        Events.addSeminarParticipant conn seminarId personId
        putStrLn "Учасника додано."
    "19" -> do
        seminarId <- promptId "ID семінару: "
        personId <- promptId "ID особи: "
        Events.removeSeminarParticipant conn seminarId personId
        putStrLn "SQL-запит виконано."
    "20" -> do
        packageId <- promptId "ID пакета: "
        date <- promptDateTime
        location <- promptOptional "Місце: "
        description <- promptOptional "Опис: "
        Events.addDemonstration conn packageId date location description
        putStrLn "Демонстрацію додано."
    "21" -> do
        demoId <- promptId "ID демонстрації: "
        date <- promptDateTime
        location <- promptOptional "Нове місце: "
        description <- promptOptional "Новий опис: "
        Events.updateDemonstration conn demoId date location description
        putStrLn "SQL-запит виконано."
    "22" -> do
        demoId <- promptId "ID демонстрації: "
        confirmed <- confirmDelete
        if confirmed
            then Events.deleteDemonstration conn demoId >> putStrLn "SQL-запит виконано."
            else putStrLn "Скасовано."
    "23" -> do
        packageId <- promptId "ID пакета: "
        date <- promptDateTime
        testType <- promptRequired "Тип випробування: "
        Events.addTrial conn packageId date testType
        putStrLn "Випробування додано."
    "24" -> do
        trialId <- promptId "ID випробування: "
        date <- promptDateTime
        testType <- promptRequired "Новий тип: "
        status <- promptOneOf "Статус" ["planned", "in_progress", "passed", "failed"]
        result <- promptOptional "Результат: "
        Events.updateTrial conn trialId date testType status result
        putStrLn "SQL-запит виконано."
    "25" -> do
        trialId <- promptId "ID випробування: "
        confirmed <- confirmDelete
        if confirmed
            then Events.deleteTrial conn trialId >> putStrLn "SQL-запит виконано."
            else putStrLn "Скасовано."
    _ -> putStrLn "Невідома команда."

promptText :: String -> IO Text
promptText label = do
    putStrLn ("\n" ++ label)
    putStr "> "
    hFlush stdout
    Text.strip . Text.pack <$> getLine

fieldLabel :: String -> String
fieldLabel = dropWhileEnd (\c -> c == ' ' || c == ':')

promptOptional :: String -> IO Text
promptOptional label = promptText (fieldLabel label ++ " [необов'язково; Enter — пропустити]:")

promptRequired :: String -> IO Text
promptRequired label = do
    value <- promptText (fieldLabel label ++ " [обов'язково]:")
    if Text.null value
        then putStrLn "Поле не може бути порожнім." >> promptRequired label
        else pure value

promptId :: String -> IO Int
promptId label = do
    value <- promptText (fieldLabel label ++ " [ціле додатне число зі списку]:")
    case readMaybe (Text.unpack value) of
        Just number | number > 0 -> pure number
        _ -> putStrLn "Введи ціле додатне число." >> promptId label

promptOneOf :: String -> [Text] -> IO Text
promptOneOf label values = do
    value <- promptText (label ++ " (" ++ intercalate "/" (map Text.unpack values) ++ "): ")
    if value `elem` values
        then pure value
        else putStrLn "Обери один із наведених варіантів." >> promptOneOf label values

promptDateTime :: IO Text
promptDateTime = do
    value <- promptText "Дата й час (РРРР-ММ-ДД ГГ:ХХ:СС): "
    case parseTimeM True defaultTimeLocale "%Y-%m-%d %H:%M:%S" (Text.unpack value) :: Maybe LocalTime of
        Just _ -> pure value
        Nothing -> putStrLn "Невірний формат дати й часу." >> promptDateTime

confirmDelete :: IO Bool
confirmDelete = do
    answer <- promptText "Підтвердити видалення? (так/ні): "
    pure (answer == "так" || answer == "yes")

showRows :: String -> [[MySQLValue]] -> IO ()
showRows heading rows = do
    putStrLn heading
    if null rows
        then putStrLn "(записів немає)"
        else mapM_ (putStrLn . intercalate " | " . map showCell) rows

showCell :: MySQLValue -> String
showCell value = case value of
    MySQLText text -> Text.unpack text
    MySQLBytes bytes -> Text.unpack (decodeUtf8With lenientDecode bytes)
    MySQLInt32 n -> show n
    MySQLInt32U n -> show n
    MySQLInt64 n -> show n
    MySQLInt64U n -> show n
    MySQLDateTime time -> formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S" time
    MySQLTimeStamp time -> formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S" time
    MySQLDate day -> formatTime defaultTimeLocale "%Y-%m-%d" day
    MySQLNull -> "—"
    other -> show other
