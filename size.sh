set -e

sym=$1

section_size() {
  local hex=`grep "     [0-9A-F]\{8\}  l_$1 " "$sym" | cut -c 6-13`
  echo "obase=10; ibase=16; $hex" | bc
}

RAM=$((
  `section_size "DATA"` +
  `section_size "DABS"` +
  `section_size "INITIALIZED"`
))

ROM=$((
  `section_size "HOME"` +
  `section_size "GSINIT"` +
  `section_size "GSFINAL"` +
  `section_size "CONST"` +
  `section_size "INITIALIZER"` +
  `section_size "CODE"` +
  `section_size "CABS"`
))

echo "Memory Usage"
echo "- RAM: `printf "0x%04X" "$RAM"` ($RAM)"
echo "- ROM: `printf "0x%04X" "$ROM"` ($ROM)"
