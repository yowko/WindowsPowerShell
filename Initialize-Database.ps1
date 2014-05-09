<#

.SYNOPSIS

Initializes and/or updates a database given a series of migration scripts.

.DESCRIPTION

Initializes and/or updates a database given a series of migration scripts.

If the specified database does not exist, it will create it.

The command will then look in the directory specified by the -MigrationScriptDirectoryPath
(or the current directory if not specified) for files that match the following
naming convention:

<integer>.sql

The integer portion of the SQL file designates the schema version that the file represents.
Consequently, the command will apply the scripts in ascending integer-order.

Once the scripts have been applied, the greates schema version will be stored as a
database property. Unless the -Reset switch is specified, subsequent invocations of the
command will only apply scripts with a schema version greater than the version stored in
the database.

If the -Reset switch is specified, the database will be dropped if it exists before it is
recreated. To suppress the confirmation prompt that appears before the database is dropped, 
pass -Force as a parameter to the command.

In order to specify a SQL script that always runs after all of the versioned scripts have
been applied, pass the -AlwaysRunScriptPath parameter with the path to the script.

.PARAMETER Database

The name of the database.

.PARAMETER ServerInstance

The instance name of the Database Engine.

.PARAMETER SchemaVersionPropertyName

Specifies the name of the database property used to store the schema version.

The default value is 'DB.Migration.SchemaVersion'

.PARAMETER Reset

Specifies that if the specified database exists, it should be dropped and recreated.

To suppress the confirmation prompt that appears before the database is dropped, 
pass -Force as a parameter to the command.

.PARAMETER MigrationScriptDirectoryPath

Specifies the path to use to scan for migration scripts.

The default value is the current directory.

.PARAMETER AlwaysRunScriptPath

Specifies the path to a SQL script that should always be run after running all of 
the versioned SQL scripts.

.EXAMPLE

Initialize-Database MySuperCoolDB

Initializes a database called MySuperCoolDB. If the database does not exist, it will
be created. Any SQL scripts in the current directory that have the <integer>.sql
pattern are applied if necessary.

.EXAMPLE 

Initialize-Database MySuperCoolDB -Reset -Force

Resets the database called MySuperCoolDB. If the database exists, it will
be dropped before it is recreated; the -Force parameter suppresses
the ensuing prompt. Any SQL scripts in the current directory that have the
<integer>.sql are then applied.

.EXAMPLE

Initialize-Database MySuperCoolDB -AlwaysRunScriptPath .\develop.sql

Initializes a database called MySuperCoolDB. If the database does not exist, it will
be created. Any SQL scripts in the current directory that have the <integer>.sql
pattern are applied if necessary. After running any required versioned SQL scripts,
runs a SQL script called develop.sql

#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Database,

    [Parameter()]
    [string]$ServerInstance = $null,

    [Parameter()]
    [string]$SchemaVersionPropertyName = 'DB.Migration.SchemaVersion',

    [Parameter()]
    [switch]$Reset,

    [Parameter()]
    [string]$MigrationScriptDirectoryPath = '.',

    [Parameter()]
    [string[]]$AlwaysRunScriptFilePath,

    [Parameter()]
    [switch]
    $Force
)

#region Constants and such

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# The separator used to indicate a SQL script file while
# running the migration
$migrationScriptSeparatorFormat = @"

-------------------------------------------------------
Running script: {0}
-------------------------------------------------------
"@

$commonSqlCmdParams = @{}
if($ServerInstance)
{
    $commonSqlCmdParams.ServerInstance = $ServerInstance
}

#endregion Constants and such

#region Supporting functions

function ResetDatabaseIfNecessary
{
    if($Reset)
    {
        if(-not $Force -and -not $PSCmdlet.ShouldContinue("Are you sure you want to drop the $Database database.","Confirm?"))
        {
            exit
        }

        InvokeSqlCmd @commonSqlCmdParams -Database master -NonQuery @"
            IF EXISTS (SELECT name FROM master.sys.databases WHERE name = N'$Database')
            BEGIN
                PRINT N'Dropping datatabase: $Database'
                ALTER DATABASE [$Database] SET single_user WITH ROLLBACK IMMEDIATE -- This should sever existing connections
                DROP DATABASE [$Database]
            END
"@
    }
}

function EnsureDatabaseExists
{
    InvokeSqlCmd @commonSqlCmdParams -Database master -NonQuery @"
        IF NOT EXISTS (SELECT name FROM master.sys.databases WHERE name = N'$Database')
        BEGIN
            PRINT N'Creating database: $Database'
            CREATE DATABASE $Database
        END
"@
}

