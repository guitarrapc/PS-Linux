#Requires -Version 3.0

Write-Verbose "Loading PS-Linux.psm1"

# PS-Linux
#
# Copyright (c) 2013 guitarrapc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


function touch{
    [CmdletBinding()]
    param(
        [parameter(
        position = 0,
        mandatory = 1,
        ValueFromPipeline = 1,
        ValueFromPipelineByPropertyName = 1
        )]
        [string]$path,

        [parameter(
        position = 1,
        mandatory = 0,
        ValueFromPipeline = 1,
        ValueFromPipelineByPropertyName = 1
        )]
        [datetime]$date = $(Get-Date),

        [parameter(
        position = 2,
        mandatory = 0,
        HelpMessage = "Change Last AccessTime only"
        )]
        [switch]$access,

        [parameter(
        position = 3,
        mandatory = 0,
        HelpMessage = "Do not create file if not exist"
        )]
        [switch]$nocreate,

        [parameter(
        position = 4,
        mandatory = 0,
        HelpMessage = "Change Last WriteTime only"
        )]
        [switch]$modify,

        [parameter(
        position = 5,
        mandatory = 0,
        HelpMessage = "LastAccessTime reference file"
        )]
        [string]$reference
    )

    if (-not(Test-Path $path))
    {
        if ((!$nocreate))
        {
            New-Item -Path $path -ItemType file -Force
        }
    }
    else
    {
        try
        {
            if ($reference)
            {
                $date = (Get-ItemProperty -Path $reference).LastAccessTime
            }

            if ($access)
            {
                Get-ChildItem $path | %{Set-ItemProperty -path $_.FullName -Name LastAccessTime -Value $date -Force -ErrorAction Stop}
            }
        
            if ($modify)
            {
                Get-ChildItem $path | %{Set-ItemProperty -path $_.FullName -Name LastWriteTime -Value $date -Force -ErrorAction Stop}
            }

            if (!$access -and !$modify)
            {
                Get-ChildItem $path | %{Set-ItemProperty -path $_.FullName -Name LastAccessTime -Value $date -Force -ErrorAction Stop}
                Get-ChildItem $path | %{Set-ItemProperty -path $_.FullName -Name LastWriteTime -Value $date -Force -ErrorAction Stop}
            }
        }
        catch
        {
            throw $_
        }
        finally
        {
            Get-ChildItem $path | %{Get-ItemProperty -Path $_.FullName | select Fullname, LastAccessTime, LastWriteTime}
        }
    }    

}





## Load External Modules ##

Write-Verbose "Loading external modules."
# . $PSScriptRoot\*.ps1


## Export Internal Cmdlets ##

Write-Verbose "Exporting Internal Cmdlets."
Export-ModuleMember `
    -Function * `
    -Cmdlet *