function Resolve-FullPath {
  [cmdletbinding()]
  param
  (
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true)]
    [string] $path
  )
     
  $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
}

$d=(Resolve-FullPath([System.IO.Path]::GetDirectoryName($args[0])))
$f = [io.path]::GetFileNameWithoutExtension($args[0])
DOSBox -c "MOUNT D $d" -c "d:" -c "msxf2w $f.bin $f.wav -2" -c "exit" -noconsole -exit