function Get-TfsBuildDefinition
{
    <#
        .SYNOPSIS
            This function will find either all build definitions of a specific project or just the requested one.

        .DESCRIPTION
            This function will find either all build definitions of a specific project or just the requested one.

            The function will take either a websession object or a uri and
            credentials. The web session can be piped to the fuction from the
            Connect-TfsServer function.

        .PARAMETER WebSession
            Websession with connection details and credentials generated by Connect-TfsServer function

        .PARAMETER ID
            The ID of the build definition to find

        .PARAMETER Project
            The name of the project containing the build definitions

        .PARAMETER Uri
            Uri of TFS serverm, including /DefaultCollection (or equivilent)

        .PARAMETER Username
            The username to connect to the remote server with

        .PARAMETER AccessToken
            Access token for the username connecting to the remote server

        .PARAMETER UseDefaultCredentails
            Switch to use the logged in users credentials for authenticating with TFS.

        .EXAMPLE
            Get-TfsBuildDefinition -WebSession $Session -Project 'Engineering'

            This will return all build definitions under the Engineering project.

        .EXAMPLE
            Get-TfsBuildDefinition -Uri 'https://test.visualstudio.com/DefaultCollection'  -Username username@email.com -AccessToken (Get-Content C:\AccessToken.txt) -Project 'Engineering' -Id 10

            This will return the build definition with an Id of 10 under the Engineering Project.
    #>
[cmdletbinding()]
    param
    (
        [Parameter(ParameterSetName='WebSession', Mandatory,ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter(Mandatory)]
        [String]$Project,

        [int]$BuildDefinitionID,

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

        #construct uri
        if ($BuildDefinitionID -gt 0)
        {
            $uri = "$uri/$project/_apis/build/definitions/$($BuildDefinitionID)?api-version=2.0"
        }
        else
        {
            $uri = "$uri/$project/_apis/build/definitions?api-version=2.0"
        }

        $Parameters.add('Uri', $Uri)

        try
        {
            $jsondata = Invoke-restmethod @Parameters -ErrorAction Stop
        }
        catch
        {
            throw
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

function Get-TfsReleaseDefinition
{
    <#
        .SYNOPSIS
            This function will find either all release definitions of a specific project or just the requested one.

        .DESCRIPTION
            This function will find either all release definitions of a specific project or just the requested one.

            The function will take either a websession object or a uri and
            credentials. The web session can be piped to the fuction from the
            Connect-TfsServer function.

        .PARAMETER WebSession
            Websession with connection details and credentials generated by Connect-TfsServer function

        .PARAMETER ID
            The ID of the release definition to find

        .PARAMETER Project
            The name of the project containing the release definitions

        .PARAMETER Uri
            Uri of TFS serverm, including /DefaultCollection (or equivilent)

        .PARAMETER Username
            The username to connect to the remote server with

        .PARAMETER AccessToken
            Access token for the username connecting to the remote server

        .PARAMETER UseDefaultCredentails
            Switch to use the logged in users credentials for authenticating with TFS.

        .EXAMPLE
            Get-TfsReleaseDefinition -WebSession $Session -Project 'Engineering'

            This will return all release definitions under the Engineering project.

        .EXAMPLE
            Get-TfsReleaseDefinition -Uri 'https://test.visualstudio.com/DefaultCollection'  -Username username@email.com -AccessToken (Get-Content C:\AccessToken.txt) -Project 'Engineering' -Id 10

            This will return the release definition with an Id of 10 under the Engineering Project.
    #>
[cmdletbinding()]
    param
    (
        [Parameter(ParameterSetName='WebSession', Mandatory,ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter(Mandatory)]
        [String]$Project,

        [int]$Id,

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

        $Uri = $Uri -replace 'visualstudio.com','vsrm.visualstudio.com'

        #construct uri
        if ($Id)
        {
            $uri = "$uri/$project/_apis/release/definitions/$($id)?api-version=3.0-preview.1"
        }
        else
        {
            $uri = "$uri/$project/_apis/release/definitions?api-version=3.0-preview.1"
        }

        $Parameters.add('Uri', $Uri)

        try
        {
            $jsondata = Invoke-restmethod @Parameters -ErrorAction Stop
        }
        catch
        {
            throw
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

function New-TfsBuildDefinition
{
    <#
        .SYNOPSIS
            This function creates a new build definition in a TFS team project

        .DESCRIPTION
            This function creates a new build definition in a TFS team project from a target
            TFS server, using either the WebSession provided or manually specified
            URI and credentials.

            If the project doesn't exist then an error will be returned. Wildcard searches are
            not currently available.

            You can also pipe the a WebSession object into the command to, either from a normal variable
            or from the Connect-TfsServer function.

        .PARAMETER WebSession
            Websession with connection details and credentials generated by Connect-TfsServer function

        .PARAMETER Project
            Existing Team Project Name

        .PARAMETER Definition
            JSON specifying the defintion to create

        .PARAMETER Uri
            Uri of TFS serverm, including /DefaultCollection (or equivilent)

        .PARAMETER Username
            The username to connect to the remote server with

        .PARAMETER AccessToken
            Access token for the username connecting to the remote server

        .PARAMETER UseDefaultCredentails
            Switch to use the logged in users credentials for authenticating with TFS.

    #>
    [cmdletbinding()]
    param
    (
        [Parameter(ParameterSetName='WebSession', Mandatory,ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter(Mandatory)]
        [String]$Project,

        [Parameter(Mandatory)]
        [String]$Definition,

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
        $uri = "$uri/$Project/_apis/build/definitions?api-version=2.0"
        $Parameters.add('Uri', $Uri)
        $Parameters.Add('body',$Definition)

        try
        {
            $jsondata = Invoke-RestMethod @Parameters -Method Post -ErrorAction Stop
        }
        catch
        {
            Throw $_
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

function New-TfsReleaseDefinition
{
    [cmdletbinding()]
    param
    (
        [Parameter(ParameterSetName='WebSession', Mandatory,ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter(Mandatory)]
        [String]$Project,

        [Parameter(Mandatory)]
        [String]$Definition,

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
        $uri = "$uri/$Project/_apis/release/definitions?api-version=2.2-preview.1"
        $uri = $uri -replace 'visualstudio.com','vsrm.visualstudio.com'

        $Parameters.add('Uri', $Uri)
        $Parameters.Add('body',$Definition)

        try
        {
            $jsondata = Invoke-RestMethod @Parameters -Method Post -ErrorAction Stop
        }
        catch
        {
            Throw $_
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
