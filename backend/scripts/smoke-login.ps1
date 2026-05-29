param([string]$Email = "alice@school.fr", [string]$Password = "password")
$body = @{ email = $Email; password = $Password } | ConvertTo-Json
$res = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method Post -ContentType "application/json" -Body $body
$global:TOKEN = $res.token
$global:HEADERS = @{ Authorization = "Bearer $($res.token)" }
"Logged in as $($res.user.full_name) (id=$($res.user.id))"
