# Extract "state = name" lines from DMI (PNG with zTXt Description)
param([string]$DmiPath = $args[0])
$bytes = [System.IO.File]::ReadAllBytes($DmiPath)
$len = $bytes.Length
$i = 8  # skip PNG signature
while ($i -lt $len - 12) {
    $chunkLen = [BitConverter]::ToInt32($bytes, $i)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes, $i, 4) }
    $chunkLen = [BitConverter]::ToUInt32($bytes, $i)
    $chunkType = [System.Text.Encoding]::ASCII.GetString($bytes, $i + 4, 4)
    $dataStart = $i + 8
    $dataLen = $chunkLen
    if ($chunkType -eq 'zTXt') {
        $keyEnd = $dataStart
        while ($keyEnd -lt $dataStart + $dataLen - 1 -and $bytes[$keyEnd] -ne 0) { $keyEnd++ }
        $key = [System.Text.Encoding]::Latin1.GetString($bytes, $dataStart, $keyEnd - $dataStart)
        if ($key -eq 'Description') {
            $compMethod = $bytes[$keyEnd + 1]
            $compressedStart = $keyEnd + 2
            $compressedLen = $dataLen - ($compressedStart - $dataStart)
            $compressed = [byte[]]::new($compressedLen)
            [Array]::Copy($bytes, $compressedStart, $compressed, 0, $compressedLen)
            try {
                $ms = [System.IO.MemoryStream]::new($compressed)
                $ds = [System.IO.Compression.DeflateStream]::new($ms, [System.IO.Compression.CompressionMode]::Decompress)
                $out = [System.IO.MemoryStream]::new()
                $ds.CopyTo($out)
                $ds.Close()
                $text = [System.Text.Encoding]::UTF8.GetString($out.ToArray())
                [regex]::Matches($text, 'state\s*=\s*([^\r\n]+)') | ForEach-Object { $_.Groups[1].Value.Trim() }
            } catch {}
            break
        }
    }
    $i += 12 + $chunkLen
}
