# SQL Server 2022 con Docker Compose

Este proyecto permite levantar una instancia local de **SQL Server 2022** usando Docker Compose y crear automáticamente una base de datos inicial.

No se crean tablas por defecto. El script de inicialización solo crea la base de datos indicada en el archivo `.env`.

---

## Estructura del proyecto

```txt
sqlserver2022-docker/
│
├── docker-compose.yml
├── .env.example
├── README.md
└── init/
    └── init.sql
```

---

## Archivos incluidos

| Archivo | Descripción |
|---|---|
| `docker-compose.yml` | Levanta SQL Server 2022 y ejecuta el servicio de inicialización. |
| `.env.example` | Plantilla de variables de entorno. |
| `init/init.sql` | Script SQL que crea únicamente la base de datos. |
| `README.md` | Documentación de instalación y uso. |

---

## Requisitos previos

Debes tener instalado:

- Docker
- Docker Compose
- Un cliente para conectarte a SQL Server, por ejemplo:
  - Azure Data Studio
  - SQL Server Management Studio
  - DBeaver
  - DataGrip
  - TablePlus

---

# 1. Preparar el archivo `.env`

Copia el archivo `.env.example` y renómbralo a `.env`.

## macOS / Linux

```bash
cp .env.example .env
```

## Windows PowerShell

```powershell
Copy-Item .env.example .env
```

El archivo `.env` contiene esta configuración:

```env
MSSQL_SA_PASSWORD=SqlServer2022*
MSSQL_PID=Developer
MSSQL_PORT=1433
MSSQL_DATABASE=MiBaseDeDatos
```

Puedes cambiar el nombre de la base de datos modificando:

```env
MSSQL_DATABASE=MiBaseDeDatos
```

Ejemplo:

```env
MSSQL_DATABASE=SistemaVentas
```

---

# 2. Archivo `docker-compose.yml`

```yml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sqlserver2022
    hostname: sqlserver2022
    restart: unless-stopped
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "${MSSQL_SA_PASSWORD}"
      MSSQL_PID: "${MSSQL_PID}"
    ports:
      - "${MSSQL_PORT}:1433"
    volumes:
      - sqlserver_data:/var/opt/mssql
    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P \"${MSSQL_SA_PASSWORD}\" -C -Q \"SELECT 1\" || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

  sqlserver-init:
    image: mcr.microsoft.com/mssql-tools
    container_name: sqlserver2022_init
    depends_on:
      sqlserver:
        condition: service_healthy
    environment:
      MSSQL_SA_PASSWORD: "${MSSQL_SA_PASSWORD}"
      MSSQL_DATABASE: "${MSSQL_DATABASE}"
    volumes:
      - ./init:/init
    entrypoint: /bin/bash
    command: >
      -c "
      echo 'SQL Server está listo. Creando base de datos si no existe...';
      /opt/mssql-tools/bin/sqlcmd
      -S sqlserver
      -U sa
      -P \"$${MSSQL_SA_PASSWORD}\"
      -v DB_NAME=\"$${MSSQL_DATABASE}\"
      -i /init/init.sql;
      echo 'Proceso de creación de base de datos finalizado.';
      "
    restart: "no"

volumes:
  sqlserver_data:
```

---

# 3. Script `init/init.sql`

Este script crea solamente la base de datos definida en el archivo `.env`.

```sql
DECLARE @DatabaseName NVARCHAR(128) = N'$(DB_NAME)';
DECLARE @Sql NVARCHAR(MAX);

IF DB_ID(@DatabaseName) IS NULL
BEGIN
    SET @Sql = N'CREATE DATABASE [' + REPLACE(@DatabaseName, ']', ']]') + N']';
    EXEC(@Sql);
END;
GO
```

---

# 4. Ejecución por sistema operativo

## macOS

Instala Docker Desktop para Mac.

Luego abre la terminal en la carpeta del proyecto y ejecuta:

```bash
docker compose up -d
```

Verifica los contenedores:

```bash
docker ps -a
```

Debes ver algo similar:

```txt
sqlserver2022        running
sqlserver2022_init   exited
```

El contenedor `sqlserver2022_init` aparece como `exited` porque solo se encarga de crear la base de datos inicial. Eso es normal.

### Nota para Mac con Apple Silicon

