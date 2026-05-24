-- Script de inicialización para SQL Server 2022.
-- Crea únicamente la base de datos definida en la variable DB_NAME.

DECLARE @DatabaseName NVARCHAR(128) = N'$(DB_NAME)';
DECLARE @Sql NVARCHAR(MAX);

IF DB_ID(@DatabaseName) IS NULL
BEGIN
    SET @Sql = N'CREATE DATABASE [' + REPLACE(@DatabaseName, ']', ']]') + N']';
    EXEC(@Sql);
END;
GO
