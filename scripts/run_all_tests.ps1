param(
    [string]$Vivado = "vivado"
)

$cases = @(
    "ECB_16B", "ECB_256B", "ECB_4KiB",
    "CBC_16B", "CBC_256B", "CBC_4KiB",
    "CFB_16B", "CFB_256B", "CFB_4KiB",
    "CTR_16B", "CTR_256B", "CTR_4KiB"
)

foreach ($case in $cases) {
    & $Vivado -mode batch -source scripts/run_test.tcl -tclargs $case
    if ($LASTEXITCODE -ne 0) {
        throw "Hardware regression failed for $case"
    }
}