function PerformMigration
{
    $currentSchemaVersionProperty = GetCurrentSchemaVersionProperty

    if(-not $currentSchemaVersionProperty.IsValid)
    {
        Write-Host 'No schema version has previously been applied.'
    }
    else
    {
        Write-Host "Database is at schema version $($currentSchemaVersionProperty.Value)."
    }

    $migrationScriptFilesToApply = `
        GetMigrationScriptFilesToApply -CurrentSchemaVersionValue $currentSchemaVersionProperty.Value

    if(-not $migrationScriptFilesToApply)
    {
        Write-Host 'Database is already up to date. No scripts to apply.'
        return
    }

    Write-Host 'The following scripts will be applied:'
    $migrationScriptFilesToApply | ForEach-Object {
        Write-Host "`t$($_.Name)"
    }

    $nextSchemaVersionValue = `
        GetNextSchemaVersion `
            -MigrationScriptFilesToApply $migrationScriptFilesToApply `
            -CurrentSchemaVersionValue $currentSchemaVersionProperty.Value

    ApplyMigrationScripts `
        -MigrationScriptFilesToApply $migrationScriptFilesToApply `
        -NextSchemaVersionValue $nextSchemaVersionValue `
        -SchemaVersionPropertyIsPresent $currentSchemaVersionProperty.IsPresent

    $currentSchemaVersionProperty = GetCurrentSchemaVersionProperty
    Write-Host "Database is now at schema version $($currentSchemaVersionProperty.Value)."
}

function GetCurrentSchemaVersionProperty
{
    $currentSchemaVersionProperty = InvokeSqlCmd @commonSqlCmdParams -Database $Database -Query @"
        SELECT value
        FROM fn_listextendedproperty(
            N'$SchemaVersionPropertyName',
            default,
            default,
            default,
            default,
            default,
            default)
"@

    $isPresent = $true
    if(-not $currentSchemaVersionProperty)
    {
        $isPresent = $false
    }

    $isValid = $true
    if(-not $currentSchemaVersionProperty -or
       -not ($currentSchemaVersionProperty.Value -as [int] -is [int]))
    {
        $isValid = $false
        $currentSchemaVersionProperty = @{
            Value = [int]::MinValue
        }
    }

    return $currentSchemaVersionProperty |
        Add-Member -MemberType NoteProperty -Name IsPresent -Value $isPresent -PassThru |
        Add-Member -MemberType NoteProperty -Name IsValid -Value $isValid -PassThru
}

function GetMigrationScriptFilesToApply
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [int]
        $CurrentSchemaVersionValue
    )

    Write-Host "Looking in $(Resolve-Path $MigrationScriptDirectoryPath) for versioned script files..."

    $migrationScriptFilesToApply = @(dir $MigrationScriptDirectoryPath *.sql |
        Where-Object { $_.BaseName -as [int] -is [int] } |
        ForEach-Object {
            Write-Host "`tFound versioned script file: $($_.Name)"
            return $_
        } |
        Where-Object { [int]($_.BaseName) -gt $CurrentSchemaVersionValue } |
        ForEach-Object {
            Add-Member `
                -InputObject $_ `
                -MemberType NoteProperty `
                -Name SchemaVersion `
                -Value ([int]$_.BaseName) `
                -PassThru
        } |
        Sort-Object SchemaVersion)

    if($AlwaysRunScriptFilePath)
    {
        $migrationScriptFilesToApply += $AlwaysRunScriptFilePath |
            dir |
            Add-Member -MemberType NoteProperty -Name SchemaVersion -Value $null -PassThru
    }

    return $migrationScriptFilesToApply
}

function GetNextSchemaVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $MigrationScriptFilesToApply,

        [Parameter(Mandatory=$true)]
        $CurrentSchemaVersionValue
    )

    $nextSchemaVersionValue = $MigrationScriptFilesToApply |
        Where-Object { $_.SchemaVersion -ne $null } |
        Select-Object -Last 1 -ExpandProperty SchemaVersion

    if(-not $nextSchemaVersionValue)
    {
        $nextSchemaVersionValue = $CurrentSchemaVersionValue
    }

    return $nextSchemaVersionValue
}

function ApplyMigrationScripts
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo[]]
        $MigrationScriptFilesToApply,

        [Parameter(Mandatory=$true)]
        [int]
        $NextSchemaVersionValue,

        [Parameter(Mandatory=$true)]
        [bool]
        $SchemaVersionPropertyIsPresent
    )

    $migrationScripts = @()
    for($i = 0; $i -lt $MigrationScriptFilesToApply.Length; ++$i)
    {
        $migrationScriptFile = $MigrationScriptFilesToApply[$i]
        $migrationScript = @()
        $migrationScript += Get-Content $migrationScriptFile.FullName

        if($i + 1 -lt $MigrationScriptFilesToApply.Length)
        {
            # Print out a header that we're running the next script at the
            # end of running the current script. This is usesful because
            # if the next script has any syntax errors, SQL will vomit on
            # it before it has a chance to print; by including the header
            # for the next script after running the current script, we'll
            # correctly display the header for the next script to the user,
            # followed by the error
            $nextMigrationScriptFile = $MigrationScriptFilesToApply[$i + 1]
            $migrationScript += "PRINT N'$($migrationScriptSeparatorFormat -f $nextMigrationScriptFile.Name)'"
        }

        $migrationScripts += $migrationScript -join "`n"
    }

    if($SchemaVersionPropertyIsPresent)
    {
        $migrationScripts += @"
            EXEC sys.sp_updateextendedproperty 
            @name = N'$SchemaVersionPropertyName', 
            @value = $NextSchemaVersionValue
"@
    }
    else
    {
        $migrationScripts += @"
            EXEC sys.sp_addextendedproperty 
            @name = N'$SchemaVersionPropertyName', 
            @value = $NextSchemaVersionValue
"@
    }

    # Preemptively print out the header for the first script so that if there's any
    # syntax errors with it, we'll correctly display the header for it followed by
    # the error
    Write-Host ($migrationScriptSeparatorFormat -f $MigrationScriptFilesToApply[0].Name)

    InvokeSqlCmd `
        @commonSqlCmdParams `
        -Database $Database `
        -NonQuery $migrationScripts `
        -UseTransaction

    Write-Host ''
    Write-Host 'Done!'
}

