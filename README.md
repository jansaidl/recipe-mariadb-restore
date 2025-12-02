# Zerops x MariaDB Backup Restore
This utility tool demonstrates how to restore MariaDB backups from Zerops infrastructure using the technologies supported by [Zerops](https://zerops.io).

## Deploy on Zerops
You can add this utility to your project by clicking the ```Import Services``` button in the project details and then pasting the provided code.
```yaml
services:
  - hostname: mariadbrestore
    type: "ubuntu@22.04"
    verticalAutoscaling:
      minRam: 2
    maxContainers: 1
    buildFromGit: https://github.com/zeropsio/recipe-mariadb-restore
```

See the [Zerops documentation](https://docs.zerops.io/references/import) and [zerops.yml](https://github.com/zeropsio/recipe-mariadb-restore/blob/main/zerops.yml) to learn how to use the import feature.

## Usage

1. Copy your MariaDB backup download URL from Zerops
2. Run the backup script using the GUI terminal or use VPN and SSH
```bash
backup.sh -d DATABASE_NAME -u BACKUP_URL 
ls -lh backup.sql
```

3. Import the data to your target database:
```bash
mariadb -u USER -h HOST -p PASSWORD DATABASE_NAME < backup.sql
```

Or download the `backup.sql` dump file for later use.

## Options
```bash
# With known password
backup.sh -u "BACKUP_URL" -p password -d mydb

# Show all available options
backup.sh --help
```