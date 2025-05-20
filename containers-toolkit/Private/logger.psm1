class Logger {
    static [string] $EventSource = "Containers-Toolkit"
    static [string] $EventLogName = "Application"
    static [string] $LogFile
    static [bool] $Quiet
    static [string] $MinLevel

    static [hashtable] $LogLevelRank = @{
        "DEBUG"   = 1
        "INFO"    = 2
        "WARNING" = 3
        "ERROR"   = 4
        "FATAL"   = 5
    }

    # Set minimum log level from environment variable: CTK_LOG_LEVEL or DebugPreference
    static [string] GetMinLevel() {
        try {
            $DebugPref = Get-Variable -Name DebugPreference -Scope Global -ValueOnly
            if ($DebugPref -ne "SilentlyContinue") {
                return "DEBUG"
            }
            elseif ($env:CTK_LOG_LEVEL) {
                return $env:CTK_LOG_LEVEL.ToUpper()
            }
            else {
                return "INFO"
            }
        }
        catch {
            return "INFO"
        }
    }

    # Set log file path from environment variable: CTK_LOG_FILE
    static [string] GetLogFile() {
        try {
            $fileName = $env:CTK_LOG_FILE
        }
        catch {
            $fileName = $null
        }
        return $fileName
    }

    # Set quiet mode from environment variable: SKIP_CTK_LOGGING
    # User-defined environment variable to skip logging. Equivalent to --quiet.
    # If not set, all messages are logged to the terminal and to the event log.
    # If set, only DEBUG messages are logged to the terminal.
    static [bool] GetQuiet() {
        try {
            $quietValue = $env:SKIP_CTK_LOGGING
            return if ($quietValue) { [bool]::Parse($quietValue) } else { $false }
        }
        catch {
            return $false
        }
    }

    # Check if the log level is greater than or equal to the minimum log level
    static [bool] ShouldLog([string] $Level) {
        return [Logger]::LogLevelRank[$Level.ToUpper()] -ge [Logger]::LogLevelRank[[Logger]::MinLevel]
    }

    # Generate a parsed log message from the log level and message
    static [string] GetLogMessage([string] $Level, [string] $Message) {
        $CallStack = Get-PSCallStack

        $CallStack | Tee-Object -FilePath "ctk.log" -Append | Out-Null
        $Caller = $CallStack | Where-Object { $_.Command } | Select-Object -Skip 2 -First 1

        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")
        $cmd = $Caller.InvocationInfo.MyCommand
        $line = $Caller.ScriptLineNumber

        # Add padding to the message based on the difference between the longest level name and the current level
        $padding = ([Logger]::LogLevelRank.Keys | Measure-Object -Maximum Length).Maximum - $Level.Length

        return "$($Level.ToUpper()):$(" " * $padding)[$timestamp] [${cmd}:${line}]: $Message"
    }

    # Write log messages to the Windows Event Log
    static [void] WriteToEventLog([string] $Level, [string] $Message) {
        # Create the event log source if it doesn't exist
        if (-not [System.Diagnostics.EventLog]::SourceExists($([Logger]::EventLogName))) {
            Write-Debug "Creating event log source: { LogName: $([Logger]::EventLogName), Source: $([Logger]::EventSource) }"
            New-EventLog -LogName $([Logger]::EventLogName) -Source $([Logger]::EventSource)
        }

        $entryType = switch ($Level) {
            "INFO" { [System.Diagnostics.EventLogEntryType]::Information }
            "WARNING" { [System.Diagnostics.EventLogEntryType]::Warning }
            "ERROR" { [System.Diagnostics.EventLogEntryType]::Error }
            "FATAL" { [System.Diagnostics.EventLogEntryType]::Error }
            default { throw [System.NotImplementedException]("Invalid log level: $Level") }
        }

        $eventId = switch ($Level) {
            "INFO" { 1000 }
            "WARNING" { 4000 }
            "ERROR" { 5000 }
            "FATAL" { 6000 }
            default { throw [System.NotImplementedException]("Invalid log level: $Level") }
        }

        try {
            Write-EventLog -LogName $([Logger]::EventLogName) `
                -Source $([Logger]::EventSource) `
                -EntryType $entryType `
                -EventId $eventId `
                -Message $Message
        }
        catch {
            # Fallback: write warning but continue
            Write-Warning "Failed to write to event log: $_"
        }
    }

    # Write log messages to the console and/or event log (or file)
    # This is the main logging function that handles all log levels
    static [void] Write([string] $Level, [string] $Message) {
        # Set values
        [Logger]::MinLevel = [Logger]::GetMinLevel()
        [Logger]::LogFile = [Logger]::GetLogFile()
        [Logger]::Quiet = [Logger]::GetQuiet()

        $Level = $Level.ToUpper()

        # Minimum log level filtering: Only log messages that are at least as severe as the minimum level
        if (-not [Logger]::ShouldLog($Level)) {
            return
        }

        # Generate the log message
        $parsedMessage = [Logger]::GetLogMessage($Level, $Message)

        # Default: Log to event log (non-DEBUG messages)
        if ($Level -ne "DEBUG") {
            [Logger]::WriteToEventLog($Level, $parsedMessage)
        }

        # Log to file if CTK_LOG_FILE is set
        if ([Logger]::LogFile) {
            Add-Content -Path [Logger]::LogFile -Value $parsedMessage
        }

        # If true, only DEBUG messages are logged to the terminal
        # else, all messages are logged to the terminal and to the event log.
        if ([Logger]::Quiet -and $Level -ne "DEBUG") {
            return
        }

        # Console output
        switch ($Level) {
            "FATAL" { [Console]::Error.WriteLine($parsedMessage); throw $Message }
            "ERROR" { [Console]::Error.WriteLine($parsedMessage) }
            default { [Console]::WriteLine($parsedMessage) }
        }
    }

    static [void] Fatal([string] $Message) { [Logger]::Write("FATAL", $Message) }
    static [void] Error([string] $Message) { [Logger]::Write("ERROR", $Message) }
    static [void] Warning([string] $Message) { [Logger]::Write("WARNING", $Message) }
    static [void] Info([string] $Message) { [Logger]::Write("INFO", $Message) }
    static [void] Debug([string] $Message) { [Logger]::Write("DEBUG", $Message) }
}
