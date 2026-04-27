$files = @("Shortcuts.lsp", "version-history.md")
foreach ($file in $files) {
    Write-Host "Converting $file to CP949..."
    $content = Get-Content -Path $file -Raw -Encoding UTF8
    [System.IO.File]::WriteAllText((Get-Item $file).FullName, $content, [System.Text.Encoding]::GetEncoding(949))
}
