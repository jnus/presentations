function Get-TfsGitRepository
{
    <#
        .SYNOPSIS
            This function gets the git repos in a TFS team project

        .DESCRIPTION
            This function gets the git repos in a TFS team project from a target
            TFS server, using either the WebSession provided or manually specified
            URI and credentials.

            If the project doesn't exist then an error will be returned. Wildcard searches are
            not currently available.

            You can also pipe the a WebSession object into the command to, either from a normal variable
            or from the Connect-TfsServer function.

        .PARAMETER WebSession
            Websession with connection details and credentials generated by Connect-TfsServer function

        .PARAMETER TeamProject
            Existing Team Project Name


        .PARAMETER Uri
            Uri of TFS serverm, including /DefaultCollection (or equivilent)

        .PARAMETER Username
            The username to connect to the remote server with

        .PARAMETER AccessToken
            Access token for the username connecting to the remote server

        .PARAMETER UseDefaultCredentails
            Switch to use the logged in users credentials for authenticating with TFS.
        
        .EXAMPLE

            Get-TfsGitRepository -WebSession $Session -Project t1 

            This will get all the git repos currently on the T1 project on the TFS server 
            in the WebSession variable.

        .EXAMPLE

            Get-TfsTeam  -Uri https://test.visualstudio.com/DefaultCollection  -Username username@email.com -AccessToken (Get-Content C:\AccessToken.txt) -Project t1 

            This will get all the git repos currently on the T1 project on the TFS server 
            specified using the credentials provided.

        .EXAMPLE

            Connect-TfsServer -Uri "https://test.visualstudio.com/DefaultCollection -Username username@email.com -AccessToken (Get-Content C:\AccessToken.txt) |  Get-TfsTeam -Project t1 

            This will get all the git repos currently on the T1 project on the TFS server 
            in the WebSession provided by the Connect-TfsServer output.
    #>
    [cmdletbinding()]
    param
    (
        [Parameter(ParameterSetName='WebSession', Mandatory,ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter(Mandatory)]
        [String]$Project,

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

        #create the REST url
        $Project = $Project.Replace(' ','%20')
        $uri = "$uri/$Project/_apis/git/repositories?api-version=1.0"
        $Parameters.add('Uri', $Uri)

        try
        {
            $jsondata = Invoke-RestMethod @Parameters -ErrorAction Stop
        }
        catch
        {
            Throw
        }
        
        #Output data to the pipeline
        if ($jsondata.count -gt 0)
        {
            write-output $jsondata.value
        }
        else
        {
            Write-Output $jsondata 
        }
    }
}