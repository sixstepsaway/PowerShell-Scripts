#A collection of powershell snippets I use in most of my scripts.

##### SIMPLE OUT SCRIPT FOR CLEANUP####

< #Powershell has this fun little thing where it doesn't dump variables when your script finishes if you're working in an IDE, so I add this to every one of my scripts. 

Put this at the very top before you start doing functions: #>

Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

# Put this before you start establishing variables:

$startingVars = Get-Variable

# Put this at the end of your script:

Out-Script

##### VERBOSE LOGGING + LOG FILE ######

<# I got annoyed having to type logs constantly so I made this tiny function for it. 

Establish a variable called $logfile that points at a .log, for example ./Logfile.log

Add this to your functions: #>

Function Out-LogMessage {
    Write-Verbose $message
    $message | Out-File $logfile -Append
}

<# To log, simply set $message and then run the function. For example: #>

$message = "This is a log file."
Out-Logfile 

<# Tadah! #>


