#!/usr/bin/awk -f

NR == 1 {
  for (i = 1; i <= NF; i++) { headers[i] = $i }
  next
}

{
  print "{"
  for (header in headers) {
    key_value="  \""headers[header]"\": \""$header"\""
    if ( header != length(headers)) {
      key_value=key_value","
    }
    print key_value
  }
  print "}"
}