# Forgo using the SQLPS module in the interest of minimizing
# client-side install dependencies
function InvokeSqlCmd
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Database,

        [Parameter(Mandatory=$true, ParameterSetName='NonQuery')]
        [object[]]
        $NonQuery,

        [Parameter(Mandatory=$true, ParameterSetName='Query')]
        [string]
        $Query,

        [switch]
        $UseTransaction,

        [Parameter]
        [string]
        $ServerInstance
    )

    $connectionStringParts = @(
        "server=localhost"
        "database=$Database"
        "Integrated Security=true"
    )

    $connectionString = $connectionStringParts -join ';'

    if($PSCmdlet.ParameterSetName -eq 'NonQuery')
    {
        $commandBatches = $NonQuery
    }
    else
    {
        $commandBatches = $Query
    }

    # Ensure that statements that precede a GO statement
    # are in their own batch since the GO statement isn't valid
    # Transact-SQL: http://technet.microsoft.com/en-us/library/ms188037.aspx
    $commandBatches = $commandBatches | ForEach-Object {
        $commandBatch = ($_ + "`n") -replace "`r`n","`n" # Normalize line endings
        $commandBatch -split "`n*?GO[\s-]+?`n+?"
    } | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } | ForEach-Object {
        Write-Verbose ($_ + "`n`nGO`n`n")
        $_
    }

    $connection = $null
    $transaction = $null
    $command = $null
    $reader = $null
    try
    {
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $connection.add_InfoMessage({ Write-Host $args[1].Message })
        $connection.Open()

        if($UseTransaction)
        {
            $transaction = $connection.BeginTransaction()
        }

        $commandBatches | ForEach-Object {
            $commandText = $_
            $command = New-Object System.Data.SqlClient.SqlCommand $commandText, $connection
            $command.Transaction = $transaction

            if($PSCmdlet.ParameterSetName -eq 'NonQuery')
            {
                $command.ExecuteNonQuery() | Out-Null
            }
            else
            {
                $reader = $command.ExecuteReader()
                while($reader.Read())
                {
                    $properties = @{}
                    for($i = 0; $i -lt $reader.FieldCount; ++$i)
                    {                
                        $properties.Add($reader.GetName($i), $reader.GetValue($i))
                    }

                    New-Object –TypeName PSObject -Property $properties
                } 
            }            
        }

        if($transaction)
        {
            $transaction.Commit()
        }
    }
    catch
    {
        if($transaction)
        {
            $transaction.Rollback()
        }

        # For usability, unwrap and throw the SQL exception
        if($_.Exception -and $_.Exception.InnerException -is [System.Data.SqlClient.SqlException])
        {
            throw $_.Exception.InnerException
        }
        else
        {
            throw
        }
    }
    finally
    {
        if($reader)
        {
            $reader.Dispose()
        }

        if($command)
        {
            $command.Dispose()
        }

        if($connection)
        {
            $connection.Dispose()
        }
    }
}

#endregion Supporting functions

#region Let's do this thing

ResetDatabaseIfNecessary
EnsureDatabaseExists
PerformMigration

#endregion Let's do this thing