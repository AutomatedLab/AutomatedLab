BeforeDiscovery {
    $gitAvailable = [bool](Get-Command -Name git -ErrorAction SilentlyContinue)
}

Describe 'PowerShell files in the repository' {
    BeforeAll {
        $repositoryRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '..\..\..')).Path
    }

    # .gitattributes marks *.ps1, *.psm1 and *.psd1 as text. Git then converts their line endings on checkout, and with
    # core.autocrlf=true it puts a CR before every 0A byte, which corrupts a UTF-16 file: it no longer parses.
    It 'are not stored as UTF-16' -Skip:(-not $gitAvailable) {
        $tracked = @(& git -c core.quotepath=off -C $repositoryRoot ls-files -- '*.ps1' '*.psm1' '*.psd1')
        if ($LASTEXITCODE -ne 0)
        {
            Set-ItResult -Skipped -Because "'$repositoryRoot' is not a git working tree"
            return
        }

        $offenders = foreach ($relativePath in $tracked)
        {
            $path = Join-Path -Path $repositoryRoot -ChildPath $relativePath
            if (-not (Test-Path -LiteralPath $path -PathType Leaf))
            {
                continue
            }

            $stream = [System.IO.File]::OpenRead($path)
            try
            {
                $buffer = New-Object -TypeName byte[] -ArgumentList 4096
                $count = $stream.Read($buffer, 0, $buffer.Length)
            }
            finally
            {
                $stream.Dispose()
            }

            $hasUtf16Bom = $count -ge 2 -and (($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE) -or ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF))
            $hasNulByte = [Array]::IndexOf($buffer, [byte]0, 0, $count) -ge 0
            if ($hasUtf16Bom -or $hasNulByte)
            {
                $relativePath
            }
        }

        $offenders | Should -BeNullOrEmpty -Because "UTF-16 files are corrupted by the line-ending conversion of git; save them as UTF-8. Found: $($offenders -join ', ')"
    }
}
