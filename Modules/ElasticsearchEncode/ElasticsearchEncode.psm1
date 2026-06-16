<#
.SYNOPSIS
    Builds and tests an Elasticsearch API key authorization header.

.DESCRIPTION
    Takes the full unencoded API key (the "id:key" pair, as stored in our config under
    UnencodedApiKey), splits it, base64-encodes it, and emits the
    "Authorization: ApiKey <encoded>" header. Optionally copies the header to the
    clipboard and tests the connection to an Elasticsearch server.

    Input is forgiving:
      - "id:key"            -> split on the first ':' and encoded
      - an already-encoded  -> detected (decodes to an id:key pair) and passed through
        base64 value           unchanged, so it is never double-encoded

.PARAMETER UnencodedApiKey
    The full API key as "id:key" (e.g. a 20-char id, ':', a 22-char key = 43 chars).
    May also be an already-encoded base64 value. If omitted, you will be prompted.

.PARAMETER Url
    (Optional) The Elasticsearch server URL to test the connection. If not provided,
    you will be prompted (press Enter to skip the test).

.PARAMETER CopyToClipboard
    If specified, copies the generated authorization header to the clipboard.

.EXAMPLE
    Generate-Elastic-Key -UnencodedApiKey "VuaCfGcBCdbkQm-e5aOx:ui2lp2axTNmsyakw9tvNnw"
    Splits, encodes, and prints the Authorization header.

.EXAMPLE
    Generate-Elastic-Key -UnencodedApiKey $cfg.UnencodedApiKey -Url "https://my-es:443" -CopyToClipboard
    Encodes the configured key, copies the header, and tests the connection.

.NOTES
    Author: Travis Haley
    Version: 1.2.0
#>
function Generate-Elastic-Key {
    [CmdletBinding()]
    param (
        [string]$UnencodedApiKey,
        [string]$Url,
        [switch]$CopyToClipboard
    )

    # Define status symbols using PowerShell's native character support
    $successSymbol = [char]0x2714  # check mark
    $failureSymbol = [char]0x2718  # cross mark

    # Prompt for the combined key if not supplied (masked -- the id isn't secret but the key is)
    if (-not $UnencodedApiKey) {
        $secure = Read-Host "Enter your UnencodedApiKey (id:key)" -AsSecureString
        $UnencodedApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        )
    }

    $UnencodedApiKey = $UnencodedApiKey.Trim()

    # Work out the encoded header value
    $encoded = $null
    $colon = $UnencodedApiKey.IndexOf(':')
    if ($colon -gt 0) {
        # Raw "id:key" form -- split on the FIRST colon and base64-encode the pair
        $key = $UnencodedApiKey.Substring($colon + 1)
        if ([string]::IsNullOrWhiteSpace($key)) {
            Write-Error "Malformed key: nothing after the ':'. Expected id:key."
            return
        }
        if ($UnencodedApiKey.Length -ne 43) {
            Write-Warning "Expected a 43-char id:key (20 + ':' + 22); got $($UnencodedApiKey.Length). Encoding anyway -- if auth fails, check the left side is the key ID, not its name."
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($UnencodedApiKey)
        $encoded = [System.Convert]::ToBase64String($bytes)
    }
    else {
        # No colon: it may already be the base64 'encoded' value -- detect and pass through
        $looksEncoded = $false
        try {
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($UnencodedApiKey))
            if ($decoded.Contains(':')) {
                $looksEncoded = $true
            }
        }
        catch {
            # not valid base64 -- falls through to the error below
        }
        if ($looksEncoded) {
            Write-Warning "No ':' found, but the value decodes to an id:key pair -- treating it as already-encoded."
            $encoded = $UnencodedApiKey
        }
        else {
            Write-Error "Input has no ':' and isn't a valid encoded key. Expected id:key (e.g. a 20-char id, ':', a 22-char key)."
            return
        }
    }

    # Build header
    $authHeader = "Authorization: ApiKey $encoded"
    $headers = @{
        Authorization = "ApiKey $encoded"
    }

    # Output header
    Write-Host "`nYour Authorization Header:"
    Write-Host $authHeader

    # Optional: copy to clipboard
    if ($CopyToClipboard) {
        Set-Clipboard -Value $authHeader
        Write-Host "`n(Header copied to clipboard $successSymbol)"
    }

    # Prompt for URL if not provided
    if (-not $Url) {
        $Url = Read-Host "`nEnter your Elasticsearch server URL (press Enter to skip connection test)"
    }

    # Test the connection only if URL was provided
    if ($Url) {
        Write-Host "`nTesting connection to $Url ..."
        try {
            $response = Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -ErrorAction Stop
            Write-Host "`n$successSymbol Connection successful. Cluster Info:"
            $response
        }
        catch {
            Write-Host "`n$failureSymbol Connection failed:"
            $_.Exception.Message
            if ($_.ErrorDetails) {
                Write-Host $_.ErrorDetails.Message
            }
        }
    }
    else {
        Write-Host "`nSkipping connection test as no URL was provided"
    }
}

# Export the function
Export-ModuleMember -Function Generate-Elastic-Key
