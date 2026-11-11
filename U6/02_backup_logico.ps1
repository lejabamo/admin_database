# Taller práctico: backup y restore en postgresql (u6)
# Paso 2: Backups Lógicos con pg_dump (4 formatos y opciones) y pg_dumpall

$env:PGPASSWORD = "postgres"
$pgBin = "C:\Program Files\PostgreSQL\16\bin"
$backupDir = "C:\pg_backups_u6"

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# 1. Los 4 formatos de pg_dump
& "$pgBin\pg_dump.exe" -U postgres -h localhost -p 5432 -d tienda -Fp -f "$backupDir\tienda.sql"
& "$pgBin\pg_dump.exe" -U postgres -h localhost -p 5432 -d tienda -Fc -f "$backupDir\tienda.dump"
& "$pgBin\pg_dump.exe" -U postgres -h localhost -p 5432 -d tienda -Fd -j 2 -f "$backupDir\tienda_dir"
& "$pgBin\pg_dump.exe" -U postgres -h localhost -p 5432 -d tienda -Ft -f "$backupDir\tienda.tar"

# 2. Backups parciales (esquema, tabla, solo estructura, excluyendo datos de logs)
& "$pgBin\pg_dump.exe" -U postgres -h localhost -p 5432 -d tienda -n ventas -Fc -f "$backupDir\ventas.dump"
& "$pgBin\pg_dump.exe" -U postgres -h localhost -p 5432 -d tienda --exclude-table-data="public.logs_*" -Fc -f "$backupDir\sin_logs.dump"
& "$pgBin\pg_dump.exe" -U postgres -h localhost -p 5432 -d tienda --schema-only -f "$backupDir\estructura.sql"

# 3. Objetos globales con pg_dumpall (roles y tablespaces)
& "$pgBin\pg_dumpall.exe" -U postgres -h localhost -p 5432 --globals-only -f "$backupDir\globales.sql"

# 4. Comparar tamaños de los respaldos generados
Get-ChildItem $backupDir | Select-Object Name, Length

