$max_depth = 6
$rp_exe_path = "C:\tools\rp-win-x86.exe"
$out_dir = Join-Path (Get-Location) "rp_output"
$all_prefix = "all_"

$target_files = $args

# Ensure the output directory exists
New-Item -ItemType Directory -Path $out_dir -Force -ErrorAction SilentlyContinue | Out-Null

function GetBaseAddress {
    param(
        [string]$filePath
    )
    # Execute the rp-win tool with the --info flag to get detailed information
    $info_output = & $rp_exe_path --info=3 -f $filePath

    # Use Select-String to find the line containing 'ImageBase'
    $baseAddressLine = $info_output | Select-String "ImageBase"

    # Extract the hexadecimal value using regex
    if ($baseAddressLine) {
        $baseAddress = $baseAddressLine -replace '.*ImageBase\s+:\s+(0x[0-9a-fA-F]+).*', '$1'
        return $baseAddress
    } else {
        return $null
    }
}

function ProcessExeOutput {
    param(
        [string]$filePath,
        [int]$recurseLevel
    )
    # Get the base filename from the full file path
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

    # Execute the rp-win tool and capture the output
    $exe_output = & $rp_exe_path -f $filePath -r $recurseLevel
    $baseAddress = GetBaseAddress $filePath
    #Write-Host "Base Address: $baseAddress"

    # Filter the output to only include lines with hex addresses and commands
    $filtered_output = $exe_output | Select-String -Pattern "0x[0-9a-fA-F]+:.*;" -AllMatches

    # Prepare data with filename, offset, and original line
    $processed_output = $filtered_output | ForEach-Object {
        $line = $_.Line
        $normal_address = $line -replace '^(0x[0-9a-fA-F]+):.*$', '$1'
        $offset = [convert]::ToInt32($normal_address, 16) - [convert]::ToInt32($baseAddress, 16)
        $offset_hex = '0x{0:x}' -f $offset
        "$fileName`t$offset_hex`t$line"
    }

    return $processed_output
}

foreach ($file in $target_files) {
    for ($i = 1; $i -le $max_depth; $i++) {
        # Constructing full paths for outfile and all_file
        $outfile = Join-Path $out_dir "${file}_${i}"
        $all_file = Join-Path $out_dir "${all_prefix}${i}.txt"

        # Process output
        $filtered_output = ProcessExeOutput -filePath $file -recurseLevel $i

        # Write filtered_output to outfile
        $filtered_output | Out-File -FilePath $outfile

        # Append filtered_output to $all_file
        $filtered_output | Out-File -FilePath $all_file -Append
    }
}