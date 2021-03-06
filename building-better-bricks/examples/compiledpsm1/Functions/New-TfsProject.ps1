function New-TfsProject
{
    <#  
        .SYNOPSIS
            This function will create a new team project.

        .DESCRIPTION
            This function will create a new team project.

            The function will take either a websession object or a uri and
            credentials. The web session can be piped to the fuction from the
            Connect-TfsServer function.

        .PARAMETER WebSession
            Websession with connection details and credentials generated by Connect-TfsServer function

        .PARAMETER Name
            The name of the Project to be created

        .PARAMETER Description
            The description for the newly created project, defaults to match the name of the project

        .PARAMETER Process
            Process to use for the project, options are Agile, CMMI and Scrum

        .PARAMETER VersionControl
            Method of version control to use, options are tfvc or git

        .PARAMETER Username
            The username to connect to the remote server with

        .PARAMETER AccessToken
            Access token for the username connecting to the remote server

        .PARAMETER Credential
            Credential object for connecting to the target TFS server

        .PARAMETER UseDefaultCredentails
            Switch to use the logged in users credentials for authenticating with TFS.

        .EXAMPLE
            New-TfsProject -Name 'Engineering' -Description 'Engineering project' -Process Agile -VersionControl Git -WebSession $Session

            This will create a new Engineering Project using git for source control and Agile process. The already created Web Session is used for authentication.

        .EXAMPLE
            New-TfsProject -Uri 'https://test.visualstudio.com/defaultcollection' -Username username@email.com -AccessToken (Get-Content C:\AccessToken.txt) -Name 'Engineering' -Description 'Engineering project' -Process Scrum -VersionControl tfvc

            This will create a new Engineering Project using tfvc for source control and Scrum process on the specified server using the provided login details.

    #>
    [cmdletbinding()]
    param
    (
        [Parameter(ParameterSetName='WebSession', Mandatory,ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter(Mandatory)]
        [String]$Name,

        [String]$Description = $Name,
        
        [parameter(Mandatory)]
        #[ValidateSet('Agile','CMMI','Scrum','Scrum 2')]
        [string]$Process,

        [parameter(Mandatory)]
        [ValidateSet('tfvc','Git')]
        [string]$VersionControl,

        [Parameter(ParameterSetName='SingleConnection',Mandatory)]
        [Parameter(ParameterSetName='LocalConnection',Mandatory)]
        [String]$uri,

        [Parameter(ParameterSetName='SingleConnection',Mandatory)]
        [string]$Username,

        [Parameter(ParameterSetName='SingleConnection',Mandatory)]
        [string]$AccessToken,

        [parameter(ParameterSetName='LocalConnection',Mandatory)]
        [switch]$UseDefaultCredentials

    )
    Process
    {
        $headers = @{'Content-Type'='application/json'}
        $Parameters = @{}

        #Use Hashtable to create param block for invoke-restmethod and splat it together
        switch ($PsCmdlet.ParameterSetName) 
        {
            'SingleConnection'
            {
                $WebSession = Connect-TfsServer -Uri $uri -Username $Username -AccessToken $AccessToken
                $Parameters.add('WebSession',$WebSession)
                $Parameters.add('Headers',$headers)

            }
            'LocalConnection'
            {
                $WebSession = Connect-TfsServer -uri $Uri -UseDefaultCredentials
                $Parameters.add('WebSession',$WebSession)
                $Parameters.add('Headers',$headers)
            }
            'WebSession'
            {
                $Uri = $WebSession.uri
                $Parameters.add('WebSession',$WebSession)
                $Parameters.add('Headers',$headers)
                #Connection details here from websession, no creds needed as already there
            }
        }

        try
        {
            $ProjectExists = Invoke-RestMethod -Uri "$uri/_apis/projects/$($name)?api-version=1.0" @Parameters -ErrorAction Stop
        }
        catch
        {
            $ErrorObject = $_ | ConvertFrom-Json

            if (-not($ErrorObject.Message -like '*The following project does not exist*'))
            {
                Throw $_
            }
        }
        
        if ($ProjectExists)
        {
            #Write-Error 'The project already exists, please choose a new unique name'
            Throw 'The project already exists, please choose a new unique name'
        }        

        #Construct the uri and add it to paramaters block
        $uri = "$uri/_apis/projects?api-version=2.0-preview"
        $Parameters.Add('uri',$uri)

        #Construct Json data to post
        Switch ($Process)
        {
            'Agile'
            {
                $ProcessId = 'adcc42ab-9882-485e-a3ed-7678f01f66bc'
            }
            'Scrum'
            {
                $ProcessId = '6b724908-ef14-45cf-84f8-768b5384da45'
            }
            'CMMI'
            {
                $ProcessId = '27450541-8e31-4150-9947-dc59f998fc01'
            }
            default
            {
                $ProcessId = Invoke-RestMethod -Uri "$($Websession.uri)/_apis/process/processes?api-version=1.0" -WebSession $WebSession |
                            Select-Object -Expand Value |
                            Where-Object {$_.Name -eq $Process} |
                            Select-Object -Expand id

                If (-not($ProcessId)) {
                    throw "Process template $Process doesn't exist on target server"
                }

            }
        }

        $Json = @"
{
  'name': '$Name',
  'description': '$Descrption',
  'capabilities': {
    'versioncontrol': {
      'sourceControlType': '$VersionControl'
    },
    'processTemplate': {
      'templateTypeId': '$ProcessId'
    }
  }
}
"@

        try
        {
            $jsondata = Invoke-restmethod @Parameters -erroraction Stop -Method Post -Body $Json
        }
        catch
        {
            throw $_
        }

        Write-Output $jsondata

    }
}
