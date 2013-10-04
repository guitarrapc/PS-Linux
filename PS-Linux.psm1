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


function Invoke-Touch{
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



function Invoke-Sed{

<#

.SYNOPSIS 
PowerShell Sed alternate function

.DESCRIPTION
This cmdlet replace string in the file as like as sed on linux

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-Sed -path D:\Deploygroup\*.ps1 -searchPattern "^10.0.0.10$" -replaceWith "#10.0.0.10" -overwrite
--------------------------------------------
replace regex ^10.0.0.10$ with # 10.0.0.10 and replace file. (like sed -f "s/^10.0.0.10$/#10.0.0.10" -i)

.EXAMPLE
Invoke-Sed -path D:\Deploygroup\*.ps1 -searchPattern "^#10.0.0.10$" -replaceWith "10.0.0.10"
--------------------------------------------
replace regex ^10.0.0.10$ with # 10.0.0.10 and not replace file.

#>

    [CmdletBinding()]
    param(
        [parameter(
            position = 0,
            mandatory = 1,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string]
        $path,

        [parameter(
            position = 1,
            mandatory = 1,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string]
        $searchPattern,

        [parameter(
            position = 2,
            mandatory = 1,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string]
        $replaceWith,

        [parameter(
            position = 3,
            mandatory = 0)]
        [switch]$overWrite
    )

    $read = Select-String -Path $path -Pattern $searchPattern

    $read.path `
        | sort -Unique `
        | %{
            Write-Warning ("Executing string replace for {0}" -f $path)
                
            Write-Verbose "Get file information"
            $path = $_
            $extention = [System.IO.Path]::GetExtension($path)

            Write-Verbose "define tmp file"
            $tmpextension = "$extention" + "_"
            $tmppath = [System.IO.Path]::ChangeExtension($path,$tmpextension)
                               
            if ($overWrite)
            {
                Write-Verbose ("execute replace string {0} with {1} for file {2} and output to {3}" -f $searchPattern, $replaceWith, $path, $tmppath)
                Get-Content -Path $path `
                    | %{$_ -replace $searchPattern,$replaceWith} `
                    | Out-File -FilePath $tmppath -Encoding utf8 -Force -Append

                Write-Verbose ("remove original file {0}" -f $path, $tmppath)
                Remove-Item -Path $path -Force

                Write-Verbose ("rename tmp file {0} to original file {1}" -f $tmppath, $path)
                Rename-Item -Path $tmppath -NewName ([System.IO.Path]::ChangeExtension($tmppath,$extention))
            }
            else
            {
                Write-Verbose ("execute replace string {0} with {1} for file {2}" -f $searchPattern, $replaceWith, $path)
                Get-Content -Path $path `
                    | %{$_ -replace $searchPattern,$replaceWith}
            }    
        }
}



#-- Set Alias for public PS-Linux commands --#

Write-Verbose "Set Alias for PS-Linux Cmdlets."

New-Alias -Name touch -Value Invoke-Touch
New-Alias -Name sed -Value Invoke-Sed


## Load External Modules ##

Write-Verbose "Loading external modules."
# . $PSScriptRoot\*.ps1


## Export Internal Cmdlets ##

Write-Verbose "Exporting Internal Cmdlets."
Export-ModuleMember `
    -Function * `
    -Cmdlet *