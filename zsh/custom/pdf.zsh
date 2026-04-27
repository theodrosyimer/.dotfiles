	# Compress PDF: gs /ebook if image-heavy, cpdf -squeeze if text/vector-heavy.
# Threshold: images-per-page ratio (default 1.0, override via COMPRESS_PDF_THRESHOLD).
function compress_pdf() {
  local input="$1"
  local output="${2:-${input:r}-compressed.pdf}"
  local threshold="${COMPRESS_PDF_THRESHOLD:-1.0}"

  [[ -z "$input" || ! -f "$input" ]] && { echo "Usage: compress_pdf <input.pdf> [output.pdf]" >&2; return 1; }

  # pdfimages -list: 2 header lines + 1 row per image; suppress spec-violation noise
  local img_lines images pages ratio use_gs
  img_lines=$(pdfimages -list "$input" 2>/dev/null | wc -l | tr -d ' ')
  images=$(( img_lines > 2 ? img_lines - 2 : 0 ))
  pages=$(pdfinfo "$input" 2>/dev/null | awk '/^Pages:/ {print $2}')
  [[ -z "$pages" || "$pages" -eq 0 ]] && { echo "Cannot read page count" >&2; return 1; }

  # Float math via awk; ratio >= threshold => image-heavy
  ratio=$(awk -v i="$images" -v p="$pages" 'BEGIN { printf "%.2f", i/p }')
  use_gs=$(awk -v r="$ratio" -v t="$threshold" 'BEGIN { print (r+0 >= t+0) ? 1 : 0 }')

  echo "Input:   $input ($(du -h "$input" | awk '{print $1}'))"
  echo "Stats:   $images images / $pages pages = $ratio per page (threshold: $threshold)"

  if [[ "$use_gs" -eq 1 ]]; then
    echo "Strategy: image-heavy → gs /screen"
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen \
       -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$output" "$input" || return 1
  else
    echo "Strategy: text/vector-heavy → cpdf -squeeze"
    cpdf -squeeze "$input" -o "$output" || return 1
  fi

  echo "Output:  $output ($(du -h "$output" | awk '{print $1}'))"
}