En Mac con chip M1, M2, M3 o M4, SQL Server puede presentar problemas por arquitectura. Si no inicia correctamente, considera usar:

- Azure SQL Database
- Una máquina virtual Linux x86_64
- Un servidor remoto con SQL Server
- Otro motor de base de datos si el proyecto lo permite

---

## Linux

Abre una terminal en la carpeta del proyecto y ejecuta:

```bash
docker compose up -d
```

Si Docker requiere permisos de administrador:

```bash
sudo docker compose up -d
```

Verifica:

```bash
docker ps -a
```

Si no quieres usar `sudo`, agrega tu usuario al grupo `docker`:

```bash
sudo usermod -aG docker $USER
```

Después cierra sesión y vuelve a entrar.

---

## Windows

En Windows se recomienda usar Docker Desktop con WSL 2.

Abre PowerShell o Windows Terminal en la carpeta del proyecto y ejecuta:

```powershell
docker compose up -d
```

Verifica:

```powershell
docker ps -a
```

Si el puerto `1433` está ocupado porque ya tienes SQL Server instalado, cambia el puerto en `.env`:

```env
MSSQL_PORT=1434
```

Luego ejecuta nuevamente:

```powershell
docker compose up -d
```

---

# 5. Datos de conexión

Por defecto, los datos de conexión son:

```txt
Host: localhost
Puerto: 1433
Usuario: sa
Contraseña: SqlServer2022*
Base de datos: MiBaseDeDatos
```

También puedes usar:

```txt
Server: localhost,1433
User: sa
Password: SqlServer2022*
Database: MiBaseDeDatos
```

Si cambiaste el puerto a `1434`, usa:

```txt
Server: localhost,1434
```

---

# 6. Conexión desde Azure Data Studio

1. Abre Azure Data Studio.
2. Selecciona `New Connection`.
3. Completa los datos:

```txt
Connection type: Microsoft SQL Server
Server: localhost,1433
Authentication type: SQL Login
User name: sa
Password: SqlServer2022*
Database: MiBaseDeDatos
Trust server certificate: true
```

4. Haz clic en `Connect`.

---

# 7. Comandos útiles

## Levantar contenedores

```bash
docker compose up -d
```

## Ver contenedores

```bash
docker ps -a
```

## Ver logs de SQL Server

```bash
docker logs sqlserver2022
```

## Ver logs del inicializador

```bash
docker logs sqlserver2022_init
```

## Detener contenedores

```bash
docker compose down
```

## Detener y eliminar datos

```bash
docker compose down -v
```

Usa `-v` solo si quieres eliminar completamente la base de datos y empezar desde cero.

---

# 8. Verificar que la base de datos fue creada

Puedes entrar al contenedor de SQL Server:

```bash
docker exec -it sqlserver2022 bash
```

Luego conectarte con `sqlcmd`:

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "SqlServer2022*" -C
```

Ejecuta:

```sql
SELECT name FROM sys.databases;
GO
```

Deberías ver la base de datos configurada en `.env`, por ejemplo:

```txt
MiBaseDeDatos
```

Para salir:

```sql
EXIT
```

---

# 9. Problemas comunes

## La contraseña no es válida

SQL Server exige una contraseña segura. Usa una que tenga:

- Mayúsculas
- Minúsculas
- Números
- Símbolos
- Mínimo 8 caracteres

Ejemplo:

```env
MSSQL_SA_PASSWORD=SqlServer2022*
```

---

## El puerto 1433 está ocupado

Cambia el puerto en `.env`:

```env
MSSQL_PORT=1434
```

Luego conecta usando:

```txt
localhost,1434
```

---

## El contenedor `sqlserver2022_init` aparece detenido

Es normal. Ese contenedor solo crea la base de datos y luego termina.

El contenedor importante que debe quedar activo es:

```txt
sqlserver2022
```

---

## Cambié el nombre de la base de datos, pero no se creó otra

Si ya existe el volumen, SQL Server conserva los datos anteriores.

Para recrear todo desde cero:

```bash
docker compose down -v
docker compose up -d
```

---

# 10. Resumen rápido

```bash
cp .env.example .env
docker compose up -d
docker ps -a
docker logs sqlserver2022_init
```

Conexión:

```txt
Server: localhost,1433
User: sa
Password: SqlServer2022*
Database: MiBaseDeDatos
```
