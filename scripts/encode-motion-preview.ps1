param([string]$FrameDirectory, [string]$Destination)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore,WindowsBase
$encoder = New-Object System.Windows.Media.Imaging.GifBitmapEncoder
for ($index = 0; $index -lt 64; $index++) {
    $source = [System.Windows.Media.Imaging.BitmapFrame]::Create([Uri](Join-Path $FrameDirectory ('frame-{0:D3}.png' -f $index)))
    $metadata = New-Object System.Windows.Media.Imaging.BitmapMetadata('gif')
    $delay = [uint16]3
    if (($index % 3) -eq 0) { $delay = [uint16]4 }
    $metadata.SetQuery('/grctlext/Delay', $delay)
    $metadata.SetQuery('/grctlext/Disposal', [byte]2)
    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($source, $null, $metadata, $null))
}
$stream = [System.IO.File]::Open($Destination, [System.IO.FileMode]::Create)
try { $encoder.Save($stream) } finally { $stream.Dispose() }
$bytes = [System.IO.File]::ReadAllBytes($Destination)
$offset = 13
if (($bytes[10] -band 128) -ne 0) { $offset += 3 * [math]::Pow(2, ($bytes[10] -band 7) + 1) }
[byte[]]$loop = 0x21,0xff,0x0b,0x4e,0x45,0x54,0x53,0x43,0x41,0x50,0x45,0x32,0x2e,0x30,0x03,0x01,0x00,0x00,0x00
$memory = New-Object System.IO.MemoryStream
$memory.Write($bytes, 0, $offset)
$memory.Write($loop, 0, $loop.Length)
$memory.Write($bytes, $offset, $bytes.Length - $offset)
[System.IO.File]::WriteAllBytes($Destination, $memory.ToArray())
$memory.Dispose()
Get-Item -LiteralPath $Destination | Select-Object Name,Length
