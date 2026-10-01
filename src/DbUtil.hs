module DbUtil (runQuery, runCommand) where

import Control.Exception (bracket)
import Control.Monad (void)
import Database.MySQL.Base
import qualified System.IO.Streams as Streams

-- A result stream must be consumed before the next command on this connection.
runQuery :: MySQLConn -> Query -> [MySQLValue] -> IO [[MySQLValue]]
runQuery conn sql params =
    bracket (prepareStmt conn sql) (closeStmt conn) $ \stmt -> do
        (_, rows) <- queryStmt conn stmt params
        Streams.toList rows

runCommand :: MySQLConn -> Query -> [MySQLValue] -> IO ()
runCommand conn sql params =
    bracket (prepareStmt conn sql) (closeStmt conn) $ \stmt ->
        void (executeStmt conn stmt params)
