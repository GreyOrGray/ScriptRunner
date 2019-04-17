$Directory = (get-item $PSCommandPath).directory

$transcript = ("{0}\ScriptRunnerOutput{1}.txt" -f $Directory, [DateTime]::Now.ToString("yyyyMMdd-HHmmss"))
Start-Transcript -path $transcript -append

$Tasks = import-csv ("{0}\ScriptRunnerTasks.csv" -f $Directory) -header "TaskNumber","Target","Script"

if ($tasks)
{
	write-host "`n`n`n"
	write-host (".:|=======================================================================================================|:.") -f green
	write-host ("                                              Powershell output") -f green
	write-host (".:|=======================================================================================================|:.") -f green
	write-host ("The following tasks have been loaded") -f green
	write-host (".:|=======================================================================================================|:.") -f green
	write-host (".:|=======================================================================================================|:.") -f green
	write-host "`n`n`n"
	$Tasks | fl | out-string | write-host

	<#
	write-host ("Are you Sure You Want To Proceed:") -f yellow
	$confirmation = Read-Host
	if ($confirmation -ne 'y') {
	  write-host ("exiting") -f red
	  break
	}
	#>

	foreach ($Task in $Tasks | sort tasknumber)
	{
		write-host "`n`n`n"
		write-host (".:|=======================================================================================================|:.") -f green
		write-host ("                                              Powershell output") -f green
		write-host (".:|=======================================================================================================|:.") -f green
		write-host ("         Task {0} starting on {1}... " -f $Task.TaskNumber, $Task.Target) -f green
		write-host ("         Connecting... " -f $Task.TaskNumber, $Task.Target) -f green
		write-host (".:|=======================================================================================================|:.") -f green
		write-host (".:|=======================================================================================================|:.") -f green
		write-host "`n`n`n"
		$TargetConnectionString = ("Server={0};Database=Master;Integrated Security=SSPI;" -f $Task.Target)
		$TargetConnection = New-Object System.Data.SqlClient.SqlConnection($TargetConnectionString)
		$NewScriptPath = ("{0}\{1}" -f $Directory, $Task.Script)
		$Command = get-content $task.script -raw
		
		$batches = [regex]::split($command,'\nGO[\t\s]*\r\n')
		
		$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Host $event.Message }
		$TargetConnection.add_InfoMessage($handler)
		$TargetConnection.FireInfoMessageEventOnUserErrors = $false  
		$TargetConnection.Open()
		
		foreach($batch in $batches)
		{
			if ($batch.Trim() -ne ""){

				$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
				$SqlCmd.CommandTimeout = 0
				$SqlCmd.CommandText = $batch
				$SqlCmd.Connection = $TargetConnection
				try
				{
					$SqlCmd.ExecuteNonQuery() | out-null
				}
				catch {
					 
					write-host "`n`n`n"
					write-host (".:|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|:.") -f red
					write-host (".:|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|:.") -f red
					write-host ("                                              Exception Raised") -f green
					write-host (".:|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|:.") -f red
					write-host ("`n         An error was raised in processing. ") -f red
					write-host ("         No further action will be taken. ") -f red
					write-host ("         Please see the output below for more information. `n`n") -f red
					$fields = $_.InvocationInfo.MyCommand.Name,
							  $_.ErrorDetails.Message,
							  $_.InvocationInfo.PositionMessage,
							  $_.CategoryInfo.ToString(),
							  $_.FullyQualifiedErrorId
					$e = $_.Exception
					
					$msg = "`n         EXCEPTION MESSAGE:::         `n"
					$msg += $e.Message
					$msg += "`n        INNER EXCEPTIONS:::         `n"
					while ($e.InnerException) {
					  $e = $e.InnerException
					  $msg += "`n" + $e.Message
					}
					write-host $msg
					write-host ("`n`n         Thank you for choosing ScriptRunner.") -f red
					write-host ("         Goodbye. `n") -f red
					write-host (".:|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|:.") -f red
					write-host (".:|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|:.") -f red
					write-host (".:|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|:.") -f red
					write-host "`n`n`n"
				
					$TargetConnection.Close();
					throw $_.msg
					Write-Error $_.msg -EA Stop
					Return
					
				}
			}
		}
		
		$TargetConnection.Close();
	}
	write-host ('Completed') -f green
}
else 
{
	write-host 'no tasks defined'
}
Stop-Transcript